import '../core/constants.dart';

class PermissionService {
  // Role hierarchy levels (higher number = higher authority)
  static const Map<String, int> roleHierarchy = {
    AppRoles.superSystemAdmin: 18,
    AppRoles.nationalAdmin: 17,
    AppRoles.nationalExecutive: 16,
    AppRoles.regionalAdmin: 15,
    AppRoles.regionalBishop: 14,
    AppRoles.districtAdmin: 13,
    AppRoles.districtPastor: 12,
    AppRoles.areaAdmin: 11,
    AppRoles.localChurchAdmin: 10,
    AppRoles.seniorPastor: 9,
    AppRoles.associatePastor: 8,
    AppRoles.churchSecretary: 7,
    AppRoles.financeOfficer: 6,
    AppRoles.ministryHead: 5,
    AppRoles.welfareHead: 5,
    AppRoles.cellLeader: 4,
    AppRoles.volunteer: 3,
    AppRoles.member: 2,
    AppRoles.guest: 1,
  };

  // Permission types
  static const String read = 'read';
  static const String write = 'write';
  static const String delete = 'delete';
  static const String approve = 'approve';
  static const String manage = 'manage';

  // Resource types
  static const String organizations = 'organizations';
  static const String regions = 'regions';
  static const String districts = 'districts';
  static const String areas = 'areas';
  static const String branches = 'branches';
  static const String members = 'members';
  static const String users = 'users';
  static const String finance = 'finance';
  static const String attendance = 'attendance';
  static const String events = 'events';
  static const String sermons = 'sermons';
  static const String departments = 'departments';
  static const String welfare = 'welfare';

