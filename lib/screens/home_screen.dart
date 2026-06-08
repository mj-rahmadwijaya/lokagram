import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/gps_mode.dart';
import '../models/store.dart';
import '../services/location_service.dart';
import '../services/store_service.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'store_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationService = LocationService();
  final _storeService = StoreService();
  final _nameController = TextEditingController();

  Store? _store;
  bool _loading = true;
  bool _permissionGranted = false;

  Position? _latestPosition;
  bool _isMocked = false;
  bool _gpsTimeout = false;
  StreamSubscription<Position>? _positionSub;

  LatLng? _flexPosition;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final store = await _storeService.loadStore();
    final savedName = prefs.getString('employee_name') ?? '';
    final granted = await _locationService.ensurePermission();

    if (!mounted) return;

    _nameController.text = savedName;

    if (granted) await _startLocationTracking();

    setState(() {
      _store = store;
      _permissionGranted = granted;
      _loading = false;
      if (store != null) _flexPosition = LatLng(store.lat, store.lng);
    });
  }

  Future<void> _startLocationTracking() async {
    await _positionSub?.cancel();
    _positionSub = null;
    if (mounted) setState(() { _latestPosition = null; _gpsTimeout = false; });

    final lastPos = await _locationService.getLastKnownPosition();
    if (lastPos != null && mounted) {
      setState(() { _latestPosition = lastPos; _isMocked = lastPos.isMocked; });
    }

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _latestPosition == null) setState(() => _gpsTimeout = true);
    });

    _locationService.getNetworkPosition().then((networkPos) {
      if (networkPos != null && mounted && _latestPosition == null) {
        setState(() { _latestPosition = networkPos; _isMocked = networkPos.isMocked; _gpsTimeout = false; });
      }
    });

    _positionSub = _locationService.positionStream().listen((pos) {
      if (mounted) setState(() { _latestPosition = pos; _isMocked = pos.isMocked; _gpsTimeout = false; });
    });
  }

  Future<void> _reloadStore() async {
    final store = await _storeService.loadStore();
    if (mounted) setState(() {
      _store = store;
      if (store != null) _flexPosition = LatLng(store.lat, store.lng);
    });
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('employee_name', name);
  }

  bool get _isValid {
    final store = _store;
    if (store == null || _nameController.text.trim().isEmpty) return false;
    switch (store.gpsMode) {
      case GpsMode.flexible:
        final flex = _flexPosition;
        if (flex == null) return false;
        return _locationService.isInsideZone(flex.latitude, flex.longitude, store);
      case GpsMode.fixed:
        final pos = _latestPosition;
        if (pos == null) return false;
        return _locationService.isInsideZone(pos.latitude, pos.longitude, store);
      case GpsMode.antiFake:
        final pos = _latestPosition;
        if (pos == null || _isMocked) return false;
        return _locationService.isInsideZone(pos.latitude, pos.longitude, store);
    }
  }

  Future<void> _openCamera() async {
    final confirmed = await showShadSheet<bool>(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (sheetContext) => SafeArea(
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
              Icon(Icons.camera_front, size: 60,
                  color: Theme.of(sheetContext).colorScheme.primary),
              const SizedBox(height: 12),
              const Text('Siap Absen?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Pastikan wajah terlihat jelas di kamera depan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  leading: const Icon(Icons.camera_alt, size: 16),
                  child: const Text('Buka Kamera'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ShadButton.ghost(
                  onPressed: () => Navigator.pop(sheetContext, false),
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
    double lat, lng;
    if (store.gpsMode == GpsMode.flexible) {
      lat = _flexPosition!.latitude;
      lng = _flexPosition!.longitude;
    } else {
      lat = _latestPosition!.latitude;
      lng = _latestPosition!.longitude;
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          employeeName: _nameController.text.trim(),
          lat: lat,
          lng: lng,
          store: store,
          isMocked: _isMocked,
        ),
      ),
    );
    if (result == true && mounted) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Absensi berhasil disimpan!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
            tooltip: 'Riwayat',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreSettingsScreen(initialStore: _store),
                ),
              );
              await _reloadStore();
            },
            tooltip: 'Pengaturan',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (!_permissionGranted) return _PermissionDeniedCard(
      onRetry: () async {
        final granted = await _locationService.ensurePermission();
        if (!mounted) return;
        setState(() => _permissionGranted = granted);
        if (granted) await _startLocationTracking();
      },
    );
    if (_store == null) return _NoStoreCard(
      onSetup: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => const StoreSettingsScreen(initialStore: null),
        ));
        await _reloadStore();
      },
    );

    final store = _store!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNameCard(),
                const SizedBox(height: 12),
                _buildStoreCard(store),
                const SizedBox(height: 12),
                _buildLocationSection(store),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isValid && _store != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildHint(store),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: _isValid ? _openCamera : null,
                    leading: const Icon(Icons.camera_alt, size: 18),
                    child: const Text(
                      'Absen Sekarang',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameCard() {
    return ShadInput(
      controller: _nameController,
      placeholder: const Text('Masukkan nama karyawan'),
      leading: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.person_outline, size: 18, color: Colors.grey),
      ),
      onChanged: _saveName,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildStoreCard(Store store) {
    final modeColors = {
      GpsMode.flexible: Colors.orange,
      GpsMode.fixed: Colors.blue,
      GpsMode.antiFake: Colors.green,
    };
    final color = modeColors[store.gpsMode]!;
    return ShadCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.store, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Radius ${store.radiusMeters.toStringAsFixed(0)}m',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(store.gpsMode.label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(Store store) {
    switch (store.gpsMode) {
      case GpsMode.flexible:
        return _buildFlexibleMap(store);
      case GpsMode.fixed:
        return _buildGpsStatusCard(store, showMockWarning: false);
      case GpsMode.antiFake:
        return _buildGpsStatusCard(store, showMockWarning: true);
    }
  }

  Widget _buildFlexibleMap(Store store) {
    final storeCenter = LatLng(store.lat, store.lng);
    final flexPos = _flexPosition ?? storeCenter;
    final inZone = _locationService.isInsideZone(flexPos.latitude, flexPos.longitude, store);

    return Column(
      children: [
        _StatusCard(
          icon: inZone ? Icons.check_circle : Icons.cancel,
          color: inZone ? Colors.green : Colors.orange,
          title: inZone ? 'Posisi di dalam zona' : 'Posisi di luar zona',
          subtitle: 'Tap peta untuk memindahkan posisi Anda',
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: storeCenter,
                initialZoom: 16,
                onTap: (_, point) => setState(() => _flexPosition = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'io.grandepos.lokagram',
                ),
                CircleLayer(circles: [
                  CircleMarker(
                    point: storeCenter,
                    radius: store.radiusMeters,
                    useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.15),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: storeCenter,
                    width: 36, height: 36,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.store, color: Colors.blue, size: 36),
                  ),
                  Marker(
                    point: flexPos,
                    width: 36, height: 36,
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.person_pin_circle,
                      color: inZone ? Colors.green : Colors.red,
                      size: 36,
                    ),
                  ),
                  if (_latestPosition != null)
                    Marker(
                      point: LatLng(_latestPosition!.latitude, _latestPosition!.longitude),
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsStatusCard(Store store, {required bool showMockWarning}) {
    final pos = _latestPosition;
    if (pos == null) {
      return Column(
        children: [
          if (_gpsTimeout)
            ShadCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gps_off, size: 40, color: Colors.orange),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GPS Tidak Terdeteksi',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Pastikan GPS aktif dan berada di area terbuka',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton.outline(
                      onPressed: () {
                        setState(() => _gpsTimeout = false);
                        _initialize();
                      },
                      leading: const Icon(Icons.refresh, size: 16),
                      child: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              ),
            )
          else
            ShadCard(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mencari sinyal GPS...',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pastikan GPS aktif dan ada di area terbuka',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _buildPositionMap(store),
        ],
      );
    }
    final distance = _locationService.distanceTo(pos.latitude, pos.longitude, store);
    final inZone = distance <= store.radiusMeters;
    return Column(
      children: [
        if (showMockWarning && _isMocked)
          const _StatusCard(
            icon: Icons.warning_amber,
            color: Colors.red,
            title: 'Fake GPS Terdeteksi!',
            subtitle: 'Matikan aplikasi mock GPS untuk melanjutkan absensi',
          )
        else
          _StatusCard(
            icon: inZone ? Icons.check_circle : Icons.cancel,
            color: inZone ? Colors.green : Colors.red,
            title: inZone ? 'Di dalam zona' : 'Di luar zona',
            subtitle:
                'Jarak: ${distance.toStringAsFixed(0)}m / radius ${store.radiusMeters.toStringAsFixed(0)}m',
          ),
        const SizedBox(height: 8),
        _buildPositionMap(store),
      ],
    );
  }

  Widget _buildPositionMap(Store store) {
    final storePos = LatLng(store.lat, store.lng);
    final pos = _latestPosition;
    final empPos = pos != null ? LatLng(pos.latitude, pos.longitude) : null;
    final inZone = empPos != null &&
        _locationService.isInsideZone(pos!.latitude, pos.longitude, store);

    final mapOptions = empPos != null
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: mapOptions,
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'io.grandepos.lokagram',
            ),
            CircleLayer(circles: [
              CircleMarker(
                point: storePos,
                radius: store.radiusMeters,
                useRadiusInMeter: true,
                color: Colors.blue.withOpacity(0.15),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              ),
            ]),
            MarkerLayer(markers: [
              Marker(
                point: storePos,
                width: 36,
                height: 36,
                alignment: Alignment.topCenter,
                child: const Icon(Icons.store, color: Colors.blue, size: 36),
              ),
              if (empPos != null)
                Marker(
                  point: empPos,
                  width: 36,
                  height: 36,
                  alignment: Alignment.topCenter,
                  child: Icon(
                    Icons.person_pin_circle,
                    color: inZone ? Colors.green : Colors.red,
                    size: 36,
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(Store store) {
    if (_nameController.text.trim().isEmpty) {
      return const Text('Masukkan nama karyawan terlebih dahulu',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12));
    }
    if (store.gpsMode == GpsMode.antiFake && _isMocked) {
      return const Text('Nonaktifkan fake GPS untuk bisa absen',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red, fontSize: 12));
    }
    return const Text('Pindahkan posisi ke dalam zona store',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 12));
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  const _StatusCard(
      {required this.icon,
      required this.color,
      required this.title,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionDeniedCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDeniedCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_disabled, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Izin Lokasi Dibutuhkan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Aktifkan GPS dan izinkan akses lokasi untuk menggunakan fitur absensi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ShadButton.outline(
              onPressed: onRetry,
              leading: const Icon(Icons.refresh, size: 16),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStoreCard extends StatelessWidget {
  final VoidCallback onSetup;
  const _NoStoreCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Store Belum Dikonfigurasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Set lokasi store terlebih dahulu sebelum karyawan bisa absen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ShadButton(
              onPressed: onSetup,
              leading: const Icon(Icons.settings, size: 16),
              child: const Text('Set Lokasi Store'),
            ),
          ],
        ),
      ),
    );
  }
}
