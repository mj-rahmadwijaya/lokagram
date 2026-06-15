import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Kartu dengan efek kaca (glassmorphism).
///
/// Menggunakan [BackdropFilter] dan [ImageFilter.blur] untuk menghasilkan
/// efek blur pada konten di belakang kartu. Pastikan widget ini diletakkan
/// di atas konten yang memiliki warna/gambar agar efek blur terlihat.
class GlassCard extends StatelessWidget {
  /// Konten yang ditampilkan di dalam kartu.
  final Widget child;

  /// Padding dalam kartu. Default: [EdgeInsets.all(16)].
  final EdgeInsetsGeometry? padding;

  /// Radius sudut kartu. Default: 20.
  final double borderRadius;

  /// Kekuatan efek blur (sigma). Default: 12.
  final double blurSigma;

  /// Warna latar kaca. Default: [AppColors.glassWhite].
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blurSigma = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final effectiveColor = color ?? AppColors.glassWhite;
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: radius,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
