import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_wrapper.dart';
import 'tenant_context.dart';
import 'sync_service.dart';
import '../core/constants.dart';
import '../core/role_dashboard_catalog.dart';
import '../models/access_control_grant.dart';

/// Service for managing page-level access control grants and activity logging.
///
/// Adapted from SIMS's accessControlStore. Allows admins to:
/// - Assign a user to another role's dashboard with full or page-level access
/// - Revoke access grants
/// - Log activity when assigned users navigate to granted pages
/// - Query grants, activities, and notifications
///
/// All data is stored encrypted via SecureStorageWrapper and synced to Supabase.
class AccessControlService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('AccessControlService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ── Grants ────────────────────────────────────────────────────────────────

  /// Assigns a user to a dashboard with either full or page-level access.
  /// If a grant already exists for this user+dashboard, it's updated.
  static Future<void> assignAccess({
    required String userId,
    required String username,
    required String displayName,
    required String dashboardKey,
    required dynamic allowedPages, // 'all' or List<String>
    required String grantedBy,
  }) async {
    final churchId = TenantContext.activeChurchId;
    final dashDef = RoleDashboardCatalog.dashboardMap[dashboardKey];
    final dashboardLabel = dashDef?.label ?? dashboardKey;

    final grants = getAllGrantsMap();
    final existing = grants.values.where((g) =>
        g.userId == userId && g.dashboardKey == dashboardKey);

    final now = DateTime.now().toIso8601String();

    if (existing.isNotEmpty) {
      // Update existing grant
      final existingGrant = existing.first;
      grants[existingGrant.id] = AccessControlGrant(
        id: existingGrant.id,
        userId: userId,
        username: username,
        displayName: displayName,
        dashboardKey: dashboardKey,
        dashboardLabel: dashboardLabel,
        allowedPages: allowedPages,
        grantedBy: grantedBy,
        grantedAt: now,
        churchId: churchId,
      );
    } else {
      // Create new grant
      final id = 'grant_${DateTime.now().millisecondsSinceEpoch}';
      grants[id] = AccessControlGrant(
        id: id,
        userId: userId,
        username: username,
        displayName: displayName,
        dashboardKey: dashboardKey,
        dashboardLabel: dashboardLabel,
        allowedPages: allowedPages,
        grantedBy: grantedBy,
        grantedAt: now,
        churchId: churchId,
      );
    }

    await _saveGrants(grants);

    // Enqueue sync change
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.accessGrants,
      recordId: userId,
      operation: 'upsert',
      data: grants[grants.keys.where((k) =>
          grants[k]!.userId == userId &&
          grants[k]!.dashboardKey == dashboardKey).first]!.toMap(),
    );
  }

  /// Revokes a specific access grant by ID.
  static Future<void> revokeAccess(String grantId) async {
    final grants = getAllGrantsMap();
    grants.remove(grantId);
    await _saveGrants(grants);
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.accessGrants,
      recordId: grantId,
      operation: 'delete',
      data: {},
    );
  }

  /// Revokes all grants for a user.
  static Future<void> revokeAllForUser(String userId) async {
    final grants = getAllGrantsMap();
    grants.removeWhere((_, g) => g.userId == userId);
    await _saveGrants(grants);
  }

  /// Gets all grants for a specific user.
  static List<AccessControlGrant> getGrantsForUser(String userId) {
    final grants = getAllGrantsMap();
    return grants.values.where((g) => g.userId == userId).toList();
  }

  /// Gets the grant for a user+dashboard combination, if any.
  static AccessControlGrant? getGrantForUserDashboard(
      String userId, String dashboardKey) {
    final grants = getAllGrantsMap();
    try {
      return grants.values.firstWhere(
          (g) => g.userId == userId && g.dashboardKey == dashboardKey);
    } catch (_) {
      return null;
    }
  }

  /// Gets all users assigned to a specific dashboard.
  static List<AccessControlGrant> getAssigneesForDashboard(String dashboardKey) {
    final grants = getAllGrantsMap();
    return grants.values.where((g) => g.dashboardKey == dashboardKey).toList();
  }

  /// Gets all dashboard keys a user has been granted access to
  /// (beyond their own role's dashboard).
  static List<String> getAssignedDashboardKeys(String userId) {
    final grants = getGrantsForUser(userId);
    return grants.map((g) => g.dashboardKey).toList();
  }

  /// Filters a list of dashboard pages based on the user's grants.
  /// If the user has a grant for this dashboard, only allowed pages are returned.
  /// If no grant exists, all pages are returned (the user's own dashboard).
  static List<DashboardPageDef> getFilteredPages(
      String userId, String dashboardKey, List<DashboardPageDef> allPages) {
    final grant = getGrantForUserDashboard(userId, dashboardKey);
    if (grant == null) return allPages; // own dashboard — no filtering
    if (grant.isFullAccess) return allPages;
    return allPages.where((p) => grant.allowsPage(p.key)).toList();
  }

  // ── Activity Logging ──────────────────────────────────────────────────────

  /// Logs an activity when an assigned user navigates to a page.
  static Future<void> logActivity({
    required String userId,
    required String username,
    required String displayName,
    required String dashboardKey,
    required String dashboardLabel,
    required String pageKey,
    required String pageLabel,
    required String action,
  }) async {
    final activities = getAllActivitiesMap();
    final id = 'activity_${DateTime.now().millisecondsSinceEpoch}';
    activities[id] = AccessActivity(
      id: id,
      userId: userId,
      username: username,
      displayName: displayName,
      dashboardKey: dashboardKey,
      dashboardLabel: dashboardLabel,
      pageKey: pageKey,
      pageLabel: pageLabel,
      action: action,
      timestamp: DateTime.now().toIso8601String(),
    );

    // Keep only last 200 activities
    if (activities.length > 200) {
      final sorted = activities.entries.toList()
        ..sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));
      final toKeep = Map<String, AccessActivity>.fromEntries(
          sorted.take(200));
      await _saveActivities(toKeep);
    } else {
      await _saveActivities(activities);
    }
  }

  /// Gets all activities for a specific dashboard.
  static List<AccessActivity> getActivitiesForDashboard(String dashboardKey) {
    final activities = getAllActivitiesMap();
    return activities.values
        .where((a) => a.dashboardKey == dashboardKey)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Gets all activities for a specific user.
  static List<AccessActivity> getActivitiesForUser(String userId) {
    final activities = getAllActivitiesMap();
    return activities.values
        .where((a) => a.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ── Storage (encrypted) ───────────────────────────────────────────────────

  static Map<String, AccessControlGrant> getAllGrantsMap() {
    final key = TenantContext.tenantKey(HiveBoxes.accessGrants);
    final encString = prefs.getString('enc_$key');
    if (encString == null) return {};
    try {
      final decoded = SecureStorageWrapper.decryptMapSync(encString);
      return decoded.map((k, v) =>
          MapEntry(k, AccessControlGrant.fromMap(v as Map)));
    } catch (_) {
      // Fallback: try old unencrypted format
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map;
          return map.map((k, v) =>
              MapEntry(k.toString(), AccessControlGrant.fromMap(v as Map)));
        } catch (_) {}
      }
      return {};
    }
  }

  static Future<void> _saveGrants(Map<String, AccessControlGrant> grants) async {
    final key = TenantContext.tenantKey(HiveBoxes.accessGrants);
    final map = grants.map((k, v) => MapEntry(k, v.toMap()));
    await SecureStorageWrapper.setSecureMap(key, map);
  }

  static Map<String, AccessActivity> getAllActivitiesMap() {
    final key = TenantContext.tenantKey(HiveBoxes.accessActivities);
    final encString = prefs.getString('enc_$key');
    if (encString == null) return {};
    try {
      final decoded = SecureStorageWrapper.decryptMapSync(encString);
      return decoded.map((k, v) =>
          MapEntry(k, AccessActivity.fromMap(v as Map)));
    } catch (_) {
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map;
          return map.map((k, v) =>
              MapEntry(k.toString(), AccessActivity.fromMap(v as Map)));
        } catch (_) {}
      }
      return {};
    }
  }

  static Future<void> _saveActivities(
      Map<String, AccessActivity> activities) async {
    final key = TenantContext.tenantKey(HiveBoxes.accessActivities);
    final map = activities.map((k, v) => MapEntry(k, v.toMap()));
    await SecureStorageWrapper.setSecureMap(key, map);
  }
}
