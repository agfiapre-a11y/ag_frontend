import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/area.dart';
import '../models/attendance_record.dart';
import '../models/branch.dart';
import '../models/church.dart';
import '../models/department.dart';
import '../models/district.dart';
import '../models/event.dart';
import '../models/member.dart';
import '../models/organization.dart';
import '../models/region.dart';
import '../models/sermon.dart';
import '../models/transaction.dart';
import '../core/constants.dart';
import 'auth_service.dart';
import 'local_db.dart';
import 'tenant_context.dart';

const _uuid = Uuid();

/// Seeds 5 churches, each with its own branches, users, departments, and members.
///
/// Each church is a fully isolated tenant — data is stored under
/// `churchId:box_name` keys via TenantContext, so there is zero cross-church
/// data leakage.
class SeedMultiChurch {
  static const String defaultPassword = 'Password123';

  // No local church templates — churches are created via the backend
  // /tenants endpoint (by a super admin) or pulled from Supabase on login.
  // Local seeding of churches caused conflicts with real Supabase tenants
  // because the local UUID didn't match the Supabase tenant ID.
  static const List<({
    String name,
    String address,
    String phone,
    String email,
    String adminName,
    String adminEmail,
  })> churchTemplates = [];

  /// Removes all locally-seeded churches that are not in [churchTemplates].
  /// Called on every app startup (before the has_seeded check) to clean up
  /// stale churches from previous seeding runs that conflict with real
  /// Supabase tenants.
  ///
  /// With [churchTemplates] now empty, this deletes ALL locally-seeded
  /// churches so the app relies on real Supabase tenants created via the
  /// backend /tenants endpoint (or pulled on login).
  static Future<void> cleanupStaleChurches() async {
    final existing = LocalDb.getAllChurches();
    if (existing.isEmpty) return;

    final templateNames = churchTemplates.map((t) => t.name).toSet();

    // Find a fallback church (one that IS in the templates) to switch to
    // after deleting stale ones.
    String? fallbackId;
    for (final church in existing) {
      if (templateNames.contains(church.name)) {
        fallbackId = church.id;
        break;
      }
    }

    for (final church in existing) {
      if (!templateNames.contains(church.name)) {
        debugPrint('[cleanupStaleChurches] Removing stale local church: '
            '${church.name} (${church.id})');
        await LocalDb.deleteChurchData(church.id, fallbackChurchId: fallbackId);
      }
    }
  }

