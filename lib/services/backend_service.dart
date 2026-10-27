import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/receipt_model.dart';
import '../services/storage_service.dart';

/// HTTP client for the PHP/MySQL backend.
///
/// Web default matches the project location under XAMPP htdocs.
/// Android emulator uses 10.0.2.2 to reach the host computer.
/// Physical phone: set custom API URL in Settings or pass --dart-define=API_BASE_URL=http://YOUR-PC-IP/student_expense_manager_backend/student_expense_manager/backend/api.php
class BackendService {
  static const _configured =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static String get baseUrl {
    if (_configured.trim().isNotEmpty) return _configured.trim();
    final customUrl = StorageService.getSetting('custom_api_url');
    if (customUrl != null && customUrl.trim().isNotEmpty) return customUrl.trim();
    if (kIsWeb) return 'http://localhost/student_expense_manager_backend/backend/api.php';
    return 'http://10.0.2.2/student_expense_manager_backend/backend/api.php';
  }

  static String? token;

  static Map<String, String> _headers() {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static Future<Map<String, dynamic>> _post(
      String action, Map<String, dynamic> body,
      {Duration timeout = const Duration(seconds: 12)}) async {
    final response = await http
        .post(Uri.parse('$baseUrl?action=$action'),
            headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw Exception('Backend returned non-object JSON (status ${response.statusCode}): ${response.body}');
      }
      data = Map<String, dynamic>.from(decoded);
    } catch (e) {
      if (e is Exception && !e.toString().contains('FormatSyntaxError') && !e.toString().contains('FormatException')) rethrow;
      final raw = response.body.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      final preview = raw.length > 150 ? '${raw.substring(0, 150)}…' : raw;
      throw Exception('Backend error (${response.statusCode}): $preview');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Backend request failed.');
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) {
    return _post('register',
        {'name': name, 'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) {
    return _post('login', {'email': email, 'password': password});
  }

  static Future<void> requestPasswordResetCode(String email) async {
    await _post('request_password_reset_code', {'email': email});
  }

  static Future<void> resetPassword(
      String email, String code, String password) async {
    await _post('reset_password',
        {'email': email, 'code': code, 'password': password});
  }

  static Future<Map<String, dynamic>> pullState() async {
    return _post('state', {});
  }

  static Future<Map<String, dynamic>> sync(
      Map<String, dynamic> state) async {
    return _post('sync', {'state': state});
  }

  static Future<Map<String, dynamic>> notifications() => _post('notifications', {});

  static Future<Map<String, dynamic>> notificationPreferences() async {
    final response = await _post('notification_preferences', {});
    return Map<String, dynamic>.from(response['data'] as Map? ?? {});
  }

  static Future<Map<String, dynamic>> saveNotificationPreferences(Map<String, dynamic> preferences) async {
    final response = await _post('notification_preferences', {'preferences': preferences});
    return Map<String, dynamic>.from(response['data'] as Map? ?? {});
  }

  static Future<void> markNotificationsRead() async {
    await _post('mark_notifications_read', {});
  }

  // ---- Receipts (files are stored in the MySQL `receipts` table) ----

  /// Uploads a receipt image/PDF. The server checks the real file type and size.
  static Future<ReceiptInfo> uploadReceipt(
      Uint8List bytes, String fileName) async {
    final response = await _post(
      'upload_receipt',
      {'fileName': fileName, 'data': base64Encode(bytes)},
      timeout: const Duration(seconds: 90),
    );
    return ReceiptInfo.fromJson(
        Map<String, dynamic>.from(response['data'] as Map));
  }

  static Future<Uint8List> downloadReceipt(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=get_receipt&id=${Uri.encodeQueryComponent(id)}'),
      headers: {
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 90));
    if (response.statusCode != 200) {
      var message = 'Could not download the receipt.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
    return response.bodyBytes;
  }

  static Future<void> deleteReceipt(String id) async {
    await _post('delete_receipt', {'id': id});
  }

  static Future<void> logout() async {
    try {
      await _post('logout', {});
    } finally {
      token = null;
    }
  }

  static bool get configured => baseUrl.trim().isNotEmpty;
}
