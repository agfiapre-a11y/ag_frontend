import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/sync_queue_entry.dart';
import '../models/church.dart';
import 'local_db.dart';
import 'supabase_config.dart';
import '../core/constants.dart';

/// Offline-first sync service.
///
/// Pushes local changes (from sync queue) to Supabase and pulls remote
/// changes down to local SharedPreferences. Works only when Supabase
/// is configured and internet is available.
///
/// The app remains fully functional offline. This service runs in the
/// background when connectivity is available.
///
/// Column names are converted between the app's camelCase convention and
/// the database's snake_case convention automatically. The special field
/// `churchId` (app) maps to `tenant_id` (database) to bridge the Flutter
/// app's local model with the NestJS backend's TypeORM schema.
class SyncService {
  static const _uuid = Uuid();

  /// Maps local HiveBoxes keys to Supabase table names.
  static const _tableMap = {
    HiveBoxes.church: 'tenants',
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
    HiveBoxes.sundaySchoolBooks: 'sunday_school_books',
    HiveBoxes.sundaySchoolChapters: 'sunday_school_chapters',
    HiveBoxes.communityPosts: 'community_posts',
    HiveBoxes.communityComments: 'community_comments',
    HiveBoxes.communityConversations: 'community_conversations',
    HiveBoxes.communityMessages: 'community_messages',
    HiveBoxes.accessGrants: 'access_grants',
    HiveBoxes.accessActivities: 'access_activities',
  };

  /// Special field mappings (app field name → database column name).
  /// Handles the churchId ↔ tenant_id bridge and any other non-standard
  /// column names that don't follow simple camelCase→snake_case conversion.
  static const _fieldMap = {
    'churchId': 'tenant_id',
    'passwordHash': 'password_hash',
    // library_books: model uses 'url' but table column is 'download_url'
    'url': 'download_url',
    'coverColor': 'cover_color',
    'addedById': 'added_by_id',
    'pageCount': 'page_count',
    'wordCount': 'word_count',
    // sunday_school: date fields and special mappings
    'startDate': 'start_date',
    'endDate': 'end_date',
    'totalChapters': 'total_chapters',
    'addedByName': 'added_by_name',
    'bookId': 'book_id',
    'chapterNumber': 'chapter_number',
    'sundayDate': 'sunday_date',
    'discussionPostId': 'discussion_post_id',
    'memoryVerseRef': 'memory_verse_ref',
    'memoryVerseText': 'memory_verse_text',
  };

