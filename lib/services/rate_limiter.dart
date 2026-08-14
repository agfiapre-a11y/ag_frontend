import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Login rate limiter — tracks failed attempts and enforces lockout.
/// 5 failed attempts → 5-minute lockout.
class RateLimiter {
  static const _key = 'login_attempts';
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  static Future<bool> isLocked(String email) async {
    final attempts = await _getAttempts(email);
    if (attempts == null) return false;
    if (attempts['count'] >= _maxAttempts) {
      final lockedAt = DateTime.parse(attempts['lockedAt'] as String);
      if (DateTime.now().difference(lockedAt) < _lockoutDuration) {
        return true;
      }
      // Lockout expired — reset
      await clearAttempts(email);
    }
    return false;
  }

  static Future<void> recordFailure(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    final all = data != null ? Map<String, dynamic>.from(jsonDecode(data) as Map) : <String, dynamic>{};
    final key = email.toLowerCase().trim();
    final current = all[key] as Map<String, dynamic>?;
    final count = (current?['count'] as int?) ?? 0;
    all[key] = {
      'count': count + 1,
      'lockedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_key, jsonEncode(all));
  }

  static Future<void> clearAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return;
    final all = Map<String, dynamic>.from(jsonDecode(data) as Map);
    all.remove(email.toLowerCase().trim());
    await prefs.setString(_key, jsonEncode(all));
  }

  static Future<int> getRemainingAttempts(String email) async {
    final attempts = await _getAttempts(email);
    if (attempts == null) return _maxAttempts;
    final count = (attempts['count'] as int?) ?? 0;
    return (_maxAttempts - count).clamp(0, _maxAttempts);
  }

  static Future<Map<String, dynamic>?> _getAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    final all = Map<String, dynamic>.from(jsonDecode(data) as Map);
    return all[email.toLowerCase().trim()] as Map<String, dynamic>?;
  }
}
