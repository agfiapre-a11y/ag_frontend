import '../core/constants.dart';

/// Defines a page within a role's dashboard.
class DashboardPageDef {
  final String key;
  final String label;

  const DashboardPageDef({required this.key, required this.label});
}

/// Defines a role's dashboard: the role, its label, and the pages it contains.
class DashboardDef {
  final String key;
  final String label;
  final String role;
  final List<DashboardPageDef> pages;

  const DashboardDef({
    required this.key,
    required this.label,
    required this.role,
    required this.pages,
  });
}

/// Catalog of all role dashboards and their pages.
///
/// Adapted from the SIMS access control model: each role maps to a dashboard
/// with a set of pages. This drives:
/// - Route-level role guards (router checks if user's activeRole can access a route)
/// - Nav item filtering (sidebar shows only pages the user is allowed to see)
/// - Page-level access grants (admins can assign users to specific pages of other dashboards)
class RoleDashboardCatalog {
  /// Map of dashboard key → DashboardDef
  static final Map<String, DashboardDef> dashboardMap = {
    for (final d in catalog) d.key: d,
  };

  /// Map of role → dashboard key
  static final Map<String, String> roleDashboardMap = {
    for (final d in catalog) d.role: d.key,
  };

  /// Get the dashboard key for a role (returns empty string if not found).
  static String dashboardKeyForRole(String role) =>
      roleDashboardMap[role] ?? '';

  /// Get the dashboard def for a role.
  static DashboardDef? dashboardForRole(String role) {
    final key = roleDashboardMap[role];
    if (key == null) return null;
    return dashboardMap[key];
  }

  /// Get all pages for a role's dashboard.
  static List<DashboardPageDef> pagesForRole(String role) {
    final dash = dashboardForRole(role);
    return dash?.pages ?? [];
  }

  /// Check if a role has access to a specific page key.
  static bool roleHasPage(String role, String pageKey) {
    final pages = pagesForRole(role);
    return pages.any((p) => p.key == pageKey);
  }

  /// Get all dashboard keys (for access control assignment UI).
  static List<String> allDashboardKeys() =>
      catalog.map((d) => d.key).toList();

  /// Get all dashboard defs.
  static List<DashboardDef> allDashboards() => catalog;

