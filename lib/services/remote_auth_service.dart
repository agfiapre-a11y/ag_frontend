import '../models/app_user.dart';
import '../models/church.dart';
import '../models/tenant_config.dart';
import '../core/constants.dart';
import 'api_client.dart';
import 'api_config.dart';

class RemoteAuthResult {
  final AppUser user;
  final Church church;
  final String accessToken;
  final String refreshToken;

  RemoteAuthResult({
    required this.user,
    required this.church,
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

    final tenantResp = await _api.post('/tenants', {
      'name': churchName,
      'slug': slug,
      'address': churchAddress,
      'phone': churchPhone,
      'email': churchEmail,
    });
    final tenant = TenantConfig.fromJson(tenantResp);

    await _api.post('/auth/register', {
      'name': adminName,
      'email': adminEmail,
      'password': adminPassword,
      'role': 'church_admin',
      'tenantId': tenant.id,
    });

    final authResp = await _api.post('/auth/login', {
      'email': adminEmail,
      'password': adminPassword,
    });

    return _mapAuthResponse(authResp, tenant);
  }

  /// Login a user remotely and return the mapped result.
  static Future<RemoteAuthResult?> login(String email, String password) async {
    try {
      final authResp = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });
      final tenantId = authResp['user']['tenantId'] as String?;
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
      'church_admin': AppRoles.localChurchAdmin,
      'branch_admin': AppRoles.branchAdmin,
      'secretary': AppRoles.churchSecretary,
      'treasurer': AppRoles.financeOfficer,
      'member': AppRoles.member,
      'observer': AppRoles.guest,
    };
    return mapping[backendRole] ?? backendRole;
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
      role: _mapRole(userJson['role'] as String),
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
