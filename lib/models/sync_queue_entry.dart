/// Represents a record that has been modified locally and needs to be synced to cloud.
class SyncQueueEntry {
  final String id;
  final String tableName;
  final String recordId;
  final String operation; // 'insert', 'update', 'delete'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  static const opInsert = 'insert';
  static const opUpdate = 'update';
  static const opUpsert = 'upsert';
  static const opDelete = 'delete';

  const SyncQueueEntry({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'tableName': tableName,
        'recordId': recordId,
        'operation': operation,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  factory SyncQueueEntry.fromMap(Map<dynamic, dynamic> map) => SyncQueueEntry(
        id: map['id'] as String,
        tableName: map['tableName'] as String,
        recordId: map['recordId'] as String,
        operation: map['operation'] as String,
        data: Map<String, dynamic>.from(map['data'] as Map),
        createdAt: DateTime.parse(map['createdAt'] as String),
        attempts: (map['attempts'] as num?)?.toInt() ?? 0,
        lastError: map['lastError'] as String?,
      );

  SyncQueueEntry copyWith({
    int? attempts,
    String? lastError,
  }) =>
      SyncQueueEntry(
        id: id,
        tableName: tableName,
        recordId: recordId,
        operation: operation,
        data: data,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );
}

/// Result of a sync operation.
class SyncResult {
  final bool success;
  final int pushed;
  final int pulled;
  final int failed;
  final String message;
  final List<String> errors;

  const SyncResult({
    required this.success,
    required this.pushed,
    required this.pulled,
    required this.failed,
    required this.message,
    this.errors = const [],
  });

  static const empty = SyncResult(
    success: true,
    pushed: 0,
    pulled: 0,
    failed: 0,
    message: 'Nothing to sync',
  );
}

/// Sync status for UI display.
enum SyncStatus { idle, syncing, success, error, notConfigured, offline }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    int? pendingCount,
    String? errorMessage,
  }) =>
      SyncState(
        status: status ?? this.status,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        pendingCount: pendingCount ?? this.pendingCount,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}
