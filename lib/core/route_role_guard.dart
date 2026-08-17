import '../core/constants.dart';

/// Maps route paths to the roles that are allowed to access them.
///
/// Adapted from SIMS's route guard model. The GoRouter redirect checks
/// this map before allowing navigation. If the user's activeRole is not
/// in the allowed list, they're redirected to /home.
///
/// Routes not listed here are accessible to all authenticated users
/// (e.g. /home, /profile, /settings).
class RouteRoleGuard {
  /// Map of route path prefix → allowed roles.
  /// A route matches if its path starts with the key.
  static const Map<String, List<String>> routeRoles = {
    // System-level routes
    '/super-admin': [
      AppRoles.superSystemAdmin,
    ],

    // Organization/region/district/area management
    '/organizations': [
      AppRoles.superSystemAdmin,
      AppRoles.nationalAdmin,
      AppRoles.nationalExecutive,
    ],
    '/regions': [
      AppRoles.superSystemAdmin,
      AppRoles.nationalAdmin,
      AppRoles.nationalExecutive,
      AppRoles.regionalAdmin,
      AppRoles.regionalBishop,
    ],
    '/districts': [
      AppRoles.superSystemAdmin,
      AppRoles.nationalAdmin,
      AppRoles.regionalAdmin,
      AppRoles.regionalBishop,
      AppRoles.districtAdmin,
      AppRoles.districtPastor,
    ],
    '/areas': [
      AppRoles.superSystemAdmin,
      AppRoles.nationalAdmin,
      AppRoles.regionalAdmin,
      AppRoles.districtAdmin,
      AppRoles.areaAdmin,
    ],

    // User management
    '/users': [
      AppRoles.superSystemAdmin,
      AppRoles.nationalAdmin,
      AppRoles.regionalAdmin,
      AppRoles.districtAdmin,
      AppRoles.areaAdmin,
      AppRoles.localChurchAdmin,
      AppRoles.seniorPastor,
    ],

    // Finance management
    '/finance': [
      AppRoles.superSystemAdmin,
      AppRoles.nationalAdmin,
      AppRoles.regionalAdmin,
      AppRoles.districtAdmin,
      AppRoles.areaAdmin,
      AppRoles.localChurchAdmin,
      AppRoles.seniorPastor,
      AppRoles.financeOfficer,
      AppRoles.ministryHead,
      AppRoles.welfareHead,
    ],

    // Attendance
    '/attendance': [
      AppRoles.superSystemAdmin,
      AppRoles.nationalAdmin,
      AppRoles.regionalAdmin,
      AppRoles.districtAdmin,
      AppRoles.areaAdmin,
      AppRoles.localChurchAdmin,
      AppRoles.seniorPastor,
      AppRoles.associatePastor,
      AppRoles.churchSecretary,
      AppRoles.ministryHead,
      AppRoles.welfareHead,
      AppRoles.cellLeader,
      AppRoles.volunteer,
    ],

    // Welfare
    '/welfare': [
      AppRoles.superSystemAdmin,
      AppRoles.nationalAdmin,
      AppRoles.regionalAdmin,
      AppRoles.districtAdmin,
      AppRoles.areaAdmin,
      AppRoles.localChurchAdmin,
      AppRoles.seniorPastor,
      AppRoles.associatePastor,
      AppRoles.churchSecretary,
      AppRoles.welfareHead,
    ],

    // Settings (church admin only)
    '/settings/church': [
      AppRoles.superSystemAdmin,
      AppRoles.localChurchAdmin,
      AppRoles.seniorPastor,
    ],
    '/settings/data-management': [
      AppRoles.superSystemAdmin,
      AppRoles.localChurchAdmin,
      AppRoles.seniorPastor,
    ],
  };

  /// Checks if a user with the given active role can access a route.
  /// Returns true if access is allowed, false otherwise.
  ///
  /// Routes not in [routeRoles] are accessible to all authenticated users.
  /// For routes in the map, the user's activeRole must be in the allowed list.
  /// Users with the superSystemAdmin role can access everything.
  static bool canAccess(String activeRole, String path) {
    // Super admin can access everything
    if (activeRole == AppRoles.superSystemAdmin) return true;

    // Find the matching route prefix
    for (final entry in routeRoles.entries) {
      if (path.startsWith(entry.key)) {
        return entry.value.contains(activeRole);
      }
    }

    // No matching route guard → allow access
    return true;
  }

  /// Returns the list of allowed roles for a route, or null if the route
  /// has no guard (accessible to all).
  static List<String>? allowedRolesFor(String path) {
    for (final entry in routeRoles.entries) {
      if (path.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
