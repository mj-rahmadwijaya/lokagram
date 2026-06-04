// dart:io → kelas File (untuk menampilkan foto dari path lokal).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // tipe Position dari stream GPS
import 'package:image_picker/image_picker.dart'; // akses kamera sistem

import '../models/allowed_zone.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import 'settings_screen.dart';

/// Layar utama: tampilkan status zona + tombol kamera + foto terakhir.
/// StatefulWidget karena UI berubah mengikuti GPS, izin, dan foto.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instance service (dibuat sekali, dipakai selama State hidup).
  final _locationService = LocationService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();

  // ---- State yang berubah (memicu rebuild lewat setState) ----
  AllowedZone? _zone; // zona tersimpan (null = belum di-set)
  File? _latestPhoto; // foto terakhir (null = belum ada). Cuma di memori.
  bool _permissionGranted = false; // status izin lokasi
  bool _loading = true; // true selama proses load awal

  /// Lifecycle: dipanggil sekali saat State dibuat.
  @override
  void initState() {
    super.initState();
    // initState tidak boleh 'async', jadi kerjaan async dipisah ke _initialize.
    _initialize();
  }

  /// Load awal: ambil zona tersimpan + minta izin lokasi.
  Future<void> _initialize() async {
    final zone = await _storageService.loadZone();
    final granted = await _locationService.ensurePermission();
    // 'mounted' check: pastikan widget masih ada sebelum setState.
    // Mencegah error kalau user keburu pindah layar saat await berjalan.
    if (!mounted) return;
    setState(() {
      _zone = zone;
      _permissionGranted = granted;
      _loading = false;
    });
  }

  /// Buka layar Settings dan tunggu hasilnya (pattern push + await pop).
  Future<void> _openSettings() async {
    // push<AllowedZone> → kita berharap layar tujuan pop dengan AllowedZone.
    final result = await Navigator.push<AllowedZone>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(initialZone: _zone),
      ),
    );
    // result null = user kembali tanpa menekan Simpan.
    if (result == null) return;
    await _storageService.saveZone(result); // simpan ke disk
    if (!mounted) return;
    setState(() => _zone = result); // perbarui UI dengan zona baru
  }

  /// Buka kamera sistem, ambil foto, lalu tampilkan di Home.
  Future<void> _takePhoto() async {
    // pickImage return XFile? (null kalau user batal).
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    if (!mounted) return;
    // Bungkus path jadi File agar bisa dipakai Image.file().
    setState(() => _latestPhoto = File(photo.path));
  }

  /// Tombol "Coba Lagi" saat izin lokasi ditolak: minta izin ulang.
  Future<void> _retryPermission() async {
    final granted = await _locationService.ensurePermission();
    if (!mounted) return;
    setState(() => _permissionGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokagram'),
        actions: [
          // Ikon gear di kanan atas → buka Settings.
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _buildBody(), // isi layar dipisah ke method agar rapi
    );
  }

  /// Pilih isi body berdasar kondisi: loading → izin → konten utama.
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_permissionGranted) {
      return _PermissionDeniedCard(onRetry: _retryPermission);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // anak melebar penuh
        children: [
          // StreamBuilder otomatis subscribe ke stream GPS dan rebuild
          // setiap ada update posisi (real-time, tanpa polling manual).
          StreamBuilder<Position>(
            stream: _locationService.positionStream(),
            builder: (context, snapshot) {
              // snapshot membawa state stream: error / data / belum ada data.
              if (snapshot.hasError) {
                return _StatusCard.error('GPS error: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const _StatusCard.loading();
              }
              // '!' = yakin tidak null (sudah dicek hasData di atas).
              return _buildStatusAndCamera(snapshot.data!);
            },
          ),
          // Spread '...[]' = render daftar widget HANYA jika ada foto.
          if (_latestPhoto != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Foto terakhir:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8), // sudut membulat
              child: Image.file(
                _latestPhoto!,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Bangun status card + tombol kamera berdasar posisi GPS saat ini.
  Widget _buildStatusAndCamera(Position position) {
    final zone = _zone;
    // Belum ada zona → tampilkan empty state + tombol disabled.
    if (zone == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StatusCard.empty(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: null, // null = tombol nonaktif
            icon: const Icon(Icons.camera_alt),
            label: const Text('Ambil Foto'),
          ),
        ],
      );
    }
    // Hitung jarak ke pusat zona → tentukan di dalam / di luar.
    final distance = _locationService.distanceTo(position, zone);
    final inZone = distance <= zone.radiusMeters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusCard.zone(
          inZone: inZone,
          distance: distance,
          radius: zone.radiusMeters,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          // Kamera hanya aktif kalau di dalam zona (ekspresi ternary).
          onPressed: inZone ? _takePhoto : null,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Ambil Foto'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

/// Widget kartu status yang dipakai ulang untuk semua kondisi.
/// Privat ('_') = hanya bisa dipakai di file ini.
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  // Constructor utama.
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  // ---- Named constructors: "preset" untuk tiap kondisi ----
  // Sintaks ': field = nilai' = initializer list (set field sebelum body).
  const _StatusCard.loading()
      : icon = Icons.gps_not_fixed,
        color = Colors.grey,
        title = 'Mencari lokasi...',
        subtitle = null;

  const _StatusCard.empty()
      : icon = Icons.location_off,
        color = Colors.orange,
        title = 'Belum ada zona',
        subtitle = 'Tap ⚙ Settings di pojok kanan atas untuk set lokasi';

  const _StatusCard.error(String message)
      : icon = Icons.error,
        color = Colors.red,
        title = 'Error',
        subtitle = message;

  /// Factory constructor: bisa berisi logika & memilih nilai sebelum return.
  /// Di sini: pilih warna/ikon hijau (di dalam) vs merah (di luar).
  factory _StatusCard.zone({
    required bool inZone,
    required double distance,
    required double radius,
  }) {
    if (inZone) {
      return _StatusCard(
        icon: Icons.check_circle,
        color: Colors.green,
        title: 'Di dalam zona',
        subtitle:
            'Jarak: ${distance.toStringAsFixed(0)}m / radius ${radius.toStringAsFixed(0)}m',
      );
    }
    return _StatusCard(
      icon: Icons.cancel,
      color: Colors.red,
      title: 'Di luar zona',
      subtitle:
          'Jarak: ${distance.toStringAsFixed(0)}m / radius ${radius.toStringAsFixed(0)}m',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // bayangan kartu
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            // Expanded → teks ambil sisa lebar (mencegah overflow).
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  // Subtitle hanya dirender kalau tidak null.
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget khusus saat izin lokasi ditolak: pesan + tombol coba lagi.
class _PermissionDeniedCard extends StatelessWidget {
  // VoidCallback = fungsi tanpa argumen & tanpa return (() -> void).
  final VoidCallback onRetry;

  const _PermissionDeniedCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // pusatkan vertikal
        children: [
          const Icon(Icons.location_disabled, size: 80, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Izin Lokasi Dibutuhkan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'App butuh izin akses lokasi untuk memantau posisi Anda. '
            'Pastikan GPS aktif dan izinkan akses lokasi.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