  /// Seeds the church(es) defined in [churchTemplates] if they don't
  /// already exist. Also cleans up any churches from previous seeding
  /// runs that are no longer in [churchTemplates].
  /// Returns the list of created church IDs.
  static Future<List<String>> seedAllChurches() async {
    final existing = LocalDb.getAllChurches();
    var existingNames = existing.map((c) => c.name).toSet();
    final templateNames = churchTemplates.map((t) => t.name).toSet();

    // Clean up churches from previous seeding that are no longer in
    // the templates list (e.g. when churches were removed from the list).
    // Keep the first template church as fallback for active church.
    final fallbackName = churchTemplates.isNotEmpty
        ? churchTemplates.first.name
        : null;
    String? fallbackId;
    for (final church in existing) {
      if (!templateNames.contains(church.name)) {
        // Find the fallback church ID (Paradise AG) before deleting
        if (fallbackId == null && church.name == fallbackName) {
          fallbackId = church.id;
          continue;
        }
        debugPrint('[seedAllChurches] Removing stale church: ${church.name}');
        await LocalDb.deleteChurchData(church.id, fallbackChurchId: fallbackId);
      } else if (fallbackId == null && church.name == fallbackName) {
        fallbackId = church.id;
      }
    }

    // Reload existing after cleanup
    existing.clear();
    existing.addAll(LocalDb.getAllChurches());
    existingNames = existing.map((c) => c.name).toSet();

    final createdIds = <String>[];

    for (final template in churchTemplates) {
      if (existingNames.contains(template.name)) continue;

      final churchId = _uuid.v4();
      final adminId = _uuid.v4();
      final now = DateTime.now();

      // 1. Create the church
      final church = Church(
        id: churchId,
        name: template.name,
        adminId: adminId,
        address: template.address,
        phone: template.phone,
        email: template.email,
        createdAt: now,
      );

      // Set tenant context before saving any church-scoped data
      TenantContext.setActiveChurch(churchId);
      await LocalDb.saveChurch(church);

      // 2. Create local church admin for this church (church-scoped)
      final admin = AppUser(
        id: adminId,
        name: template.adminName,
        email: template.adminEmail.toLowerCase().trim(),
        passwordHash: AuthService.hashPassword('Admin1234'),
        roles: [AppRoles.localChurchAdmin], activeRole: AppRoles.localChurchAdmin,
        churchId: churchId,
        branchId: '',
        phone: template.phone,
        createdAt: now,
      );
      await LocalDb.saveUser(admin);

      // 3. Seed branches for this church
      final branchIds = await _seedBranches(churchId, template);

      // 4. Seed departments for this church
      await _seedDepartments(churchId, branchIds);

      // 5. Seed members for this church
      await _seedMembers(churchId, branchIds);

      // 6. Seed a pastor for the first branch
      await _seedPastor(churchId, branchIds[0], template);

      // 7. Seed hierarchy: organization, region, district, area
      final hierarchyIds = await _seedHierarchy(churchId, adminId, template);

      // 8. Link members to hierarchy
      await _linkMembersToHierarchy(churchId, hierarchyIds);

      // 9. Seed finance transactions
      await _seedFinance(churchId, branchIds);

      // 10. Seed events
      await _seedEvents(churchId, branchIds);

      // 11. Seed sermons
      await _seedSermons(churchId, branchIds);

      // 12. Seed attendance records
      await _seedAttendance(churchId, branchIds);

      createdIds.add(churchId);
    }

    // Set active church back to the first one
    if (createdIds.isNotEmpty) {
      await LocalDb.setActiveChurch(createdIds.first);
    } else if (existing.isNotEmpty) {
      await LocalDb.setActiveChurch(existing.first.id);
    }

    // Seed a system-level superSystemAdmin (not tied to any single church)
    await _seedSystemAdmin();

    return createdIds;
  }

  static Future<List<String>> _seedBranches(
    String churchId,
    ({String name, String address, String phone, String email, String adminName, String adminEmail}) template,
  ) async {
    final branchNames = [
      'Main Branch',
      'North Campus',
      'South Campus',
    ];

    final branchIds = <String>[];
    for (int i = 0; i < branchNames.length; i++) {
      final branchId = _uuid.v4();
      branchIds.add(branchId);
      await LocalDb.saveBranch(Branch(
        id: branchId,
        churchId: churchId,
        name: '${branchNames[i]} - ${template.address.split(',').first}',
        location: template.address,
        pastorId: '',
        createdAt: DateTime.now().subtract(Duration(days: 365 - i * 60)),
      ));
    }
    return branchIds;
  }

  static Future<void> _seedDepartments(String churchId, List<String> branchIds) async {
    final deptTemplates = [
      ('Choir', 'Music ministry', 0),
      ('Ushers', 'Hospitality team', 0),
      ('Youth Ministry', 'Young adults fellowship', 1),
      ('Children Ministry', 'Kids church', 0),
      ('Evangelism', 'Outreach team', 2),
    ];

    for (final (name, desc, branchIndex) in deptTemplates) {
      final branchId = branchIds[branchIndex % branchIds.length];
      await LocalDb.saveDepartment(Department(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branchId,
        name: name,
        description: desc,
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ));
    }
  }

