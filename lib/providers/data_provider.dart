import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';
import '../models/branch.dart';
import '../models/department.dart';
import '../models/member.dart';
import '../models/event.dart';
import '../models/sermon.dart';
import '../models/transaction.dart';
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
import '../models/sunday_school_book.dart';
import '../models/community_post.dart';
import '../models/comment.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../core/constants.dart';
import '../services/local_db.dart';
import '../services/movement_classifier.dart';
import '../services/api_config.dart';
import '../services/api_client.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

/// Uses the canonical AppRoles.isAboveChurchLevel to determine if a role
/// has cross-church data access (superSystemAdmin, nationalAdmin, etc.)
bool _isCrossChurchRole(String? role) => AppRoles.isAboveChurchLevel(role);

// ── Users ─────────────────────────────────────────────────────────────────────

class UserNotifier extends StateNotifier<List<AppUser>> {
  final String churchId;
  final bool crossChurch;

  UserNotifier(this.churchId, {this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    final all = crossChurch
        ? LocalDb.getAllUsersAcrossChurches()
        : LocalDb.getAllUsers().where((u) => u.churchId == churchId).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    state = all;
  }

  Future<void> update(AppUser user) async {
    await LocalDb.saveUser(user);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteUser(id);
    _load();
  }

  void refresh() => _load();
}

final userProvider =
    StateNotifierProvider<UserNotifier, List<AppUser>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  return UserNotifier(churchId, crossChurch: _isCrossChurchRole(appState.user?.role));
});

// ── Branches (deprecated — branches removed, always returns empty) ──────────

final branchProvider =
    StateNotifierProvider<BranchStubNotifier, List<Branch>>((ref) {
  return BranchStubNotifier();
});

class BranchStubNotifier extends StateNotifier<List<Branch>> {
  BranchStubNotifier() : super([]);

  void refresh() {}
}

// ── Departments ───────────────────────────────────────────────────────────────

class DepartmentNotifier extends StateNotifier<List<Department>> {
  final String churchId;
  final String? branchFilter;
  final bool crossChurch;

  DepartmentNotifier(this.churchId, this.branchFilter, {this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllDepartmentsAcrossChurches()
        : LocalDb.getAllDepartments(
            churchId: churchId,
            branchId: branchFilter,
          );
  }

  Future<void> add({
    required String branchId,
    required String name,
    required String description,
  }) async {
    final dept = Department(
      id: _uuid.v4(),
      churchId: churchId,
      branchId: branchId,
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveDepartment(dept);
    _load();
  }

  Future<void> update(Department dept) async {
    await LocalDb.saveDepartment(dept);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteDepartment(id);
    _load();
  }

  void refresh() => _load();
}

final departmentProvider =
    StateNotifierProvider<DepartmentNotifier, List<Department>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return DepartmentNotifier(churchId, null,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Members ───────────────────────────────────────────────────────────────────

class MemberNotifier extends StateNotifier<List<Member>> {
  final String churchId;
  final String? branchFilter;
  final String? departmentFilter;
  final String? organizationId;
  final String? regionId;
  final String? districtId;
  final String? areaId;
  final bool crossChurch;

  MemberNotifier(
    this.churchId, {
    this.branchFilter,
    this.departmentFilter,
    this.organizationId,
    this.regionId,
    this.districtId,
    this.areaId,
    this.crossChurch = false,
  }) : super([]) {
    _load();
  }

  void _load() {
    final list = crossChurch
        ? LocalDb.getAllMembersAcrossChurches(
            branchId: branchFilter,
            departmentId: departmentFilter,
            organizationId: organizationId,
            regionId: regionId,
            districtId: districtId,
            areaId: areaId,
          )
        : LocalDb.getAllMembers(
            churchId: churchId,
            branchId: branchFilter,
            departmentId: departmentFilter,
            organizationId: organizationId,
            regionId: regionId,
            districtId: districtId,
            areaId: areaId,
          );
    list.sort((a, b) => a.name.compareTo(b.name));
    state = list;
  }

  Future<void> add({
    required String branchId,
    required String name,
    required String email,
    required String phone,
    required String address,
    required String gender,
    DateTime? dateOfBirth,
    String maritalStatus = 'single',
    bool isEmployed = false,
    String departmentId = '',
  }) async {
    final movement = MovementClassifier.classify(
      dateOfBirth: dateOfBirth,
      gender: gender,
      maritalStatus: maritalStatus,
      isEmployed: isEmployed,
    );
    final member = Member(
      id: _uuid.v4(),
      churchId: churchId,
      branchId: branchId,
      departmentId: departmentId,
      name: name,
      email: email,
      phone: phone,
      address: address,
      gender: gender,
      dateOfBirth: dateOfBirth,
      maritalStatus: maritalStatus,
      isEmployed: isEmployed,
      movement: movement,
      membershipDate: DateTime.now(),
      isActive: true,
    );
    await LocalDb.saveMember(member);
    _load();
  }

  Future<void> update(Member member) async {
    await LocalDb.saveMember(member);
    _load();
  }

  Future<void> toggleActive(String id) async {
    final member = LocalDb.getMemberById(id);
    if (member == null) return;
    await LocalDb.saveMember(member.copyWith(isActive: !member.isActive));
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteMember(id);
    _load();
  }

  void refresh() => _load();
}

final memberProvider =
    StateNotifierProvider<MemberNotifier, List<Member>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;

  String? deptFilter;
  String? organizationId, regionId, districtId, areaId;

  // Apply hierarchical filtering based on user role
  if (user?.role == AppRoles.nationalAdmin ||
      user?.role == AppRoles.nationalExecutive) {
    organizationId = user?.organizationId;
  } else if (user?.role == AppRoles.regionalAdmin ||
      user?.role == AppRoles.regionalBishop) {
    organizationId = user?.organizationId;
    regionId = user?.regionId;
  } else if (user?.role == AppRoles.districtAdmin ||
      user?.role == AppRoles.districtPastor) {
    organizationId = user?.organizationId;
    regionId = user?.regionId;
    districtId = user?.districtId;
  } else if (user?.role == AppRoles.areaAdmin ||
      user?.role == AppRoles.localChurchAdmin ||
      user?.role == AppRoles.seniorPastor ||
      user?.role == AppRoles.associatePastor ||
      user?.role == AppRoles.churchSecretary ||
      user?.role == AppRoles.financeOfficer ||
      user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    organizationId = user?.organizationId;
    regionId = user?.regionId;
    districtId = user?.districtId;
    areaId = user?.areaId;
    deptFilter = user?.departmentId;
  }

  return MemberNotifier(
    churchId,
    departmentFilter: deptFilter,
    organizationId: organizationId,
    regionId: regionId,
    districtId: districtId,
    areaId: areaId,
    crossChurch: _isCrossChurchRole(user?.role),
  );
});

// ── Attendance ────────────────────────────────────────────────────────────────

class AttendanceNotifier extends StateNotifier<List<AttendanceRecord>> {
  final String churchId;
  final String? branchFilter;
  final bool crossChurch;
  final String? ministryTypeFilter;
  final String? tenantId;

  AttendanceNotifier(this.churchId, this.branchFilter,
      {this.crossChurch = false, this.ministryTypeFilter, this.tenantId}) : super([]) {
    _load();
  }

  void _load() {
    if (ApiConfig.isConfigured && tenantId != null && !crossChurch) {
      _loadFromBackend();
    } else {
      _loadLocal();
    }
  }

