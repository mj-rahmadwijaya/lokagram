import 'dart:io';

import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../models/gps_mode.dart';
import '../services/attendance_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = AttendanceService();
  List<AttendanceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _service.loadRecords();
    if (mounted) {
      setState(() {
        _records = records.reversed.toList();
        _loading = false;
      });
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text('Data absensi tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.clearRecords();
      setState(() => _records = []);
    }
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year}  $h:$mi';
  }

  Color _modeColor(GpsMode mode) {
    switch (mode) {
      case GpsMode.flexible:
        return Colors.orange;
      case GpsMode.fixed:
        return Colors.blue;
      case GpsMode.antiFake:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmClear,
              tooltip: 'Hapus semua',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Belum ada riwayat absensi',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _RecordCard(
                    record: _records[i],
                    formatDateTime: _formatDateTime,
                    modeColor: _modeColor,
                  ),
                ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final String Function(DateTime) formatDateTime;
  final Color Function(GpsMode) modeColor;

  const _RecordCard({
    required this.record,
    required this.formatDateTime,
    required this.modeColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        record.photoPath != null && File(record.photoPath!).existsSync();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasPhoto
                  ? Image.file(
                      File(record.photoPath!),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.person, color: Colors.grey, size: 32),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.employeeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(record.timestamp),
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Chip(
                        label: record.gpsMode.label,
                        color: modeColor(record.gpsMode),
                      ),
                      _Chip(
                        label: record.isInsideZone
                            ? 'Di dalam zona'
                            : 'Di luar zona',
                        color: record.isInsideZone
                            ? Colors.green
                            : Colors.red,
                      ),
                      if (record.isMocked)
                        const _Chip(
                          label: 'Fake GPS',
                          color: Colors.red,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
