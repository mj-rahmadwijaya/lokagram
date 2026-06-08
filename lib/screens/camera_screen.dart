import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/attendance_record.dart';
import '../models/store.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';

class CameraScreen extends StatefulWidget {
  final String employeeName;
  final double lat;
  final double lng;
  final Store store;
  final bool isMocked;

  const CameraScreen({
    super.key,
    required this.employeeName,
    required this.lat,
    required this.lng,
    required this.store,
    required this.isMocked,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _attendanceService = AttendanceService();
  final _locationService = LocationService();

  XFile? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  Future<void> _takePhoto() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );
    if (photo == null && mounted) {
      Navigator.pop(context, false);
      return;
    }
    if (mounted) setState(() => _photo = photo);
  }

  Future<void> _save() async {
    if (_photo == null) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final record = AttendanceRecord(
      id: now.millisecondsSinceEpoch.toString(),
      employeeName: widget.employeeName,
      timestamp: now,
      photoPath: _photo!.path,
      lat: widget.lat,
      lng: widget.lng,
      isInsideZone:
          _locationService.isInsideZone(widget.lat, widget.lng, widget.store),
      isMocked: widget.isMocked,
      gpsMode: widget.store.gpsMode,
    );

    await _attendanceService.saveRecord(record);
    if (mounted) Navigator.pop(context, true);
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/${dt.year}  $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Absensi')),
      body: _photo == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photo!.path),
                      height: 320,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShadCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person,
                          label: 'Karyawan',
                          value: widget.employeeName,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.access_time,
                          label: 'Waktu',
                          value: _formatDateTime(DateTime.now()),
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.store,
                          label: 'Store',
                          value: widget.store.name,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.gps_fixed,
                          label: 'Mode GPS',
                          value: widget.store.gpsMode.label,
                        ),
                        if (widget.isMocked) ...[
                          const Divider(height: 20),
                          const _InfoRow(
                            icon: Icons.warning,
                            label: 'Peringatan',
                            value: 'Fake GPS terdeteksi',
                            valueColor: Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: _saving ? null : _save,
                      leading: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 16),
                      child: Text(_saving ? 'Menyimpan...' : 'Konfirmasi Absensi'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton.outline(
                      onPressed: _saving ? null : _takePhoto,
                      leading: const Icon(Icons.camera_alt, size: 16),
                      child: const Text('Ambil Ulang'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