  void _loadLocal() {
    state = crossChurch
        ? LocalDb.getAllAttendanceAcrossChurches()
        : LocalDb.getAllAttendanceRecords(
            churchId: churchId,
            branchId: branchFilter,
            ministryType: ministryTypeFilter,
          );
  }

  Future<void> _loadFromBackend() async {
    try {
      final api = ApiClient();
      final queryPath = branchFilter != null
          ? '/tenants/$tenantId/attendance?branchId=$branchFilter'
          : '/tenants/$tenantId/attendance';
      final list = await api.getList(queryPath);
      state = list
          .map((e) => AttendanceRecord.fromBackend(e as Map<dynamic, dynamic>))
          .toList();
      // Also cache locally for offline access
      for (final record in state) {
        await LocalDb.saveAttendanceRecord(record);
      }
    } catch (_) {
      _loadLocal();
    }
  }

  Future<String?> save(AttendanceRecord record) async {
    if (ApiConfig.isConfigured && tenantId != null && !crossChurch) {
      return _saveToBackend(record);
    }
    await LocalDb.saveAttendanceRecord(record);
    _loadLocal();
    return null;
  }

  Future<String?> _saveToBackend(AttendanceRecord record) async {
    try {
      final api = ApiClient();
      final resp = await api.post('/tenants/$tenantId/attendance', {
        'branchId': record.branchId,
        'serviceType': record.serviceType,
        'date': record.date.toIso8601String(),
        'recordedById': record.recordedById,
        'ministryType': record.ministryType,
        'latitude': record.latitude,
        'longitude': record.longitude,
        'proximityRadius': record.proximityRadius,
      });
      final saved = AttendanceRecord.fromBackend(resp);

      // Sync manually-marked present members to backend
      if (record.presentMemberIds.isNotEmpty) {
        await api.post(
          '/tenants/$tenantId/attendance/${saved.id}/mark-present',
          {'memberIds': record.presentMemberIds},
        );
        saved.copyWith(presentMemberIds: record.presentMemberIds);
      }

      await LocalDb.saveAttendanceRecord(saved);
      _loadFromBackend();
      return null;
    } catch (e) {
      // Fallback to local save
      await LocalDb.saveAttendanceRecord(record);
      _loadLocal();
      return e.toString();
    }
  }

  Future<String?> update(AttendanceRecord record) async {
    if (ApiConfig.isConfigured && tenantId != null && !crossChurch) {
      try {
        final api = ApiClient();
        await api.patch('/tenants/$tenantId/attendance/${record.id}', {
          'serviceType': record.serviceType,
          'date': record.date.toIso8601String(),
          'ministryType': record.ministryType,
          'latitude': record.latitude,
          'longitude': record.longitude,
          'proximityRadius': record.proximityRadius,
          'isActive': record.isActive,
        });
        // Also update present members on backend
        await api.post(
          '/tenants/$tenantId/attendance/${record.id}/mark-present',
          {'memberIds': record.presentMemberIds},
        );
        _loadFromBackend();
        return null;
      } catch (e) {
        await LocalDb.saveAttendanceRecord(record);
        _loadLocal();
        return e.toString();
      }
    }
    await LocalDb.saveAttendanceRecord(record);
    _loadLocal();
    return null;
  }

  Future<String?> delete(String id) async {
    if (ApiConfig.isConfigured && tenantId != null && !crossChurch) {
      try {
        final api = ApiClient();
        await api.delete('/tenants/$tenantId/attendance/$id');
        _loadFromBackend();
        return null;
      } catch (e) {
        await LocalDb.deleteAttendanceRecord(id);
        _loadLocal();
        return e.toString();
      }
    }
    await LocalDb.deleteAttendanceRecord(id);
    _loadLocal();
    return null;
  }

  // Member self-check-in with GPS proximity validation
  Future<({bool success, String message, int distance})> selfCheckIn(
    String attendanceId,
    double latitude,
    double longitude,
  ) async {
    if (ApiConfig.isConfigured && tenantId != null) {
      try {
        final api = ApiClient();
        final resp = await api.post(
          '/tenants/$tenantId/attendance/$attendanceId/self-checkin',
          {'latitude': latitude, 'longitude': longitude},
        );
        final success = resp['success'] as bool;
        final message = resp['message'] as String;
        final distance = (resp['distance'] as num).toInt();
        if (success) _loadFromBackend();
        return (success: success, message: message, distance: distance);
      } catch (e) {
        return (success: false, message: e.toString(), distance: 0);
      }
    }
    return (success: false, message: 'Backend not configured', distance: 0);
  }

  void refresh() => _load();
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;

  // Ministry-specific heads see only their ministry attendance
  String? ministryTypeFilter;
  if (user?.role == AppRoles.youthMinistryHead) {
    ministryTypeFilter = MinistryType.youth;
  } else if (user?.role == AppRoles.menFellowshipHead) {
    ministryTypeFilter = MinistryType.menFellowship;
  } else if (user?.role == AppRoles.womenFellowshipHead) {
    ministryTypeFilter = MinistryType.womenFellowship;
  } else if (user?.role == AppRoles.childrenMinistryHead) {
    ministryTypeFilter = MinistryType.children;
  }

  return AttendanceNotifier(churchId, null,
      crossChurch: _isCrossChurchRole(user?.role),
      ministryTypeFilter: ministryTypeFilter,
      tenantId: user?.churchId.isNotEmpty == true ? user!.churchId : null);
});

// ── Finance ───────────────────────────────────────────────────────────────────

class FinanceNotifier extends StateNotifier<List<FinanceTransaction>> {
  final String churchId;
  final String? branchFilter;
  final bool crossChurch;

