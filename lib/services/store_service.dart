import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store.dart';

class StoreService {
  static const _key = 'store_data';

  Future<Store?> loadStore() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    return Store.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveStore(Store store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(store.toJson()));
  }
}
