import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/session.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/session_service.dart';
import 'barcode_scan_screen.dart';
import 'checkin_confirm_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _sessionService = SessionService();
  final _apiService = ApiService();
  final _locService = LocationService();

  Session? _session;
  Position? _position;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _loggingOut = false;

  static const _hari = [
    'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  ];
  static const _bulan = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    _loadSession();
    _startClock();
    _startLocation();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final s = await _sessionService.loadSession();
    if (mounted) setState(() => _session = s);
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _startLocation() async {
    final granted = await _locService.ensurePermission()
        .timeout(const Duration(seconds: 5), onTimeout: () => false);
    if (!granted || !mounted) return;
    _locService.positionStream().listen((p) {
      if (mounted) setState(() => _position = p);
    });
    final last = await _locService.getLastKnownPosition();
    if (last != null && mounted && _position == null) {
      setState(() => _position = last);
    }
  }

  String _clockStr() {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _dateStr() {
    return '${_hari[_now.weekday % 7]}, ${_now.day} ${_bulan[_now.month]} ${_now.year}';
  }

  String _distanceStr() {
    final session = _session;
    final pos = _position;
    if (session == null || pos == null) return 'Mengukur jarak...';
    final dist = Geolocator.distanceBetween(
      pos.latitude, pos.longitude,
      session.outletLat, session.outletLng,
    );
    final radius = 100; // default radius meter
    return 'Jarak ${dist.toStringAsFixed(0)}m / ${radius}m dari outlet';
  }

  Future<void> _checkin() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
    if (barcode == null || !mounted) return;

    // Validasi barcode vs session
    // Format dummy barcode: "staffId|outletId|uniqueId"
    final session = await _sessionService.loadSession();
    final parts = barcode.split('|');

    if (session == null) {
      // Belum ada session → tawaran simpan
      final ok = await _showConfirm(
        title: 'Simpan data ke device?',
        body: 'Data dari barcode akan disimpan di device ini.',
      );
      if (!mounted) return;
      if (ok != true) return;
      // Data dari barcode (format dummy), langsung lanjut
    } else {
      if (parts.length == 3) {
        final cocok = parts[0] == session.staffId &&
            parts[1] == session.outletId &&
            parts[2] == session.uniqueId;
        if (!cocok) {
          if (!mounted) return;
          await _showAlert(
            title: 'Data Tidak Cocok',
            body: 'Barcode tidak cocok dengan data device ini.',
          );
          return;
        }
      }
      // Data cocok atau format tidak dikenali → lanjut konfirmasi
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckinConfirmScreen(session: _session!),
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await _showConfirm(
      title: 'Keluar?',
      body: 'Anda akan keluar dari akun ini.',
    );
    if (ok != true || !mounted) return;

    setState(() => _loggingOut = true);
    final session = _session;
    if (session != null) {
      await _apiService.logout(token: session.token);
    }
    await _sessionService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, a, b) => const LoginScreen(),
        transitionsBuilder: (context, anim, b, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (_) => false,
    );
  }

  Future<bool?> _showConfirm({
    required String title,
    required String body,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAlert({required String title, required String body}) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _session?.outletName ?? 'Attendance',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF1A1A2E)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF1976D2)),
            tooltip: 'Riwayat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          _loggingOut
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _logout,
                  child: const Text('logout',
                      style: TextStyle(color: Color(0xFFE53935))),
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_available_rounded,
                    size: 56, color: Color(0xFF1976D2)),
              ),
            ),
            const SizedBox(height: 32),

            // Jarak
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: Color(0xFF1976D2)),
                  const SizedBox(width: 6),
                  Text(
                    _distanceStr(),
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Jam
            Text(
              _clockStr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),

            // Tanggal
            Text(
              _dateStr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 48),

            // Tombol Checkin
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _checkin,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                label: const Text('Checkin',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
