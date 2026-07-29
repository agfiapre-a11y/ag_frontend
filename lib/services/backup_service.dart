import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Service for creating and restoring encrypted backups of all app data.
///
/// Backups include ALL SharedPreferences data (every church, every box),
/// plus metadata about the backup (app version, timestamp, church count, etc.).
///
/// Encryption uses AES-256-GCM with a key derived from SHA-256(password + salt).
/// This provides UK GDPR Art. 32 compliant encryption for backup files.
class BackupService {
  static const _backupVersion = 2;
  static const _salt = 'paradise_ag_backup_salt_v2';

  /// Exports all app data to an encrypted backup.
  ///
  /// [password] is used to encrypt the backup.
  /// [appVersion] is stored in backup metadata.
  /// Returns the encrypted bytes and a suggested file name — works on
  /// all platforms (web, mobile, desktop) since no file system is touched.
  static Future<({Uint8List bytes, String fileName})> createBackup({
    required String password,
    String appVersion = '1.0.0',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Collect ALL keys from SharedPreferences
    final allKeys = prefs.getKeys();
    final dataMap = <String, dynamic>{};

    for (final key in allKeys) {
      final value = prefs.get(key);
      if (value != null) {
        dataMap[key] = value;
      }
    }

    // Build backup envelope
    final backup = {
      'metadata': {
        'version': _backupVersion,
        'appVersion': appVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'totalKeys': dataMap.length,
        'backupId': const Uuid().v4(),
      },
      'data': dataMap,
    };

    // Serialize to JSON
    final jsonStr = jsonEncode(backup);

    // Encrypt
    final encrypted = _encrypt(jsonStr, password);

    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final fileName = 'paradise_backup_$timestamp.pab';

    return (bytes: encrypted, fileName: fileName);
  }

  /// Restores app data from an encrypted backup.
  ///
  /// [bytes] is the raw content of the backup file.
  /// [password] is used to decrypt the backup.
  /// [merge] if true, merges data with existing; if false, clears existing first.
  ///
  /// Returns a [RestoreResult] with details about the restore.
  static Future<RestoreResult> restoreBackup({
    required Uint8List bytes,
    required String password,
    bool merge = false,
  }) async {
    // Decrypt
    String jsonStr;
    try {
      jsonStr = _decrypt(bytes, password);
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Failed to decrypt backup. Wrong password or corrupted file.',
      );
    }

    // Parse JSON
    Map<String, dynamic> backup;
    try {
      backup = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Backup file is corrupted or invalid',
      );
    }

    final metadata = backup['metadata'] as Map<String, dynamic>?;
    final data = backup['data'] as Map<String, dynamic>?;

    if (data == null) {
      return RestoreResult(
        success: false,
        message: 'Backup file contains no data',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    // If not merging, clear all existing data
    if (!merge) {
      final existingKeys = prefs.getKeys().toList();
      for (final key in existingKeys) {
        await prefs.remove(key);
      }
    }

    // Restore all data
    int restoredCount = 0;
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is String) {
        await prefs.setString(key, value);
        restoredCount++;
      } else if (value is int) {
        await prefs.setInt(key, value);
        restoredCount++;
      } else if (value is double) {
        await prefs.setDouble(key, value);
        restoredCount++;
      } else if (value is bool) {
        await prefs.setBool(key, value);
        restoredCount++;
      } else if (value is List) {
        await prefs.setStringList(key, value.cast<String>());
        restoredCount++;
      }
    }

