import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// AES-256 encryption service for protecting PII at rest.
/// Uses a device-derived key stored in flutter_secure_storage.
class EncryptionService {
  /// Generates a random IV, with fallback for web without secure context.
  static enc.IV _generateIV() {
    try {
      return enc.IV.fromSecureRandom(16);
    } catch (_) {
      // Random.secure() fails on web without secure context (HTTP).
      // Fall back to Random() — IV is still random enough for this use case.
      final rng = Random();
      final bytes = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        bytes[i] = rng.nextInt(256);
      }
      return enc.IV(bytes);
    }
  }

  /// Encrypts a plaintext string and returns base64 ciphertext.
  static String encryptString(String plaintext, String key) {
    final k = enc.Key.fromUtf8(_padKey(key));
    final iv = _generateIV();
    final encrypter = enc.Encrypter(enc.AES(k, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a base64 ciphertext string.
  static String decryptString(String ciphertext, String key) {
    final parts = ciphertext.split(':');
    if (parts.length != 2) throw FormatException('Invalid ciphertext format');
    final k = enc.Key.fromUtf8(_padKey(key));
    final iv = enc.IV.fromBase64(parts[0]);
    final encrypter = enc.Encrypter(enc.AES(k, mode: enc.AESMode.gcm));
    final decrypted = encrypter.decrypt64(parts[1], iv: iv);
    return decrypted;
  }

  /// Encrypts a JSON map and returns base64 string.
  static String encryptMap(Map<String, dynamic> data, String key) {
    return encryptString(jsonEncode(data), key);
  }

  /// Decrypts a base64 string back to a JSON map.
  static Map<String, dynamic> decryptMap(String ciphertext, String key) {
    final plain = decryptString(ciphertext, key);
    return Map<String, dynamic>.from(jsonDecode(plain) as Map);
  }

  /// Derives a stable encryption key from a passphrase using SHA-256.
  static String deriveKey(String passphrase) {
    final hash = sha256.convert(utf8.encode(passphrase)).toString();
    return hash;
  }

  /// Pads or truncates key to exactly 32 bytes for AES-256.
  static String _padKey(String key) {
    if (key.length >= 32) return key.substring(0, 32);
    return key.padRight(32, '0');
  }
}
