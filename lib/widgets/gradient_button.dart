import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Tombol dengan latar gradient dan efek bayangan halus.
///
/// Saat [onPressed] bernilai `null`, tombol tampak pudar (opacity 0.4)
/// dan tidak dapat ditekan — [InkWell] secara otomatis menonaktifkan
/// interaksi ketika `onTap` adalah `null`.
class GradientButton extends StatelessWidget {
  /// Callback saat tombol ditekan. Set `null` untuk menonaktifkan tombol.
  final VoidCallback? onPressed;

  /// Konten dalam tombol (biasanya [Text] berwarna putih).
  final Widget child;

  /// Warna gradient tombol.
  /// Default: [[AppColors.gradSecStart], [AppColors.gradSecEnd]].
  final List<Color>? colors;

  /// Tinggi tombol. Default: 56.
  final double height;

  /// Radius sudut tombol. Default: 16.
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colors,
    this.height = 56,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColors = colors ??
        const [AppColors.gradSecStart, AppColors.gradSecEnd];
    final radius = BorderRadius.circular(borderRadius);

    return AnimatedOpacity(
      opacity: onPressed == null ? 0.4 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: effectiveColors),
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x401E88E5),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