  /// The full catalog of role dashboards.
  static const catalog = [
    DashboardDef(
      key: 'SuperAdmin',
      label: 'Super System Admin',
      role: AppRoles.superSystemAdmin,
      pages: [
        DashboardPageDef(key: 'overview', label: 'System Overview'),
        DashboardPageDef(key: 'organizations', label: 'Organizations'),
        DashboardPageDef(key: 'regions', label: 'Regions'),
        DashboardPageDef(key: 'districts', label: 'Districts'),
        DashboardPageDef(key: 'areas', label: 'Areas'),
        DashboardPageDef(key: 'churches', label: 'Churches'),
        DashboardPageDef(key: 'users', label: 'User Management'),
        DashboardPageDef(key: 'access', label: 'Access Control'),
        DashboardPageDef(key: 'settings', label: 'System Settings'),
        DashboardPageDef(key: 'sync', label: 'Sync & Data'),
      ],
    ),
    DashboardDef(
      key: 'NationalAdmin',
      label: 'National Admin',
      role: AppRoles.nationalAdmin,
      pages: [
        DashboardPageDef(key: 'overview', label: 'National Overview'),
        DashboardPageDef(key: 'regions', label: 'Regions'),
        DashboardPageDef(key: 'districts', label: 'Districts'),
        DashboardPageDef(key: 'areas', label: 'Areas'),
        DashboardPageDef(key: 'churches', label: 'Churches'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'users', label: 'Users'),
        DashboardPageDef(key: 'finance', label: 'Finance'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
        DashboardPageDef(key: 'access', label: 'Access Control'),
      ],
    ),
    DashboardDef(
      key: 'NationalExecutive',
      label: 'National Executive',
      role: AppRoles.nationalExecutive,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Executive Overview'),
        DashboardPageDef(key: 'regions', label: 'Regions'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
        DashboardPageDef(key: 'approvals', label: 'Approvals'),
      ],
    ),
    DashboardDef(
      key: 'RegionalAdmin',
      label: 'Regional Admin',
      role: AppRoles.regionalAdmin,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Regional Overview'),
        DashboardPageDef(key: 'districts', label: 'Districts'),
        DashboardPageDef(key: 'areas', label: 'Areas'),
        DashboardPageDef(key: 'churches', label: 'Churches'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'users', label: 'Users'),
        DashboardPageDef(key: 'finance', label: 'Finance'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
        DashboardPageDef(key: 'access', label: 'Access Control'),
      ],
    ),
    DashboardDef(
      key: 'RegionalBishop',
      label: 'Regional Bishop',
      role: AppRoles.regionalBishop,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Regional Oversight'),
        DashboardPageDef(key: 'districts', label: 'Districts'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
        DashboardPageDef(key: 'approvals', label: 'Approvals'),
      ],
    ),
    DashboardDef(
      key: 'DistrictAdmin',
      label: 'District Admin',
      role: AppRoles.districtAdmin,
      pages: [
        DashboardPageDef(key: 'overview', label: 'District Overview'),
        DashboardPageDef(key: 'areas', label: 'Areas'),
        DashboardPageDef(key: 'churches', label: 'Churches'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'users', label: 'Users'),
        DashboardPageDef(key: 'finance', label: 'Finance'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
        DashboardPageDef(key: 'access', label: 'Access Control'),
      ],
    ),
    DashboardDef(
      key: 'DistrictPastor',
      label: 'District Pastor',
      role: AppRoles.districtPastor,
      pages: [
        DashboardPageDef(key: 'overview', label: 'District Oversight'),
        DashboardPageDef(key: 'areas', label: 'Areas'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
        DashboardPageDef(key: 'approvals', label: 'Approvals'),
      ],
    ),
    DashboardDef(
      key: 'AreaAdmin',
      label: 'Area Admin',
      role: AppRoles.areaAdmin,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Area Overview'),
        DashboardPageDef(key: 'churches', label: 'Churches'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'users', label: 'Users'),
        DashboardPageDef(key: 'finance', label: 'Finance'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
        DashboardPageDef(key: 'access', label: 'Access Control'),
      ],
    ),
    DashboardDef(
      key: 'ChurchAdmin',
      label: 'Church Admin',
      role: AppRoles.localChurchAdmin,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Church Overview'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'users', label: 'Users'),
        DashboardPageDef(key: 'finance', label: 'Finance'),
        DashboardPageDef(key: 'attendance', label: 'Attendance'),
        DashboardPageDef(key: 'events', label: 'Events'),
        DashboardPageDef(key: 'sermons', label: 'Sermons'),
        DashboardPageDef(key: 'departments', label: 'Departments'),
        DashboardPageDef(key: 'welfare', label: 'Welfare'),
        DashboardPageDef(key: 'library', label: 'Library'),
        DashboardPageDef(key: 'community', label: 'Community'),
        DashboardPageDef(key: 'ministries', label: 'Ministries'),
        DashboardPageDef(key: 'access', label: 'Access Control'),
        DashboardPageDef(key: 'settings', label: 'Settings'),
        DashboardPageDef(key: 'sync', label: 'Sync & Data'),
      ],
    ),
    DashboardDef(
      key: 'SeniorPastor',
      label: 'Senior Pastor',
      role: AppRoles.seniorPastor,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Pastoral Overview'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'finance', label: 'Finance'),
        DashboardPageDef(key: 'attendance', label: 'Attendance'),
        DashboardPageDef(key: 'events', label: 'Events'),
        DashboardPageDef(key: 'sermons', label: 'Sermons'),
        DashboardPageDef(key: 'departments', label: 'Departments'),
        DashboardPageDef(key: 'welfare', label: 'Welfare'),
        DashboardPageDef(key: 'approvals', label: 'Approvals'),
        DashboardPageDef(key: 'library', label: 'Library'),
      ],
    ),
    DashboardDef(
      key: 'AssociatePastor',
      label: 'Associate Pastor',
      role: AppRoles.associatePastor,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Pastoral Overview'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'attendance', label: 'Attendance'),
        DashboardPageDef(key: 'events', label: 'Events'),
        DashboardPageDef(key: 'sermons', label: 'Sermons'),
        DashboardPageDef(key: 'departments', label: 'Departments'),
        DashboardPageDef(key: 'welfare', label: 'Welfare'),
        DashboardPageDef(key: 'library', label: 'Library'),
      ],
    ),
    DashboardDef(
      key: 'ChurchSecretary',
      label: 'Church Secretary',
      role: AppRoles.churchSecretary,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Secretary Overview'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'attendance', label: 'Attendance'),
        DashboardPageDef(key: 'events', label: 'Events'),
        DashboardPageDef(key: 'sermons', label: 'Sermons'),
        DashboardPageDef(key: 'departments', label: 'Departments'),
        DashboardPageDef(key: 'welfare', label: 'Welfare'),
      ],
    ),
    DashboardDef(
      key: 'FinanceOfficer',
      label: 'Finance Officer',
      role: AppRoles.financeOfficer,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Finance Overview'),
        DashboardPageDef(key: 'finance', label: 'Finance'),
        DashboardPageDef(key: 'budgets', label: 'Budgets'),
        DashboardPageDef(key: 'approvals', label: 'Approvals'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
      ],
    ),
    DashboardDef(
      key: 'MinistryHead',
      label: 'Ministry Head',
      role: AppRoles.ministryHead,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Ministry Overview'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'attendance', label: 'Attendance'),
        DashboardPageDef(key: 'events', label: 'Events'),
        DashboardPageDef(key: 'departments', label: 'Departments'),
        DashboardPageDef(key: 'finance', label: 'Ministry Finance'),
        DashboardPageDef(key: 'announcements', label: 'Announcements'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
      ],
    ),
    DashboardDef(
      key: 'WelfareHead',
      label: 'Welfare Head',
      role: AppRoles.welfareHead,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Welfare Overview'),
        DashboardPageDef(key: 'welfare', label: 'Welfare Cases'),
        DashboardPageDef(key: 'finance', label: 'Welfare Finance'),
        DashboardPageDef(key: 'contributions', label: 'Contributions'),
        DashboardPageDef(key: 'reports', label: 'Reports'),
      ],
    ),
    DashboardDef(
      key: 'CellLeader',
      label: 'Cell Leader',
      role: AppRoles.cellLeader,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Cell Overview'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'attendance', label: 'Attendance'),
        DashboardPageDef(key: 'events', label: 'Events'),
      ],
    ),
    DashboardDef(
      key: 'Volunteer',
      label: 'Volunteer',
      role: AppRoles.volunteer,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Volunteer Overview'),
        DashboardPageDef(key: 'members', label: 'Members'),
        DashboardPageDef(key: 'attendance', label: 'Attendance'),
        DashboardPageDef(key: 'events', label: 'Events'),
      ],
    ),
    DashboardDef(
      key: 'Member',
      label: 'Member',
      role: AppRoles.member,
      pages: [
        DashboardPageDef(key: 'overview', label: 'My Overview'),
        DashboardPageDef(key: 'events', label: 'Events'),
        DashboardPageDef(key: 'sermons', label: 'Sermons'),
        DashboardPageDef(key: 'library', label: 'Library'),
        DashboardPageDef(key: 'community', label: 'Community'),
        DashboardPageDef(key: 'welfare', label: 'My Welfare'),
        DashboardPageDef(key: 'contributions', label: 'My Contributions'),
      ],
    ),
    DashboardDef(
      key: 'Guest',
      label: 'Guest',
      role: AppRoles.guest,
      pages: [
        DashboardPageDef(key: 'overview', label: 'Welcome'),
        DashboardPageDef(key: 'events', label: 'Events'),
        DashboardPageDef(key: 'sermons', label: 'Sermons'),
      ],
    ),
  ];
}

