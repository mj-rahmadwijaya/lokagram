import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/store.dart';
import '../services/store_service.dart';
import 'login_screen.dart';

class StoreSettingsScreen extends StatefulWidget {
  final Store? initialStore;
  final bool isInitialSetup;

  const StoreSettingsScreen({
    super.key,
    this.initialStore,
    this.isInitialSetup = false,
  });

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  static const _defaultCenter = LatLng(-6.1751, 106.8650);
  static const _defaultRadius = 100.0;

  final _storeService = StoreService();
  final _nameController = TextEditingController();
  final _mapController = MapController();

  late LatLng _pinPosition;
  late double _radius;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    final store = widget.initialStore;
    if (store != null) {
      _pinPosition = LatLng(store.lat, store.lng);
      _radius = store.radiusMeters;
      _nameController.text = store.name;
    } else {
      _pinPosition = _defaultCenter;
      _radius = _defaultRadius;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() => _pinPosition = point);
  }

  Future<void> _useMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aktifkan GPS terlebih dahulu')),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak')),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final point = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _pinPosition = point);
        _mapController.move(point, 16);
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Nama outlet tidak boleh kosong'),
        ),
      );
      return;
    }
    await _storeService.saveStore(Store(
      name: name,
      lat: _pinPosition.latitude,
      lng: _pinPosition.longitude,
      radiusMeters: _radius,
    ));
    if (!mounted) return;
    if (widget.isInitialSetup) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, a, b) => const LoginScreen(),
        transitionsBuilder: (context, anim, b, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isInitialSetup,
        title: Text(
          widget.isInitialSetup ? 'Setup Outlet' : 'Pengaturan Outlet',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ShadButton(
              onPressed: _save,
              size: ShadButtonSize.sm,
              leading: const Icon(Icons.save, size: 14),
              child: Text(
                widget.isInitialSetup ? 'Simpan & Lanjut' : 'Simpan',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.isInitialSetup) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF1976D2)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atur informasi outlet sebelum login. '
                      'Tap di peta untuk set lokasi outlet.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShadInput(
                  controller: _nameController,
                  placeholder: const Text('Nama Outlet'),
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.store, size: 18, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Radius:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Slider(
                        min: 50,
                        max: 500,
                        divisions: 9,
                        value: _radius,
                        label: '${_radius.toStringAsFixed(0)}m',
                        onChanged: (v) => setState(() => _radius = v),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${_radius.toStringAsFixed(0)}m',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Tap di peta untuk set lokasi outlet',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pinPosition,
                    initialZoom: 16,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'io.grandepos.lokagram',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _pinPosition,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: const Color(0xFF1976D2).withValues(alpha: 0.15),
                          borderColor: const Color(0xFF1976D2),
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pinPosition,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.store_rounded,
                            color: Color(0xFF1976D2),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    onPressed: _isLoadingLocation ? null : _useMyLocation,
                    tooltip: 'Gunakan lokasi saya',
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    child: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