  /// Converts a camelCase string to snake_case.
  static String _toSnakeCase(String key) {
    // Check special field mappings first
    if (_fieldMap.containsKey(key)) return _fieldMap[key]!;
    // camelCase → snake_case: insert _ before each uppercase, lowercase all
    final result = key.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );
    return result;
  }

  /// Converts a snake_case string to camelCase.
  static String _toCamelCase(String key) {
    // Reverse special field mappings
    for (final entry in _fieldMap.entries) {
      if (entry.value == key) return entry.key;
    }
    // snake_case → camelCase: remove _ and capitalize next letter
    final result = key.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (m) => m[1]!.toUpperCase(),
    );
    return result;
  }

  /// Converts all keys in a map from camelCase to snake_case for database.
  static Map<String, dynamic> _keysToDb(Map<String, dynamic> map) {
    return map.map((k, v) => MapEntry(_toSnakeCase(k), v));
  }

  /// Converts all keys in a map from snake_case to camelCase for local storage.
  static Map<String, dynamic> _keysFromDb(Map<String, dynamic> map) {
    return map.map((k, v) => MapEntry(_toCamelCase(k), v));
  }

  /// Public version of _keysFromDb for use by providers.
  static Map<String, dynamic> keysFromDb(Map<String, dynamic> map) =>
      _keysFromDb(map);

  /// Fetches all records from a Supabase table for a given tenant.
  /// Returns records with keys converted to camelCase (app format).
  /// Returns empty list if Supabase is not configured or fetch fails.
  static Future<List<Map<String, dynamic>>> fetchTable({
    required String tableName,
    required String churchId,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    if (!SupabaseConfig.isConfigured) return [];
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final tenantId = await resolveTenantId(churchId);

      // Build query — use dynamic to avoid type mismatch between
      // PostgrestFilterBuilder and PostgrestTransformBuilder
      dynamic query = client.from(tableName).select();

      // Global tables don't have tenant_id
      final isGlobal = tableName == 'tenants' ||
          tableName == 'organizations' ||
          tableName == 'regions' ||
          tableName == 'districts' ||
          tableName == 'areas';
      if (!isGlobal) {
        query = query.eq('tenant_id', tenantId);
      }

      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final result = await query.timeout(const Duration(seconds: 10));

      return (result as List)
          .map((r) => _keysFromDb(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

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
          // Convert camelCase keys to snake_case for the database
          final dbData = _keysToDb(syncData);
          await client.from(tableName).upsert(dbData, onConflict: 'id');
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

  /// Resolves the correct Supabase tenant_id for a given local church.
  /// When the app uses local login (backend unreachable), the local church ID
  /// is a random UUID that doesn't match the Supabase tenant_id. This method
  /// looks up the tenant by church name and returns the correct ID.
  static Future<String> resolveTenantId(String churchId) async {
    if (!SupabaseConfig.isConfigured) return churchId;
    final client = SupabaseConfig.client;
    if (client == null) return churchId;

    // First, try the churchId directly — if it matches a tenant, use it
    try {
      final direct = await client
          .from('tenants')
          .select('id')
          .eq('id', churchId)
          .limit(1);
      if (direct.isNotEmpty) return churchId;
    } catch (_) {}

    // Try to find by church name from local storage
    final church = LocalDb.getChurchById(churchId);
    if (church != null) {
      try {
        // Look up by name (case-insensitive)
        final byName = await client
            .from('tenants')
            .select('id, name')
            .ilike('name', church.name)
            .limit(1);
        if (byName.isNotEmpty) {
          final supabaseId = byName.first['id'] as String;
          // Update the local church ID to match Supabase
          final updated = Church(
            id: supabaseId,
            name: church.name,
            adminId: church.adminId,
            address: church.address,
            phone: church.phone,
            email: church.email,
            createdAt: church.createdAt,
          );
          await LocalDb.saveChurch(updated);
          await LocalDb.setActiveChurch(supabaseId);
          return supabaseId;
        }
      } catch (_) {}
    }

    return churchId;
  }

  /// Pulls remote changes from Supabase and merges into local storage.
  static Future<int> pullRemoteChanges({required String churchId}) async {
    if (!SupabaseConfig.isConfigured) return 0;

    final client = SupabaseConfig.client;
    if (client == null) return 0;

    // Resolve the correct Supabase tenant_id (may differ from local church ID)
    final tenantId = await resolveTenantId(churchId);

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
        // Use tenant_id (database column name) instead of church_id.
        // The tenants table itself and global tables don't have tenant_id.
        if (boxKey != HiveBoxes.organization &&
            boxKey != HiveBoxes.region &&
            boxKey != HiveBoxes.district &&
            boxKey != HiveBoxes.area &&
            boxKey != HiveBoxes.church) {
          query = query.eq('tenant_id', tenantId);
        }

        final result = await query;

        // Merge into local encrypted storage
        if (boxKey == HiveBoxes.users) {
          // Users: merge into encrypted storage + cache
          final existing = LocalDb.getAllUsersMap();
          final localMap = Map<String, dynamic>.from(existing);

          for (final record in result as List) {
            final recordMap = record as Map<String, dynamic>;
            final id = recordMap['id']?.toString();
            if (id != null) {
              localMap[id] = _keysFromDb(recordMap);
              pulled++;
            }
          }

          await LocalDb.savePulledUsers(churchId, localMap);
        } else {
          // All other boxes: merge into encrypted storage + cache
          final existing = LocalDb.getAllBoxMapSync(boxKey);
          final localMap = Map<String, dynamic>.from(existing);

          for (final record in result as List) {
            final recordMap = record as Map<String, dynamic>;
            final id = recordMap['id']?.toString();
            if (id != null) {
              localMap[id] = _keysFromDb(recordMap);
              pulled++;
            }
          }

          await LocalDb.savePulledBoxData(churchId, boxKey, localMap);
        }
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
