import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../widgets/app_theme.dart';
import '../widgets/glass_card.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _detected = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value == null) return;
    _detected = true;
    _ctrl.stop();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Scan Barcode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GlassCard(
              borderRadius: 50,
              blurSigma: 8,
              color: const Color(0x33000000),
              padding: const EdgeInsets.all(4),
              child: IconButton(
                icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                onPressed: () => _ctrl.toggleTorch(),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),
          // Frame overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.gradSecEnd,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Sudut kiri atas
                  Positioned(
                    top: -1,
                    left: -1,
                    child: _CornerAccent(alignment: Alignment.topLeft),
                  ),
                  // Sudut kanan atas
                  Positioned(
                    top: -1,
                    right: -1,
                    child: _CornerAccent(alignment: Alignment.topRight),
                  ),
                  // Sudut kiri bawah
                  Positioned(
                    bottom: -1,
                    left: -1,
                    child: _CornerAccent(alignment: Alignment.bottomLeft),
                  ),
                  // Sudut kanan bawah
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: _CornerAccent(alignment: Alignment.bottomRight),
                  ),
                ],
              ),
            ),
          ),
          // Hint text
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GlassCard(
                blurSigma: 8,
                color: const Color(0x33000000),
                borderRadius: 20,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text(
                  'Arahkan kamera ke barcode / QR Code',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget sudut aksen untuk frame panduan scan.
///
/// Menggambar garis sudut tebal berwarna putih di salah satu dari empat posisi
/// sudut frame (ditentukan oleh [alignment]).
class _CornerAccent extends StatelessWidget {
  final Alignment alignment;

  const _CornerAccent({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;

    return CustomPaint(
      size: const Size(24, 24),
      painter: _CornerPainter(isTop: isTop, isLeft: isLeft),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;

  const _CornerPainter({required this.isTop, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final dx = isLeft ? size.width : -size.width;
    final dy = isTop ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) =>
      oldDelegate.isTop != isTop || oldDelegate.isLeft != isLeft;
}