  // Role permissions matrix
  static const Map<String, Map<String, List<String>>> rolePermissions = {
    AppRoles.superSystemAdmin: {
      organizations: [read, write, delete, manage],
      regions: [read, write, delete, manage],
      districts: [read, write, delete, manage],
      areas: [read, write, delete, manage],
      branches: [read, write, delete, manage],
      members: [read, write, delete, manage],
      users: [read, write, delete, manage],
      finance: [read, write, delete, manage],
      attendance: [read, write, delete, manage],
      events: [read, write, delete, manage],
      sermons: [read, write, delete, manage],
      departments: [read, write, delete, manage],
      welfare: [read, write, delete, manage],
    },
    AppRoles.nationalAdmin: {
      organizations: [read],
      regions: [read, write, delete, manage],
      districts: [read, write, delete, manage],
      areas: [read, write, delete, manage],
      branches: [read, write, delete, manage],
      members: [read, write, delete, manage],
      users: [read, write, delete, manage],
      finance: [read, write, delete, manage],
      attendance: [read, write, delete, manage],
      events: [read, write, delete, manage],
      sermons: [read, write, delete, manage],
      departments: [read, write, delete, manage],
      welfare: [read, write, delete, manage],
    },
    AppRoles.nationalExecutive: {
      organizations: [read],
      regions: [read, approve],
      districts: [read],
      areas: [read],
      branches: [read],
      members: [read],
      users: [read],
      finance: [read, approve],
      attendance: [read],
      events: [read, approve],
      sermons: [read],
      departments: [read],
      welfare: [read, approve],
    },
    AppRoles.regionalAdmin: {
      regions: [read],
      districts: [read, write, delete, manage],
      areas: [read, write, delete, manage],
      branches: [read, write, delete, manage],
      members: [read, write, delete, manage],
      users: [read, write, delete, manage],
      finance: [read, write, delete, manage],
      attendance: [read, write, delete, manage],
      events: [read, write, delete, manage],
      sermons: [read, write, delete, manage],
      departments: [read, write, delete, manage],
      welfare: [read, write, delete, manage],
    },
    AppRoles.regionalBishop: {
      regions: [read],
      districts: [read, approve],
      areas: [read],
      branches: [read],
      members: [read],
      users: [read],
      finance: [read, approve],
      attendance: [read],
      events: [read, approve],
      sermons: [read],
      departments: [read],
      welfare: [read, approve],
    },
    AppRoles.districtAdmin: {
      districts: [read],
      areas: [read, write, delete, manage],
      branches: [read, write, delete, manage],
      members: [read, write, delete, manage],
      users: [read, write, delete, manage],
      finance: [read, write, delete, manage],
      attendance: [read, write, delete, manage],
      events: [read, write, delete, manage],
      sermons: [read, write, delete, manage],
      departments: [read, write, delete, manage],
      welfare: [read, write, delete, manage],
    },
    AppRoles.districtPastor: {
      districts: [read],
      areas: [read, approve],
      branches: [read],
      members: [read],
      users: [read],
      finance: [read, approve],
      attendance: [read],
      events: [read, approve],
      sermons: [read],
      departments: [read],
      welfare: [read, approve],
    },
    AppRoles.areaAdmin: {
      areas: [read],
      branches: [read, write, delete, manage],
      members: [read, write, delete, manage],
      users: [read, write, delete, manage],
      finance: [read, write, delete, manage],
      attendance: [read, write, delete, manage],
      events: [read, write, delete, manage],
      sermons: [read, write, delete, manage],
      departments: [read, write, delete, manage],
      welfare: [read, write, delete, manage],
    },
    AppRoles.localChurchAdmin: {
      branches: [read, write, delete, manage],
      members: [read, write, delete, manage],
      users: [read, write, delete, manage],
      finance: [read, write, delete, manage],
      attendance: [read, write, delete, manage],
      events: [read, write, delete, manage],
      sermons: [read, write, delete, manage],
      departments: [read, write, delete, manage],
      welfare: [read, write, delete, manage],
    },
    AppRoles.seniorPastor: {
      branches: [read, write, manage],
      members: [read, write, manage],
      users: [read, write],
      finance: [read, write, approve],
      attendance: [read, write, manage],
      events: [read, write, approve],
      sermons: [read, write, manage],
      departments: [read, write, manage],
      welfare: [read, write, approve],
    },
    AppRoles.associatePastor: {
      branches: [read],
      members: [read, write],
      users: [read],
      finance: [read],
      attendance: [read, write],
      events: [read, write],
      sermons: [read, write],
      departments: [read, write],
      welfare: [read, write],
    },
    AppRoles.churchSecretary: {
      branches: [read],
      members: [read, write],
      users: [read],
      finance: [read],
      attendance: [read, write],
      events: [read, write],
      sermons: [read],
      departments: [read],
      welfare: [read, write],
    },
    AppRoles.financeOfficer: {
      branches: [read],
      members: [read],
      users: [read],
      finance: [read, write, manage],
      attendance: [read],
      events: [read],
      sermons: [read],
      departments: [read],
      welfare: [read],
    },
    AppRoles.ministryHead: {
      branches: [read],
      members: [read, write],
      users: [read],
      finance: [read],
      attendance: [read, write],
      events: [read, write],
      sermons: [read],
      departments: [read, write, manage],
      welfare: [read],
    },
    AppRoles.welfareHead: {
      branches: [read],
      members: [read, write],
      users: [read],
      finance: [read],
      attendance: [read],
      events: [read],
      sermons: [read],
      departments: [read],
      welfare: [read, write, manage],
    },
    AppRoles.cellLeader: {
      branches: [read],
      members: [read, write],
      users: [read],
      finance: [read],
      attendance: [read, write],
      events: [read],
      sermons: [read],
      departments: [read],
    },
    AppRoles.volunteer: {
      branches: [read],
      members: [read],
      users: [read],
      finance: [read],
      attendance: [read, write],
      events: [read],
      sermons: [read],
      departments: [read],
    },
    AppRoles.member: {
      branches: [read],
      members: [read],
      users: [read],
      finance: [read],
      attendance: [read],
      events: [read, write],
      sermons: [read],
      departments: [read],
    },
    AppRoles.guest: {
      events: [read, write],
      sermons: [read],
    },
  };

  // Check if a role has a specific permission for a resource
  static bool hasPermission(String role, String resource, String permission) {
    final permissions = rolePermissions[role];
    if (permissions == null) return false;
    
    final resourcePermissions = permissions[resource];
    if (resourcePermissions == null) return false;
    
    return resourcePermissions.contains(permission);
  }

  // Check if a role can manage another role
  static bool canManageRole(String managerRole, String targetRole) {
    final managerLevel = roleHierarchy[managerRole] ?? 0;
    final targetLevel = roleHierarchy[targetRole] ?? 0;
    return managerLevel > targetLevel;
  }

  // Get all permissions for a role
  static Map<String, List<String>> getRolePermissions(String role) {
    return rolePermissions[role] ?? {};
  }

  // Get role hierarchy level
  static int getRoleLevel(String role) {
    return roleHierarchy[role] ?? 0;
  }

  // Check if role is at or above a certain level
  static bool isRoleAtOrAbove(String role, int level) {
    return getRoleLevel(role) >= level;
  }
}
