import 'package:flutter/material.dart';
// flutter_map: widget peta berbasis OpenStreetMap (tanpa API key).
import 'package:flutter_map/flutter_map.dart';
// latlong2: tipe LatLng (koordinat) yang dipakai flutter_map.
import 'package:latlong2/latlong.dart';

import '../models/allowed_zone.dart';

/// Layar Settings: user tap di peta untuk taruh pin + atur radius via slider.
/// StatefulWidget karena isinya berubah (pin pindah, radius berubah).
class SettingsScreen extends StatefulWidget {
  // Zona awal (opsional). Kalau user edit zona yang sudah ada, mulai dari sini.
  // Nilai dari widget ini immutable; data yang berubah ada di State (di bawah).
  final AllowedZone? initialZone;

  const SettingsScreen({super.key, this.initialZone});

  // StatefulWidget dipecah jadi 2 class: widget (config) + State (data berubah).
  // createState() dipanggil framework sekali untuk bikin object State.
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State menyimpan data yang berubah & berisi method build().
class _SettingsScreenState extends State<SettingsScreen> {
  // Nilai default kalau belum ada zona tersimpan.
  static const _defaultCenter = LatLng(-6.1751, 106.8650); // Monas Jakarta
  static const _defaultRadius = 100.0;

  // 'late' = dijanjikan di-isi sebelum dipakai (di initState). Menghindari
  // keharusan nullable padahal kita tahu pasti terisi.
  late LatLng _pinPosition;
  late double _radius;
  final _mapController = MapController(); // handle ke peta (kontrol programatik)

  /// Lifecycle: dipanggil SEKALI saat State dibuat, sebelum build pertama.
  /// Wajib super.initState() lebih dulu.
  @override
  void initState() {
    super.initState();
    // 'widget' = referensi ke SettingsScreen di atas (akses initialZone).
    final zone = widget.initialZone;
    if (zone != null) {
      _pinPosition = LatLng(zone.lat, zone.lng);
      _radius = zone.radiusMeters;
    } else {
      _pinPosition = _defaultCenter;
      _radius = _defaultRadius;
    }
  }

  /// Callback saat user tap peta. setState() WAJIB agar UI ikut ter-rebuild
  /// dengan posisi pin baru — tanpa setState, perubahan tidak tampil.
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _pinPosition = point);
  }

  /// Callback tombol Simpan. Navigator.pop() menutup layar ini dan
  /// MENGEMBALIKAN AllowedZone ke layar Home yang memanggil (pattern push/pop).
  void _onSave() {
    Navigator.pop(
      context,
      AllowedZone(
        lat: _pinPosition.latitude,
        lng: _pinPosition.longitude,
        radiusMeters: _radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold = kerangka layar Material (AppBar + body + FAB).
    return Scaffold(
      appBar: AppBar(title: const Text('Set Lokasi')),
      body: Column(
        children: [
          // Expanded = ambil semua sisa ruang vertikal → peta jadi besar,
          // sisanya (slider) di bawah.
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pinPosition,
                initialZoom: 15,
                onTap: _onMapTap, // daftarkan callback tap
              ),
              // Peta disusun berlapis (layer), digambar dari bawah ke atas.
              children: [
                // Layer 1: tile gambar peta dari OpenStreetMap.
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // WAJIB unik — jangan 'com.example.app' (OSM blokir UA generic).
                  userAgentPackageName: 'io.grandepos.lokagram',
                ),
                // Layer 2: lingkaran radius zona.
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _pinPosition,
                      radius: _radius,
                      // true → radius dihitung dalam meter geografis, bukan pixel.
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                // Layer 3: pin merah penanda pusat zona.
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pinPosition,
                      width: 40,
                      height: 40,
                      // topCenter → ujung bawah pin yang nunjuk tepat ke koordinat.
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Area bawah: label radius + slider + petunjuk.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            child: Column(
              children: [
                Text(
                  // toStringAsFixed(0) → tampilkan tanpa angka desimal.
                  'Radius: ${_radius.toStringAsFixed(0)} meter',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Slider(
                  min: 50,
                  max: 500,
                  divisions: 9, // snap ke kelipatan 50 (50,100,...,500)
                  value: _radius,
                  label: '${_radius.toStringAsFixed(0)}m',
                  // onChanged dipanggil tiap geser → setState rebuild lingkaran.
                  onChanged: (value) => setState(() => _radius = value),
                ),
                const Text(
                  'Tap di peta untuk memindahkan pin',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      // Tombol mengambang dengan label + ikon.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onSave,
        icon: const Icon(Icons.save),
        label: const Text('Simpan'),
      ),
    );
  }
}
