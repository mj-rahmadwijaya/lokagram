import 'package:flutter/material.dart';

/// Konstanta warna untuk tema Glass / Gradient Bold.
///
/// Semua nilai bersifat [const] sehingga dapat digunakan di
/// `const` constructor tanpa overhead runtime.
class AppColors {
  AppColors._();

  // --- Gradient utama (biru-ungu) ---
  static const Color gradStart = Color(0xFF0D47A1);
  static const Color gradMid = Color(0xFF1565C0);
  static const Color gradEnd = Color(0xFF6A1B9A);

  // --- Gradient sekunder (biru muda) ---
  static const Color gradSecStart = Color(0xFF1E88E5);
  static const Color gradSecEnd = Color(0xFF42A5F5);

  // --- Efek kaca (glass) ---
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // --- Teks di atas gradient ---
  static const Color textOnGrad = Color(0xFFFFFFFF);
  static const Color textSubOnGrad = Color(0xCCFFFFFF);

  // --- Status ---
  static const Color successGlass = Color(0xFF00C853);
  static const Color errorGlass = Color(0xFFFF1744);
  static const Color warningGlass = Color(0xFFFF9100);
}

/// Koleksi [LinearGradient] standar yang dipakai di seluruh aplikasi.
class AppGradients {
  AppGradients._();

  /// Gradient utama biru-ungu — digunakan sebagai latar layar utama.
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.gradStart, AppColors.gradMid, AppColors.gradEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradient sekunder biru muda — digunakan untuk tombol dan aksen.
  static const LinearGradient secondary = LinearGradient(
    colors: [AppColors.gradSecStart, AppColors.gradSecEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
