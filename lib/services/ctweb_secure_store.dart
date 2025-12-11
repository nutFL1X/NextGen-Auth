// lib/services/ctweb_secure_store.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CtWebSecureStore {
  // Uses Android Keystore / iOS Keychain under the hood
  static const _storage = FlutterSecureStorage();

  /// Build a unique key per (user, site) pair
  static String _makeKey(String userId, String siteId) =>
      'ctweb::$userId::$siteId';

  static Future<void> saveCtWeb({
    required String userId,
    required String siteId,
    required String ctWebBase64,
  }) async {
    final key = _makeKey(userId, siteId);
    await _storage.write(key: key, value: ctWebBase64);
  }

  static Future<String?> loadCtWeb({
    required String userId,
    required String siteId,
  }) async {
    final key = _makeKey(userId, siteId);
    return _storage.read(key: key);
  }

  static Future<void> deleteCtWeb({
    required String userId,
    required String siteId,
  }) async {
    final key = _makeKey(userId, siteId);
    await _storage.delete(key: key);
  }
}