  FinanceNotifier(this.churchId, this.branchFilter, {this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllTransactionsAcrossChurches()
        : LocalDb.getAllTransactions(
            churchId: churchId,
            branchId: branchFilter,
          );
  }

  Future<void> add(FinanceTransaction tx) async {
    await LocalDb.saveTransaction(tx);
    _load();
  }

  Future<void> update(FinanceTransaction tx) async {
    await LocalDb.saveTransaction(tx);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteTransaction(id);
    _load();
  }

  void refresh() => _load();
}

final financeProvider =
    StateNotifierProvider<FinanceNotifier, List<FinanceTransaction>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return FinanceNotifier(churchId, null,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Sermons ───────────────────────────────────────────────────────────────────

class SermonNotifier extends StateNotifier<List<Sermon>> {
  final String churchId;
  final String? branchFilter;
  final bool crossChurch;

  SermonNotifier(this.churchId, this.branchFilter, {this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllSermonsAcrossChurches()
        : LocalDb.getAllSermons(
            churchId: churchId,
            branchId: branchFilter,
          );
  }

  Future<void> save(Sermon sermon) async {
    await LocalDb.saveSermon(sermon);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteSermon(id);
    _load();
  }

  void refresh() => _load();
}

final sermonProvider =
    StateNotifierProvider<SermonNotifier, List<Sermon>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return SermonNotifier(churchId, null,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Library: Digital Books ──────────────────────────────────────────────────

class LibraryBookNotifier extends StateNotifier<List<LibraryBook>> {
  final String churchId;
  final bool crossChurch;

  LibraryBookNotifier(this.churchId, {this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllLibraryBooksAcrossChurches()
        : LocalDb.getAllLibraryBooks(churchId: churchId);
  }

  Future<void> save(LibraryBook book) async {
    await LocalDb.saveLibraryBook(book);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteLibraryBook(id);
    _load();
  }

  void refresh() => _load();
}

final libraryBookProvider =
    StateNotifierProvider<LibraryBookNotifier, List<LibraryBook>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return LibraryBookNotifier(churchId,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Library: Daily Devotion & Prayer Guide ───────────────────────────────────

class DevotionGuideNotifier extends StateNotifier<List<DevotionGuide>> {
  final String churchId;
  final bool crossChurch;

  DevotionGuideNotifier(this.churchId, {this.crossChurch = false})
      : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllDevotionGuidesAcrossChurches()
        : LocalDb.getAllDevotionGuides(churchId: churchId);
  }

  Future<void> save(DevotionGuide devotion) async {
    await LocalDb.saveDevotionGuide(devotion);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteDevotionGuide(id);
    _load();
  }

  void refresh() => _load();
}

final devotionGuideProvider =
    StateNotifierProvider<DevotionGuideNotifier, List<DevotionGuide>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return DevotionGuideNotifier(churchId,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Library: Bible Study Resources ───────────────────────────────────────────

class BibleStudyResourceNotifier
    extends StateNotifier<List<BibleStudyResource>> {
  final String churchId;
  final bool crossChurch;

  BibleStudyResourceNotifier(this.churchId, {this.crossChurch = false})
      : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllBibleStudyResourcesAcrossChurches()
        : LocalDb.getAllBibleStudyResources(churchId: churchId);
  }

  Future<void> save(BibleStudyResource study) async {
    await LocalDb.saveBibleStudyResource(study);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteBibleStudyResource(id);
    _load();
  }

  void refresh() => _load();
}

final bibleStudyResourceProvider = StateNotifierProvider<
    BibleStudyResourceNotifier, List<BibleStudyResource>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return BibleStudyResourceNotifier(churchId,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Library: Sunday School Books & Chapters ──────────────────────────────────

class SundaySchoolBookNotifier extends StateNotifier<List<SundaySchoolBook>> {
  final String churchId;
  final bool crossChurch;

  SundaySchoolBookNotifier(this.churchId, {this.crossChurch = false})
      : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllSundaySchoolBooksAcrossChurches()
        : LocalDb.getAllSundaySchoolBooks(churchId: churchId);
  }

  Future<void> save(SundaySchoolBook book) async {
    await LocalDb.saveSundaySchoolBook(book);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteSundaySchoolBook(id);
    _load();
  }

  void refresh() => _load();
}

final sundaySchoolBookProvider =
    StateNotifierProvider<SundaySchoolBookNotifier, List<SundaySchoolBook>>(
        (ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return SundaySchoolBookNotifier(churchId,
      crossChurch: _isCrossChurchRole(user?.role));
});

class SundaySchoolChapterNotifier
    extends StateNotifier<List<SundaySchoolChapter>> {
  final String churchId;
  final String? bookIdFilter;
  final bool crossChurch;

  SundaySchoolChapterNotifier(this.churchId,
      {this.bookIdFilter, this.crossChurch = false})
      : super([]) {
    _load();
  }

  void _load() {
    var all = crossChurch
        ? LocalDb.getAllSundaySchoolChaptersAcrossChurches()
        : LocalDb.getAllSundaySchoolChapters(churchId: churchId);
    if (bookIdFilter != null) {
      all = all.where((c) => c.bookId == bookIdFilter).toList();
    }
    state = all;
  }

  Future<void> save(SundaySchoolChapter chapter) async {
    await LocalDb.saveSundaySchoolChapter(chapter);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteSundaySchoolChapter(id);
    _load();
  }

  void refresh() => _load();
}

final sundaySchoolChapterProvider = StateNotifierProvider<
    SundaySchoolChapterNotifier, List<SundaySchoolChapter>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return SundaySchoolChapterNotifier(churchId,
      crossChurch: _isCrossChurchRole(user?.role));
});

/// Family provider that returns chapters for a specific book.
final sundaySchoolChaptersForBookProvider = StateNotifierProvider.family<
    SundaySchoolChapterNotifier,
    List<SundaySchoolChapter>,
    String>((ref, bookId) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  return SundaySchoolChapterNotifier(churchId, bookIdFilter: bookId);
});

// ── Community: Feed Posts ────────────────────────────────────────────────────

class CommunityPostNotifier extends StateNotifier<List<CommunityPost>> {
  final String churchId;
  final bool crossChurch;

  CommunityPostNotifier(this.churchId, {this.crossChurch = false})
      : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllCommunityPostsAcrossChurches()
        : LocalDb.getAllCommunityPosts(churchId: churchId);
  }

  Future<CommunityPost> createPost({
    required String authorId,
    required String authorName,
    required String authorRole,
    required String text,
    String mediaUrl = '',
    String mediaType = CommunityMediaType.text,
  }) async {
    final post = CommunityPost(
      id: _uuid.v4(),
      churchId: churchId,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      text: text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveCommunityPost(post);
    _load();
    return post;
  }

  Future<void> toggleLike(CommunityPost post, String userId) async {
    final likes = List<String>.from(post.likes);
    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    await LocalDb.saveCommunityPost(post.copyWith(
      likes: likes,
      updatedAt: DateTime.now(),
    ));
    _load();
  }

  Future<void> deletePost(String id) async {
    await LocalDb.deleteCommunityPost(id);
    _load();
  }

  void refresh() => _load();
}

final communityPostProvider =
    StateNotifierProvider<CommunityPostNotifier, List<CommunityPost>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  return CommunityPostNotifier(churchId,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Community: Comments ──────────────────────────────────────────────────────

class CommentNotifier extends StateNotifier<List<Comment>> {
  final String churchId;

  CommentNotifier(this.churchId) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllComments(churchId: churchId);
  }

  List<Comment> commentsForPost(String postId) =>
      state.where((c) => c.postId == postId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<Comment> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String authorRole,
    required String text,
  }) async {
    final comment = Comment(
      id: _uuid.v4(),
      churchId: churchId,
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      text: text,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveComment(comment);
    _load();
    return comment;
  }

  Future<void> deleteComment(String id) async {
    await LocalDb.deleteComment(id);
    _load();
  }

  void refresh() => _load();
}

final commentProvider =
    StateNotifierProvider<CommentNotifier, List<Comment>>((ref) {
  final appState = ref.watch(appStateProvider);
  return CommentNotifier(appState.church?.id ?? '');
});

// ── Community: Conversations ─────────────────────────────────────────────────

class ConversationNotifier extends StateNotifier<List<Conversation>> {
  final String churchId;
  final String userId;

  ConversationNotifier(this.churchId, this.userId) : super([]) {
    _load();
  }

  void _load() {
    if (churchId.isEmpty || userId.isEmpty) {
      state = [];
      return;
    }
    state = LocalDb.getConversationsForUser(churchId: churchId, userId: userId);
  }

  /// Opens (or creates) a 1:1 conversation with [otherUserId].
  Future<Conversation> openDirectMessage({
    required String otherUserId,
    required String otherUserName,
    required String currentUserName,
  }) async {
    final id = Conversation.oneOnOneId(userId, otherUserId);
    final existing = LocalDb.getConversationById(id);
    if (existing != null) {
      // Backfill names if missing
      final names = Map<String, String>.from(existing.participantNames);
      names[userId] = currentUserName;
      names[otherUserId] = otherUserName;
      if (names.length != existing.participantNames.length) {
        await LocalDb.saveConversation(existing.copyWith(participantNames: names));
      }
      _load();
      return existing;
    }
    final convo = Conversation(
      id: id,
      churchId: churchId,
      participantIds: [userId, otherUserId],
      participantNames: {userId: currentUserName, otherUserId: otherUserName},
      createdAt: DateTime.now(),
    );
    await LocalDb.saveConversation(convo);
    _load();
    return convo;
  }

  Future<void> deleteConversation(String id) async {
    await LocalDb.deleteConversation(id);
    _load();
  }

  void refresh() => _load();
}

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, List<Conversation>>((ref) {
  final appState = ref.watch(appStateProvider);
  return ConversationNotifier(
      appState.church?.id ?? '', appState.user?.id ?? '');
});

// ── Community: Messages ──────────────────────────────────────────────────────

class MessageNotifier extends StateNotifier<List<Message>> {
  final String churchId;
  final String? conversationId;

  MessageNotifier(this.churchId, this.conversationId) : super([]) {
    _load();
  }

  void _load() {
    if (conversationId == null) {
      state = [];
      return;
    }
    state = LocalDb.getMessagesForConversation(conversationId!);
  }

  Future<Message> sendMessage({
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final message = Message(
      id: _uuid.v4(),
      churchId: churchId,
      conversationId: conversationId!,
      senderId: senderId,
      senderName: senderName,
      text: text,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveMessage(message);
    // Update the conversation's last message preview
    final convo = LocalDb.getConversationById(conversationId!);
    if (convo != null) {
      await LocalDb.saveConversation(convo.copyWith(
        lastMessageText: text,
        lastMessageAt: message.createdAt,
      ));
    }
    _load();
    return message;
  }

  Future<void> markRead(String currentUserId) async {
    if (conversationId == null) return;
    await LocalDb.markConversationRead(
        conversationId: conversationId!, userId: currentUserId);
    _load();
  }

  void refresh() => _load();
}

final messageProvider =
    StateNotifierProvider<MessageNotifier, List<Message>>((ref) {
  final appState = ref.watch(appStateProvider);
  return MessageNotifier(appState.church?.id ?? '', null);
});

/// Family provider for messages scoped to a specific conversation.
final messageForConversationProvider =
    StateNotifierProvider.family<MessageNotifier, List<Message>, String>(
        (ref, conversationId) {
  final appState = ref.watch(appStateProvider);
  return MessageNotifier(appState.church?.id ?? '', conversationId);
});

// ── Events ────────────────────────────────────────────────────────────────────

class EventNotifier extends StateNotifier<List<ChurchEvent>> {
  final String churchId;
  final String? branchFilter;
  final String? departmentFilter;
  final bool crossChurch;
  final String? ministryTypeFilter;

  EventNotifier(this.churchId, this.branchFilter, this.departmentFilter,
      {this.crossChurch = false, this.ministryTypeFilter})
      : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllEventsAcrossChurches()
        : LocalDb.getAllEvents(
            churchId: churchId,
            branchId: branchFilter,
            departmentId: departmentFilter,
            ministryType: ministryTypeFilter,
          );
  }

  Future<void> save(ChurchEvent event) async {
    await LocalDb.saveEvent(event);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteEvent(id);
    _load();
  }

  void refresh() => _load();
}

final eventProvider =
    StateNotifierProvider<EventNotifier, List<ChurchEvent>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;

  String? deptFilter;
  String? ministryTypeFilter;

  // Local church level users see only their department
  if (user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    deptFilter = (user?.departmentId.isNotEmpty ?? false) ? user?.departmentId : null;
  }

  // Ministry-specific heads see only their ministry events
  if (user?.role == AppRoles.youthMinistryHead) {
    ministryTypeFilter = MinistryType.youth;
  } else if (user?.role == AppRoles.menFellowshipHead) {
    ministryTypeFilter = MinistryType.menFellowship;
  } else if (user?.role == AppRoles.womenFellowshipHead) {
    ministryTypeFilter = MinistryType.womenFellowship;
  } else if (user?.role == AppRoles.childrenMinistryHead) {
    ministryTypeFilter = MinistryType.children;
  }

  return EventNotifier(churchId, null, deptFilter,
      crossChurch: _isCrossChurchRole(user?.role),
      ministryTypeFilter: ministryTypeFilter);
});

// ── Organizations ─────────────────────────────────────────────────────────────

class OrganizationNotifier extends StateNotifier<List<Organization>> {
  final bool crossChurch;
  OrganizationNotifier({this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    final list = crossChurch
        ? LocalDb.getAllOrganizationsAcrossChurches()
        : LocalDb.getAllOrganizations();
    list.sort((a, b) => a.name.compareTo(b.name));
    state = list;
  }

  Future<void> add({
    required String name,
    required String description,
    required String adminId,
    required String address,
    required String phone,
    required String email,
    required String website,
  }) async {
    final org = Organization(
      id: _uuid.v4(),
      name: name,
      description: description,
      adminId: adminId,
      address: address,
      phone: phone,
      email: email,
      website: website,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveOrganization(org);
    _load();
  }

  Future<void> update(Organization org) async {
    await LocalDb.saveOrganization(org);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteOrganization(id);
    _load();
  }

  void refresh() => _load();
}

final organizationProvider =
    StateNotifierProvider<OrganizationNotifier, List<Organization>>((ref) {
  final user = ref.watch(appStateProvider).user;
  return OrganizationNotifier(crossChurch: _isCrossChurchRole(user?.role));
});

// ── Regions ─────────────────────────────────────────────────────────────────

class RegionNotifier extends StateNotifier<List<Region>> {
  final String? organizationId;
  final bool crossChurch;

  RegionNotifier(this.organizationId, {this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    final list = crossChurch
        ? LocalDb.getAllRegionsAcrossChurches(organizationId: organizationId)
        : LocalDb.getAllRegions(organizationId: organizationId);
    list.sort((a, b) => a.name.compareTo(b.name));
    state = list;
  }

  Future<void> add({
    required String name,
    required String organizationId,
    required String adminId,
    required String description,
    required String address,
    required String phone,
    required String email,
  }) async {
    final region = Region(
      id: _uuid.v4(),
      name: name,
      organizationId: organizationId,
      adminId: adminId,
      description: description,
      address: address,
      phone: phone,
      email: email,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveRegion(region);
    _load();
  }

  Future<void> update(Region region) async {
    await LocalDb.saveRegion(region);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteRegion(id);
    _load();
  }

  void refresh() => _load();
}

final regionProvider =
    StateNotifierProvider<RegionNotifier, List<Region>>((ref) {
  final appState = ref.watch(appStateProvider);
  final user = appState.user;
  String? orgId;
  if (user?.role == AppRoles.superSystemAdmin) {
    orgId = null; // See all
  } else if (user?.organizationId != null) {
    orgId = user?.organizationId;
  }
  return RegionNotifier(orgId,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Districts ───────────────────────────────────────────────────────────────

class DistrictNotifier extends StateNotifier<List<District>> {
  final String? regionId;
  final bool crossChurch;

  DistrictNotifier(this.regionId, {this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    final list = crossChurch
        ? LocalDb.getAllDistrictsAcrossChurches(regionId: regionId)
        : LocalDb.getAllDistricts(regionId: regionId);
    list.sort((a, b) => a.name.compareTo(b.name));
    state = list;
  }

  Future<void> add({
    required String name,
    required String regionId,
    required String adminId,
    required String description,
    required String address,
    required String phone,
    required String email,
  }) async {
    final district = District(
      id: _uuid.v4(),
      name: name,
      regionId: regionId,
      adminId: adminId,
      description: description,
      address: address,
      phone: phone,
      email: email,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveDistrict(district);
    _load();
  }

  Future<void> update(District district) async {
    await LocalDb.saveDistrict(district);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteDistrict(id);
    _load();
  }

  void refresh() => _load();
}

final districtProvider =
    StateNotifierProvider<DistrictNotifier, List<District>>((ref) {
  final appState = ref.watch(appStateProvider);
  final user = appState.user;
  String? regionId;
  // Only filter by regionId if user is at district level or below
  if (user?.role == AppRoles.districtAdmin ||
      user?.role == AppRoles.districtPastor ||
      user?.role == AppRoles.areaAdmin ||
      user?.role == AppRoles.localChurchAdmin ||
      user?.role == AppRoles.seniorPastor ||
      user?.role == AppRoles.associatePastor ||
      user?.role == AppRoles.churchSecretary ||
      user?.role == AppRoles.financeOfficer ||
      user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    regionId = user?.regionId;
  }
  return DistrictNotifier(regionId,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Areas ────────────────────────────────────────────────────────────────────

class AreaNotifier extends StateNotifier<List<Area>> {
  final String? districtId;
  final bool crossChurch;

  AreaNotifier(this.districtId, {this.crossChurch = false}) : super([]) {
    _load();
  }

  void _load() {
    final list = crossChurch
        ? LocalDb.getAllAreasAcrossChurches(districtId: districtId)
        : LocalDb.getAllAreas(districtId: districtId);
    list.sort((a, b) => a.name.compareTo(b.name));
    state = list;
  }

  Future<void> add({
    required String name,
    required String districtId,
    required String adminId,
    required String description,
    required String address,
    required String phone,
    required String email,
  }) async {
    final area = Area(
      id: _uuid.v4(),
      name: name,
      districtId: districtId,
      adminId: adminId,
      description: description,
      address: address,
      phone: phone,
      email: email,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveArea(area);
    _load();
  }

  Future<void> update(Area area) async {
    await LocalDb.saveArea(area);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteArea(id);
    _load();
  }

  void refresh() => _load();
}

final areaProvider =
    StateNotifierProvider<AreaNotifier, List<Area>>((ref) {
  final appState = ref.watch(appStateProvider);
  final user = appState.user;
  String? districtId;
  // Only filter by districtId if user is at area level or below
  if (user?.role == AppRoles.areaAdmin ||
      user?.role == AppRoles.localChurchAdmin ||
      user?.role == AppRoles.seniorPastor ||
      user?.role == AppRoles.associatePastor ||
      user?.role == AppRoles.churchSecretary ||
      user?.role == AppRoles.financeOfficer ||
      user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    districtId = user?.districtId;
  }
  return AreaNotifier(districtId,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Welfare Cases ─────────────────────────────────────────────────────────────

class WelfareNotifier extends StateNotifier<List<WelfareCase>> {
  final String churchId;
  final String? branchFilter;
  final String? statusFilter;

  WelfareNotifier(
    this.churchId, {
    this.branchFilter,
    this.statusFilter,
  }) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllWelfareCases(
      churchId: churchId,
      branchId: branchFilter,
      status: statusFilter,
    );
  }

  Future<void> add(WelfareCase welfareCase) async {
    await LocalDb.saveWelfareCase(welfareCase);
    _load();
  }

  Future<void> update(WelfareCase welfareCase) async {
    await LocalDb.saveWelfareCase(welfareCase);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteWelfareCase(id);
    _load();
  }

  void refresh() => _load();
}

final welfareProvider =
    StateNotifierProvider<WelfareNotifier, List<WelfareCase>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  String? branchFilter;

  // Local church level users see only their branch
  if (user?.role == AppRoles.localChurchAdmin ||
      user?.role == AppRoles.seniorPastor ||
      user?.role == AppRoles.associatePastor ||
      user?.role == AppRoles.churchSecretary ||
      user?.role == AppRoles.welfareHead ||
      user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    branchFilter =
        (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  }

  return WelfareNotifier(churchId, branchFilter: branchFilter);
});

// ── Welfare Finance (Transactions) ────────────────────────────────────────────

class WelfareTransactionNotifier extends StateNotifier<List<WelfareTransaction>> {
  final String churchId;
  final String? branchFilter;

  WelfareTransactionNotifier(
    this.churchId, {
    this.branchFilter,
  }) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllWelfareTransactions(
      churchId: churchId,
      branchId: branchFilter,
    );
  }

  Future<void> add(WelfareTransaction txn) async {
    await LocalDb.saveWelfareTransaction(txn);
    _load();
  }

  Future<void> update(WelfareTransaction txn) async {
    await LocalDb.saveWelfareTransaction(txn);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteWelfareTransaction(id);
    _load();
  }

  void refresh() => _load();
}

final welfareFinanceProvider =
    StateNotifierProvider<WelfareTransactionNotifier, List<WelfareTransaction>>(
        (ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  String? branchFilter;

  if (user?.role == AppRoles.localChurchAdmin ||
      user?.role == AppRoles.seniorPastor ||
      user?.role == AppRoles.associatePastor ||
      user?.role == AppRoles.churchSecretary ||
      user?.role == AppRoles.welfareHead ||
      user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    branchFilter =
        (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  }

  return WelfareTransactionNotifier(churchId, branchFilter: branchFilter);
});

// ── Department Welfare ────────────────────────────────────────────────────────

class DepartmentWelfareNotifier extends StateNotifier<List<DepartmentWelfare>> {
  final String churchId;
  final String? branchFilter;

  DepartmentWelfareNotifier(
    this.churchId, {
    this.branchFilter,
  }) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllDepartmentWelfare(
      churchId: churchId,
      branchId: branchFilter,
    );
  }

  Future<void> add(DepartmentWelfare dw) async {
    await LocalDb.saveDepartmentWelfare(dw);
    _load();
  }

  Future<void> update(DepartmentWelfare dw) async {
    await LocalDb.saveDepartmentWelfare(dw);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteDepartmentWelfare(id);
    _load();
  }

  void refresh() => _load();
}

final departmentWelfareProvider =
    StateNotifierProvider<DepartmentWelfareNotifier, List<DepartmentWelfare>>(
        (ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  String? branchFilter;

  if (user?.role == AppRoles.localChurchAdmin ||
      user?.role == AppRoles.seniorPastor ||
      user?.role == AppRoles.associatePastor ||
      user?.role == AppRoles.churchSecretary ||
      user?.role == AppRoles.welfareHead ||
      user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    branchFilter =
        (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  }

  return DepartmentWelfareNotifier(churchId, branchFilter: branchFilter);
});

// ── Welfare Statements ───────────────────────────────────────────────────────

class WelfareStatementNotifier extends StateNotifier<List<WelfareStatement>> {
  final String churchId;
  final String? branchFilter;
  final String? memberFilter;

  WelfareStatementNotifier(
    this.churchId, {
    this.branchFilter,
    this.memberFilter,
  }) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllWelfareStatements(
      churchId: churchId,
      branchId: branchFilter,
      memberId: memberFilter,
    );
  }

  Future<void> add(WelfareStatement stmt) async {
    await LocalDb.saveWelfareStatement(stmt);
    _load();
  }

  Future<void> update(WelfareStatement stmt) async {
    await LocalDb.saveWelfareStatement(stmt);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteWelfareStatement(id);
    _load();
  }

  void refresh() => _load();
}

final welfareStatementProvider =
    StateNotifierProvider<WelfareStatementNotifier, List<WelfareStatement>>(
        (ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  String? branchFilter;
  String? memberFilter;

  // Members see only their own statements
  if (user?.role == AppRoles.member ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.cellLeader) {
    memberFilter = user?.id;
  }

  // Local church level users see only their branch
  if (user?.role == AppRoles.localChurchAdmin ||
      user?.role == AppRoles.seniorPastor ||
      user?.role == AppRoles.associatePastor ||
      user?.role == AppRoles.churchSecretary ||
      user?.role == AppRoles.welfareHead ||
      user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    branchFilter =
        (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  }

  return WelfareStatementNotifier(churchId,
      branchFilter: branchFilter, memberFilter: memberFilter);
});

// ── Shared Reports ───────────────────────────────────────────────────────────

class SharedReportNotifier extends StateNotifier<List<SharedReport>> {
  final String churchId;
  final String? branchFilter;
  final String? memberFilter;

  SharedReportNotifier(
    this.churchId, {
    this.branchFilter,
    this.memberFilter,
  }) : super([]) {
    _load();
  }

  void _load() {
    if (memberFilter != null) {
      state = LocalDb.getAllSharedReports(
        churchId: churchId,
        branchId: branchFilter,
        sharedToMemberId: memberFilter,
      );
    } else {
      state = LocalDb.getAllSharedReports(
        churchId: churchId,
        branchId: branchFilter,
      );
    }
  }

  Future<void> add(SharedReport report) async {
    await LocalDb.saveSharedReport(report);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteSharedReport(id);
    _load();
  }

  Future<void> markRead(String id) async {
    await LocalDb.markSharedReportRead(id);
    _load();
  }

  void refresh() => _load();
}

final sharedReportProvider =
    StateNotifierProvider<SharedReportNotifier, List<SharedReport>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  String? branchFilter;
  String? memberFilter;

  // Members see only reports shared to them
  if (user?.role == AppRoles.member ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.cellLeader) {
    memberFilter = user?.id;
  }

  // Local church level users see only their branch
  if (user?.role == AppRoles.localChurchAdmin ||
      user?.role == AppRoles.seniorPastor ||
      user?.role == AppRoles.associatePastor ||
      user?.role == AppRoles.churchSecretary ||
      user?.role == AppRoles.welfareHead ||
      user?.role == AppRoles.ministryHead ||
      user?.role == AppRoles.cellLeader ||
      user?.role == AppRoles.volunteer ||
      user?.role == AppRoles.member) {
    branchFilter =
        (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  }

  return SharedReportNotifier(churchId,
      branchFilter: branchFilter, memberFilter: memberFilter);
});

// ── Ministries ───────────────────────────────────────────────────────────────

class MinistryNotifier extends StateNotifier<List<Ministry>> {
  final String churchId;
  final String? branchFilter;
  final String? typeFilter;
  final String? orgId, regId, distId, arId;

  MinistryNotifier(
    this.churchId, {
    this.branchFilter,
    this.typeFilter,
    this.orgId,
    this.regId,
    this.distId,
    this.arId,
  }) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllMinistries(
      churchId: churchId,
      branchId: branchFilter,
      ministryType: typeFilter,
      organizationId: orgId,
      regionId: regId,
      districtId: distId,
      areaId: arId,
    );
  }

  Future<void> add(Ministry ministry) async {
    await LocalDb.saveMinistry(ministry);
    _load();
  }

  Future<void> update(Ministry ministry) async {
    await LocalDb.saveMinistry(ministry);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteMinistry(id);
    _load();
  }

  void refresh() => _load();
}

final ministryProvider =
    StateNotifierProvider<MinistryNotifier, List<Ministry>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  String? branchFilter;
  String? typeFilter;
  String? orgId, regId, distId, arId;

  // Multi-tenant hierarchical filtering
  if (user?.role == AppRoles.nationalAdmin ||
      user?.role == AppRoles.nationalExecutive ||
      user?.role == AppRoles.superSystemAdmin) {
    orgId = user?.organizationId;
  } else if (user?.role == AppRoles.regionalAdmin ||
      user?.role == AppRoles.regionalBishop) {
    orgId = user?.organizationId;
    regId = user?.regionId;
  } else if (user?.role == AppRoles.districtAdmin ||
      user?.role == AppRoles.districtPastor) {
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
  } else if (user?.role == AppRoles.areaAdmin) {
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
    arId = user?.areaId;
  } else {
    // Local church level — branch scoped
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
    arId = user?.areaId;
    branchFilter =
        (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  }

  // Ministry-specific heads see only their ministry type
  if (user?.role == AppRoles.youthMinistryHead) {
    typeFilter = MinistryType.youth;
  } else if (user?.role == AppRoles.menFellowshipHead) {
    typeFilter = MinistryType.menFellowship;
  } else if (user?.role == AppRoles.womenFellowshipHead) {
    typeFilter = MinistryType.womenFellowship;
  } else if (user?.role == AppRoles.childrenMinistryHead) {
    typeFilter = MinistryType.children;
  }

  return MinistryNotifier(churchId,
      branchFilter: branchFilter,
      typeFilter: typeFilter,
      orgId: orgId,
      regId: regId,
      distId: distId,
      arId: arId);
});

// ── Ministry Finance ─────────────────────────────────────────────────────────

class MinistryFinanceNotifier extends StateNotifier<List<MinistryFinance>> {
  final String churchId;
  final String? branchFilter;
  final String? ministryTypeFilter;
  final String? orgId, regId, distId, arId;

  MinistryFinanceNotifier(
    this.churchId, {
    this.branchFilter,
    this.ministryTypeFilter,
    this.orgId,
    this.regId,
    this.distId,
    this.arId,
  }) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllMinistryFinance(
      churchId: churchId,
      branchId: branchFilter,
      ministryType: ministryTypeFilter,
      organizationId: orgId,
      regionId: regId,
      districtId: distId,
      areaId: arId,
    );
  }

  Future<void> add(MinistryFinance tx) async {
    await LocalDb.saveMinistryFinance(tx);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteMinistryFinance(id);
    _load();
  }

  void refresh() => _load();
}

final ministryFinanceProvider =
    StateNotifierProvider<MinistryFinanceNotifier, List<MinistryFinance>>(
        (ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;

  String? branchFilter;
  String? typeFilter;
  String? orgId, regId, distId, arId;

  // Multi-tenant hierarchical filtering
  if (user?.role == AppRoles.nationalAdmin ||
      user?.role == AppRoles.nationalExecutive ||
      user?.role == AppRoles.superSystemAdmin) {
    orgId = user?.organizationId;
  } else if (user?.role == AppRoles.regionalAdmin ||
      user?.role == AppRoles.regionalBishop) {
    orgId = user?.organizationId;
    regId = user?.regionId;
  } else if (user?.role == AppRoles.districtAdmin ||
      user?.role == AppRoles.districtPastor) {
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
  } else if (user?.role == AppRoles.areaAdmin) {
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
    arId = user?.areaId;
  } else {
    // Local church level — branch scoped
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
    arId = user?.areaId;
    branchFilter =
        (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  }

  // Ministry-specific heads see only their ministry type
  if (user?.role == AppRoles.youthMinistryHead) {
    typeFilter = MinistryType.youth;
  } else if (user?.role == AppRoles.menFellowshipHead) {
    typeFilter = MinistryType.menFellowship;
  } else if (user?.role == AppRoles.womenFellowshipHead) {
    typeFilter = MinistryType.womenFellowship;
  } else if (user?.role == AppRoles.childrenMinistryHead) {
    typeFilter = MinistryType.children;
  }

  return MinistryFinanceNotifier(churchId,
      branchFilter: branchFilter,
      ministryTypeFilter: typeFilter,
      orgId: orgId,
      regId: regId,
      distId: distId,
      arId: arId);
});

// ── Ministry Announcements ───────────────────────────────────────────────────

class MinistryAnnouncementNotifier
    extends StateNotifier<List<MinistryAnnouncement>> {
  final String churchId;
  final String? branchFilter;
  final String? ministryTypeFilter;
  final String? memberIdFilter;
  final String? orgId, regId, distId, arId;

  MinistryAnnouncementNotifier(
    this.churchId, {
    this.branchFilter,
    this.ministryTypeFilter,
    this.memberIdFilter,
    this.orgId,
    this.regId,
    this.distId,
    this.arId,
  }) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllMinistryAnnouncements(
      churchId: churchId,
      branchId: branchFilter,
      ministryType: ministryTypeFilter,
      memberId: memberIdFilter,
      organizationId: orgId,
      regionId: regId,
      districtId: distId,
      areaId: arId,
    );
  }

  Future<void> add(MinistryAnnouncement ann) async {
    await LocalDb.saveMinistryAnnouncement(ann);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteMinistryAnnouncement(id);
    _load();
  }

  void refresh() => _load();
}

final ministryAnnouncementProvider = StateNotifierProvider<
    MinistryAnnouncementNotifier, List<MinistryAnnouncement>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;

  String? branchFilter;
  String? typeFilter;
  String? orgId, regId, distId, arId;

  if (user?.role == AppRoles.nationalAdmin ||
      user?.role == AppRoles.nationalExecutive ||
      user?.role == AppRoles.superSystemAdmin) {
    orgId = user?.organizationId;
  } else if (user?.role == AppRoles.regionalAdmin ||
      user?.role == AppRoles.regionalBishop) {
    orgId = user?.organizationId;
    regId = user?.regionId;
  } else if (user?.role == AppRoles.districtAdmin ||
      user?.role == AppRoles.districtPastor) {
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
  } else if (user?.role == AppRoles.areaAdmin) {
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
    arId = user?.areaId;
  } else {
    orgId = user?.organizationId;
    regId = user?.regionId;
    distId = user?.districtId;
    arId = user?.areaId;
    branchFilter =
        (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  }

  if (user?.role == AppRoles.youthMinistryHead) {
    typeFilter = MinistryType.youth;
  } else if (user?.role == AppRoles.menFellowshipHead) {
    typeFilter = MinistryType.menFellowship;
  } else if (user?.role == AppRoles.womenFellowshipHead) {
    typeFilter = MinistryType.womenFellowship;
  } else if (user?.role == AppRoles.childrenMinistryHead) {
    typeFilter = MinistryType.children;
  }

  return MinistryAnnouncementNotifier(churchId,
      branchFilter: branchFilter,
      ministryTypeFilter: typeFilter,
      orgId: orgId,
      regId: regId,
      distId: distId,
      arId: arId);
});

// ── Ministry Auto-Assignment by Age/Gender ───────────────────────────────────

class MinistryAssignment {
  static String? getMinistryTypeForMember(Member member) {
    final dob = member.dateOfBirth;
    if (dob == null) return null;

    final age = DateTime.now().difference(dob).inDays ~/ 365;
    final isMale = member.gender.toLowerCase() == 'male';

    if (age < 13) {
      return MinistryType.children;
    } else if (age >= 13 && age <= 45) {
      return MinistryType.youth;
    } else {
      // Above 45
      return isMale ? MinistryType.menFellowship : MinistryType.womenFellowship;
    }
  }

  static int getAge(Member member) {
    if (member.dateOfBirth == null) return 0;
    return DateTime.now().difference(member.dateOfBirth!).inDays ~/ 365;
  }

  static List<Member> getMembersForMinistry(
      List<Member> allMembers, String ministryType) {
    return allMembers.where((m) {
      if (m.dateOfBirth == null) return false;
      final type = getMinistryTypeForMember(m);
      return type == ministryType;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

// ── Member Contributions ──────────────────────────────────────────────────────

class ContributionNotifier extends StateNotifier<List<MemberContribution>> {
  final String churchId;
  final String? branchFilter;
  final String? memberIdFilter;

  ContributionNotifier(this.churchId, this.branchFilter, this.memberIdFilter)
      : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllContributions(
      churchId: churchId,
      branchId: branchFilter,
      memberId: memberIdFilter,
    );
  }

  Future<void> add(MemberContribution c) async {
    await LocalDb.saveContribution(c);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteContribution(id);
    _load();
  }

  void refresh() => _load();
}

final contributionProvider =
    StateNotifierProvider<ContributionNotifier, List<MemberContribution>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  final branchFilter =
      (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  return ContributionNotifier(churchId, branchFilter, null);
});

final myContributionProvider =
    StateNotifierProvider<ContributionNotifier, List<MemberContribution>>((ref) {
  final appState = ref.watch(appStateProvider);
  return ContributionNotifier(
      appState.church?.id ?? '', appState.user?.branchId, appState.user?.id);
});

// ── Benefit Requests ──────────────────────────────────────────────────────────

class BenefitRequestNotifier extends StateNotifier<List<BenefitRequest>> {
  final String churchId;
  final String? branchFilter;
  final String? memberIdFilter;

  BenefitRequestNotifier(this.churchId, this.branchFilter, this.memberIdFilter)
      : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllBenefitRequests(
      churchId: churchId,
      branchId: branchFilter,
      memberId: memberIdFilter,
    );
  }

  Future<void> add(BenefitRequest r) async {
    await LocalDb.saveBenefitRequest(r);
    _load();
  }

  Future<void> update(BenefitRequest r) async {
    await LocalDb.saveBenefitRequest(r);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteBenefitRequest(id);
    _load();
  }

  void refresh() => _load();
}

final benefitRequestProvider =
    StateNotifierProvider<BenefitRequestNotifier, List<BenefitRequest>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  final branchFilter = (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  return BenefitRequestNotifier(churchId, branchFilter, null);
});

final myBenefitRequestProvider =
    StateNotifierProvider<BenefitRequestNotifier, List<BenefitRequest>>((ref) {
  final appState = ref.watch(appStateProvider);
  return BenefitRequestNotifier(
      appState.church?.id ?? '', appState.user?.branchId, appState.user?.id);
});

// ── Budgets ───────────────────────────────────────────────────────────────────

class BudgetNotifier extends StateNotifier<List<Budget>> {
  final String churchId;
  final String? branchFilter;

  BudgetNotifier(this.churchId, this.branchFilter) : super([]) {
    _load();
  }

  void _load() {
    state = LocalDb.getAllBudgets(churchId: churchId, branchId: branchFilter);
  }

  Future<void> add(Budget b) async {
    await LocalDb.saveBudget(b);
    _load();
  }

  Future<void> update(Budget b) async {
    await LocalDb.saveBudget(b);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteBudget(id);
    _load();
  }

  void refresh() => _load();
}

final budgetProvider =
    StateNotifierProvider<BudgetNotifier, List<Budget>>((ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  final branchFilter =
      (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  return BudgetNotifier(churchId, branchFilter);
});

// ── Finance Approvals ─────────────────────────────────────────────────────────

class FinanceApprovalNotifier
    extends StateNotifier<List<FinanceApprovalRequest>> {
  final String churchId;
  final String? branchFilter;
  final bool crossChurch;

  FinanceApprovalNotifier(this.churchId, this.branchFilter,
      {this.crossChurch = false})
      : super([]) {
    _load();
  }

  void _load() {
    state = crossChurch
        ? LocalDb.getAllFinanceApprovalsAcrossChurches()
        : LocalDb.getAllFinanceApprovals(
            churchId: churchId, branchId: branchFilter);
  }

  Future<void> add(FinanceApprovalRequest r) async {
    await LocalDb.saveFinanceApproval(r);
    _load();
  }

  Future<void> approve(FinanceApprovalRequest r, String approverId, String approverName) async {
    final updated = r.copyWith(
      status: FinanceApprovalStatus.approved,
      approverId: approverId,
      approverName: approverName,
      decidedAt: DateTime.now(),
    );
    await LocalDb.saveFinanceApproval(updated);
    _load();
  }

  Future<void> reject(FinanceApprovalRequest r, String approverId, String approverName, String reason) async {
    final updated = r.copyWith(
      status: FinanceApprovalStatus.rejected,
      approverId: approverId,
      approverName: approverName,
      rejectionReason: reason,
      decidedAt: DateTime.now(),
    );
    await LocalDb.saveFinanceApproval(updated);
    _load();
  }

  Future<void> delete(String id) async {
    await LocalDb.deleteFinanceApproval(id);
    _load();
  }

  void refresh() => _load();
}

final financeApprovalProvider =
    StateNotifierProvider<FinanceApprovalNotifier, List<FinanceApprovalRequest>>(
        (ref) {
  final appState = ref.watch(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final user = appState.user;
  final branchFilter =
      (user?.branchId.isNotEmpty ?? false) ? user?.branchId : null;
  return FinanceApprovalNotifier(churchId, branchFilter,
      crossChurch: _isCrossChurchRole(user?.role));
});

// ── Notifications ─────────────────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  final String churchId;
  final String userId;

  NotificationNotifier(this.churchId, this.userId) : super([]) {
    _load();
  }

  void _load() {
    if (churchId.isEmpty || userId.isEmpty) return;
    state = LocalDb.getNotifications(churchId: churchId, userId: userId);
  }

  Future<void> add(AppNotification notification) async {
    await LocalDb.saveNotification(notification);
    _load();
  }

  Future<void> markRead(String notificationId) async {
    await LocalDb.markNotificationRead(notificationId, churchId: churchId, userId: userId);
    _load();
  }

  Future<void> markAllRead() async {
    await LocalDb.markAllNotificationsRead(churchId: churchId, userId: userId);
    _load();
  }

  Future<void> delete(String notificationId) async {
    await LocalDb.deleteNotification(notificationId, churchId: churchId);
    _load();
  }

  void refresh() => _load();

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  final appState = ref.watch(appStateProvider);
  return NotificationNotifier(
    appState.church?.id ?? '',
    appState.user?.id ?? '',
  );
});

/// Generates notifications from existing app data (approvals, events, welfare, etc.)
/// and saves any new ones that don't already exist.
Future<void> generateAutoNotifications(WidgetRef ref) async {
  final appState = ref.read(appStateProvider);
  final churchId = appState.church?.id ?? '';
  final userId = appState.user?.id ?? '';
  if (churchId.isEmpty || userId.isEmpty) return;

  final existing = ref.read(notificationProvider);
  final existingKeys = existing.map((n) => '${n.type}:${n.title}').toSet();

  final notifs = <AppNotification>[];

  // Pending finance approvals
  final approvals = ref.read(financeApprovalProvider);
  final pendingApprovals = approvals.where((a) => a.status == FinanceApprovalStatus.pending).toList();
  if (pendingApprovals.isNotEmpty) {
    final key = '${AppNotification.typeApproval}:Pending Approvals';
    if (!existingKeys.contains(key)) {
      notifs.add(AppNotification(
        id: _uuid.v4(),
        churchId: churchId,
        userId: userId,
        title: 'Pending Approvals',
        body: '${pendingApprovals.length} finance approval(s) awaiting your review',
        type: AppNotification.typeApproval,
        route: '/finance/approvals',
        createdAt: DateTime.now(),
      ));
    }
  }

  // Upcoming events (next 7 days)
  final events = ref.read(eventProvider);
  final now = DateTime.now();
  final upcoming = events.where((e) {
    return e.startDate.isAfter(now) && e.startDate.isBefore(now.add(const Duration(days: 7)));
  }).toList();
  if (upcoming.isNotEmpty) {
    final key = '${AppNotification.typeEvent}:Upcoming Events';
    if (!existingKeys.contains(key)) {
      notifs.add(AppNotification(
        id: _uuid.v4(),
        churchId: churchId,
        userId: userId,
        title: 'Upcoming Events',
        body: '${upcoming.length} event(s) in the next 7 days',
        type: AppNotification.typeEvent,
        route: '/events',
        createdAt: DateTime.now(),
      ));
    }
  }

  // Open welfare cases
  final welfareCases = ref.read(welfareProvider);
  final openCases = welfareCases.where((c) => c.status == WelfareStatus.open).toList();
  if (openCases.isNotEmpty) {
    final key = '${AppNotification.typeWelfare}:Open Welfare Cases';
    if (!existingKeys.contains(key)) {
      notifs.add(AppNotification(
        id: _uuid.v4(),
        churchId: churchId,
        userId: userId,
        title: 'Open Welfare Cases',
        body: '${openCases.length} welfare case(s) need attention',
        type: AppNotification.typeWelfare,
        route: '/welfare',
        createdAt: DateTime.now(),
      ));
    }
  }

  // Pending welfare cases
  final pendingCases = welfareCases.where((c) => c.status == WelfareStatus.pending).toList();
  if (pendingCases.isNotEmpty) {
    final key = '${AppNotification.typeWelfare}:Pending Welfare Cases';
    if (!existingKeys.contains(key)) {
      notifs.add(AppNotification(
        id: _uuid.v4(),
        churchId: churchId,
        userId: userId,
        title: 'Pending Welfare Cases',
        body: '${pendingCases.length} welfare case(s) pending review',
        type: AppNotification.typeWelfare,
        route: '/welfare',
        createdAt: DateTime.now(),
      ));
    }
  }

  // New members this month
  final members = ref.read(memberProvider);
  final newMembers = members.where((m) =>
      m.membershipDate.month == now.month && m.membershipDate.year == now.year).length;
  if (newMembers > 0) {
    final key = '${AppNotification.typeMember}:New Members This Month';
    if (!existingKeys.contains(key)) {
      notifs.add(AppNotification(
        id: _uuid.v4(),
        churchId: churchId,
        userId: userId,
        title: 'New Members This Month',
        body: '$newMembers new member(s) joined this month',
        type: AppNotification.typeMember,
        route: '/members',
        createdAt: DateTime.now(),
      ));
    }
  }

  // Save all new notifications
  for (final n in notifs) {
    await ref.read(notificationProvider.notifier).add(n);
  }
}
