import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/sync_queue_entry.dart';
import 'local_db.dart';
import 'supabase_config.dart';
import 'tenant_context.dart';
import '../core/constants.dart';

/// Offline-first sync service.
///
/// Pushes local changes (from sync queue) to Supabase and pulls remote
/// changes down to local SharedPreferences. Works only when Supabase
/// is configured and internet is available.
///
/// The app remains fully functional offline. This service runs in the
/// background when connectivity is available.
class SyncService {
  static const _uuid = Uuid();

  /// Maps local HiveBoxes keys to Supabase table names.
  static const _tableMap = {
    HiveBoxes.church: 'churches',
    HiveBoxes.users: 'users',
    HiveBoxes.branches: 'branches',
    HiveBoxes.departments: 'departments',
    HiveBoxes.members: 'members',
    HiveBoxes.attendance: 'attendance_records',
    HiveBoxes.finance: 'transactions',
    HiveBoxes.sermons: 'sermons',
    HiveBoxes.events: 'events',
    HiveBoxes.welfare: 'welfare_cases',
    HiveBoxes.welfareFinance: 'welfare_finance',
    HiveBoxes.ministries: 'ministries',
    HiveBoxes.ministryFinance: 'ministry_finance',
    HiveBoxes.contributions: 'contributions',
    HiveBoxes.budgets: 'budgets',
    HiveBoxes.financeApprovals: 'finance_approvals',
    HiveBoxes.libraryBooks: 'library_books',
    HiveBoxes.devotionGuides: 'devotion_guides',
    HiveBoxes.bibleStudyResources: 'bible_study_resources',
    HiveBoxes.communityPosts: 'community_posts',
    HiveBoxes.communityComments: 'community_comments',
    HiveBoxes.communityConversations: 'community_conversations',
    HiveBoxes.communityMessages: 'community_messages',
  };

  // ── Queue Management ──────────────────────────────────────────────────────

  /// Records a local change to the sync queue for later push to cloud.
  static Future<void> enqueueChange({
    required String boxKey,
    required String recordId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final entry = SyncQueueEntry(
      id: _uuid.v4(),
      tableName: boxKey,
      recordId: recordId,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );
    await LocalDb.addToSyncQueue(entry);
  }

  /// Gets count of pending sync operations.
  static int getPendingCount() => LocalDb.getSyncQueueCount();

  // ── Connectivity ──────────────────────────────────────────────────────────

  /// Checks if internet is available.
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((c) => c != ConnectivityResult.none);
  }

  // ── Push (local → cloud) ──────────────────────────────────────────────────

  /// Pushes all pending local changes to Supabase.
  static Future<int> pushLocalChanges() async {
    if (!SupabaseConfig.isConfigured) return 0;

    final client = SupabaseConfig.client;
    if (client == null) return 0;

    final queue = LocalDb.getSyncQueue();
    if (queue.isEmpty) return 0;

    int pushed = 0;

    for (final entry in queue) {
      final tableName = _tableMap[entry.tableName];
      if (tableName == null) {
        await LocalDb.removeFromSyncQueue(entry.id);
        continue;
      }

      try {
        if (entry.operation == SyncQueueEntry.opDelete) {
          await client.from(tableName).delete().eq('id', entry.recordId);
        } else {
          // Defense-in-depth: strip passwordHash from any user data
          // before pushing to cloud (UK GDPR Art. 5(1)(f))
          final syncData = Map<String, dynamic>.from(entry.data);
          syncData.remove('passwordHash');
          await client.from(tableName).upsert(syncData, onConflict: 'id');
        }

        await LocalDb.removeFromSyncQueue(entry.id);
        pushed++;
      } catch (e) {
        await LocalDb.updateSyncQueueEntry(
          entry.copyWith(
            attempts: entry.attempts + 1,
            lastError: e.toString(),
          ),
        );
      }
    }

    return pushed;
  }

  // ── Pull (cloud → local) ──────────────────────────────────────────────────

  /// Pulls remote changes from Supabase and merges into local storage.
  static Future<int> pullRemoteChanges({required String churchId}) async {
    if (!SupabaseConfig.isConfigured) return 0;

    final client = SupabaseConfig.client;
    if (client == null) return 0;

    final lastSync = LocalDb.getLastSyncTime();
    final since = lastSync ?? DateTime(2000);

    int pulled = 0;

    for (final entry in _tableMap.entries) {
      final boxKey = entry.key;
      final tableName = entry.value;

      try {
        // Fetch records updated since last sync, scoped to church
        var query = client.from(tableName).select().gte('updated_at', since.toIso8601String());

        // Church-scoped tables (not global ones like organization, region, etc.)
        if (boxKey != HiveBoxes.organization &&
            boxKey != HiveBoxes.region &&
            boxKey != HiveBoxes.district &&
            boxKey != HiveBoxes.area) {
          query = query.eq('church_id', churchId);
        }

        final result = await query;

        // Merge into local storage
        final scopedKey = TenantContext.scopedKey(churchId, boxKey);
        final existingData = LocalDb.prefs.getString(scopedKey);
        final localMap = existingData != null
            ? Map<String, dynamic>.from(jsonDecode(existingData) as Map)
            : <String, dynamic>{};

        for (final record in result as List) {
          final recordMap = record as Map<String, dynamic>;
          final id = recordMap['id'] as String?;
          if (id != null) {
            localMap[id] = recordMap;
            pulled++;
          }
        }

        await LocalDb.prefs.setString(scopedKey, jsonEncode(localMap));
      } catch (e) {
        // Skip tables that don't exist yet or have errors
        continue;
      }
    }

    return pulled;
  }

  // ── Full Sync ─────────────────────────────────────────────────────────────

  /// Runs a full sync: push local changes, then pull remote changes.
  static Future<SyncResult> fullSync({required String churchId}) async {
    if (!SupabaseConfig.isConfigured) {
      return const SyncResult(
        success: false,
        pushed: 0,
        pulled: 0,
        failed: 0,
        message: 'Supabase is not configured. Add your credentials in supabase_config.dart.',
      );
    }

    final online = await isOnline();
    if (!online) {
      return const SyncResult(
        success: false,
        pushed: 0,
        pulled: 0,
        failed: 0,
        message: 'No internet connection. Changes will sync when you are back online.',
      );
    }

    try {
      // Push first
      final pushed = await pushLocalChanges();

      // Then pull
      final pulled = await pullRemoteChanges(churchId: churchId);

      // Update last sync time
      await LocalDb.setLastSyncTime(DateTime.now());

      final remaining = LocalDb.getSyncQueueCount();

      return SyncResult(
        success: true,
        pushed: pushed,
        pulled: pulled,
        failed: remaining,
        message: remaining > 0
            ? 'Synced $pushed up, $pulled down. $remaining failed.'
            : 'Sync complete: $pushed pushed, $pulled pulled.',
      );
    } catch (e) {
      return SyncResult(
        success: false,
        pushed: 0,
        pulled: 0,
        failed: LocalDb.getSyncQueueCount(),
        message: 'Sync error: $e',
      );
    }
  }

  // ── Auto Sync ─────────────────────────────────────────────────────────────

  /// Listens to connectivity changes and auto-syncs when online.
  static Stream<bool> connectivityStream() {
    return Connectivity().onConnectivityChanged.map((results) {
      return results.any((c) => c != ConnectivityResult.none);
    });
  }

  /// Gets the last sync time from local storage.
  static DateTime? getLastSyncTime() => LocalDb.getLastSyncTime();

  /// Whether Supabase is configured.
  static bool get isConfigured => SupabaseConfig.isConfigured;
}
