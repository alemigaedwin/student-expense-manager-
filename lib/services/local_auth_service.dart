import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'storage_service.dart';

/// Device-local account credentials for offline sign-in.
/// Passwords are never stored as plain text; the hash is salted per account.
class LocalAuthService {
  static const _emailKey = 'local_account_email';
  static const _nameKey = 'local_account_name';
  static const _passwordHashKey = 'local_account_password_hash';
  static const _iterations = 30000;

  static String? get registeredEmail => StorageService.getSetting(_emailKey);
  static String? get registeredName => StorageService.getSetting(_nameKey);

  static Future<bool> register(String name, String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (registeredEmail != null && registeredEmail!.isNotEmpty) {
      if (registeredEmail == cleanEmail) {
        throw StateError('An account with this email is already registered on this device.');
      }
      throw StateError('This device already has a local account. Sign in to it or clear app data first.');
    }

    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final digest = _derive(password, salt);
    StorageService.setSetting(_emailKey, cleanEmail);
    StorageService.setSetting(_nameKey, name.trim());
    StorageService.setSetting(_passwordHashKey, '${base64Url.encode(salt)}:${base64Url.encode(digest)}');
    return true;
  }

  /// Caches credentials after a successful server login so the same account
  /// can be opened offline later. A remote sign-in may replace the local profile.
  static void cacheSuccessfulLogin(String name, String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final digest = _derive(password, salt);
    StorageService.setSetting(_emailKey, cleanEmail);
    StorageService.setSetting(_nameKey, name.trim());
    StorageService.setSetting(_passwordHashKey, '${base64Url.encode(salt)}:${base64Url.encode(digest)}');
    // Remove credentials written by older app versions.
    StorageService.setSetting('user_password', '');
  }

  static bool verify(String email, String password) {
    if (registeredEmail != email.trim().toLowerCase()) return false;
    final stored = StorageService.getSetting(_passwordHashKey);
    if (stored == null) return false;
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    try {
      final salt = base64Url.decode(parts[0]);
      final expected = base64Url.decode(parts[1]);
      final actual = _derive(password, salt);
      if (actual.length != expected.length) return false;
      var difference = 0;
      for (var i = 0; i < actual.length; i++) {
        difference |= actual[i] ^ expected[i];
      }
      return difference == 0;
    } catch (_) {
      return false;
    }
  }

  static List<int> _derive(String password, List<int> salt) {
    var digest = sha256.convert([...salt, ...utf8.encode(password)]).bytes;
    for (var i = 1; i < _iterations; i++) {
      digest = sha256.convert([...salt, ...digest]).bytes;
    }
    return digest;
  }
}