  static Future<void> _seedMembers(String churchId, List<String> branchIds) async {
    // Each church gets 15-20 members spread across branches
    final memberTemplates = [
      ('Kwame Asante', 'Male', 0),
      ('Abena Mensah', 'Female', 0),
      ('Kojo Ofori', 'Male', 0),
      ('Akua Frempong', 'Female', 0),
      ('Kofi Annan', 'Male', 0),
      ('Ama Boateng', 'Female', 0),
      ('Emmanuel Agyeman', 'Male', 0),
      ('Grace Osei', 'Female', 0),
      ('Yaw Adjei', 'Male', 1),
      ('Efua Kwarteng', 'Female', 1),
      ('Kwabena Darko', 'Male', 1),
      ('Yaa Owusu', 'Female', 1),
      ('Ibrahim Mohammed', 'Male', 2),
      ('Fatima Alhassan', 'Female', 2),
      ('Daniel Addo', 'Male', 2),
      ('Sarah Owusu', 'Female', 2),
    ];

    for (final (name, gender, branchIndex) in memberTemplates) {
      final branchId = branchIds[branchIndex % branchIds.length];
      final member = Member(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branchId,
        departmentId: '',
        name: name,
        email: '${name.toLowerCase().replaceAll(' ', '.')}@gmail.com',
        phone: '+233 2${_randomDigits(8)}',
        address: 'P.O. Box ${_randomDigits(4)}, Ghana',
        gender: gender,
        dateOfBirth: DateTime(1980 + _randomNumber(18, 45), _randomNumber(1, 12), _randomNumber(1, 28)),
        membershipDate: DateTime.now().subtract(Duration(days: _randomNumber(30, 365))),
        isActive: true,
      );
      await LocalDb.saveMember(member);
    }
  }

  static Future<void> _seedPastor(
    String churchId,
    String branchId,
    ({String name, String address, String phone, String email, String adminName, String adminEmail}) template,
  ) async {
    final pastorName = 'Rev. ${template.adminName.replaceAll(' Admin', '')}';
    final pastor = AppUser(
      id: _uuid.v4(),
      name: pastorName,
      email: 'pastor@${template.email.split('@').last}',
      passwordHash: AuthService.hashPassword(defaultPassword),
      roles: [AppRoles.seniorPastor], activeRole: AppRoles.seniorPastor,
      churchId: churchId,
      branchId: branchId,
      phone: template.phone,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );
    await LocalDb.saveUser(pastor);
  }

  // ── System Admin Seeding ───────────────────────────────────────────────────

  /// Seeds a system-level superSystemAdmin that is NOT tied to any single church.
  /// This user has cross-church access to all churches.
  /// Stored in the first church's user box with churchId='' to be findable
  /// by the cross-church login, but the login flow will recognize the
  /// above-church role and not restrict to one tenant.
  static Future<void> _seedSystemAdmin() async {
    final email = 'sysadmin@paradiseag.org';
    // Check if already exists
    final existing = await LocalDb.getUserByEmailAcrossChurches(email);
    if (existing != null) return;

    final churches = LocalDb.getAllChurches();
    if (churches.isEmpty) return;

    // Store in first church's tenant scope so cross-church login can find it
    TenantContext.setActiveChurch(churches.first.id);

    final sysAdmin = AppUser(
      id: _uuid.v4(),
      name: 'System Administrator',
      email: email,
      passwordHash: AuthService.hashPassword('Admin1234'),
      roles: [AppRoles.superSystemAdmin], activeRole: AppRoles.superSystemAdmin,
      churchId: '',  // Not tied to any church
      branchId: '',
      phone: '+233 30 000 0000',
      createdAt: DateTime.now(),
    );
    await LocalDb.saveUser(sysAdmin);
  }

  // ── Hierarchy Seeding ──────────────────────────────────────────────────────