    return RestoreResult(
      success: true,
      message: 'Successfully restored $restoredCount data entries',
      metadata: metadata,
      restoredKeys: restoredCount,
    );
  }

  /// Reads backup metadata without restoring (for preview).
  static Future<BackupPreview?> previewBackup({
    required Uint8List bytes,
    required String password,
  }) async {
    String jsonStr;
    try {
      jsonStr = _decrypt(bytes, password);
    } catch (e) {
      return null;
    }

    try {
      final backup = jsonDecode(jsonStr) as Map<String, dynamic>;
      final metadata = backup['metadata'] as Map<String, dynamic>?;
      final data = backup['data'] as Map<String, dynamic>?;

      return BackupPreview(
        metadata: metadata ?? {},
        totalKeys: data?.length ?? 0,
        churchesCount: _countChurches(data ?? {}),
        hasUsers: data?.values.any((v) => v.toString().contains('users_box')) ?? false,
      );
    } catch (e) {
      return null;
    }
  }

  static int _countChurches(Map<String, dynamic> data) {
    final churchesKey = 'all_churches';
    if (!data.containsKey(churchesKey)) return 0;
    try {
      final map = jsonDecode(data[churchesKey] as String) as Map;
      return map.length;
    } catch (e) {
      return 0;
    }
  }

  /// Encrypts a string using AES-256-GCM with a key derived from SHA-256(password + salt).
  /// Format: [magic(4)][iv(16)][ciphertext(N)]
  static Uint8List _encrypt(String plaintext, String password) {
    final keyBytes = _deriveKey(password);
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    final magic = utf8.encode('PAB2'); // Paradise AG Backup v2 (AES-256-GCM)
    final ivBytes = iv.bytes;
    final cipherBytes = encrypted.bytes;

    final output = Uint8List(magic.length + ivBytes.length + cipherBytes.length);
    output.setRange(0, magic.length, magic);
    output.setRange(magic.length, magic.length + ivBytes.length, ivBytes);
    output.setRange(magic.length + ivBytes.length, output.length, cipherBytes);

    return output;
  }

  /// Decrypts bytes produced by [_encrypt].
  /// Supports both v2 (AES-256-GCM) and v1 (XOR+HMAC) for backward compatibility.
  static String _decrypt(Uint8List encrypted, String password) {
    final keyBytes = _deriveKey(password);

    // Check minimum length
    if (encrypted.length < 4) {
      throw Exception('File too short to be a valid backup');
    }

    // Detect format by magic header
    final magicV2 = utf8.encode('PAB2');
    final magicV1 = utf8.encode('PAB1');
    final isV2 = encrypted.length >= 4 &&
        encrypted[0] == magicV2[0] &&
        encrypted[1] == magicV2[1] &&
        encrypted[2] == magicV2[2] &&
        encrypted[3] == magicV2[3];
    final isV1 = encrypted.length >= 4 &&
        encrypted[0] == magicV1[0] &&
        encrypted[1] == magicV1[1] &&
        encrypted[2] == magicV1[2] &&
        encrypted[3] == magicV1[3];

    if (isV2) {
      // AES-256-GCM decryption
      final ivBytes = encrypted.sublist(4, 4 + 16);
      final cipherBytes = encrypted.sublist(4 + 16);
      final key = enc.Key(keyBytes);
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encData = enc.Encrypted(cipherBytes);
      return encrypter.decrypt(encData, iv: iv);
    }

    if (isV1) {
      // Legacy XOR+HMAC decryption for backward compatibility
      if (encrypted.length < magicV1.length + 32) {
        throw Exception('File too short to be a valid backup');
      }
      final storedHmac = encrypted.sublist(magicV1.length, magicV1.length + 32);
      final cipherBytes = encrypted.sublist(magicV1.length + 32);
      final plainBytes = Uint8List(cipherBytes.length);
      for (int i = 0; i < cipherBytes.length; i++) {
        plainBytes[i] = cipherBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      final hmac = Hmac(sha256, keyBytes);
      final digest = hmac.convert(plainBytes);
      final computedHmac = Uint8List.fromList(digest.bytes);
      for (int i = 0; i < 32; i++) {
        if (storedHmac[i] != computedHmac[i]) {
          throw Exception('HMAC verification failed - wrong password or corrupted data');
        }
      }
      return utf8.decode(plainBytes);
    }

    throw Exception('Invalid backup file format');
  }

  static Uint8List _deriveKey(String password) {
    final bytes = utf8.encode(password + _salt);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Gets a summary of current app data for display.
  static Future<DataSummary> getDataSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    int churchCount = 0;
    int userCount = 0;
    int memberCount = 0;
    int transactionCount = 0;
    int eventCount = 0;
    int sermonCount = 0;
    int welfareCount = 0;
    int attendanceCount = 0;
    int totalEntries = 0;

    for (final key in allKeys) {
      final value = prefs.get(key);
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) {
            totalEntries += decoded.length;

            if (key == 'all_churches') {
              churchCount = decoded.length;
            } else if (key.contains('users_box')) {
              userCount += decoded.length;
            } else if (key.contains('members_box')) {
              memberCount += decoded.length;
            } else if (key.contains('finance_box')) {
              transactionCount += decoded.length;
            } else if (key.contains('events_box')) {
              eventCount += decoded.length;
            } else if (key.contains('sermons_box')) {
              sermonCount += decoded.length;
            } else if (key.contains('welfare_box')) {
              welfareCount += decoded.length;
            } else if (key.contains('attendance_box')) {
              attendanceCount += decoded.length;
            }
          }
        } catch (e) {
          // Not JSON, skip
        }
      }
    }

    return DataSummary(
      totalKeys: allKeys.length,
      totalEntries: totalEntries,
      churches: churchCount,
      users: userCount,
      members: memberCount,
      transactions: transactionCount,
      events: eventCount,
      sermons: sermonCount,
      welfareCases: welfareCount,
      attendanceRecords: attendanceCount,
    );
  }

  /// Clears all app data (factory reset).
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Gets the approximate size of all stored data in bytes.
  static Future<int> getEstimatedDataSize() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    int size = 0;

    for (final key in allKeys) {
      final value = prefs.get(key);
      if (value is String) {
        size += value.length;
      }
    }

    return size;
  }
}

class RestoreResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? metadata;
  final int? restoredKeys;

  const RestoreResult({
    required this.success,
    required this.message,
    this.metadata,
    this.restoredKeys,
  });
}

class BackupPreview {
  final Map<String, dynamic> metadata;
  final int totalKeys;
  final int churchesCount;
  final bool hasUsers;

  const BackupPreview({
    required this.metadata,
    required this.totalKeys,
    required this.churchesCount,
    required this.hasUsers,
  });

  DateTime? get createdAt =>
      metadata['createdAt'] != null ? DateTime.tryParse(metadata['createdAt'] as String) : null;

  String? get appVersion => metadata['appVersion'] as String?;

  int? get backupVersion => metadata['version'] as int?;
}

class DataSummary {
  final int totalKeys;
  final int totalEntries;
  final int churches;
  final int users;
  final int members;
  final int transactions;
  final int events;
  final int sermons;
  final int welfareCases;
  final int attendanceRecords;

  const DataSummary({
    required this.totalKeys,
    required this.totalEntries,
    required this.churches,
    required this.users,
    required this.members,
    required this.transactions,
    required this.events,
    required this.sermons,
    required this.welfareCases,
    required this.attendanceRecords,
  });
}
