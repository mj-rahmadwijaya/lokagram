// Paket shared_preferences: penyimpanan key-value sederhana yang persist
// di disk (mirip localStorage di web). Cocok untuk sedikit nilai primitif.
import 'package:shared_preferences/shared_preferences.dart';

import '../models/allowed_zone.dart';

/// Service yang membungkus persistence zona ke SharedPreferences.
/// Hanya simpan 3 angka (lat, lng, radius) — tidak perlu database.
class StorageService {
  // Key penyimpanan. 'static const' = konstanta level class.
  // Prefix '_' = private (Dart pakai underscore, bukan keyword 'private').
  static const _keyLat = 'zone_lat';
  static const _keyLng = 'zone_lng';
  static const _keyRadius = 'zone_radius';

  /// Baca zona tersimpan. Return null kalau belum pernah disimpan
  /// (return type 'AllowedZone?' — tanda '?' artinya boleh null).
  Future<AllowedZone?> loadZone() async {
    final prefs = await SharedPreferences.getInstance();
    // getDouble return double? (null kalau key belum ada).
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    final radius = prefs.getDouble(_keyRadius);
    // Kalau salah satu null → data tidak lengkap → anggap belum ada zona.
    if (lat == null || lng == null || radius == null) return null;
    return AllowedZone(lat: lat, lng: lng, radiusMeters: radius);
  }

  /// Simpan zona ke disk. Future<void> = async tanpa nilai balik.
  /// 'await' wajib eksplisit di Dart (tidak auto-await seperti beberapa bahasa).
  Future<void> saveZone(AllowedZone zone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, zone.lat);
    await prefs.setDouble(_keyLng, zone.lng);
    await prefs.setDouble(_keyRadius, zone.radiusMeters);
  }
}