  static Future<({
    String organizationId,
    String regionId,
    String districtId,
    String areaId,
  })> _seedHierarchy(
    String churchId,
    String adminId,
    ({String name, String address, String phone, String email, String adminName, String adminEmail}) template,
  ) async {
    final now = DateTime.now();

    final orgId = _uuid.v4();
    final org = Organization(
      id: orgId,
      name: '${template.name} National Office',
      description: 'National headquarters for ${template.name}',
      adminId: adminId,
      address: template.address,
      phone: template.phone,
      email: template.email,
      website: 'www.${template.email.split('@').last}',
      createdAt: now.subtract(const Duration(days: 730)),
    );
    await LocalDb.saveOrganization(org);

    final regionId = _uuid.v4();
    final regionName = template.address.split(',').last.trim();
    final region = Region(
      id: regionId,
      name: '$regionName Region',
      organizationId: orgId,
      adminId: adminId,
      description: 'Regional oversight for $regionName',
      address: template.address,
      phone: template.phone,
      email: 'region.${template.email}',
      createdAt: now.subtract(const Duration(days: 600)),
    );
    await LocalDb.saveRegion(region);

    final districtId = _uuid.v4();
    final districtName = template.address.split(',').first.trim();
    final district = District(
      id: districtId,
      name: '$districtName District',
      regionId: regionId,
      adminId: adminId,
      description: 'District covering $districtName area',
      address: template.address,
      phone: template.phone,
      email: 'district.${template.email}',
      createdAt: now.subtract(const Duration(days: 480)),
    );
    await LocalDb.saveDistrict(district);

    final areaId = _uuid.v4();
    final area = Area(
      id: areaId,
      name: '$districtName Area',
      districtId: districtId,
      adminId: adminId,
      description: 'Local area covering $districtName',
      address: template.address,
      phone: template.phone,
      email: 'area.${template.email}',
      createdAt: now.subtract(const Duration(days: 360)),
    );
    await LocalDb.saveArea(area);

    return (
      organizationId: orgId,
      regionId: regionId,
      districtId: districtId,
      areaId: areaId,
    );
  }

  static Future<void> _linkMembersToHierarchy(
    String churchId,
    ({String organizationId, String regionId, String districtId, String areaId}) hierarchyIds,
  ) async {
    final members = LocalDb.getAllMembers(churchId: churchId);
    for (final member in members) {
      final updated = member.copyWith(
        organizationId: hierarchyIds.organizationId,
        regionId: hierarchyIds.regionId,
        districtId: hierarchyIds.districtId,
        areaId: hierarchyIds.areaId,
      );
      await LocalDb.saveMember(updated);
    }
  }

  // ── Finance Seeding ─────────────────────────────────────────────────────────

  static Future<void> _seedFinance(String churchId, List<String> branchIds) async {
    final now = DateTime.now();
    final incomes = [
      ('Tithe', 2500.0), ('Offering', 1200.0), ('Donation', 800.0),
      ('Fundraising', 3500.0), ('Tithe', 1800.0), ('Offering', 950.0),
      ('Donation', 600.0), ('Tithe', 3100.0),
    ];
    final expenses = [
      ('Salary', 2000.0), ('Utilities', 450.0), ('Rent', 1200.0),
      ('Maintenance', 350.0), ('Events', 800.0), ('Welfare', 500.0),
      ('Missions', 700.0),
    ];

    for (int i = 0; i < incomes.length; i++) {
      final (cat, amt) = incomes[i];
      await LocalDb.saveTransaction(FinanceTransaction(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branchIds[i % branchIds.length],
        type: TransactionType.income,
        category: cat,
        amount: amt,
        description: '$cat for ${now.subtract(Duration(days: i * 7)).month} month',
        date: now.subtract(Duration(days: i * 7)),
        recordedById: '',
        createdAt: now.subtract(Duration(days: i * 7)),
      ));
    }

    for (int i = 0; i < expenses.length; i++) {
      final (cat, amt) = expenses[i];
      await LocalDb.saveTransaction(FinanceTransaction(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branchIds[i % branchIds.length],
        type: TransactionType.expense,
        category: cat,
        amount: amt,
        description: '$cat expense',
        date: now.subtract(Duration(days: i * 5 + 3)),
        recordedById: '',
        createdAt: now.subtract(Duration(days: i * 5 + 3)),
      ));
    }
  }

  // ── Events Seeding ──────────────────────────────────────────────────────────

