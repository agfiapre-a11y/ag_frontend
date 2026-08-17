import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:bcrypt/bcrypt.dart';

class SecurityService {
  static const _uuid = Uuid();
  static int get _pbkdf2Iterations => kIsWeb ? 10000 : 100000;
  static const int _keyLength = 32;
  static const int _saltLength = 16;

  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hash = _pbkdf2(password, salt, _pbkdf2Iterations);
    return 'pbkdf2:$_pbkdf2Iterations:${_bytesToHex(salt)}:${_bytesToHex(hash)}';
  }

  static bool verifyPassword(String password, String storedHash) {
    // PBKDF2 hashes (Flutter app's native format)
    if (storedHash.startsWith('pbkdf2:')) {
      final parts = storedHash.split(':');
      if (parts.length != 4) return false;
      final iterations = int.tryParse(parts[1]) ?? _pbkdf2Iterations;
      final salt = _hexToBytes(parts[2]);
      final stored = _hexToBytes(parts[3]);
      final computed = _pbkdf2(password, salt, iterations);
      return _constantTimeEquals(stored, computed);
    }
    // Bcrypt hashes (from NestJS backend / Supabase — $2a$, $2b$, $2y$ prefix)
    if (storedHash.startsWith('\$2a\$') ||
        storedHash.startsWith('\$2b\$') ||
        storedHash.startsWith('\$2y\$')) {
      try {
        return BCrypt.checkpw(password, storedHash);
      } catch (_) {
        return false;
      }
    }
    // Legacy SHA-256 hashes
    final legacy = sha256.convert(utf8.encode(password)).toString();
    return legacy == storedHash;
  }

  static bool isLegacyHash(String storedHash) =>
      !storedHash.startsWith('pbkdf2:') &&
      !storedHash.startsWith('\$2a\$') &&
      !storedHash.startsWith('\$2b\$') &&
      !storedHash.startsWith('\$2y\$');

  /// Returns true if the hash is a bcrypt hash (from the backend/Supabase).
  static bool isBcryptHash(String storedHash) =>
      storedHash.startsWith('\$2a\$') ||
      storedHash.startsWith('\$2b\$') ||
      storedHash.startsWith('\$2y\$');

  static Uint8List _generateSalt() {
    final salt = Uint8List(_saltLength);
    final ts = DateTime.now().microsecondsSinceEpoch;
    for (int i = 0; i < _saltLength; i++) {
      salt[i] = ((ts >> (i % 8)) ^ (i * 37)) & 0xFF;
    }
    final uuidBytes = utf8.encode(_uuid.v4());
    for (int i = 0; i < _saltLength && i < uuidBytes.length; i++) {
      salt[i] ^= uuidBytes[i];
    }
    return salt;
  }

  static Uint8List _pbkdf2(String password, Uint8List salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final blockCount = (_keyLength + 31) ~/ 32;
    final derivedKey = <int>[];
    for (int blockNum = 1; blockNum <= blockCount; blockNum++) {
      final block = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..[salt.length] = (blockNum >> 24) & 0xFF
        ..[salt.length + 1] = (blockNum >> 16) & 0xFF
        ..[salt.length + 2] = (blockNum >> 8) & 0xFF
        ..[salt.length + 3] = blockNum & 0xFF;
      var u = hmac.convert(block).bytes;
      var t = List<int>.from(u);
      for (int i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      derivedKey.addAll(t);
    }
    return Uint8List.fromList(derivedKey.sublist(0, _keyLength));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  static String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }
}
