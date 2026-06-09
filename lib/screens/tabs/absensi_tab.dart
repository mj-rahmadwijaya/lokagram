import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/attendance_record.dart';
import '../../models/gps_mode.dart';
import '../../models/store.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../services/store_service.dart';
import '../camera_screen.dart';
import '../store_settings_screen.dart';

class AbsensiTab extends StatefulWidget {
  final VoidCallback onRiwayat;
  const AbsensiTab({super.key, required this.onRiwayat});

  @override
  State<AbsensiTab> createState() => AbsensiTabState();
}

class AbsensiTabState extends State<AbsensiTab> {
  final _locService = LocationService();
  final _storeService = StoreService();
  final _attendanceService = AttendanceService();
  final _nameCtrl = TextEditingController();

  Store? _store;
  bool _loading = true;
  AttendanceRecord? _todayRecord;

  Position? _position;
  bool _isMocked = false;
  bool _gpsTimeout = false;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<ServiceStatus>? _serviceSub;

  // Fake GPS
  bool _fakeGpsEnabled = false;
  double _fakeLat = -6.2088;
  double _fakeLng = 106.8456;

  // Flexible mode — pin yang bisa digeser di peta
  LatLng? _flexPin;
  final _mapCtrl = MapController();

  // Clock
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

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
    _initialize();
    _clockTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) { if (mounted) setState(() => _now = DateTime.now()); });
    // Listen GPS service — mulai tracking otomatis saat GPS dinyalakan
    _serviceSub = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.enabled && mounted) {
        _refreshFakeGps().then((_) => _startTracking());
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _serviceSub?.cancel();
    _clockTimer?.cancel();
    _nameCtrl.dispose();
    _mapCtrl.dispose();
    super.dispose();
  }

  // Dipanggil MainScreen setiap kali tab Absensi dipilih
  Future<void> refresh() async {
    await _refreshFakeGps();
    // Restart tracking agar posisi terbaru diambil
    final granted = await _locService.ensurePermission()
        .timeout(const Duration(seconds: 3), onTimeout: () => false);
    if (granted && mounted) _startTracking();
  }

  Future<void> _refreshFakeGps() async {
    final prefs = await SharedPreferences.getInstance();
    final today = await _attendanceService.todayRecord();
    if (!mounted) return;
    setState(() {
      _fakeGpsEnabled = prefs.getBool('dev_fake_gps') ?? false;
      _fakeLat = prefs.getDouble('dev_fake_lat') ?? -6.2088;
      _fakeLng = prefs.getDouble('dev_fake_lng') ?? 106.8456;
      _todayRecord = today;
      if (_position != null) {
        _isMocked = _fakeGpsEnabled || _position!.isMocked;
      }
    });
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final store = await _storeService.loadStore();
      final savedName = prefs.getString('employee_name') ?? '';
      final fakeEnabled = prefs.getBool('dev_fake_gps') ?? false;
      final fakeLat = prefs.getDouble('dev_fake_lat') ?? -6.2088;
      final fakeLng = prefs.getDouble('dev_fake_lng') ?? 106.8456;
      final todayRecord = await _attendanceService.todayRecord();
      if (!mounted) return;
      // Tampilkan UI dulu, GPS tracking menyusul di background
      _nameCtrl.text = savedName;
      setState(() {
        _store = store;
        _fakeGpsEnabled = fakeEnabled;
        _fakeLat = fakeLat;
        _fakeLng = fakeLng;
        _todayRecord = todayRecord;
        _loading = false;
      });
      final granted = await _locService.ensurePermission()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      if (granted && mounted) _startTracking();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startTracking() async {
    await _posSub?.cancel();
    _posSub = null;
    if (mounted) setState(() { _position = null; _gpsTimeout = false; });

    final last = await _locService.getLastKnownPosition();
    if (last != null && mounted) {
      setState(() { _position = last; _isMocked = _fakeGpsEnabled || last.isMocked; });
    }

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _position == null) setState(() => _gpsTimeout = true);
    });

    _locService.getNetworkPosition().then((p) {
      if (p != null && mounted && _position == null) {
        setState(() { _position = p; _isMocked = _fakeGpsEnabled || p.isMocked; _gpsTimeout = false; });
      }
    });

    _posSub = _locService.positionStream().listen((p) {
      if (mounted) setState(() { _position = p; _isMocked = _fakeGpsEnabled || p.isMocked; _gpsTimeout = false; });
    });
  }

  Future<void> _reloadStore() async {
    final store = await _storeService.loadStore();
    if (mounted) setState(() => _store = store);
  }

  bool get _isFlexible => _store?.gpsMode == GpsMode.flexible;

  double get _effectiveLat {
    if (_isFlexible) return _flexPin?.latitude ?? (_position?.latitude ?? 0);
    if (_fakeGpsEnabled) return _fakeLat;
    return _position?.latitude ?? 0;
  }

  double get _effectiveLng {
    if (_isFlexible) return _flexPin?.longitude ?? (_position?.longitude ?? 0);
    if (_fakeGpsEnabled) return _fakeLng;
    return _position?.longitude ?? 0;
  }

  bool get _hasPosition {
    if (_isFlexible) return _flexPin != null || _position != null;
    return _fakeGpsEnabled || _position != null;
  }

  bool get _isValid {
    final store = _store;
    if (store == null) return false;
    if (!_hasPosition) return false;
    if (store.gpsMode == GpsMode.antiFake && _isMocked) return false;
    return _locService.isInsideZone(_effectiveLat, _effectiveLng, store);
  }

  Future<void> _checkIn() async {
    final confirmed = await showShadSheet<bool>(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_front,
                    size: 40, color: Color(0xFF43A047)),
              ),
              const SizedBox(height: 14),
              const Text('Siap Check In?',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Pastikan wajah terlihat jelas di kamera depan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  leading: const Icon(Icons.camera_alt, size: 16),
                  child: const Text('Buka Kamera'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ShadButton.ghost(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final store = _store!;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          employeeName: _nameCtrl.text.trim(),
          lat: _effectiveLat,
          lng: _effectiveLng,
          store: store,
          isMocked: _isMocked,
        ),
      ),
    );
    if (result == true && mounted) {
      final today = await _attendanceService.todayRecord();
      if (mounted) setState(() => _todayRecord = today);
      ShadToaster.of(context).show(const ShadToast(
          description: Text('Check in berhasil!')));
    }
  }

  Future<void> _checkOut() async {
    final confirmed = await showShadSheet<bool>(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 40, color: Color(0xFFFF9800)),
              ),
              const SizedBox(height: 14),
              const Text('Konfirmasi Check Out?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Pastikan Anda sudah selesai bekerja hari ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Check Out Sekarang',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ShadButton.ghost(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    await _attendanceService.saveCheckOut(
        _todayRecord!.id, DateTime.now());
    final today = await _attendanceService.todayRecord();
    if (!mounted) return;
    setState(() => _todayRecord = today);
    ShadToaster.of(context).show(const ShadToast(
        description: Text('Check out berhasil!')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Absensi',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1A1A2E))),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined,
                color: Color(0xFF1A1A2E)),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          StoreSettingsScreen(initialStore: _store)));
              await _reloadStore();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Peta
                  _buildMap(),
                  const SizedBox(height: 16),

                  // Info Lokasi
                  _buildLocationInfo(),
                  const SizedBox(height: 20),

                  // Jam digital
                  _buildClock(),
                  const SizedBox(height: 24),

                  // Tombol Check In
                  _buildButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildMap() {
    final store = _store;
    final pos = _position;

    if (store == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Store belum dikonfigurasi',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }

    final storePos = LatLng(store.lat, store.lng);
    final empPos = _hasPosition
        ? LatLng(_effectiveLat, _effectiveLng)
        : (pos != null ? LatLng(pos.latitude, pos.longitude) : null);

    final isFlexible = store.gpsMode == GpsMode.flexible;

    final mapOptions = isFlexible
        ? MapOptions(
            initialCenter: _flexPin ?? storePos,
            initialZoom: 16,
            onTap: (_, point) => setState(() => _flexPin = point),
          )
        : empPos != null
            ? MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints([storePos, empPos]),
                  padding: const EdgeInsets.all(60),
                  maxZoom: 17,
                ),
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
              )
            : MapOptions(
                initialCenter: storePos,
                initialZoom: 16,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.none),
              );

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: mapOptions,
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'io.grandepos.lokagram',
                ),
                CircleLayer(circles: [
                  CircleMarker(
                    point: storePos,
                    radius: store.radiusMeters,
                    useRadiusInMeter: true,
                    color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                    borderColor: const Color(0xFF1976D2),
                    borderStrokeWidth: 2,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: storePos,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.store_rounded,
                        color: Color(0xFF1976D2), size: 36),
                  ),
                  if (empPos != null)
                    Marker(
                      point: empPos,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        isFlexible
                            ? Icons.location_pin
                            : Icons.person_pin_circle_rounded,
                        color: _isValid
                            ? const Color(0xFF43A047)
                            : const Color(0xFFFF7043),
                        size: 36,
                      ),
                    ),
                ]),
              ],
            ),
            // Hint tap untuk flexible mode
            if (isFlexible)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Tap di peta untuk set lokasi Anda',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    final store = _store;
    if (store == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: Colors.grey, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lokasi Toko',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  const Text('Store belum dikonfigurasi',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final inZone = _hasPosition &&
        _locService.isInsideZone(_effectiveLat, _effectiveLng, store);
    final distance = _hasPosition
        ? _locService.distanceTo(_effectiveLat, _effectiveLng, store)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Color(0xFF1976D2), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lokasi Toko',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(store.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (distance != null)
                  Text(
                    '${distance.toStringAsFixed(0)}m dari titik store',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (!_hasPosition && _gpsTimeout)
            GestureDetector(
              onTap: () {
                setState(() => _gpsTimeout = false);
                _initialize();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Coba Lagi',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF7043),
                        fontWeight: FontWeight.w600)),
              ),
            )
          else if (!_hasPosition)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            _buildStatusBadge(inZone),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool inZone) {
    if (_store?.gpsMode == GpsMode.antiFake && _isMocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE9E7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Fake GPS',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFFFF7043),
                fontWeight: FontWeight.w600)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: inZone
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        inZone ? 'Dalam Radius' : 'Diluar Radius',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: inZone
              ? const Color(0xFF43A047)
              : const Color(0xFFFF7043),
        ),
      ),
    );
  }

  Widget _buildClock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _clockStr(),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _dateStr(),
            style: const TextStyle(
                fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          // GPS mode badge
          if (_store != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Mode: ${_store!.gpsMode.label}',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final today = _todayRecord;
    final checkedIn = today != null;
    final checkedOut = today?.checkOutTime != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status selesai
        if (checkedIn && checkedOut) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF43A047), size: 36),
                SizedBox(height: 8),
                Text('Absensi selesai hari ini',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF43A047),
                        fontSize: 15)),
              ],
            ),
          ),
        ] else if (!checkedIn) ...[
          // Check In
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isValid ? _checkIn : null,
              icon: const Icon(Icons.login_rounded, size: 20),
              label: const Text('Check In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          if (!_isValid && _store != null) ...[
            const SizedBox(height: 10),
            _buildHint(),
          ],
        ] else ...[
          // Check Out
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isValid ? _checkOut : null,
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Check Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          if (!_isValid && _store != null) ...[
            const SizedBox(height: 10),
            _buildHint(),
          ],
        ],

        const SizedBox(height: 12),
        // Lihat Riwayat
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: widget.onRiwayat,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: const Text('Lihat Riwayat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1976D2),
              side: const BorderSide(color: Color(0xFF1976D2)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHint() {
    String msg;
    if (_store == null) {
      msg = 'Konfigurasi store terlebih dahulu';
    } else if (!_hasPosition) {
      msg = _gpsTimeout
          ? 'GPS tidak terdeteksi — tap Coba Lagi'
          : 'Menunggu sinyal GPS...';
    } else if (_store!.gpsMode == GpsMode.antiFake && _isMocked) {
      msg = 'Matikan fake GPS untuk check in';
    } else {
      msg = 'Posisi di luar radius store';
    }
    return Text(msg,
        textAlign: TextAlign.center,
        style:
            const TextStyle(color: Colors.grey, fontSize: 12));
  }
}
