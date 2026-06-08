import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../models/gps_mode.dart';
import '../../services/attendance_service.dart';

class RiwayatTab extends StatefulWidget {
  const RiwayatTab({super.key});

  @override
  State<RiwayatTab> createState() => RiwayatTabState();
}

class RiwayatTabState extends State<RiwayatTab> {
  final _service = AttendanceService();
  List<AttendanceRecord> _all = [];
  bool _loading = true;
  late DateTime _selectedMonth;

  static const _namaHari = [
    'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'
  ];
  static const _namaBulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    final records = await _service.loadRecords();
    if (!mounted) return;
    setState(() {
      _all = records.reversed.toList();
      _loading = false;
    });
  }

  void reload() => _load();

  // Semua hari di bulan yang dipilih sampai hari ini
  List<DateTime> get _daysInMonth {
    final now = DateTime.now();
    final lastDay = (_selectedMonth.year == now.year &&
            _selectedMonth.month == now.month)
        ? now.day
        : DateUtils.getDaysInMonth(
            _selectedMonth.year, _selectedMonth.month);
    return List.generate(
      lastDay,
      (i) => DateTime(_selectedMonth.year, _selectedMonth.month, i + 1),
    ).reversed.toList();
  }

  AttendanceRecord? _recordForDay(DateTime day) {
    try {
      return _all.firstWhere((r) =>
          r.timestamp.year == day.year &&
          r.timestamp.month == day.month &&
          r.timestamp.day == day.day);
    } catch (_) {
      return null;
    }
  }

  void _prevMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });

  void _nextMonth() {
    final next =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isBefore(DateTime(DateTime.now().year,
        DateTime.now().month + 1))) {
      setState(() => _selectedMonth = next);
    }
  }

  Future<void> _konfirmasiHapus() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Semua Riwayat?'),
        content:
            const Text('Data absensi tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.clearRecords();
      setState(() => _all = []);
    }
  }

  String _formatTanggal(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '${_namaHari[dt.weekday % 7]}, $d/$mo/${dt.year}';
  }

  String _formatWaktu(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _modeColor(GpsMode m) {
    switch (m) {
      case GpsMode.flexible:
        return const Color(0xFFFF9800);
      case GpsMode.fixed:
        return const Color(0xFF1976D2);
      case GpsMode.antiFake:
        return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth;
    final hadirCount = days.where((d) => _recordForDay(d) != null).length;
    final tidakHadirCount = days.where((d) => _recordForDay(d) == null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Riwayat Absensi',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1A1A2E))),
        actions: [
          if (_all.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFFF7043)),
              onPressed: _konfirmasiHapus,
              tooltip: 'Hapus semua',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month selector
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(Icons.chevron_left_rounded,
                            size: 28),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        '${_namaBulan[_selectedMonth.month]} ${_selectedMonth.year}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E)),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right_rounded,
                            size: 28),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                // Stats bar
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      _StatChip(
                          label: 'Hadir',
                          value: '$hadirCount',
                          color: const Color(0xFF43A047)),
                      const SizedBox(width: 10),
                      _StatChip(
                          label: 'Tidak Hadir',
                          value: '$tidakHadirCount',
                          color: const Color(0xFFFF7043)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // List
                Expanded(
                  child: days.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 56,
                                  color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Tidak ada data bulan ini',
                                  style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              16, 4, 16, 20),
                          itemCount: days.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final day = days[i];
                            final r = _recordForDay(day);
                            return _RiwayatCard(
                              record: r,
                              tanggal: _formatTanggal(day),
                              masuk: r != null ? _formatWaktu(r.timestamp) : null,
                              modeColor: r != null ? _modeColor(r.gpsMode) : Colors.grey,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color)),
            Text(label,
                style:
                    TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final AttendanceRecord? record;
  final String tanggal;
  final String? masuk;
  final Color modeColor;

  const _RiwayatCard({
    required this.record,
    required this.tanggal,
    required this.masuk,
    required this.modeColor,
  });

  @override
  Widget build(BuildContext context) {
    final hadir = record != null;
    final inZone = record?.isInsideZone ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indikator hadir/tidak hadir
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hadir
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hadir ? Icons.check_rounded : Icons.close_rounded,
              color: hadir
                  ? const Color(0xFF43A047)
                  : const Color(0xFFE53935),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Tanggal & jam
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tanggal,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                if (hadir)
                  Row(
                    children: [
                      const Icon(Icons.login_rounded,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(masuk!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF43A047))),
                    ],
                  )
                else
                  Text('Tidak Hadir',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
          // Badge status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hadir
                      ? (inZone
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFBE9E7))
                      : const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hadir
                      ? (inZone ? 'Dalam Zona' : 'Luar Zona')
                      : 'Absen',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hadir
                          ? (inZone
                              ? const Color(0xFF43A047)
                              : const Color(0xFFFF7043))
                          : const Color(0xFFE53935)),
                ),
              ),
              if (hadir) ...[
                const SizedBox(height: 6),
                // GPS mode
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: modeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    record!.gpsMode.label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: modeColor),
                  ),
                ),
              ],
              if (record?.isMocked == true) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBE9E7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Fake GPS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFFF7043))),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
