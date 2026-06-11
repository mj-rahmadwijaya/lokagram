import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/attendance_record.dart';
import '../models/session.dart';
import '../services/attendance_service.dart';

class CheckinConfirmScreen extends StatefulWidget {
  final Session session;
  final String? barcodeData;

  const CheckinConfirmScreen({
    super.key,
    required this.session,
    this.barcodeData,
  });

  @override
  State<CheckinConfirmScreen> createState() => _CheckinConfirmScreenState();
}

class _CheckinConfirmScreenState extends State<CheckinConfirmScreen> {
  bool _saving = false;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final record = AttendanceRecord(
        id: now.millisecondsSinceEpoch.toString(),
        employeeName: widget.session.employeeName,
        timestamp: now,
        lat: 0,
        lng: 0,
        isInsideZone: true,
        isMocked: false,
        barcodeData: widget.barcodeData,
      );
      await AttendanceService().saveRecord(record);
      if (!mounted) return;
      ShadToaster.of(context).show(
          const ShadToast(description: Text('Check-in berhasil!')));
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Konfirmasi Absensi',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF1A1A2E))),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.how_to_reg_rounded,
                    size: 48, color: Color(0xFF43A047)),
              ),
            ),
            const SizedBox(height: 28),

            // Nama
            Text(
              widget.session.employeeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 6),

            // Outlet
            Text(
              widget.session.outletName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Pertanyaan
            const Text(
              'Apakah anda yakin absensi?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 36),

            // Tombol Ya
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Ya',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // Tombol Tidak
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Tidak',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
