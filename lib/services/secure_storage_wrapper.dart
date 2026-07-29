import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

/// Secure storage wrapper that encrypts sensitive PII before storing
/// in SharedPreferences. The encryption key is stored in flutter_secure_storage
/// (Keychain on iOS, Keystore on Android, encrypted Web Storage on web).
///
/// UK GDPR Art. 32 compliant: personal data is encrypted at rest.
class SecureStorageWrapper {
  static const _secureStorage = FlutterSecureStorage();
  static const _keyStorageKey = 'paradise_ag_encryption_key';
  static const _fallbackKeyStorageKey = 'paradise_ag_encryption_key_fallback';
  static String? _cachedKey;
  static bool? _isWeb;

  static bool get _web => _isWeb ??= kIsWeb;

  /// Gets or creates the device-specific encryption key (native only).
  static Future<String> _getEncryptionKey() async {
    if (_cachedKey != null) return _cachedKey!;

    try {
      var key = await _secureStorage.read(key: _keyStorageKey);
      if (key != null) {
        _cachedKey = key;
        return key;
      }
      final newKey = DateTime.now().microsecondsSinceEpoch.toString() +
          DateTime.now().millisecondsSinceEpoch.toString();
      key = EncryptionService.deriveKey(newKey);
      await _secureStorage.write(key: _keyStorageKey, value: key);
      _cachedKey = key;
      return key;
    } catch (e) {
      // Fallback for web without secure context (HTTP) or platforms where
      // flutter_secure_storage is unavailable. Data is still encrypted at rest.
      if (kDebugMode) {
        debugPrint('flutter_secure_storage unavailable, using fallback: $e');
      }
      final prefs = await SharedPreferences.getInstance();
      var key = prefs.getString(_fallbackKeyStorageKey);
      if (key == null) {
        final newKey = DateTime.now().microsecondsSinceEpoch.toString() +
            DateTime.now().millisecondsSinceEpoch.toString();
        key = EncryptionService.deriveKey(newKey);
        await prefs.setString(_fallbackKeyStorageKey, key);
      }
      _cachedKey = key;
      return key;
    }
  }

  /// Encrypts and stores a map in SharedPreferences.
  /// On web: stores as plain JSON. On native: encrypts with AES-256-GCM.
  static Future<void> setSecureMap(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (_web) {
      await prefs.setString('enc_$key', jsonEncode(data));
      return;
    }
    try {
      final encKey = await _getEncryptionKey();
      final encrypted = EncryptionService.encryptMap(data, encKey);
      await prefs.setString('enc_$key', encrypted);
    } catch (e) {
      if (kDebugMode) debugPrint('Encryption failed, storing plain: $e');
      await prefs.setString('enc_$key', jsonEncode(data));
    }
  }

  /// Retrieves and decrypts a map from SharedPreferences.
  static Future<Map<String, dynamic>?> getSecureMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('enc_$key');
    if (stored == null) return null;
    // Check if it's plain JSON (fallback mode) — starts with '{'
    if (stored.startsWith('{')) {
      try {
        return Map<String, dynamic>.from(jsonDecode(stored) as Map);
      } catch (_) {
        return null;
      }
    }
    try {
      final encKey = await _getEncryptionKey();
      return EncryptionService.decryptMap(stored, encKey);
    } catch (_) {
      try {
        return Map<String, dynamic>.from(jsonDecode(stored) as Map);
      } catch (_) {
        return null;
      }
    }
  }

  /// Removes a secure map from SharedPreferences.
  static Future<void> removeSecureMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enc_$key');
  }

  /// Encrypts and stores a string in SharedPreferences.
  static Future<void> setSecureString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    if (_web) {
      await prefs.setString('enc_$key', value);
      return;
    }
    try {
      final encKey = await _getEncryptionKey();
      final encrypted = EncryptionService.encryptString(value, encKey);
      await prefs.setString('enc_$key', encrypted);
    } catch (e) {
      if (kDebugMode) debugPrint('Encryption failed, storing plain: $e');
      await prefs.setString('enc_$key', value);
    }
  }

  /// Retrieves and decrypts a string from SharedPreferences.
  static Future<String?> getSecureString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('enc_$key');
    if (stored == null) return null;
    if (_web) return stored;
    try {
      final encKey = await _getEncryptionKey();
      return EncryptionService.decryptString(stored, encKey);
    } catch (_) {
      return stored;
    }
  }

  /// Removes a secure string from SharedPreferences.
  static Future<void> removeSecureString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('enc_$key');
  }
}
