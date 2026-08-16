import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/church.dart';
import '../models/tenant_config.dart';
import '../core/constants.dart';
import 'local_db.dart';
import 'tenant_context.dart';
import 'security_service.dart';
import 'rate_limiter.dart';
import 'session_manager.dart';
import 'audit_service.dart';
import 'movement_classifier.dart';
import 'api_config.dart';
import 'api_client.dart';
import 'remote_auth_service.dart';
import 'auth_token_manager.dart';

class AuthService {
  static const _uuid = Uuid();

  static String hashPassword(String password) {
    return SecurityService.hashPassword(password);
  }

  // First-time setup: create church + admin account.
  // Uses the NestJS backend when API_BASE_URL is configured, otherwise local DB.
  static Future<({Church church, AppUser admin})> setupChurch({
    required String churchName,
    required String churchAddress,
    required String churchPhone,
    required String churchEmail,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String adminPhone,
  }) async {
    if (ApiConfig.isConfigured) {
      final result = await RemoteAuthService.setupChurch(
        churchName: churchName,
        churchAddress: churchAddress,
        churchPhone: churchPhone,
        churchEmail: churchEmail,
        adminName: adminName,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        adminPhone: adminPhone,
      );
      await _persistRemoteSession(
        result.user,
        result.church,
        result.accessToken,
        result.refreshToken,
      );
      return (church: result.church, admin: result.user);
    }

    return _setupChurchLocal(
      churchName: churchName,
      churchAddress: churchAddress,
      churchPhone: churchPhone,
      churchEmail: churchEmail,
      adminName: adminName,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      adminPhone: adminPhone,
    );
  }

  static Future<({Church church, AppUser admin})> _setupChurchLocal({
    required String churchName,
    required String churchAddress,
    required String churchPhone,
    required String churchEmail,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String adminPhone,
  }) async {
    final churchId = _uuid.v4();
    final adminId = _uuid.v4();
    final now = DateTime.now();

    final church = Church(
      id: churchId,
      name: churchName,
      adminId: adminId,
      address: churchAddress,
      phone: churchPhone,
      email: churchEmail,
      createdAt: now,
    );

    final admin = AppUser(
      id: adminId,
      name: adminName,
      email: adminEmail.toLowerCase().trim(),
      passwordHash: hashPassword(adminPassword),
      role: AppRoles.localChurchAdmin,
      churchId: churchId,
      branchId: '',
      phone: adminPhone,
      createdAt: now,
    );

    await LocalDb.saveChurch(church);
    await LocalDb.saveUser(admin);
    await LocalDb.saveSession(adminId);

    return (church: church, admin: admin);
  }

  // Login with email + password.
  // Uses the NestJS backend when API_BASE_URL is configured, otherwise local DB.
  static Future<({AppUser user, Church? church, TenantConfig? tenantConfig})?> login(
      String email, String password) async {
    if (await RateLimiter.isLocked(email)) {
      return null;
    }

    if (ApiConfig.isConfigured) {
      try {
        final result = await RemoteAuthService.login(email, password);
        if (result == null) {
          await RateLimiter.recordFailure(email);
          return null;
        }
        await _persistRemoteSession(
          result.user,
          result.church,
          result.accessToken,
          result.refreshToken,
        );
        await RateLimiter.clearAttempts(email);
        return (user: result.user, church: result.church, tenantConfig: result.tenantConfig);
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          await RateLimiter.recordFailure(email);
          return null;
        }
        rethrow;
      }
    }

