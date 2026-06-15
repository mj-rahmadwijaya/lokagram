import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session.dart';

class SessionService {
  static const _keySession = 'session_data';
  static const _keyDeviceId = 'device_unique_id';

  Future<Session?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keySession);
    if (json == null) return null;
    return Session.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySession, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
  }

  /// Ambil atau generate unique ID device (disimpan permanen).
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyDeviceId);
    if (id == null) {
      id = _generateId();
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  String _generateId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buf.write(chars[rng.nextInt(chars.length)]);
    }
    return buf.toString();
  }
}
