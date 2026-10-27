import 'package:hive_flutter/hive_flutter.dart';

/// Hive stores only device/session settings. Account records and all other
/// user-owned data are loaded from and written to the authenticated backend.
class StorageService {
  static const String settingsBox = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(settingsBox);
  }

  // Only the auth session, API endpoint, and non-sensitive device sync status
  // are local. Profile fields and application records live in MySQL.
  static const _deviceSettingKeys = <String>{
    'backend_token',
    'logged_in',
    'custom_api_url',
    'theme_mode',
    'last_sync_at',
    'last_sync_error',
  };

  static String? getSetting(String key) {
    if (!_deviceSettingKeys.contains(key)) return null;
    return Hive.box<String>(settingsBox).get(key);
  }

  static void setSetting(String key, String value) {
    if (_deviceSettingKeys.contains(key)) {
      Hive.box<String>(settingsBox).put(key, value);
    }
  }
}