    return _loginLocal(email, password);
  }

  static Future<({AppUser user, Church? church, TenantConfig? tenantConfig})?> _loginLocal(
      String email, String password) async {
    final result = await LocalDb.getUserByEmailAcrossChurches(email);
    if (result == null) {
      await RateLimiter.recordFailure(email);
      return null;
    }
    final user = result.user;
    if (!SecurityService.verifyPassword(password, user.passwordHash)) {
      await RateLimiter.recordFailure(email);
      return null;
    }

    await RateLimiter.clearAttempts(email);

    if (SecurityService.isLegacyHash(user.passwordHash)) {
      final migrated = user.copyWith(passwordHash: SecurityService.hashPassword(password));
      await LocalDb.saveUser(migrated);
    }

    if (AppRoles.isAboveChurchLevel(user.role)) {
      final churches = LocalDb.getAllChurches();
      if (churches.isNotEmpty) {
        await LocalDb.setActiveChurch(churches.first.id);
        TenantContext.setActiveChurch(churches.first.id);
      }
      await SessionManager.saveSession(user.id);
      await AuditService.log(
        actorId: user.id,
        actorName: user.name,
        action: 'login',
        resource: 'auth',
      );
      return (user: user, church: null, tenantConfig: null);
    }

    final church = LocalDb.getChurchById(result.churchId);
    if (church == null) return null;

    await LocalDb.setActiveChurch(church.id);
    TenantContext.setActiveChurch(church.id);
    await SessionManager.saveSession(user.id);
    await AuditService.log(
      actorId: user.id,
      actorName: user.name,
      action: 'login',
      resource: 'auth',
    );
    return (user: user, church: church, tenantConfig: null);
  }

  static Future<void> _persistRemoteSession(
    AppUser user,
    Church church,
    String accessToken,
    String refreshToken,
  ) async {
    await LocalDb.saveChurch(church);
    await LocalDb.saveUser(user);
    await LocalDb.setActiveChurch(church.id);
    TenantContext.setActiveChurch(church.id);
    await SessionManager.saveSession(user.id);
    await AuthTokenManager.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tenantId: user.churchId,
    );
    await AuditService.log(
      actorId: user.id,
      actorName: user.name,
      action: 'login',
      resource: 'auth',
    );
  }

  static Future<void> logout() async {
    final user = currentUser();
    if (user != null) {
      await AuditService.log(
        actorId: user.id,
        actorName: user.name,
        action: 'logout',
        resource: 'auth',
      );
    }
    if (ApiConfig.isConfigured) {
      await RemoteAuthService.logout();
      await AuthTokenManager.clearTokens();
    }
    await SessionManager.clearSession();
  }

  static AppUser? currentUser() {
    final userId = LocalDb.getSessionUserId();
    if (userId == null) return null;
    return LocalDb.getUserById(userId);
  }

  static Future<AppUser?> currentUserAsync() async {
    final userId = await SessionManager.getValidSessionUserId();
    if (userId == null) return null;
    return LocalDb.getUserById(userId);
  }

  // Add a staff/member user account
  static Future<AppUser> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String churchId,
    required String branchId,
    String departmentId = '',
    DateTime? dateOfBirth,
    String gender = 'male',
    String maritalStatus = 'single',
    bool isEmployed = false,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) async {
    // One admin per church: block locally too (covers offline mode and any
    // path that writes straight to local storage / syncs directly to
    // Supabase without going through the backend's onboard-user endpoint,
    // which also enforces this rule).
    if (role == AppRoles.localChurchAdmin && churchId.isNotEmpty) {
      final admins = LocalDb.getUsersByRole(AppRoles.localChurchAdmin)
          .where((u) => u.churchId == churchId);
      if (admins.isNotEmpty) {
        final existingAdmin = admins.first;
        throw Exception(
          'This church already has an admin (${existingAdmin.name} — ${existingAdmin.email}). '
          'Demote or remove the existing admin before assigning a new one.',
        );
      }
    }

    // Register on backend when API is configured
    if (ApiConfig.isConfigured && churchId.isNotEmpty) {
      await RemoteAuthService.registerUser(
        name: name,
        email: email,
        password: password,
        role: role,
        tenantId: churchId,
      );
    }

    final movement = MovementClassifier.classify(
      dateOfBirth: dateOfBirth,
      gender: gender,
      maritalStatus: maritalStatus,
      isEmployed: isEmployed,
    );
    final user = AppUser(
      id: _uuid.v4(),
      name: name,
      email: email.toLowerCase().trim(),
      passwordHash: hashPassword(password),
      role: role,
      churchId: churchId,
      branchId: branchId,
      departmentId: departmentId,
      phone: phone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      maritalStatus: maritalStatus,
      isEmployed: isEmployed,
      movement: movement,
      organizationId: organizationId,
      regionId: regionId,
      districtId: districtId,
      areaId: areaId,
      createdAt: DateTime.now(),
    );
    await LocalDb.saveUser(user);
    return user;
  }
}
