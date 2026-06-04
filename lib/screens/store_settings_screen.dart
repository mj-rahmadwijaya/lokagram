import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/gps_mode.dart';
import '../models/store.dart';
import '../services/store_service.dart';

class StoreSettingsScreen extends StatefulWidget {
  final Store? initialStore;

  const StoreSettingsScreen({super.key, this.initialStore});

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
  late GpsMode _gpsMode;

  @override
  void initState() {
    super.initState();
    final store = widget.initialStore;
    if (store != null) {
      _pinPosition = LatLng(store.lat, store.lng);
      _radius = store.radiusMeters;
      _gpsMode = store.gpsMode;
      _nameController.text = store.name;
    } else {
      _pinPosition = _defaultCenter;
      _radius = _defaultRadius;
      _gpsMode = GpsMode.fixed;
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama store tidak boleh kosong')),
      );
      return;
    }
    await _storeService.saveStore(Store(
      name: name,
      lat: _pinPosition.latitude,
      lng: _pinPosition.longitude,
      radiusMeters: _radius,
      gpsMode: _gpsMode,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Store'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Store',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mode GPS',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<GpsMode>(
                  segments: const [
                    ButtonSegment(
                      value: GpsMode.flexible,
                      label: Text('Flexible'),
                      icon: Icon(Icons.touch_app),
                    ),
                    ButtonSegment(
                      value: GpsMode.fixed,
                      label: Text('Fixed GPS'),
                      icon: Icon(Icons.gps_fixed),
                    ),
                    ButtonSegment(
                      value: GpsMode.antiFake,
                      label: Text('Anti Fake'),
                      icon: Icon(Icons.security),
                    ),
                  ],
                  selected: {_gpsMode},
                  onSelectionChanged: (modes) =>
                      setState(() => _gpsMode = modes.first),
                ),
                const SizedBox(height: 6),
                Text(
                  _gpsMode.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Radius:'),
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
                    Text(
                      '${_radius.toStringAsFixed(0)}m',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Tap di peta untuk set lokasi store',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: FlutterMap(
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
                      color: Colors.blue.withOpacity(0.15),
                      borderColor: Colors.blue,
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
                        Icons.store,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
