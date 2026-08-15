import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_wrapper.dart';
import 'session_manager.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/branch.dart';
import '../models/department.dart';
import '../models/event.dart';
import '../models/sermon.dart';
import '../models/transaction.dart';
import '../models/church.dart';
import '../models/member.dart';
import '../models/organization.dart';
import '../models/region.dart';
import '../models/district.dart';
import '../models/area.dart';
import '../models/welfare_case.dart';
import '../models/welfare_finance.dart';
import '../models/welfare_statement.dart';
import '../models/ministry.dart';
import '../models/ministry_finance.dart';
import '../models/contribution.dart';
import '../models/budget.dart';
import '../models/finance_approval.dart';
import '../models/app_notification.dart';
import '../models/library_book.dart';
import '../models/devotion_guide.dart';
import '../models/bible_study_resource.dart';
import '../models/sync_queue_entry.dart';
import '../core/constants.dart';
import 'tenant_context.dart';
import 'sync_service.dart';

class LocalDb {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Pre-load encrypted user data into cache for sync access
    await _refreshUsersCache();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalDb not initialized. Call LocalDb.init() first.');
    }
    return _prefs!;
  }

  // ── Church (Multi-tenant: supports multiple churches per device) ─────────

  static const _churchesKey = 'all_churches';
  static const _activeChurchKey = 'active_church_id';

  static Future<void> saveChurch(Church church) async {
    final map = _getAllChurchesMap();
    map[church.id] = church.toMap();
    await prefs.setString(_churchesKey, jsonEncode(map));
    await prefs.setString(_activeChurchKey, church.id);
    TenantContext.setActiveChurch(church.id);
    await _refreshUsersCache();
  }

  static Church? getChurch() {
    final activeId = prefs.getString(_activeChurchKey);
    if (activeId == null) return null;
    return getChurchById(activeId);
  }

  static Church? getChurchById(String churchId) {
    final map = _getAllChurchesMap();
    final data = map[churchId];
    if (data == null) return null;
    return Church.fromMap(data as Map);
  }

  static List<Church> getAllChurches() {
    final map = _getAllChurchesMap();
    return map.values.map((v) => Church.fromMap(v as Map)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static Future<void> setActiveChurch(String churchId) async {
    final church = getChurchById(churchId);
    if (church == null) return;
    await prefs.setString(_activeChurchKey, churchId);
    TenantContext.setActiveChurch(churchId);
    // Load encrypted user data for this tenant into cache
    await _refreshUsersCache();
  }

  static Map<String, dynamic> _getAllChurchesMap() {
    final data = prefs.getString(_churchesKey);
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data) as Map);
  }

  /// Cross-church helper: reads a box key from ALL churches and merges results.
  /// Used by higher-level roles (superSystemAdmin, nationalAdmin, etc.) that
  /// need to see data across multiple churches.
  static Map<String, dynamic> _getAllAcrossChurches(String boxKey) {
    final merged = <String, dynamic>{};
    final churches = getAllChurches();
    for (final church in churches) {
      final key = TenantContext.scopedKey(church.id, boxKey);
      final data = prefs.getString(key);
      if (data == null) continue;
      final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
      merged.addAll(map);
    }
    return merged;
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  /// In-memory cache of encrypted user data for sync access.
  /// Populated by _refreshUsersCache() after any write operation.
  static Map<String, dynamic>? _usersCache;

  static Future<void> _refreshUsersCache() async {
    if (!TenantContext.isActive) return;
    final key = TenantContext.tenantKey(HiveBoxes.users);
    final data = await SecureStorageWrapper.getSecureMap(key);
    if (data != null && data.isNotEmpty) {
      _usersCache = data;
      return;
    }
    // Fallback: try reading unencrypted (migration from pre-encryption format)
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        _usersCache = map;
        // Migrate: re-save as encrypted
        await SecureStorageWrapper.setSecureMap(key, map);
        // Remove old unencrypted data
        await prefs.remove(key);
        return;
      } catch (_) {}
    }
    _usersCache = {};
  }

  static Future<void> saveUser(AppUser user) async {
    final users = getAllUsersMap();
    users[user.id] = user.toMap();
    await SecureStorageWrapper.setSecureMap(
        TenantContext.tenantKey(HiveBoxes.users), users);
    _usersCache = users;
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.users,
      recordId: user.id,
      operation: SyncQueueEntry.opUpsert,
      data: user.toSyncMap(),
    );
  }

  static AppUser? getUserById(String id) {
    if (id.isEmpty) return null;
    final users = getAllUsersMap();
    final data = users[id];
    if (data == null) return null;
    return AppUser.fromMap(data as Map);
  }

  /// Cross-church user lookup by ID — searches all churches.
  /// Used for session restore when tenant context isn't set yet.
  static Future<({AppUser user, String churchId})?> getUserByIdAcrossChurches(String id) async {
    if (id.isEmpty) return null;
    final churches = getAllChurches();
    for (final church in churches) {
      final key = TenantContext.scopedKey(church.id, HiveBoxes.users);
      final usersMap = await SecureStorageWrapper.getSecureMap(key);
      if (usersMap == null) {
        // Fallback: try unencrypted (migration from old format)
        final data = prefs.getString(key);
        if (data == null) continue;
        final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
        final userData = map[id];
        if (userData != null) {
          return (user: AppUser.fromMap(userData as Map), churchId: church.id);
        }
        continue;
      }
      final userData = usersMap[id];
      if (userData != null) {
        return (user: AppUser.fromMap(userData as Map), churchId: church.id);
      }
    }
    return null;
  }

  static AppUser? getUserByEmail(String email) {
    final users = getAllUsersMap();
    for (final userData in users.values) {
      if (userData['email'] == email.toLowerCase().trim()) {
        return AppUser.fromMap(userData as Map);
      }
    }
    return null;
  }

  /// Cross-church user lookup: searches ALL churches for a user by email.
  /// Returns the user and their churchId so the caller can switch tenant context.
  /// Used during login before a tenant context is set.
  static Future<({AppUser user, String churchId})?> getUserByEmailAcrossChurches(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    final churches = getAllChurches();
    for (final church in churches) {
      final key = TenantContext.scopedKey(church.id, HiveBoxes.users);
      final usersMap = await SecureStorageWrapper.getSecureMap(key);
      if (usersMap == null) {
        // Fallback: try unencrypted (migration from old format)
        final data = prefs.getString(key);
        if (data == null) continue;
        final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
        for (final userData in map.values) {
          if (userData['email'] == normalizedEmail) {
            return (user: AppUser.fromMap(userData as Map), churchId: church.id);
          }
        }
        continue;
      }
      for (final userData in usersMap.values) {
        if (userData['email'] == normalizedEmail) {
          return (user: AppUser.fromMap(userData as Map), churchId: church.id);
        }
      }
    }
    return null;
  }

  static List<AppUser> getAllUsers() {
    final users = getAllUsersMap();
    return users.values.map((v) => AppUser.fromMap(v as Map)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static Map<String, dynamic> getAllUsersMap() {
    // Return cached data if available (populated after save/init)
    if (_usersCache != null) return Map<String, dynamic>.from(_usersCache!);
    // Fallback: try reading unencrypted (for migration from old format)
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.users));
    if (data != null) {
      final map = Map<String, dynamic>.from(jsonDecode(data));
      _usersCache = map;
      return map;
    }
    return {};
  }

  static List<AppUser> getUsersByRole(String role) {
    return getAllUsers().where((u) => u.role == role).toList();
  }

  static List<AppUser> getUsersByRoles(Set<String> roles) {
    return getAllUsers().where((u) => roles.contains(u.role)).toList();
  }

  static Future<void> deleteUser(String id) async {
    final users = getAllUsersMap();
    users.remove(id);
    await SecureStorageWrapper.setSecureMap(
        TenantContext.tenantKey(HiveBoxes.users), users);
    _usersCache = users;
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.users,
      recordId: id,
      operation: SyncQueueEntry.opDelete,
      data: {},
    );
  }

  static Future<void> clearAllUsers() async {
    await SecureStorageWrapper.removeSecureMap(
        TenantContext.tenantKey(HiveBoxes.users));
    _usersCache = {};
  }

  // ── Session ───────────────────────────────────────────────────────────────

  static Future<void> saveSession(String userId) async {
    await SessionManager.saveSession(userId);
  }

  static String? getSessionUserId() {
    // Sync fallback — reads raw session data without expiry check.
    // Use SessionManager.getValidSessionUserId() for expiry-aware access.
    final prefs = _prefs;
    if (prefs == null) return null;
    final data = prefs.getString('session_data');
    if (data == null) return null;
    try {
      final session = jsonDecode(data) as Map;
      return session['userId'] as String?;
    } catch (_) {
      // Fallback to old session key
      final oldData = prefs.getString(HiveKeys.session);
      if (oldData == null) return null;
      final session = jsonDecode(oldData) as Map;
      return session['userId'] as String?;
    }
  }

  static Future<void> clearSession() async {
    await SessionManager.clearSession();
  }

  // ── Branches ──────────────────────────────────────────────────────────────

  static Future<void> saveBranch(Branch branch) async {
    final branches = getAllBranchesMap();
    branches[branch.id] = branch.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.branches), jsonEncode(branches));
  }

  static Future<void> deleteBranch(String id) async {
    final branches = getAllBranchesMap();
    branches.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.branches), jsonEncode(branches));
  }

  static Future<void> clearAllBranches() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.branches));
  }

  static Branch? getBranchById(String id) {
    final branches = getAllBranchesMap();
    final data = branches[id];
    if (data == null) return null;
    return Branch.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllBranchesMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.branches));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<Branch> getAllBranches({
    String? churchId,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) {
    final branchesMap = getAllBranchesMap();
    var all = branchesMap.values.map((v) => Branch.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((b) => b.churchId == churchId).toList();
    }
    if (organizationId != null) {
      all = all.where((b) => b.organizationId == organizationId).toList();
    }
    if (regionId != null) {
      all = all.where((b) => b.regionId == regionId).toList();
    }
    if (districtId != null) {
      all = all.where((b) => b.districtId == districtId).toList();
    }
    if (areaId != null) {
      all = all.where((b) => b.areaId == areaId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  // ── Departments ───────────────────────────────────────────────────────────

  static Future<void> saveDepartment(Department dept) async {
    final departments = getAllDepartmentsMap();
    departments[dept.id] = dept.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.departments), jsonEncode(departments));
  }

  static Future<void> deleteDepartment(String id) async {
    final departments = getAllDepartmentsMap();
    departments.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.departments), jsonEncode(departments));
  }

  static Future<void> clearAllDepartments() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.departments));
  }

  static Department? getDepartmentById(String id) {
    if (id.isEmpty) return null;
    final departments = getAllDepartmentsMap();
    final data = departments[id];
    if (data == null) return null;
    return Department.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllDepartmentsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.departments));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<Department> getAllDepartments({
    String? churchId,
    String? branchId,
  }) {
    final departmentsMap = getAllDepartmentsMap();
    var all = departmentsMap.values.map((v) => Department.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((d) => d.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((d) => d.branchId == branchId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  // ── Members ───────────────────────────────────────────────────────────────

  static Future<void> saveMember(Member member) async {
    final members = getAllMembersMap();
    members[member.id] = member.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.members), jsonEncode(members));
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.members,
      recordId: member.id,
      operation: SyncQueueEntry.opUpsert,
      data: member.toMap(),
    );
  }

  static Future<void> deleteMember(String id) async {
    final members = getAllMembersMap();
    members.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.members), jsonEncode(members));
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.members,
      recordId: id,
      operation: SyncQueueEntry.opDelete,
      data: {},
    );
  }

  static Future<void> clearAllMembers() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.members));
  }

  static Member? getMemberById(String id) {
    final members = getAllMembersMap();
    final data = members[id];
    if (data == null) return null;
    return Member.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllMembersMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.members));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<Member> getAllMembers({
    String? churchId,
    String? branchId,
    String? departmentId,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) {
    final membersMap = getAllMembersMap();
    var all = membersMap.values.map((v) => Member.fromMap(v as Map)).toList();
    if (churchId != null) all = all.where((m) => m.churchId == churchId).toList();
    if (organizationId != null) {
      all = all.where((m) => m.organizationId == organizationId).toList();
    }
    if (regionId != null) {
      all = all.where((m) => m.regionId == regionId).toList();
    }
    if (districtId != null) {
      all = all.where((m) => m.districtId == districtId).toList();
    }
    if (areaId != null) {
      all = all.where((m) => m.areaId == areaId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((m) => m.branchId == branchId).toList();
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      all = all.where((m) => m.departmentId == departmentId).toList();
    }
    return all;
  }

  // ── Attendance ────────────────────────────────────────────────────────────

  static Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    final records = getAllAttendanceRecordsMap();
    records[record.id] = record.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.attendance), jsonEncode(records));
  }

  static Future<void> deleteAttendanceRecord(String id) async {
    final records = getAllAttendanceRecordsMap();
    records.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.attendance), jsonEncode(records));
  }

  static Future<void> clearAllAttendanceRecords() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.attendance));
  }

  static AttendanceRecord? getAttendanceRecordById(String id) {
    final records = getAllAttendanceRecordsMap();
    final data = records[id];
    if (data == null) return null;
    return AttendanceRecord.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllAttendanceRecordsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.attendance));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<AttendanceRecord> getAllAttendanceRecords({
    String? churchId,
    String? branchId,
    String? ministryType,
  }) {
    final recordsMap = getAllAttendanceRecordsMap();
    var all = recordsMap.values.map((v) => AttendanceRecord.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((r) => r.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((r) => r.branchId == branchId).toList();
    }
    if (ministryType != null && ministryType.isNotEmpty) {
      all = all.where((r) => r.ministryType == ministryType).toList();
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // ── Library: Digital Books ───────────────────────────────────────────────

  static Future<void> saveLibraryBook(LibraryBook book) async {
    final books = getAllLibraryBooksMap();
    books[book.id] = book.toMap();
    await prefs.setString(
        TenantContext.tenantKey(HiveBoxes.libraryBooks), jsonEncode(books));
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.libraryBooks,
      recordId: book.id,
      operation: SyncQueueEntry.opUpsert,
      data: book.toMap(),
    );
  }

  static Future<void> deleteLibraryBook(String id) async {
    final books = getAllLibraryBooksMap();
    books.remove(id);
    await prefs.setString(
        TenantContext.tenantKey(HiveBoxes.libraryBooks), jsonEncode(books));
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.libraryBooks,
      recordId: id,
      operation: SyncQueueEntry.opDelete,
      data: {},
    );
  }

  static Future<void> clearAllLibraryBooks() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.libraryBooks));
  }

  static LibraryBook? getLibraryBookById(String id) {
    final books = getAllLibraryBooksMap();
    final data = books[id];
    if (data == null) return null;
    return LibraryBook.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllLibraryBooksMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.libraryBooks));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<LibraryBook> getAllLibraryBooks({String? churchId}) {
    final booksMap = getAllLibraryBooksMap();
    var all = booksMap.values.map((v) => LibraryBook.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((b) => b.churchId == churchId).toList();
    }
    all.sort((a, b) => a.title.compareTo(b.title));
    return all;
  }

  // ── Library: Daily Devotion & Prayer Guide ───────────────────────────────

  static Future<void> saveDevotionGuide(DevotionGuide devotion) async {
    final devotions = getAllDevotionGuidesMap();
    devotions[devotion.id] = devotion.toMap();
    await prefs.setString(
        TenantContext.tenantKey(HiveBoxes.devotionGuides), jsonEncode(devotions));
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.devotionGuides,
      recordId: devotion.id,
      operation: SyncQueueEntry.opUpsert,
      data: devotion.toMap(),
    );
  }

  static Future<void> deleteDevotionGuide(String id) async {
    final devotions = getAllDevotionGuidesMap();
    devotions.remove(id);
    await prefs.setString(
        TenantContext.tenantKey(HiveBoxes.devotionGuides), jsonEncode(devotions));
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.devotionGuides,
      recordId: id,
      operation: SyncQueueEntry.opDelete,
      data: {},
    );
  }

  static Future<void> clearAllDevotionGuides() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.devotionGuides));
  }

  static DevotionGuide? getDevotionGuideById(String id) {
    final devotions = getAllDevotionGuidesMap();
    final data = devotions[id];
    if (data == null) return null;
    return DevotionGuide.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllDevotionGuidesMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.devotionGuides));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<DevotionGuide> getAllDevotionGuides({String? churchId}) {
    final map = getAllDevotionGuidesMap();
    var all = map.values.map((v) => DevotionGuide.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((d) => d.churchId == churchId).toList();
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // ── Library: Bible Study Resources ───────────────────────────────────────

  static Future<void> saveBibleStudyResource(BibleStudyResource study) async {
    final studies = getAllBibleStudyResourcesMap();
    studies[study.id] = study.toMap();
    await prefs.setString(
        TenantContext.tenantKey(HiveBoxes.bibleStudyResources), jsonEncode(studies));
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.bibleStudyResources,
      recordId: study.id,
      operation: SyncQueueEntry.opUpsert,
      data: study.toMap(),
    );
  }

  static Future<void> deleteBibleStudyResource(String id) async {
    final studies = getAllBibleStudyResourcesMap();
    studies.remove(id);
    await prefs.setString(
        TenantContext.tenantKey(HiveBoxes.bibleStudyResources), jsonEncode(studies));
    await SyncService.enqueueChange(
      boxKey: HiveBoxes.bibleStudyResources,
      recordId: id,
      operation: SyncQueueEntry.opDelete,
      data: {},
    );
  }

  static Future<void> clearAllBibleStudyResources() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.bibleStudyResources));
  }

  static BibleStudyResource? getBibleStudyResourceById(String id) {
    final studies = getAllBibleStudyResourcesMap();
    final data = studies[id];
    if (data == null) return null;
    return BibleStudyResource.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllBibleStudyResourcesMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.bibleStudyResources));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<BibleStudyResource> getAllBibleStudyResources({String? churchId}) {
    final map = getAllBibleStudyResourcesMap();
    var all = map.values.map((v) => BibleStudyResource.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((s) => s.churchId == churchId).toList();
    }
    all.sort((a, b) => a.title.compareTo(b.title));
    return all;
  }

  // ── Finance ───────────────────────────────────────────────────────────────

  static Future<void> saveTransaction(FinanceTransaction tx) async {
    final transactions = getAllTransactionsMap();
    transactions[tx.id] = tx.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.finance), jsonEncode(transactions));
  }

  static Future<void> deleteTransaction(String id) async {
    final transactions = getAllTransactionsMap();
    transactions.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.finance), jsonEncode(transactions));
  }

  static Future<void> clearAllTransactions() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.finance));
  }

  static FinanceTransaction? getTransactionById(String id) {
    final transactions = getAllTransactionsMap();
    final data = transactions[id];
    if (data == null) return null;
    return FinanceTransaction.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllTransactionsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.finance));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<FinanceTransaction> getAllTransactions({
    String? churchId,
    String? branchId,
    String? type,
    int? month,
    int? year,
  }) {
    final transactionsMap = getAllTransactionsMap();
    var all = transactionsMap.values.map((v) => FinanceTransaction.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((t) => t.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((t) => t.branchId == branchId).toList();
    }
    if (type != null) {
      all = all.where((t) => t.type == type).toList();
    }
    if (month != null && year != null) {
      all = all.where((t) => t.date.month == month && t.date.year == year).toList();
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // ── Sermons ───────────────────────────────────────────────────────────────

  static Future<void> saveSermon(Sermon sermon) async {
    final sermons = getAllSermonsMap();
    sermons[sermon.id] = sermon.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.sermons), jsonEncode(sermons));
  }

  static Future<void> deleteSermon(String id) async {
    final sermons = getAllSermonsMap();
    sermons.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.sermons), jsonEncode(sermons));
  }

  static Future<void> clearAllSermons() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.sermons));
  }

  static Sermon? getSermonById(String id) {
    final sermons = getAllSermonsMap();
    final data = sermons[id];
    if (data == null) return null;
    return Sermon.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllSermonsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.sermons));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<Sermon> getAllSermons({String? churchId, String? branchId}) {
    final sermonsMap = getAllSermonsMap();
    var all = sermonsMap.values.map((v) => Sermon.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((s) => s.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((s) => s.branchId == branchId).toList();
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // ── Events ────────────────────────────────────────────────────────────────

  static Future<void> saveEvent(ChurchEvent event) async {
    final events = getAllEventsMap();
    events[event.id] = event.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.events), jsonEncode(events));
  }

  static Future<void> deleteEvent(String id) async {
    final events = getAllEventsMap();
    events.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.events), jsonEncode(events));
  }

  static Future<void> clearAllEvents() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.events));
  }

  static ChurchEvent? getEventById(String id) {
    final events = getAllEventsMap();
    final data = events[id];
    if (data == null) return null;
    return ChurchEvent.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllEventsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.events));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<ChurchEvent> getAllEvents({
    String? churchId,
    String? branchId,
    String? departmentId,
    String? ministryType,
  }) {
    final eventsMap = getAllEventsMap();
    var all = eventsMap.values.map((v) => ChurchEvent.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((e) => e.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((e) => e.branchId == branchId).toList();
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      all = all.where((e) =>
          e.departmentId == departmentId || e.departmentId.isEmpty)
          .toList();
    }
    if (ministryType != null && ministryType.isNotEmpty) {
      all = all.where((e) => e.ministryType == ministryType).toList();
    }
    all.sort((a, b) => a.startDate.compareTo(b.startDate));
    return all;
  }

  // ── Organizations ──────────────────────────────────────────────────────────

  static Future<void> saveOrganization(Organization org) async {
    final organizations = getAllOrganizationsMap();
    organizations[org.id] = org.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.organization), jsonEncode(organizations));
  }

  static Future<void> deleteOrganization(String id) async {
    final organizations = getAllOrganizationsMap();
    organizations.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.organization), jsonEncode(organizations));
  }

  static Future<void> clearAllOrganizations() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.organization));
  }

  static Organization? getOrganizationById(String id) {
    final organizations = getAllOrganizationsMap();
    final data = organizations[id];
    if (data == null) return null;
    return Organization.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllOrganizationsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.organization));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<Organization> getAllOrganizations() {
    final organizationsMap = getAllOrganizationsMap();
    return organizationsMap.values.map((v) => Organization.fromMap(v as Map)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ── Regions ─────────────────────────────────────────────────────────────────

  static Future<void> saveRegion(Region region) async {
    final regions = getAllRegionsMap();
    regions[region.id] = region.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.region), jsonEncode(regions));
  }

  static Future<void> deleteRegion(String id) async {
    final regions = getAllRegionsMap();
    regions.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.region), jsonEncode(regions));
  }

  static Future<void> clearAllRegions() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.region));
  }

  static Region? getRegionById(String id) {
    final regions = getAllRegionsMap();
    final data = regions[id];
    if (data == null) return null;
    return Region.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllRegionsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.region));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<Region> getAllRegions({String? organizationId}) {
    final regionsMap = getAllRegionsMap();
    var all = regionsMap.values.map((v) => Region.fromMap(v as Map)).toList();
    if (organizationId != null) {
      all = all.where((r) => r.organizationId == organizationId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  // ── Districts ───────────────────────────────────────────────────────────────

  static Future<void> saveDistrict(District district) async {
    final districts = getAllDistrictsMap();
    districts[district.id] = district.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.district), jsonEncode(districts));
  }

  static Future<void> deleteDistrict(String id) async {
    final districts = getAllDistrictsMap();
    districts.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.district), jsonEncode(districts));
  }

  static Future<void> clearAllDistricts() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.district));
  }

  static District? getDistrictById(String id) {
    final districts = getAllDistrictsMap();
    final data = districts[id];
    if (data == null) return null;
    return District.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllDistrictsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.district));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<District> getAllDistricts({String? regionId}) {
    final districtsMap = getAllDistrictsMap();
    var all = districtsMap.values.map((v) => District.fromMap(v as Map)).toList();
    if (regionId != null) {
      all = all.where((d) => d.regionId == regionId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  // ── Areas ────────────────────────────────────────────────────────────────────

  static Future<void> saveArea(Area area) async {
    final areas = getAllAreasMap();
    areas[area.id] = area.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.area), jsonEncode(areas));
  }

  static Future<void> deleteArea(String id) async {
    final areas = getAllAreasMap();
    areas.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.area), jsonEncode(areas));
  }

  static Future<void> clearAllAreas() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.area));
  }

  static Area? getAreaById(String id) {
    final areas = getAllAreasMap();
    final data = areas[id];
    if (data == null) return null;
    return Area.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllAreasMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.area));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<Area> getAllAreas({String? districtId}) {
    final areasMap = getAllAreasMap();
    var all = areasMap.values.map((v) => Area.fromMap(v as Map)).toList();
    if (districtId != null) {
      all = all.where((a) => a.districtId == districtId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  // ── Welfare Cases ──────────────────────────────────────────────────────────

  static Future<void> saveWelfareCase(WelfareCase welfareCase) async {
    final cases = getAllWelfareCasesMap();
    cases[welfareCase.id] = welfareCase.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.welfare), jsonEncode(cases));
  }

  static Future<void> deleteWelfareCase(String id) async {
    final cases = getAllWelfareCasesMap();
    cases.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.welfare), jsonEncode(cases));
  }

  static Future<void> clearAllWelfareCases() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.welfare));
  }

  static WelfareCase? getWelfareCaseById(String id) {
    final cases = getAllWelfareCasesMap();
    final data = cases[id];
    if (data == null) return null;
    return WelfareCase.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllWelfareCasesMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.welfare));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<WelfareCase> getAllWelfareCases({
    String? churchId,
    String? branchId,
    String? memberId,
    String? status,
    String? type,
    String? welfareHeadId,
  }) {
    final casesMap = getAllWelfareCasesMap();
    var all = casesMap.values.map((v) => WelfareCase.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((w) => w.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((w) => w.branchId == branchId).toList();
    }
    if (memberId != null && memberId.isNotEmpty) {
      all = all.where((w) => w.memberId == memberId).toList();
    }
    if (status != null && status.isNotEmpty) {
      all = all.where((w) => w.status == status).toList();
    }
    if (type != null && type.isNotEmpty) {
      all = all.where((w) => w.type == type).toList();
    }
    if (welfareHeadId != null && welfareHeadId.isNotEmpty) {
      all = all.where((w) => w.welfareHeadId == welfareHeadId).toList();
    }
    all.sort((a, b) => b.dateRequested.compareTo(a.dateRequested));
    return all;
  }

  // ── Welfare Transactions ───────────────────────────────────────────────────

  static Future<void> saveWelfareTransaction(WelfareTransaction txn) async {
    final txns = getAllWelfareTransactionsMap();
    txns[txn.id] = txn.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.welfareFinance), jsonEncode(txns));
  }

  static Future<void> deleteWelfareTransaction(String id) async {
    final txns = getAllWelfareTransactionsMap();
    txns.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.welfareFinance), jsonEncode(txns));
  }

  static Future<void> clearAllWelfareTransactions() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.welfareFinance));
  }

  static WelfareTransaction? getWelfareTransactionById(String id) {
    final txns = getAllWelfareTransactionsMap();
    final data = txns[id];
    if (data == null) return null;
    return WelfareTransaction.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllWelfareTransactionsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.welfareFinance));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<WelfareTransaction> getAllWelfareTransactions({
    String? churchId,
    String? branchId,
    String? memberId,
    String? type,
    String? departmentId,
    String? welfareCaseId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final txnsMap = getAllWelfareTransactionsMap();
    var all = txnsMap.values
        .map((v) => WelfareTransaction.fromMap(v as Map))
        .toList();
    if (churchId != null) {
      all = all.where((t) => t.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((t) => t.branchId == branchId).toList();
    }
    if (memberId != null && memberId.isNotEmpty) {
      all = all.where((t) => t.memberId == memberId).toList();
    }
    if (type != null && type.isNotEmpty) {
      all = all.where((t) => t.type == type).toList();
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      all = all.where((t) => t.departmentId == departmentId).toList();
    }
    if (welfareCaseId != null && welfareCaseId.isNotEmpty) {
      all = all.where((t) => t.welfareCaseId == welfareCaseId).toList();
    }
    if (startDate != null) {
      all = all.where((t) => t.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
    }
    if (endDate != null) {
      all = all.where((t) => t.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // ── Department Welfare ──────────────────────────────────────────────────────

  static Future<void> saveDepartmentWelfare(DepartmentWelfare dw) async {
    final dws = getAllDepartmentWelfareMap();
    dws[dw.id] = dw.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.departmentWelfare), jsonEncode(dws));
  }

  static Future<void> deleteDepartmentWelfare(String id) async {
    final dws = getAllDepartmentWelfareMap();
    dws.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.departmentWelfare), jsonEncode(dws));
  }

  static Future<void> clearAllDepartmentWelfare() async {
    await prefs.remove(TenantContext.tenantKey(HiveBoxes.departmentWelfare));
  }

  static DepartmentWelfare? getDepartmentWelfareById(String id) {
    final dws = getAllDepartmentWelfareMap();
    final data = dws[id];
    if (data == null) return null;
    return DepartmentWelfare.fromMap(data as Map);
  }

  static DepartmentWelfare? getDepartmentWelfareByDepartment(
      String departmentId) {
    final dws = getAllDepartmentWelfareMap();
    for (final v in dws.values) {
      final dw = DepartmentWelfare.fromMap(v as Map);
      if (dw.departmentId == departmentId) return dw;
    }
    return null;
  }

  static Map<String, dynamic> getAllDepartmentWelfareMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.departmentWelfare));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<DepartmentWelfare> getAllDepartmentWelfare({
    String? churchId,
    String? branchId,
    bool? isActive,
  }) {
    final dwsMap = getAllDepartmentWelfareMap();
    var all = dwsMap.values
        .map((v) => DepartmentWelfare.fromMap(v as Map))
        .toList();
    if (churchId != null) {
      all = all.where((d) => d.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((d) => d.branchId == branchId).toList();
    }
    if (isActive != null) {
      all = all.where((d) => d.isActive == isActive).toList();
    }
    all.sort((a, b) => a.departmentName.compareTo(b.departmentName));
    return all;
  }

  // ── Welfare Statements ─────────────────────────────────────────────────────

  static Future<void> saveWelfareStatement(WelfareStatement stmt) async {
    final stmts = getAllWelfareStatementsMap();
    stmts[stmt.id] = stmt.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.welfareStatements), jsonEncode(stmts));
  }

  static Future<void> deleteWelfareStatement(String id) async {
    final stmts = getAllWelfareStatementsMap();
    stmts.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.welfareStatements), jsonEncode(stmts));
  }

  static WelfareStatement? getWelfareStatementById(String id) {
    final stmts = getAllWelfareStatementsMap();
    final data = stmts[id];
    if (data == null) return null;
    return WelfareStatement.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllWelfareStatementsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.welfareStatements));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<WelfareStatement> getAllWelfareStatements({
    String? churchId,
    String? branchId,
    String? memberId,
    String? status,
  }) {
    final stmtsMap = getAllWelfareStatementsMap();
    var all = stmtsMap.values
        .map((v) => WelfareStatement.fromMap(v as Map))
        .toList();
    if (churchId != null) {
      all = all.where((s) => s.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((s) => s.branchId == branchId).toList();
    }
    if (memberId != null && memberId.isNotEmpty) {
      all = all.where((s) => s.memberId == memberId).toList();
    }
    if (status != null && status.isNotEmpty) {
      all = all.where((s) => s.status == status).toList();
    }
    all.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return all;
  }

  // ── Shared Reports ─────────────────────────────────────────────────────────

  static Future<void> saveSharedReport(SharedReport report) async {
    final reports = getAllSharedReportsMap();
    reports[report.id] = report.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.sharedReports), jsonEncode(reports));
  }

  static Future<void> deleteSharedReport(String id) async {
    final reports = getAllSharedReportsMap();
    reports.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.sharedReports), jsonEncode(reports));
  }

  static Map<String, dynamic> getAllSharedReportsMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.sharedReports));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<SharedReport> getAllSharedReports({
    String? churchId,
    String? branchId,
    String? sharedToMemberId,
    String? sharedById,
  }) {
    final reportsMap = getAllSharedReportsMap();
    var all = reportsMap.values
        .map((v) => SharedReport.fromMap(v as Map))
        .toList();
    if (churchId != null) {
      all = all.where((r) => r.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((r) => r.branchId == branchId).toList();
    }
    if (sharedToMemberId != null && sharedToMemberId.isNotEmpty) {
      all = all.where((r) => r.sharedToMemberId == sharedToMemberId).toList();
    }
    if (sharedById != null && sharedById.isNotEmpty) {
      all = all.where((r) => r.sharedById == sharedById).toList();
    }
    all.sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
    return all;
  }

  static Future<void> markSharedReportRead(String id) async {
    final reports = getAllSharedReportsMap();
    final data = reports[id];
    if (data != null) {
      final report = SharedReport.fromMap(data as Map);
      reports[id] = report.copyWith(isRead: true).toMap();
      await prefs.setString(TenantContext.tenantKey(HiveBoxes.sharedReports), jsonEncode(reports));
    }
  }

  // ── Ministries ──────────────────────────────────────────────────────────────

  static Future<void> saveMinistry(Ministry ministry) async {
    final ministries = getAllMinistriesMap();
    ministries[ministry.id] = ministry.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.ministries), jsonEncode(ministries));
  }

  static Future<void> deleteMinistry(String id) async {
    final ministries = getAllMinistriesMap();
    ministries.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.ministries), jsonEncode(ministries));
  }

  static Ministry? getMinistryById(String id) {
    final ministries = getAllMinistriesMap();
    final data = ministries[id];
    if (data == null) return null;
    return Ministry.fromMap(data as Map);
  }

  static Map<String, dynamic> getAllMinistriesMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.ministries));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<Ministry> getAllMinistries({
    String? churchId,
    String? branchId,
    String? ministryType,
    String? headId,
    bool? isActive,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) {
    final ministriesMap = getAllMinistriesMap();
    var all = ministriesMap.values
        .map((v) => Ministry.fromMap(v as Map))
        .toList();
    if (churchId != null) {
      all = all.where((m) => m.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((m) => m.branchId == branchId).toList();
    }
    if (ministryType != null && ministryType.isNotEmpty) {
      all = all.where((m) => m.ministryType == ministryType).toList();
    }
    if (headId != null && headId.isNotEmpty) {
      all = all.where((m) => m.headId == headId).toList();
    }
    if (isActive != null) {
      all = all.where((m) => m.isActive == isActive).toList();
    }
    if (organizationId != null && organizationId.isNotEmpty) {
      all = all.where((m) => m.organizationId == organizationId).toList();
    }
    if (regionId != null && regionId.isNotEmpty) {
      all = all.where((m) => m.regionId == regionId).toList();
    }
    if (districtId != null && districtId.isNotEmpty) {
      all = all.where((m) => m.districtId == districtId).toList();
    }
    if (areaId != null && areaId.isNotEmpty) {
      all = all.where((m) => m.areaId == areaId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  // ── Ministry Finance ────────────────────────────────────────────────────────

  static Future<void> saveMinistryFinance(MinistryFinance tx) async {
    final map = _getMinistryFinanceMap();
    map[tx.id] = tx.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.ministryFinance), jsonEncode(map));
  }

  static Future<void> deleteMinistryFinance(String id) async {
    final map = _getMinistryFinanceMap();
    map.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.ministryFinance), jsonEncode(map));
  }

  static Map<String, dynamic> _getMinistryFinanceMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.ministryFinance));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<MinistryFinance> getAllMinistryFinance({
    String? churchId,
    String? branchId,
    String? ministryType,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) {
    final map = _getMinistryFinanceMap();
    var all = map.values.map((v) => MinistryFinance.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((t) => t.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((t) => t.branchId == branchId).toList();
    }
    if (ministryType != null && ministryType.isNotEmpty) {
      all = all.where((t) => t.ministryType == ministryType).toList();
    }
    if (organizationId != null && organizationId.isNotEmpty) {
      all = all.where((t) => t.organizationId == organizationId).toList();
    }
    if (regionId != null && regionId.isNotEmpty) {
      all = all.where((t) => t.regionId == regionId).toList();
    }
    if (districtId != null && districtId.isNotEmpty) {
      all = all.where((t) => t.districtId == districtId).toList();
    }
    if (areaId != null && areaId.isNotEmpty) {
      all = all.where((t) => t.areaId == areaId).toList();
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // ── Ministry Announcements ──────────────────────────────────────────────────

  static Future<void> saveMinistryAnnouncement(MinistryAnnouncement ann) async {
    final map = _getMinistryAnnouncementMap();
    map[ann.id] = ann.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.ministryAnnouncements), jsonEncode(map));
  }

  static Future<void> deleteMinistryAnnouncement(String id) async {
    final map = _getMinistryAnnouncementMap();
    map.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.ministryAnnouncements), jsonEncode(map));
  }

  static Map<String, dynamic> _getMinistryAnnouncementMap() {
    final data = prefs.getString(TenantContext.tenantKey(HiveBoxes.ministryAnnouncements));
    if (data == null) return {};
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static List<MinistryAnnouncement> getAllMinistryAnnouncements({
    String? churchId,
    String? branchId,
    String? ministryType,
    String? memberId,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) {
    final map = _getMinistryAnnouncementMap();
    var all =
        map.values.map((v) => MinistryAnnouncement.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((a) => a.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((a) => a.branchId == branchId).toList();
    }
    if (ministryType != null && ministryType.isNotEmpty) {
      all = all.where((a) => a.ministryType == ministryType).toList();
    }
    if (organizationId != null && organizationId.isNotEmpty) {
      all = all.where((a) => a.organizationId == organizationId).toList();
    }
    if (regionId != null && regionId.isNotEmpty) {
      all = all.where((a) => a.regionId == regionId).toList();
    }
    if (districtId != null && districtId.isNotEmpty) {
      all = all.where((a) => a.districtId == districtId).toList();
    }
    if (areaId != null && areaId.isNotEmpty) {
      all = all.where((a) => a.areaId == areaId).toList();
    }
    if (memberId != null && memberId.isNotEmpty) {
      all = all.where((a) {
        if (a.isBroadcast) return true;
        return a.targetMemberIds.contains(memberId);
      }).toList();
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  // ── Member Contributions ────────────────────────────────────────────────

  static Future<void> saveContribution(MemberContribution c) async {
    final map = getAllContributionsMap();
    map[c.id] = c.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.contributions), jsonEncode(map));
  }

  static Future<void> deleteContribution(String id) async {
    final map = getAllContributionsMap();
    map.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.contributions), jsonEncode(map));
  }

  static Map<String, dynamic> getAllContributionsMap() {
    final raw = prefs.getString(TenantContext.tenantKey(HiveBoxes.contributions));
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static List<MemberContribution> getAllContributions({
    String? churchId,
    String? branchId,
    String? memberId,
    String? type,
  }) {
    final map = getAllContributionsMap();
    var all = map.values
        .map((v) => MemberContribution.fromMap(v as Map))
        .toList();
    if (churchId != null) {
      all = all.where((c) => c.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((c) => c.branchId == branchId).toList();
    }
    if (memberId != null && memberId.isNotEmpty) {
      all = all.where((c) => c.memberId == memberId).toList();
    }
    if (type != null) {
      all = all.where((c) => c.type == type).toList();
    }
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  // ── Benefit Requests ────────────────────────────────────────────────────

  static Future<void> saveBenefitRequest(BenefitRequest r) async {
    final map = getAllBenefitRequestsMap();
    map[r.id] = r.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.benefitRequests), jsonEncode(map));
  }

  static Future<void> deleteBenefitRequest(String id) async {
    final map = getAllBenefitRequestsMap();
    map.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.benefitRequests), jsonEncode(map));
  }

  static Map<String, dynamic> getAllBenefitRequestsMap() {
    final raw = prefs.getString(TenantContext.tenantKey(HiveBoxes.benefitRequests));
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static List<BenefitRequest> getAllBenefitRequests({
    String? churchId,
    String? branchId,
    String? memberId,
    String? status,
  }) {
    final map = getAllBenefitRequestsMap();
    var all = map.values
        .map((v) => BenefitRequest.fromMap(v as Map))
        .toList();
    if (churchId != null) {
      all = all.where((r) => r.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((r) => r.branchId == branchId).toList();
    }
    if (memberId != null && memberId.isNotEmpty) {
      all = all.where((r) => r.memberId == memberId).toList();
    }
    if (status != null) {
      all = all.where((r) => r.status == status).toList();
    }
    all.sort((a, b) => b.requestDate.compareTo(a.requestDate));
    return all;
  }

  // ── Budgets ─────────────────────────────────────────────────────────────

  static Future<void> saveBudget(Budget b) async {
    final map = getAllBudgetsMap();
    map[b.id] = b.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.budgets), jsonEncode(map));
  }

  static Future<void> deleteBudget(String id) async {
    final map = getAllBudgetsMap();
    map.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.budgets), jsonEncode(map));
  }

  static Map<String, dynamic> getAllBudgetsMap() {
    final raw = prefs.getString(TenantContext.tenantKey(HiveBoxes.budgets));
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static List<Budget> getAllBudgets({
    String? churchId,
    String? branchId,
    String? period,
  }) {
    final map = getAllBudgetsMap();
    var all = map.values.map((v) => Budget.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((b) => b.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((b) => b.branchId == branchId).toList();
    }
    if (period != null && period.isNotEmpty) {
      all = all.where((b) => b.period == period).toList();
    }
    all.sort((a, b) => a.category.compareTo(b.category));
    return all;
  }

  // ── Finance Approvals ───────────────────────────────────────────────────

  static Future<void> saveFinanceApproval(FinanceApprovalRequest r) async {
    final map = getAllFinanceApprovalsMap();
    map[r.id] = r.toMap();
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.financeApprovals), jsonEncode(map));
  }

  static Future<void> deleteFinanceApproval(String id) async {
    final map = getAllFinanceApprovalsMap();
    map.remove(id);
    await prefs.setString(TenantContext.tenantKey(HiveBoxes.financeApprovals), jsonEncode(map));
  }

  static Map<String, dynamic> getAllFinanceApprovalsMap() {
    final raw = prefs.getString(TenantContext.tenantKey(HiveBoxes.financeApprovals));
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static List<FinanceApprovalRequest> getAllFinanceApprovals({
    String? churchId,
    String? branchId,
    String? status,
    String? requestedById,
  }) {
    final map = getAllFinanceApprovalsMap();
    var all =
        map.values.map((v) => FinanceApprovalRequest.fromMap(v as Map)).toList();
    if (churchId != null) {
      all = all.where((r) => r.churchId == churchId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((r) => r.branchId == branchId).toList();
    }
    if (status != null) {
      all = all.where((r) => r.status == status).toList();
    }
    if (requestedById != null && requestedById.isNotEmpty) {
      all = all.where((r) => r.requestedById == requestedById).toList();
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  static List<FinanceApprovalRequest> getAllFinanceApprovalsAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.financeApprovals);
    return map.values
        .map((v) => FinanceApprovalRequest.fromMap(v as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CROSS-CHURCH QUERIES — for higher-level roles (superSystemAdmin,
  // nationalAdmin, regionalAdmin, etc.) that need to see data across
  // multiple churches. These read from ALL churches' storage keys.
  // ═══════════════════════════════════════════════════════════════════════════

  static List<AppUser> getAllUsersAcrossChurches() {
    // Users are stored encrypted — use cache or fallback to unencrypted
    final merged = <String, dynamic>{};
    final churches = getAllChurches();
    for (final church in churches) {
      // Try cache first (current church)
      if (church.id == TenantContext.activeChurchId && _usersCache != null) {
        merged.addAll(_usersCache!);
        continue;
      }
      // Fallback: try unencrypted (for other churches during migration)
      final key = TenantContext.scopedKey(church.id, HiveBoxes.users);
      final data = prefs.getString(key);
      if (data != null) {
        final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
        merged.addAll(map);
      }
    }
    return merged.values.map((v) => AppUser.fromMap(v as Map)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<Branch> getAllBranchesAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.branches);
    return map.values.map((v) => Branch.fromMap(v as Map)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<Department> getAllDepartmentsAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.departments);
    return map.values.map((v) => Department.fromMap(v as Map)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<Member> getAllMembersAcrossChurches({
    String? branchId,
    String? departmentId,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) {
    final map = _getAllAcrossChurches(HiveBoxes.members);
    var all = map.values.map((v) => Member.fromMap(v as Map)).toList();
    if (organizationId != null) {
      all = all.where((m) => m.organizationId == organizationId).toList();
    }
    if (regionId != null) {
      all = all.where((m) => m.regionId == regionId).toList();
    }
    if (districtId != null) {
      all = all.where((m) => m.districtId == districtId).toList();
    }
    if (areaId != null) {
      all = all.where((m) => m.areaId == areaId).toList();
    }
    if (branchId != null && branchId.isNotEmpty) {
      all = all.where((m) => m.branchId == branchId).toList();
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      all = all.where((m) => m.departmentId == departmentId).toList();
    }
    return all;
  }

  static List<AttendanceRecord> getAllAttendanceAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.attendance);
    return map.values.map((v) => AttendanceRecord.fromMap(v as Map)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<FinanceTransaction> getAllTransactionsAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.finance);
    return map.values.map((v) => FinanceTransaction.fromMap(v as Map)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Sermon> getAllSermonsAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.sermons);
    return map.values.map((v) => Sermon.fromMap(v as Map)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<LibraryBook> getAllLibraryBooksAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.libraryBooks);
    return map.values.map((v) => LibraryBook.fromMap(v as Map)).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  static List<DevotionGuide> getAllDevotionGuidesAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.devotionGuides);
    return map.values.map((v) => DevotionGuide.fromMap(v as Map)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<BibleStudyResource> getAllBibleStudyResourcesAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.bibleStudyResources);
    return map.values.map((v) => BibleStudyResource.fromMap(v as Map)).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  static List<ChurchEvent> getAllEventsAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.events);
    return map.values.map((v) => ChurchEvent.fromMap(v as Map)).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  static List<Organization> getAllOrganizationsAcrossChurches() {
    final map = _getAllAcrossChurches(HiveBoxes.organization);
    return map.values.map((v) => Organization.fromMap(v as Map)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<Region> getAllRegionsAcrossChurches({String? organizationId}) {
    final map = _getAllAcrossChurches(HiveBoxes.region);
    var all = map.values.map((v) => Region.fromMap(v as Map)).toList();
    if (organizationId != null) {
      all = all.where((r) => r.organizationId == organizationId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  static List<District> getAllDistrictsAcrossChurches({String? regionId}) {
    final map = _getAllAcrossChurches(HiveBoxes.district);
    var all = map.values.map((v) => District.fromMap(v as Map)).toList();
    if (regionId != null) {
      all = all.where((d) => d.regionId == regionId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  static List<Area> getAllAreasAcrossChurches({String? districtId}) {
    final map = _getAllAcrossChurches(HiveBoxes.area);
    var all = map.values.map((v) => Area.fromMap(v as Map)).toList();
    if (districtId != null) {
      all = all.where((a) => a.districtId == districtId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  // ── Notifications ────────────────────────────────────────────────────────

  static const _notificationsKey = 'notifications';

  static Future<void> saveNotification(AppNotification notification) async {
    final key = TenantContext.scopedKey(notification.churchId, _notificationsKey);
    final data = prefs.getString(key);
    final map = data != null ? Map<String, dynamic>.from(jsonDecode(data) as Map) : <String, dynamic>{};
    map[notification.id] = notification.toMap();
    await prefs.setString(key, jsonEncode(map));
  }

  static List<AppNotification> getNotifications({required String churchId, required String userId}) {
    final key = TenantContext.scopedKey(churchId, _notificationsKey);
    final data = prefs.getString(key);
    if (data == null) return [];
    final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
    return map.values
        .map((v) => AppNotification.fromMap(v as Map))
        .where((n) => n.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> markNotificationRead(String notificationId, {required String churchId, required String userId}) async {
    final key = TenantContext.scopedKey(churchId, _notificationsKey);
    final data = prefs.getString(key);
    if (data == null) return;
    final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
    if (map[notificationId] == null) return;
    final notif = AppNotification.fromMap(map[notificationId] as Map);
    map[notificationId] = notif.copyWith(isRead: true).toMap();
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<void> markAllNotificationsRead({required String churchId, required String userId}) async {
    final key = TenantContext.scopedKey(churchId, _notificationsKey);
    final data = prefs.getString(key);
    if (data == null) return;
    final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
    for (final entry in map.entries) {
      final notif = AppNotification.fromMap(entry.value as Map);
      if (notif.userId == userId && !notif.isRead) {
        map[entry.key] = notif.copyWith(isRead: true).toMap();
      }
    }
    await prefs.setString(key, jsonEncode(map));
  }

  static Future<void> deleteNotification(String notificationId, {required String churchId}) async {
    final key = TenantContext.scopedKey(churchId, _notificationsKey);
    final data = prefs.getString(key);
    if (data == null) return;
    final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
    map.remove(notificationId);
    await prefs.setString(key, jsonEncode(map));
  }

  // ── Sync Queue ───────────────────────────────────────────────────────────

  static const _syncQueueKey = 'sync_queue';
  static const _lastSyncKey = 'last_sync_at';

  static Future<void> addToSyncQueue(SyncQueueEntry entry) async {
    final data = prefs.getString(_syncQueueKey);
    final map = data != null ? Map<String, dynamic>.from(jsonDecode(data) as Map) : <String, dynamic>{};
    map[entry.id] = entry.toMap();
    await prefs.setString(_syncQueueKey, jsonEncode(map));
  }

  static List<SyncQueueEntry> getSyncQueue() {
    final data = prefs.getString(_syncQueueKey);
    if (data == null) return [];
    final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
    return map.values
        .map((v) => SyncQueueEntry.fromMap(v as Map))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static int getSyncQueueCount() {
    final data = prefs.getString(_syncQueueKey);
    if (data == null) return 0;
    final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
    return map.length;
  }

  static Future<void> removeFromSyncQueue(String entryId) async {
    final data = prefs.getString(_syncQueueKey);
    if (data == null) return;
    final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
    map.remove(entryId);
    await prefs.setString(_syncQueueKey, jsonEncode(map));
  }

  static Future<void> updateSyncQueueEntry(SyncQueueEntry entry) async {
    final data = prefs.getString(_syncQueueKey);
    if (data == null) return;
    final map = Map<String, dynamic>.from(jsonDecode(data) as Map);
    map[entry.id] = entry.toMap();
    await prefs.setString(_syncQueueKey, jsonEncode(map));
  }

  static Future<void> clearSyncQueue() async {
    await prefs.remove(_syncQueueKey);
  }

  static DateTime? getLastSyncTime() {
    final data = prefs.getString(_lastSyncKey);
    if (data == null) return null;
    return DateTime.tryParse(data);
  }

  static Future<void> setLastSyncTime(DateTime time) async {
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }
}
