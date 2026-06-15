import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/attendance_record.dart';
import '../models/session.dart';
import '../services/attendance_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_scaffold.dart';

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
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textOnGrad),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Konfirmasi Absensi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.textOnGrad,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ikon konfirmasi dalam GlassCard bulat dengan aksen hijau
            Center(
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 44,
                color: const Color(0x3300C853),
                child: const Icon(
                  Icons.how_to_reg_rounded,
                  size: 48,
                  color: AppColors.textOnGrad,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Nama karyawan
            Text(
              widget.session.employeeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnGrad,
              ),
            ),
            const SizedBox(height: 6),

            // Nama outlet
            Text(
              widget.session.outletName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSubOnGrad,
              ),
            ),
            const SizedBox(height: 32),

            // Pertanyaan konfirmasi dalam GlassCard persegi panjang
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: const Text(
                'Apakah anda yakin absensi?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textOnGrad,
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Tombol Ya — GradientButton dengan gradien hijau
            GradientButton(
              height: 52,
              borderRadius: 14,
              colors: const [AppColors.successGlass, Color(0xFF00E676)],
              onPressed: _saving ? null : _confirm,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text(
                      'Ya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnGrad,
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            // Tombol Tidak — GlassCard tipis sebagai tombol sekunder
            GlassCard(
              padding: EdgeInsets.zero,
              borderRadius: 14,
              child: SizedBox(
                height: 52,
                child: InkWell(
                  onTap: _saving ? null : () => Navigator.pop(context, false),
                  borderRadius: BorderRadius.circular(14),
                  child: const Center(
                    child: Text(
                      'Tidak',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xB3FFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