/// Human-readable role labels (adapted from SIMS ROLE_LABELS).
class RoleLabels {
  static const Map<String, String> labels = {
    AppRoles.superSystemAdmin: 'Super System Admin',
    AppRoles.nationalAdmin: 'National Admin',
    AppRoles.nationalExecutive: 'National Executive',
    AppRoles.regionalAdmin: 'Regional Admin',
    AppRoles.regionalBishop: 'Regional Bishop',
    AppRoles.districtAdmin: 'District Admin',
    AppRoles.districtPastor: 'District Pastor',
    AppRoles.areaAdmin: 'Area Admin',
    AppRoles.localChurchAdmin: 'Church Admin',
    AppRoles.seniorPastor: 'Senior Pastor',
    AppRoles.associatePastor: 'Associate Pastor',
    AppRoles.churchSecretary: 'Church Secretary',
    AppRoles.financeOfficer: 'Finance Officer',
    AppRoles.ministryHead: 'Ministry Head',
    AppRoles.youthMinistryHead: 'Youth Ministry Head',
    AppRoles.menFellowshipHead: 'Men Fellowship Head',
    AppRoles.womenFellowshipHead: 'Women Fellowship Head',
    AppRoles.childrenMinistryHead: 'Children Ministry Head',
    AppRoles.welfareHead: 'Welfare Head',
    AppRoles.cellLeader: 'Cell Leader',
    AppRoles.volunteer: 'Volunteer',
    AppRoles.member: 'Member',
    AppRoles.guest: 'Guest',
  };

  static String labelFor(String role) => labels[role] ?? role;
}
