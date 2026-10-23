import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/scan_history_item.dart';
import '../api/api_exception.dart';

class LocalStorage {
  LocalStorage(this.prefs);
  final SharedPreferences prefs;
  Future<void> setString(String key, String value) async {
    if (!await prefs.setString(key, value)) {
      throw const ApiException(Failure.storage);
    }
  }

  Future<void> setBool(String key, bool value) async {
    if (!await prefs.setBool(key, value)) {
      throw const ApiException(Failure.storage);
    }
  }

  Future<void> completeOnboarding() async {
    if (!await prefs.setBool('onboardingCompleted', true)) {
      throw const ApiException(Failure.storage);
    }
  }

  List<ScanHistoryItem> readHistory() {
    final raw = prefs.getString('history');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ScanHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      // Keep the original stored value intact so failed reads never erase data.
      throw const ApiException(Failure.storage);
    }
  }

  Future<void> saveHistory(List<ScanHistoryItem> items) =>
      setString('history', jsonEncode(items.map((e) => e.toJson()).toList()));
}
