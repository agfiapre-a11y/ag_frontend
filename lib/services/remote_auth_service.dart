import '../models/app_user.dart';
import '../models/church.dart';
import '../models/tenant_config.dart';
import '../core/constants.dart';
import 'api_client.dart';
import 'api_config.dart';

class RemoteAuthResult {
  final AppUser user;
  final Church church;
  final TenantConfig? tenantConfig;
  final String accessToken;
  final String refreshToken;

  RemoteAuthResult({
    required this.user,
    required this.church,
    this.tenantConfig,
    required this.accessToken,
    required this.refreshToken,
  });
}

/// Handles remote authentication against the NestJS backend.
/// Falls back silently when API_BASE_URL is not configured.
class RemoteAuthService {
  static final ApiClient _api = ApiClient();

  static bool get isAvailable => ApiConfig.isConfigured;

  /// Create a new tenant (church) and its admin account.
  static Future<RemoteAuthResult> setupChurch({
    required String churchName,
    required String churchAddress,
    required String churchPhone,
    required String churchEmail,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String adminPhone,
  }) async {
    final slug = _slugify(churchName);

    final tenantResp = await _api.request('POST', '/tenants', body: {
      'name': churchName,
      'slug': slug,
      'address': churchAddress,
      'phone': churchPhone,
      'email': churchEmail,
    }, timeout: ApiClient.authTimeout);
    final tenant = TenantConfig.fromJson(tenantResp);

    await _api.request('POST', '/auth/register', body: {
      'name': adminName,
      'email': adminEmail,
      'password': adminPassword,
      'role': 'local_church_admin',
      'tenantId': tenant.id,
    }, timeout: ApiClient.authTimeout);

    final authResp = await _api.request('POST', '/auth/login', body: {
      'email': adminEmail,
      'password': adminPassword,
    }, timeout: ApiClient.authTimeout);

    return _mapAuthResponse(authResp, tenant);
  }

  /// Login a user remotely and return the mapped result.
  static Future<RemoteAuthResult?> login(String email, String password) async {
    try {
      final authResp = await _api.request('POST', '/auth/login', body: {
        'email': email,
        'password': password,
      }, timeout: ApiClient.authTimeout);
      final accessToken = authResp['accessToken'] as String;
      final tenantId = authResp['user']['tenantId'] as String?;

      // Set auth token BEFORE fetching tenant so the request is authenticated
      _api.setAuth(token: accessToken, tenantId: tenantId);

      final tenant = await _fetchTenant(tenantId);
      return _mapAuthResponse(authResp, tenant);
    } on ApiException catch (e) {
      if (e.statusCode == 401) return null;
      rethrow;
    }
  }

  static Future<TenantConfig?> _fetchTenant(String? tenantId) async {
    if (tenantId == null || tenantId.isEmpty) {
      return null;
    }
    final resp = await _api.get('/tenants/by-id/$tenantId');
    return TenantConfig.fromJson(resp);
  }

  /// Maps backend snake_case roles to Flutter camelCase roles.
  static String _mapRole(String backendRole) {
    const mapping = {
      'super_system_admin': AppRoles.superSystemAdmin,
      'national_admin': AppRoles.nationalAdmin,
      'national_executive': AppRoles.nationalExecutive,
      'regional_admin': AppRoles.regionalAdmin,
      'regional_bishop': AppRoles.regionalBishop,
      'district_admin': AppRoles.districtAdmin,
      'district_pastor': AppRoles.districtPastor,
      'area_admin': AppRoles.areaAdmin,
      'local_church_admin': AppRoles.localChurchAdmin,
      'senior_pastor': AppRoles.seniorPastor,
      'associate_pastor': AppRoles.associatePastor,
      'church_secretary': AppRoles.churchSecretary,
      'finance_officer': AppRoles.financeOfficer,
      'ministry_head': AppRoles.ministryHead,
      'youth_ministry_head': AppRoles.youthMinistryHead,
      'men_fellowship_head': AppRoles.menFellowshipHead,
      'women_fellowship_head': AppRoles.womenFellowshipHead,
      'children_ministry_head': AppRoles.childrenMinistryHead,
      'welfare_head': AppRoles.welfareHead,
      'cell_leader': AppRoles.cellLeader,
      'volunteer': AppRoles.volunteer,
      'member': AppRoles.member,
      'guest': AppRoles.guest,
    };
    return mapping[backendRole] ?? backendRole;
  }

