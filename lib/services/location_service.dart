// Paket geolocator: akses GPS, izin lokasi, dan hitung jarak antar koordinat.
import 'package:geolocator/geolocator.dart';

import '../models/allowed_zone.dart';

/// Service yang membungkus semua interaksi dengan GPS (geolocator).
/// Tujuan: pisahkan logika lokasi dari UI (separation of concerns).
class LocationService {
  /// Pastikan service GPS aktif & user kasih izin location.
  /// Return true kalau OK siap dipakai.
  /// 'async' → fungsi asinkron, return Future<bool> (hasil datang nanti).
  Future<bool> ensurePermission() async {
    // 1. Cek dulu apakah GPS device dinyalakan (toggle di quick settings).
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    // 2. Cek status izin app. Kalau masih 'denied' (belum pernah ditanya),
    //    munculkan dialog OS untuk minta izin.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // 3. Izin cukup kalau 'always' atau 'whileInUse'. App ini cuma butuh
    //    whileInUse (saat app dibuka), bukan tracking background.
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Stream posisi GPS dengan distance filter 5 meter — hemat baterai
  /// karena hanya emit event saat user gerak ≥5m.
  /// Stream = aliran event async yang datang berulang dari waktu ke waktu
  /// (mirip Observable/EventEmitter). Yang "mendengarkan" = StreamBuilder di UI.
  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  /// Jarak meter dari posisi sekarang ke pusat zona.
  /// distanceBetween() pakai rumus Haversine (great-circle) — built-in.
  double distanceTo(Position current, AllowedZone zone) {
    return Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      zone.lat,
      zone.lng,
    );
  }

  /// Apakah posisi sekarang berada dalam zona?
  /// (Helper opsional; di HomeScreen perhitungan ini ditulis inline.)
  bool isInsideZone(Position current, AllowedZone zone) {
    return distanceTo(current, zone) <= zone.radiusMeters;
  }
}
