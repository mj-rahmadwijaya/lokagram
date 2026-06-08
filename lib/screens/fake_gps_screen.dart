import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGpsScreen extends StatefulWidget {
  const FakeGpsScreen({super.key});

  @override
  State<FakeGpsScreen> createState() => _FakeGpsScreenState();
}

class _FakeGpsScreenState extends State<FakeGpsScreen> {
  static const _keyEnabled = 'dev_fake_gps';
  static const _keyLat = 'dev_fake_lat';
  static const _keyLng = 'dev_fake_lng';

  // Default: Jakarta
  static const _defaultLat = -6.2088;
  static const _defaultLng = 106.8456;

  bool _enabled = false;
  LatLng _pin = const LatLng(_defaultLat, _defaultLng);
  bool _loading = true;
  bool _saved = false;

  final _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool(_keyEnabled) ?? false;
      final lat = prefs.getDouble(_keyLat) ?? _defaultLat;
      final lng = prefs.getDouble(_keyLng) ?? _defaultLng;
      _pin = LatLng(lat, lng);
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, _enabled);
    await prefs.setDouble(_keyLat, _pin.latitude);
    await prefs.setDouble(_keyLng, _pin.longitude);
    if (!mounted) return;
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2),
        () { if (mounted) setState(() => _saved = false); });
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() { _pin = point; _saved = false; });
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Fake GPS',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1A1A2E))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _save,
              child: Text(
                _saved ? 'Tersimpan ✓' : 'Simpan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _saved
                      ? const Color(0xFF43A047)
                      : const Color(0xFF1976D2),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Toggle aktif
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktifkan Fake GPS',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text(
                      _enabled
                          ? 'Absensi akan memakai lokasi pin di bawah'
                          : 'Menggunakan GPS asli',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _enabled,
                    onChanged: (v) => setState(() { _enabled = v; _saved = false; }),
                    activeColor: const Color(0xFF1976D2),
                  ),
                ),
                const Divider(height: 1),

                // Koordinat
                if (_enabled)
                  Container(
                    color: const Color(0xFFE3F2FD),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_pin,
                            color: Color(0xFF1976D2), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Lat: ${_pin.latitude.toStringAsFixed(6)},  '
                          'Lng: ${_pin.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                // Peta
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapCtrl,
                        options: MapOptions(
                          initialCenter: _pin,
                          initialZoom: 15,
                          onTap: _enabled ? _onMapTap : null,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'io.grandepos.lokagram',
                          ),
                          if (_enabled)
                            MarkerLayer(markers: [
                              Marker(
                                point: _pin,
                                width: 48,
                                height: 56,
                                alignment: Alignment.topCenter,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Color(0xFFE53935),
                                  size: 48,
                                ),
                              ),
                            ]),
                        ],
                      ),

                      // Hint tap
                      if (_enabled)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Tap di peta untuk pindah lokasi',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),

                      // Overlay saat nonaktif
                      if (!_enabled)
                        Container(
                          color: Colors.black.withValues(alpha: 0.25),
                          child: const Center(
                            child: Text(
                              'Aktifkan Fake GPS untuk memilih lokasi',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Warning
                Container(
                  color: const Color(0xFFFFF8E1),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFF57F17), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hanya untuk pengujian. Matikan setelah selesai uji.',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFF57F17)),
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
