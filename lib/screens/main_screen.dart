import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/session.dart';
import '../models/store.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/session_service.dart';
import '../services/store_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_scaffold.dart';
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
  final _storeService = StoreService();

  Session? _session;
  Store? _store;
  Position? _position;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _loggingOut = false;
  bool _locating = true;
  bool _isFakeGps = false;

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
    _loadStore();
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

  Future<void> _loadStore() async {
    final s = await _storeService.loadStore();
    if (mounted) setState(() => _store = s);
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _startLocation() async {
    final granted = await _locService.ensurePermission()
        .timeout(const Duration(seconds: 5), onTimeout: () => false);
    if (!granted || !mounted) {
      setState(() => _locating = false);
      return;
    }

    final last = await _locService.getLastKnownPosition();
    if (last != null && mounted) {
      if (last.isMocked) {
        setState(() { _isFakeGps = true; _locating = false; });
      } else {
        setState(() { _position = last; _locating = false; });
      }
    }

    _locService.positionStream().listen((p) {
      if (!mounted) return;
      if (p.isMocked) {
        setState(() { _isFakeGps = true; _locating = false; });
      } else {
        setState(() { _isFakeGps = false; _position = p; _locating = false; });
      }
    });

    if (last == null) {
      final net = await _locService.getNetworkPosition();
      if (net != null && mounted && _position == null) {
        if (net.isMocked) {
          setState(() { _isFakeGps = true; _locating = false; });
        } else {
          setState(() { _position = net; _locating = false; });
        }
      }
    }
  }

  double? get _distanceMeters {
    final store = _store;
    final pos = _position;
    if (store == null || pos == null) return null;
    return Geolocator.distanceBetween(
      pos.latitude, pos.longitude,
      store.lat, store.lng,
    );
  }

  bool get _isInRange {
    final store = _store;
    final d = _distanceMeters;
    if (store == null || d == null) return false;
    return d <= store.radiusMeters;
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
    if (_isFakeGps) return 'Fake GPS terdeteksi!';
    if (_locating || _position == null) return 'Mengukur jarak...';
    final d = _distanceMeters;
    if (d == null) return 'Mengukur jarak...';
    final radius = _store?.radiusMeters.toInt() ?? 100;
    return '${d.toStringAsFixed(0)}m dari outlet (radius ${radius}m)';
  }

  Future<void> _checkin() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
    if (barcode == null || !mounted) return;

    final session = await _sessionService.loadSession();
    final parts = barcode.split('|');

    if (session == null) {
      final ok = await _showConfirm(
        title: 'Simpan data ke device?',
        body: 'Data dari barcode akan disimpan di device ini.',
      );
      if (!mounted) return;
      if (ok != true) return;
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
    }

    if (!mounted) return;
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckinConfirmScreen(session: _session!),
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        surfaceTintColor: Colors.white,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        surfaceTintColor: Colors.white,
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
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header: nama outlet + tombol logout
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _store?.name ?? _session?.outletName ?? 'Attendance',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnGrad,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  _loggingOut
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnGrad,
                          ),
                        )
                      : IconButton(
                          onPressed: _logout,
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.textOnGrad,
                          ),
                        ),
                ],
              ),
            ),

            // Banner Fake GPS
            if (_isFakeGps)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.errorGlass,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fake GPS terdeteksi! Matikan aplikasi pemalsuan lokasi.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Jam besar
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 28),
                      child: Column(
                        children: [
                          Text(
                            _clockStr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textOnGrad,
                              fontFeatures: [FontFeature.tabularFigures()],
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dateStr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSubOnGrad,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pill status GPS
                    Builder(builder: (context) {
                      final Color iconColor;
                      if (_isFakeGps) {
                        iconColor = AppColors.errorGlass;
                      } else if (_locating || _position == null) {
                        iconColor = Colors.white60;
                      } else if (_isInRange) {
                        iconColor = AppColors.successGlass;
                      } else {
                        iconColor = AppColors.errorGlass;
                      }

                      return GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_locating && !_isFakeGps)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white60),
                              )
                            else
                              Icon(
                                _isFakeGps
                                    ? Icons.warning_rounded
                                    : _isInRange
                                        ? Icons.location_on_rounded
                                        : Icons.location_off_rounded,
                                size: 16,
                                color: iconColor,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              _distanceStr(),
                              style: TextStyle(
                                fontSize: 13,
                                color: iconColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),

                    // Tombol Checkin
                    GradientButton(
                      height: 60,
                      // Kondisi persis dari kode sebelumnya: (!_isFakeGps && _isInRange)
                      onPressed: (!_isFakeGps && _isInRange) ? _checkin : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded,
                              size: 22, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _isFakeGps ? 'Fake GPS Aktif' : 'Checkin',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
