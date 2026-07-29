import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuditEntry {
  final String id;
  final String actorId;
  final String actorName;
  final String action;
  final String resource;
  final String? resourceId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime timestamp;
  final String? ipAddress;

  const AuditEntry({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.resource,
    this.resourceId,
    this.oldValues,
    this.newValues,
    required this.timestamp,
    this.ipAddress,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'actorId': actorId,
        'actorName': actorName,
        'action': action,
        'resource': resource,
        'resourceId': resourceId,
        'oldValues': oldValues,
        'newValues': newValues,
        'timestamp': timestamp.toIso8601String(),
        'ipAddress': ipAddress,
      };

  factory AuditEntry.fromMap(Map<dynamic, dynamic> map) => AuditEntry(
        id: map['id'] as String,
        actorId: map['actorId'] as String,
        actorName: map['actorName'] as String,
        action: map['action'] as String,
        resource: map['resource'] as String,
        resourceId: map['resourceId'] as String?,
        oldValues: map['oldValues'] as Map<String, dynamic>?,
        newValues: map['newValues'] as Map<String, dynamic>?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        ipAddress: map['ipAddress'] as String?,
      );
}

class AuditService {
  static const _uuid = Uuid();
  static const _key = 'audit_log';
  static const int _maxEntries = 5000;

  static Future<void> log({
    required String actorId,
    required String actorName,
    required String action,
    required String resource,
    String? resourceId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _getAll(prefs);
    entries.insert(
        0,
        AuditEntry(
          id: _uuid.v4(),
          actorId: actorId,
          actorName: actorName,
          action: action,
          resource: resource,
          resourceId: resourceId,
          oldValues: oldValues,
          newValues: newValues,
          timestamp: DateTime.now(),
        ));
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }
    await prefs.setString(_key, jsonEncode(entries.map((e) => e.toMap()).toList()));
  }

  static Future<List<AuditEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _getAll(prefs);
  }

  static List<AuditEntry> _getAll(SharedPreferences prefs) {
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => AuditEntry.fromMap(e as Map)).toList();
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
