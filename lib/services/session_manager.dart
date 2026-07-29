import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Session manager with expiry timestamps.
/// NCSC-compliant: 15-minute idle timeout, 8-hour max session.
class SessionManager {
  static const _key = 'session_data';
  static const Duration _maxSessionDuration = Duration(hours: 8);
  static const Duration _idleTimeout = Duration(minutes: 15);

  static Future<void> saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final session = {
      'userId': userId,
      'createdAt': now.toIso8601String(),
      'lastActivityAt': now.toIso8601String(),
    };
    await prefs.setString(_key, jsonEncode(session));
  }

  static Future<String?> getValidSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    final session = Map<String, dynamic>.from(jsonDecode(data) as Map);
    final userId = session['userId'] as String?;
    if (userId == null) return null;

    final createdAt = DateTime.parse(session['createdAt'] as String);
    final lastActivity = DateTime.parse(session['lastActivityAt'] as String);
    final now = DateTime.now();

    // Check max session duration
    if (now.difference(createdAt) > _maxSessionDuration) {
      await clearSession();
      return null;
    }

    // Check idle timeout
    if (now.difference(lastActivity) > _idleTimeout) {
      await clearSession();
      return null;
    }

    return userId;
  }

  static Future<void> updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return;
    final session = Map<String, dynamic>.from(jsonDecode(data) as Map);
    session['lastActivityAt'] = DateTime.now().toIso8601String();
    await prefs.setString(_key, jsonEncode(session));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static bool isSessionValidSync(String? sessionData) {
    if (sessionData == null) return false;
    try {
      final session = Map<String, dynamic>.from(jsonDecode(sessionData) as Map);
      final createdAt = DateTime.parse(session['createdAt'] as String);
      final lastActivity = DateTime.parse(session['lastActivityAt'] as String);
      final now = DateTime.now();
      if (now.difference(createdAt) > _maxSessionDuration) return false;
      if (now.difference(lastActivity) > _idleTimeout) return false;
      return true;
    } catch (_) {
      return false;
    }
  }
}