  static Future<void> _seedEvents(String churchId, List<String> branchIds) async {
    final now = DateTime.now();
    final eventTemplates = [
      ('Sunday Service', 'Weekly worship service', 'Service', 'Main Sanctuary'),
      ('Prayer Meeting', 'Midweek prayer gathering', 'Prayer', 'Chapel'),
      ('Youth Night', 'Youth fellowship night', 'Youth', 'Youth Hall'),
      ('Bible Study', 'Weekly Bible study', 'Study', 'Fellowship Hall'),
      ('Outreach Day', 'Community evangelism', 'Outreach', 'Community Center'),
    ];

    for (int i = 0; i < eventTemplates.length; i++) {
      final (title, desc, cat, loc) = eventTemplates[i];
      final startDate = now.add(Duration(days: i * 7 + 1));
      await LocalDb.saveEvent(ChurchEvent(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branchIds[i % branchIds.length],
        title: title,
        description: desc,
        category: cat,
        location: loc,
        organizer: 'Church Administration',
        startDate: startDate,
        endDate: startDate.add(const Duration(hours: 2)),
        isAllDay: false,
        recordedById: '',
        createdAt: now,
      ));
    }
  }

  // ── Sermons Seeding ─────────────────────────────────────────────────────────

  static Future<void> _seedSermons(String churchId, List<String> branchIds) async {
    final now = DateTime.now();
    final sermonTemplates = [
      ('Walking by Faith', 'Rev. Samuel Owusu', 'Faith Series', '2 Corinthians 5:7'),
      ('The Power of Prayer', 'Rev. Samuel Owusu', 'Prayer Series', 'Matthew 7:7'),
      ('Living in Grace', 'Rev. Samuel Owusu', 'Grace Series', 'Ephesians 2:8'),
      ('Hope in Christ', 'Rev. Samuel Owusu', 'Hope Series', 'Romans 15:13'),
    ];

    for (int i = 0; i < sermonTemplates.length; i++) {
      final (title, speaker, series, scripture) = sermonTemplates[i];
      await LocalDb.saveSermon(Sermon(
        id: _uuid.v4(),
        churchId: churchId,
        branchId: branchIds[0],
        title: title,
        speaker: speaker,
        series: series,
        scriptureReference: scripture,
        notes: 'Sermon on $title',
        audioUrl: '',
        videoUrl: '',
        serviceType: 'Sunday Service',
        date: now.subtract(Duration(days: i * 7)),
        recordedById: '',
        createdAt: now.subtract(Duration(days: i * 7)),
      ));
    }
  }

  // ── Attendance Seeding ─────────────────────────────────────────────────────

  static Future<void> _seedAttendance(String churchId, List<String> branchIds) async {
    final members = LocalDb.getAllMembers(churchId: churchId);
    if (members.isEmpty) return;

    final now = DateTime.now();

    for (int i = 0; i < 4; i++) {
      final date = now.subtract(Duration(days: (i * 7) + (now.weekday - DateTime.sunday)));

      for (int b = 0; b < branchIds.length; b++) {
        final branchMembers = members
            .where((m) => m.branchId == branchIds[b])
            .toList();
        if (branchMembers.isEmpty) continue;

        final presentCount = _randomNumber(
            branchMembers.length ~/ 2, branchMembers.length);
        final presentIds = branchMembers
            .take(presentCount)
            .map((m) => m.id)
            .toList();

        await LocalDb.saveAttendanceRecord(AttendanceRecord(
          id: _uuid.v4(),
          churchId: churchId,
          branchId: branchIds[b],
          serviceType: ServiceTypes.sundayService,
          date: date,
          presentMemberIds: presentIds,
          recordedById: '',
          createdAt: date,
        ));
      }
    }
  }

  static int _randomNumber(int min, int max) {
    return min + (DateTime.now().microsecondsSinceEpoch % (max - min + 1));
  }

  static String _randomDigits(int count) {
    return List.generate(count, (_) => _randomNumber(0, 9).toString()).join();
  }
}
