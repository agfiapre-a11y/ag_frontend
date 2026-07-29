import '../core/constants.dart';
import 'auth_service.dart';
import 'local_db.dart';
import 'tenant_context.dart';

/// Seeds one test user per role so every dashboard can be tested.
///
/// All users share the password [defaultPassword] and use the email
/// pattern `<roleKey>@test.com` (e.g. `seniorPastor@test.com`).
class SeedRoleUsers {
  static const String defaultPassword = 'password123';

  /// All roles that should get a dedicated test login, in dashboard order.
  static const List<String> roles = [
    // System Level
    AppRoles.superSystemAdmin,
    AppRoles.nationalAdmin,
    AppRoles.nationalExecutive,
    // Regional Level
    AppRoles.regionalAdmin,
    AppRoles.regionalBishop,
    // District Level
    AppRoles.districtAdmin,
    AppRoles.districtPastor,
    // Area Level
    AppRoles.areaAdmin,
    // Local Church Level
    AppRoles.localChurchAdmin,
    AppRoles.seniorPastor,
    AppRoles.associatePastor,
    AppRoles.churchSecretary,
    AppRoles.financeOfficer,
    AppRoles.ministryHead,
    AppRoles.youthMinistryHead,
    AppRoles.menFellowshipHead,
    AppRoles.womenFellowshipHead,
    AppRoles.childrenMinistryHead,
    AppRoles.welfareHead,
    // Member Level
    AppRoles.cellLeader,
    AppRoles.volunteer,
    AppRoles.member,
    AppRoles.guest,
  ];

  /// Above-church roles — seeded only once (system-level), not per church.
  static const List<String> aboveChurchRoles = [
    AppRoles.superSystemAdmin,
    AppRoles.nationalAdmin,
    AppRoles.nationalExecutive,
    AppRoles.regionalAdmin,
    AppRoles.regionalBishop,
    AppRoles.districtAdmin,
    AppRoles.districtPastor,
    AppRoles.areaAdmin,
  ];

  /// Church-scoped roles — seeded per church with church-specific emails.
  static const List<String> churchScopedRoles = [
    AppRoles.localChurchAdmin,
    AppRoles.seniorPastor,
    AppRoles.associatePastor,
    AppRoles.churchSecretary,
    AppRoles.financeOfficer,
    AppRoles.ministryHead,
    AppRoles.youthMinistryHead,
    AppRoles.menFellowshipHead,
    AppRoles.womenFellowshipHead,
    AppRoles.childrenMinistryHead,
    AppRoles.welfareHead,
    AppRoles.cellLeader,
    AppRoles.volunteer,
    AppRoles.member,
    AppRoles.guest,
  ];

  static String emailFor(String role) => '${role.toLowerCase()}@test.com';

  /// Church-specific email so each church has its own set of role users.
  /// e.g. member@paradiseag.org, member@gracetabernacle.org
  static String emailForChurch(String role, String churchEmail) {
    final domain = churchEmail.split('@').lastOrNull ?? 'test.com';
    return '${role.toLowerCase()}@$domain';
  }

  /// Creates a user for every church-scoped role, tied to the given church.
  /// Above-church roles are NOT seeded here — use [seedAboveChurchRoleUsers].
  /// Returns the list of [(email, password, role)] credentials created.
  static Future<List<(String email, String password, String role)>>
      seedAllRoleUsers(String churchId, {String? churchEmail}) async {
    if (!TenantContext.isActive) {
      TenantContext.setActiveChurch(churchId);
    }
    // Attach church-scoped roles to the first available branch/department
    // so their dashboards have context to display.
    final branches = LocalDb.getAllBranches(churchId: churchId);
    final branchId = branches.isNotEmpty ? branches.first.id : '';

    final departments =
        LocalDb.getAllDepartments(churchId: churchId, branchId: branchId);
    final departmentId = departments.isNotEmpty ? departments.first.id : '';

    final credentials = <(String, String, String)>[];

    for (final role in churchScopedRoles) {
      final email = churchEmail != null
          ? emailForChurch(role, churchEmail)
          : emailFor(role);
      credentials.add((email, defaultPassword, role));

      // Skip if a user with this email already exists.
      if (LocalDb.getUserByEmail(email) != null) continue;

      await AuthService.registerUser(
        name: AppRoles.label(role),
        email: email,
        password: defaultPassword,
        phone: '',
        role: role,
        churchId: churchId,
        branchId: _needsBranch(role) ? branchId : '',
        departmentId: _needsDepartment(role) ? departmentId : '',
      );
    }

    return credentials;
  }

  /// Seeds above-church role users once (system-level).
  /// These users are NOT tied to any single church — they have cross-church
  /// access. They are stored in the first church's tenant scope with
  /// churchId='' so the cross-church login can find them.
  /// Each user is linked to the first church's hierarchy (org/region/district/area)
  /// so hierarchical filtering works on their dashboards.
  static Future<List<(String email, String password, String role)>>
      seedAboveChurchRoleUsers() async {
    final churches = LocalDb.getAllChurches();
    if (churches.isEmpty) return [];

    final firstChurch = churches.first;
    TenantContext.setActiveChurch(firstChurch.id);

    // Get hierarchy from the first church for linking
    final orgs = LocalDb.getAllOrganizations();
    final regions = LocalDb.getAllRegions();
    final districts = LocalDb.getAllDistricts();
    final areas = LocalDb.getAllAreas();

    final orgId = orgs.isNotEmpty ? orgs.first.id : null;
    final regionId = regions.isNotEmpty ? regions.first.id : null;
    final districtId = districts.isNotEmpty ? districts.first.id : null;
    final areaId = areas.isNotEmpty ? areas.first.id : null;

    final credentials = <(String, String, String)>[];

    for (final role in aboveChurchRoles) {
      final email = '${role.toLowerCase()}@system.org';
      credentials.add((email, defaultPassword, role));

      await AuthService.registerUser(
        name: AppRoles.label(role),
        email: email,
        password: defaultPassword,
        phone: '',
        role: role,
        churchId: '',  // Not tied to any church
        branchId: '',
        organizationId: orgId,
        regionId: regionId,
        districtId: districtId,
        areaId: areaId,
      );
    }

    return credentials;
  }

  /// Roles operating at the local-church level get a branch assignment.
  static bool _needsBranch(String role) {
    const churchLevel = {
      AppRoles.localChurchAdmin,
      AppRoles.seniorPastor,
      AppRoles.associatePastor,
      AppRoles.churchSecretary,
      AppRoles.financeOfficer,
      AppRoles.ministryHead,
      AppRoles.youthMinistryHead,
      AppRoles.menFellowshipHead,
      AppRoles.womenFellowshipHead,
      AppRoles.childrenMinistryHead,
      AppRoles.welfareHead,
      AppRoles.cellLeader,
      AppRoles.volunteer,
      AppRoles.member,
    };
    return churchLevel.contains(role);
  }

  /// Ministry-facing roles get a department assignment.
  static bool _needsDepartment(String role) {
    const deptLevel = {
      AppRoles.ministryHead,
      AppRoles.youthMinistryHead,
      AppRoles.menFellowshipHead,
      AppRoles.womenFellowshipHead,
      AppRoles.childrenMinistryHead,
      AppRoles.cellLeader,
      AppRoles.volunteer,
    };
    return deptLevel.contains(role);
  }
}
