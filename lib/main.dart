// Import paket Material Design — berisi widget dasar Flutter (MaterialApp,
// Scaffold, AppBar, Text, dll). Hampir semua app Flutter mulai dari sini.
import 'package:flutter/material.dart';

// Import file lokal pakai path relatif. HomeScreen = layar pertama yang tampil.
import 'screens/home_screen.dart';

/// Entry point aplikasi — fungsi pertama yang dijalankan Dart (seperti main()
/// di C/Go/Java). runApp() melampirkan widget root ke layar & mulai event loop.
void main() {
  runApp(const LokagramApp());
}

/// Widget root aplikasi.
/// StatelessWidget = widget yang TIDAK punya state berubah (config statis).
class LokagramApp extends StatelessWidget {
  // Constructor const → Flutter bisa cache instance ini (optimisasi).
  // super.key = identitas widget untuk proses diffing widget tree.
  const LokagramApp({super.key});

  // build() = method WAJIB tiap widget. Flutter panggil saat perlu render.
  // Return-nya adalah widget tree yang akan ditampilkan.
  @override
  Widget build(BuildContext context) {
    // MaterialApp = root untuk app bergaya Material Design. Menyediakan
    // theming, navigasi (Navigator), dan konfigurasi global.
    return MaterialApp(
      title: 'Lokagram',
      theme: ThemeData(
        // Material 3: generate seluruh palet warna otomatis dari 1 warna seed.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // home = widget yang dirender saat app pertama kali dibuka.
      home: const HomeScreen(),
    );
  }
}
