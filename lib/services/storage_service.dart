import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Local offline storage service using Hive.
/// Stores application data, user accounts, transactions, budgets, notes,
/// and reminders locally on the phone so the app can be used 100% offline.
class StorageService {
  static const String settingsBox = 'settings_box';
  static const String dataBox = 'app_local_data_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(settingsBox);
    await Hive.openBox<String>(dataBox);
  }

  // Device settings keys
  static const _deviceSettingKeys = <String>{
    'backend_token',
    'logged_in',
    'offline_mode',
    'custom_api_url',
    'theme_mode',
    'last_sync_at',
    'last_sync_error',
    'last_update_check',
    'cached_user_name',
    'cached_user_email',
  };

  static String? getSetting(String key) {
    if (!_deviceSettingKeys.contains(key)) {
      return Hive.box<String>(settingsBox).get(key);
    }
    return Hive.box<String>(settingsBox).get(key);
  }

  static void setSetting(String key, String value) {
    Hive.box<String>(settingsBox).put(key, value);
  }

  /// Save full state JSON locally on the phone
  static void saveLocalState(Map<String, dynamic> state) {
    try {
      final jsonStr = jsonEncode(state);
      Hive.box<String>(dataBox).put('app_state', jsonStr);
    } catch (e) {
      // Local save fallback
    }
  }

  /// Load full state JSON from phone's local storage
  static Map<String, dynamic>? getLocalState() {
    try {
      final raw = Hive.box<String>(dataBox).get('app_state');
      if (raw == null || raw.isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear local data on explicit request
  static void clearLocalState() {
    Hive.box<String>(dataBox).delete('app_state');
  }
}
