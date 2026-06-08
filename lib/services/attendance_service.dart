import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  static const _key = 'attendance_records';

  Future<List<AttendanceRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRecord(AttendanceRecord record) async {
    final records = await loadRecords();
    records.add(record);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  Future<AttendanceRecord?> todayRecord() async {
    final records = await loadRecords();
    final now = DateTime.now();
    try {
      return records.lastWhere((r) =>
          r.timestamp.year == now.year &&
          r.timestamp.month == now.month &&
          r.timestamp.day == now.day);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCheckOut(String recordId, DateTime checkOutTime) async {
    final records = await loadRecords();
    final idx = records.indexWhere((r) => r.id == recordId);
    if (idx == -1) return;
    records[idx] = records[idx].copyWith(checkOutTime: checkOutTime);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