  /// Maps Flutter camelCase roles to backend snake_case roles.
  static String _mapRoleToBackend(String flutterRole) {
    const mapping = {
      AppRoles.superSystemAdmin: 'super_system_admin',
      AppRoles.nationalAdmin: 'national_admin',
      AppRoles.nationalExecutive: 'national_executive',
      AppRoles.regionalAdmin: 'regional_admin',
      AppRoles.regionalBishop: 'regional_bishop',
      AppRoles.districtAdmin: 'district_admin',
      AppRoles.districtPastor: 'district_pastor',
      AppRoles.areaAdmin: 'area_admin',
      AppRoles.localChurchAdmin: 'local_church_admin',
      AppRoles.seniorPastor: 'senior_pastor',
      AppRoles.associatePastor: 'associate_pastor',
      AppRoles.churchSecretary: 'church_secretary',
      AppRoles.financeOfficer: 'finance_officer',
      AppRoles.ministryHead: 'ministry_head',
      AppRoles.youthMinistryHead: 'youth_ministry_head',
      AppRoles.menFellowshipHead: 'men_fellowship_head',
      AppRoles.womenFellowshipHead: 'women_fellowship_head',
      AppRoles.childrenMinistryHead: 'children_ministry_head',
      AppRoles.welfareHead: 'welfare_head',
      AppRoles.cellLeader: 'cell_leader',
      AppRoles.volunteer: 'volunteer',
      AppRoles.member: 'member',
      AppRoles.guest: 'guest',
    };
    return mapping[flutterRole] ?? flutterRole;
  }

  /// Register a new user on the backend (authenticated onboarding).
  static Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String tenantId,
  }) async {
    await _api.post('/auth/onboard-user', {
      'name': name,
      'email': email,
      'password': password,
      'role': _mapRoleToBackend(role),
      'tenantId': tenantId,
    });
  }

  static RemoteAuthResult _mapAuthResponse(
    Map<String, dynamic> authResp,
    TenantConfig? tenant,
  ) {
    final accessToken = authResp['accessToken'] as String;
    final refreshToken = authResp['refreshToken'] as String;
    final userJson = authResp['user'] as Map<String, dynamic>;

    _api.setAuth(token: accessToken, tenantId: userJson['tenantId'] as String?);

    final user = AppUser(
      id: userJson['id'] as String,
      name: userJson['name'] as String,
      email: userJson['email'] as String,
      passwordHash: '',
      roles: [_mapRole(userJson['role'] as String)], activeRole: _mapRole(userJson['role'] as String),
      churchId: userJson['tenantId'] as String? ?? '',
      branchId: '',
      phone: '',
      createdAt: DateTime.now(),
    );

    final church = tenant != null
        ? Church(
            id: tenant.id,
            name: tenant.name,
            adminId: user.id,
            address: tenant.address ?? '',
            phone: tenant.phone ?? '',
            email: tenant.email ?? '',
            createdAt: DateTime.now(),
          )
        : Church(
            id: 'system',
            name: 'Assemblies of God, Ghana',
            adminId: user.id,
            address: 'P.O. Box AN 7644, Accra-North, Ghana',
            phone: '0302 788 583',
            email: 'agghanagc@gmail.com',
            createdAt: DateTime.now(),
          );

    return RemoteAuthResult(
      user: user,
      church: church,
      tenantConfig: tenant,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static String _slugify(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  static Future<void> logout() async {
    _api.clearAuth();
  }
}
