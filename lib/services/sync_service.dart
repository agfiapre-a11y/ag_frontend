import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
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

  /// Builds an upsert payload with the correct tenant column for a table.
  /// [desiredTenantCol] is one of 'tenant_id', 'church_id', or null (strip).
  /// The input [dbData] is assumed to have been produced by _keysToDb,
  /// so it may contain a `tenant_id` key. This helper renames or removes
  /// it to match the target table's actual schema.
  static Map<String, dynamic> _buildUpsertPayload(
    Map<String, dynamic> dbData,
    String? desiredTenantCol,
  ) {
    final payload = Map<String, dynamic>.from(dbData);
    final tenantValue = payload['tenant_id'] ?? payload['church_id'];

    // Remove both possible tenant columns; re-add the desired one.
    payload.remove('tenant_id');
    payload.remove('church_id');

    if (desiredTenantCol != null && tenantValue != null) {
      payload[desiredTenantCol] = tenantValue;
    }
    return payload;
  }

  /// Global tables that have no tenant-scoping column.
  static const _globalTables = {
    'tenants',
    'organizations',
    'regions',
    'districts',
    'areas',
  };

  /// Column whitelist per table — lists the actual columns that exist in
  /// the Supabase database (NestJS/TypeORM schema). Payloads are filtered
  /// to only include these columns before upsert, preventing 400 errors
  /// from extra columns the Flutter model has but the DB table doesn't.
  ///
  /// Tables not listed here are not filtered (legacy behaviour).
  static const _tableColumns = <String, Set<String>>{
    'users': {
      'id', 'email', 'password_hash', 'name', 'role', 'roles',
      'active_role', 'tenant_id', 'is_active', 'created_at', 'updated_at',
    },
    'members': {
      'id', 'tenant_id', 'first_name', 'last_name', 'email', 'phone',
      'gender', 'date_of_birth', 'marital_status', 'is_employed',
      'address', 'city', 'is_active', 'created_at', 'updated_at',
    },
  };

  /// Tables where tenant_id is NOT NULL with FK to tenants.id.
  /// If the tenant doesn't exist in the Supabase tenants table, the
  /// upsert is skipped to avoid FK violations.
  static const _tenantIdTables = {
    'members', 'attendance_records', 'transactions', 'welfare_cases',
    'contributions', 'budgets', 'finance_approvals',
  };

  /// Tables where church_id is NOT NULL with FK to churches.id.
  /// These tables reference the Flutter migrations' churches table,
  /// NOT the NestJS tenants table. The church must exist in the
  /// churches table before data can be pushed.
  static const _churchIdTables = {
    'departments', 'ministries', 'ministry_finance',
    'welfare_finance',
  };

  /// Filters an upsert payload to only include columns that exist in the
  /// target table. Also handles special field transformations:
  /// - members: splits `name` into `first_name` + `last_name`
  static Map<String, dynamic> _filterPayload(
    String tableName,
    Map<String, dynamic> payload,
  ) {
    final allowed = _tableColumns[tableName];
    if (allowed == null) return payload;

    final filtered = <String, dynamic>{};
    for (final entry in payload.entries) {
      if (allowed.contains(entry.key)) {
        filtered[entry.key] = entry.value;
      }
    }

    // Special case: members table uses first_name + last_name, not name.
    if (tableName == 'members' && !filtered.containsKey('first_name')) {
      final name = payload['name'] as String? ?? '';
      if (name.isNotEmpty) {
        final parts = name.trim().split(RegExp(r'\s+'));
        filtered['first_name'] = parts.first;
        filtered['last_name'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    return filtered;
  }

  /// Fetches all records from a Supabase table for a given tenant.
  /// Returns records with keys converted to camelCase (app format).
  /// Returns empty list if Supabase is not configured or fetch fails.
  ///
  /// [columns] — optional comma-separated list of columns to select
  /// (e.g. 'id,title,tenant_id' to exclude large fields like content).
  ///
  /// The DB schema is inconsistent: tables created by the Flutter migrations
  /// use `tenant_id`, while tables created by the NestJS backend (TypeORM)
  /// use `church_id`. This method tries `tenant_id` first, then falls back
  /// to `church_id`, then to no tenant filter, so both schemas work.
  static Future<List<Map<String, dynamic>>> fetchTable({
    required String tableName,
    required String churchId,
    String? orderBy,
    bool ascending = true,
    int? limit,
    String? columns,
  }) async {
    if (!SupabaseConfig.isConfigured) return [];
    final client = SupabaseConfig.client;
    if (client == null) return [];

    try {
      final tenantId = await resolveTenantId(churchId);

      final isGlobal = _globalTables.contains(tableName);
      // Candidate tenant columns to try, in order of preference.
      final tenantColumns =
          isGlobal ? <String?>[null] : <String?>['tenant_id', 'church_id', null];

      Object? lastError;
      for (var i = 0; i < tenantColumns.length; i++) {
        final col = tenantColumns[i];
        final isLast = i == tenantColumns.length - 1;
        try {
          // Build query — use dynamic to avoid type mismatch between
          // PostgrestFilterBuilder and PostgrestTransformBuilder
          dynamic query = client.from(tableName).select(columns ?? '*');
          if (col != null) {
            query = query.eq(col, tenantId);
          }
          if (orderBy != null) {
            query = query.order(orderBy, ascending: ascending);
          }
          if (limit != null) {
            query = query.limit(limit);
          }

          final result = await query.timeout(const Duration(seconds: 10));
          final rows = (result as List)
              .map((r) => _keysFromDb(r as Map<String, dynamic>))
              .toList();

          // If we got rows, or this is the last fallback column, we're done.
          // If we got 0 rows but more fallback columns remain, try them —
          // the data may live under a different tenant column (e.g. rows
          // have tenant_id NULL but church_id populated).
          if (rows.isNotEmpty || isLast) return rows;
          // Empty result on a non-final column: fall through to next.
        } catch (e) {
          // Column doesn't exist (42703) or other error — try next column.
          // Only retry on column-mismatch errors; bail on genuine failures
          // (timeouts, network) after the first attempt to avoid long waits.
          lastError = e;
          final str = e.toString();
          final isColumnError = str.contains('42703') ||
              str.contains('does not exist') ||
              str.contains('Could not find column') ||
              str.contains('column') && str.contains('does not exist');
          if (!isColumnError) break;
        }
      }
      // All attempts failed — return empty so local data still shows.
      debugPrint('[fetchTable] $tableName exhausted tenant-column fallbacks: '
          '$lastError');
      return [];
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

  /// Maximum number of push attempts before an entry is quarantined
  /// (removed from the active queue) to stop it from being retried forever.
  static const _maxPushAttempts = 8;

  /// Base delay for exponential backoff between retry attempts.
  /// Effective delay = _backoffBase * 2^(attempts - 1), capped at 1 hour.
  static const _backoffBase = Duration(seconds: 30);

  /// Whether a sync queue entry is due for another push attempt, based on
  /// its attempt count and the time of its last attempt (exponential
  /// backoff). Entries with 0 attempts are always due.
  static bool _isDueForRetry(SyncQueueEntry entry) {
    if (entry.attempts == 0) return true;
    final backoffMultiplier = 1 << (entry.attempts - 1).clamp(0, 6); // cap 2^6
    final delay = _backoffBase * backoffMultiplier;
    final cappedDelay = delay > const Duration(hours: 1)
        ? const Duration(hours: 1)
        : delay;
    return DateTime.now().isAfter(entry.createdAt.add(cappedDelay)) &&
        (entry.lastRetryAt == null ||
            DateTime.now().isAfter(entry.lastRetryAt!.add(cappedDelay)));
  }

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

      // Respect exponential backoff — skip entries not yet due for retry.
      if (!_isDueForRetry(entry)) continue;

      // Quarantine entries that have exhausted their retry budget so they
      // stop being retried forever and flooding the console/network.
      if (entry.attempts >= _maxPushAttempts) {
        debugPrint('[pushLocalChanges] Quarantining $tableName/${entry.recordId} '
            'after ${entry.attempts} failed attempts: ${entry.lastError}');
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
          // Convert camelCase keys to snake_case for the database.
          // _keysToDb maps churchId → tenant_id by default.
          final dbData = _keysToDb(syncData);

          // Resolve the real Supabase tenant_id for this record's church.
          // The Flutter app generates local UUIDs that don't match the
          // Supabase tenants table; resolveTenantId maps by name.
          final rawTenantId = dbData['tenant_id'] as String? ??
              dbData['church_id'] as String?;
          final resolvedTenantId = rawTenantId != null && rawTenantId.isNotEmpty
              ? await resolveTenantId(rawTenantId)
              : null;

          // For tables where tenant_id is NOT NULL with a FK to tenants,
          // skip the upsert if the tenant doesn't exist in Supabase yet.
          // This prevents FK violations (400) during local-only seeding
          // before the church has been created in Supabase.
          if (_tenantIdTables.contains(tableName)) {
            final effectiveTenantId = resolvedTenantId ?? rawTenantId;
            if (effectiveTenantId == null || effectiveTenantId.isEmpty) {
              debugPrint('[pushLocalChanges] Skipping $tableName/'
                  '${entry.recordId}: no tenant_id');
              continue;
            }
            if (!await _tenantExists(client, effectiveTenantId)) {
              debugPrint('[pushLocalChanges] Skipping $tableName/'
                  '${entry.recordId}: tenant $effectiveTenantId '
                  'does not exist in Supabase tenants table');
              continue;
            }
          }

          // For tables where church_id is NOT NULL with a FK to churches,
          // ensure the church exists in the churches table before pushing.
          // The churches table is separate from the tenants table and is
          // populated by Flutter migrations, not by the NestJS backend.
          if (_churchIdTables.contains(tableName)) {
            final effectiveChurchId = resolvedTenantId ?? rawTenantId;
            if (effectiveChurchId == null || effectiveChurchId.isEmpty) {
              debugPrint('[pushLocalChanges] Skipping $tableName/'
                  '${entry.recordId}: no church_id');
              continue;
            }
            // Auto-insert the church into the churches table if missing
            await _ensureChurchExists(client, effectiveChurchId);
          }

          // Replace the raw tenant_id with the resolved one
          if (resolvedTenantId != null && resolvedTenantId != rawTenantId) {
            dbData['tenant_id'] = resolvedTenantId;
            dbData.remove('church_id');
          }

          // The DB schema is inconsistent: migration-created tables use
          // `tenant_id`, NestJS/TypeORM-created tables use `church_id`.
          // Try tenant_id first, then church_id, then strip the tenant
          // column entirely, retrying only on column-mismatch (400/42703).
          final isGlobal = _globalTables.contains(tableName);
          final tenantCols = isGlobal
              ? <String?>[null]
              : <String?>['tenant_id', 'church_id', null];

          Object? lastError;
          bool succeeded = false;
          for (final col in tenantCols) {
            try {
              final payload = _buildUpsertPayload(dbData, col);
              // Filter to only columns that exist in the target table
              // to prevent 400 errors from extra model fields.
              final filtered = _filterPayload(tableName, payload);
              await client
                  .from(tableName)
                  .upsert(filtered, onConflict: 'id');
              succeeded = true;
              break;
            } catch (e) {
              lastError = e;
              final str = e.toString();
              final isColumnError = str.contains('42703') ||
                  str.contains('does not exist') ||
                  str.contains('Could not find column') ||
                  str.contains('400');
              if (!isColumnError) break;
            }
          }
          if (!succeeded) {
            throw lastError ?? Exception('upsert failed for $tableName');
          }
        }

        await LocalDb.removeFromSyncQueue(entry.id);
        pushed++;
      } catch (e) {
        // Log the real error so we can diagnose schema/data issues instead
        // of only seeing a generic "400 Bad Request" in the network tab.
        debugPrint('[pushLocalChanges] Failed to push $tableName/'
            '${entry.recordId} (attempt ${entry.attempts + 1}/'
            '$_maxPushAttempts): $e');
        await LocalDb.updateSyncQueueEntry(
          entry.copyWith(
            attempts: entry.attempts + 1,
            lastError: e.toString(),
            lastRetryAt: DateTime.now(),
          ),
        );
      }
    }

    return pushed;
  }

  /// Checks whether a tenant with the given ID exists in the Supabase
  /// tenants table. Returns false on any error (fail-safe).
  static Future<bool> _tenantExists(dynamic client, String? tenantId) async {
    if (tenantId == null || tenantId.isEmpty) return false;
    try {
      final result = await client
          .from('tenants')
          .select('id')
          .eq('id', tenantId)
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return (result as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether a church with the given ID exists in the Supabase
  /// churches table (Flutter migrations schema). Returns false on any
  /// error (fail-safe).
  static Future<bool> _churchExists(dynamic client, String? churchId) async {
    if (churchId == null || churchId.isEmpty) return false;
    try {
      final result = await client
          .from('churches')
          .select('id')
          .eq('id', churchId)
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return (result as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Ensures the church exists in the Supabase churches table (Flutter
  /// migrations schema). This is needed because branches, departments,
  /// ministries, etc. have FK to churches(id), but the sync service
  /// only syncs churches to the tenants table (NestJS schema).
  /// Inserts a minimal church record if it doesn't already exist.
  static Future<void> _ensureChurchExists(
    dynamic client,
    String churchId,
  ) async {
    if (await _churchExists(client, churchId)) return;

    // Look up the church from local storage to get its details
    final church = LocalDb.getChurchById(churchId);
    final now = DateTime.now().toIso8601String();

    try {
      await client.from('churches').upsert({
        'id': churchId,
        'name': church?.name ?? 'Unknown Church',
        'email': church?.email,
        'phone': church?.phone,
        'address': church?.address,
        'description': '',
        'logo_url': '',
        'created_at': now,
        'updated_at': now,
      }, onConflict: 'id');
      debugPrint('[sync] Inserted church $churchId into churches table');
    } catch (e) {
      debugPrint('[sync] Failed to insert church into churches table: $e');
    }
  }

  /// Public wrapper for _ensureChurchExists — called after login to
  /// make sure the church exists in the Supabase churches table before
  /// any tenant-scoped data is synced.
  static Future<void> ensureChurchInSupabase(String churchId) async {
    if (!SupabaseConfig.isConfigured) return;
    final client = SupabaseConfig.client;
    if (client == null) return;
    await _ensureChurchExists(client, churchId);
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
        // Determine which tenant column this table uses.
        // The DB schema is inconsistent: migration-created tables use
        // `tenant_id`, NestJS/TypeORM-created tables use `church_id`.
        final isGlobal = boxKey == HiveBoxes.organization ||
            boxKey == HiveBoxes.region ||
            boxKey == HiveBoxes.district ||
            boxKey == HiveBoxes.area ||
            boxKey == HiveBoxes.church ||
            _globalTables.contains(tableName);
        final tenantColumns = isGlobal
            ? <String?>[null]
            : <String?>['tenant_id', 'church_id', null];

        List? result;
        Object? lastError;
        for (var i = 0; i < tenantColumns.length; i++) {
          final col = tenantColumns[i];
          final isLast = i == tenantColumns.length - 1;
          try {
            var query = client
                .from(tableName)
                .select()
                .gte('updated_at', since.toIso8601String());
            if (col != null) {
              query = query.eq(col, tenantId);
            }
            final fetched = await query as List;
            // If we got rows, or this is the last fallback column, accept it.
            // If empty but more fallbacks remain, try them — data may live
            // under a different tenant column (e.g. tenant_id NULL but
            // church_id populated on legacy rows).
            if (fetched.isNotEmpty || isLast) {
              result = fetched;
              break;
            }
          } catch (e) {
            lastError = e;
            final str = e.toString();
            final isColumnError = str.contains('42703') ||
                str.contains('does not exist') ||
                str.contains('Could not find column');
            if (!isColumnError) break;
          }
        }
        if (result == null) {
          debugPrint('[pullRemoteChanges] $tableName fallback exhausted: '
              '$lastError');
          continue;
        }

        // Merge into local encrypted storage
        if (boxKey == HiveBoxes.users) {
          // Users: merge into encrypted storage + cache
          final existing = LocalDb.getAllUsersMap();
          final localMap = Map<String, dynamic>.from(existing);

          for (final record in result) {
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

          for (final record in result) {
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
      // ONLINE-FIRST: Pull first, then push.
      // This ensures the app has the latest data from Supabase before
      // pushing local changes, reducing conflicts and ensuring the user
      // sees fresh data immediately after login.
      final pulled = await pullRemoteChanges(churchId: churchId);

      // Then push local changes
      final pushed = await pushLocalChanges();

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
