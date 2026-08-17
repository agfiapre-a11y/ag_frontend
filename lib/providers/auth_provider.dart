import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/church.dart';
import '../models/tenant_config.dart';
import '../services/auth_service.dart';
import '../services/local_db.dart';
import '../services/sync_service.dart';
import '../services/tenant_context.dart';
import '../services/rate_limiter.dart';
import '../services/api_config.dart';
import '../services/auth_token_manager.dart';
import '../services/session_manager.dart';
import '../services/api_client.dart';

enum AppInitState { loading, needsSetup, unauthenticated, authenticated }

class AppState {
  final AppInitState initState;
  final AppUser? user;
  final Church? church;
  final TenantConfig? tenantConfig;

  const AppState({
    required this.initState,
    this.user,
    this.church,
    this.tenantConfig,
  });

  AppState copyWith({
    AppInitState? initState,
    AppUser? user,
    Church? church,
    TenantConfig? tenantConfig,
  }) =>
      AppState(
        initState: initState ?? this.initState,
        user: user ?? this.user,
        church: church ?? this.church,
        tenantConfig: tenantConfig ?? this.tenantConfig,
      );
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier()
      : super(const AppState(initState: AppInitState.loading)) {
    _init();
  }

  void _init() async {
    try {
      if (ApiConfig.isConfigured) {
        await AuthTokenManager.loadTokens();
      }
      final churches = LocalDb.getAllChurches();
      if (churches.isEmpty) {
        state = const AppState(initState: AppInitState.needsSetup);
        return;
      }

      // Check for a valid stored session — auto-login returning users
      final sessionUserId = await SessionManager.getValidSessionUserId();
      if (sessionUserId != null) {
        final user = LocalDb.getUserById(sessionUserId);
        final activeChurch = LocalDb.getChurch();
        if (user != null && activeChurch != null) {
          // Update last activity timestamp to extend the session
          await SessionManager.updateLastActivity();

          // Fetch tenant config if API is configured and user has a tenant
          TenantConfig? tenantConfig;
          if (ApiConfig.isConfigured && user.churchId.isNotEmpty) {
            try {
              final resp = await ApiClient().get('/tenants/by-id/${user.churchId}');
              tenantConfig = TenantConfig.fromJson(resp);
            } catch (_) {
              // If tenant fetch fails, still proceed with local data
            }
          }

          state = AppState(
            initState: AppInitState.authenticated,
            user: user,
            church: activeChurch,
            tenantConfig: tenantConfig,
          );
          return;
        }
      }

      final activeChurch = LocalDb.getChurch();
      state = AppState(initState: AppInitState.unauthenticated, church: activeChurch);
    } catch (e) {
      // If init fails, show setup screen rather than blank loading
      state = const AppState(initState: AppInitState.needsSetup);
    }
  }

  // Returns error message or null on success
  Future<String?> login(String email, String password) async {
    if (await RateLimiter.isLocked(email)) {
      return 'Too many failed attempts. Account locked for 5 minutes.';
    }
    try {
      final result = await AuthService.login(email, password);
      if (result == null) {
        final remaining = await RateLimiter.getRemainingAttempts(email);
        if (remaining < 5) {
          return 'Invalid email or password. $remaining attempt(s) remaining.';
        }
        return 'Invalid email or password.';
      }
      state = AppState(
          initState: AppInitState.authenticated,
          user: result.user,
          church: result.church,
          tenantConfig: result.tenantConfig);
      // Pull remote data (users, members, etc.) so the admin sees all records
      // immediately after login, not just the ones in local storage.
      if (SyncService.isConfigured && result.church != null) {
        try {
          await SyncService.pullRemoteChanges(churchId: result.church!.id);
        } catch (_) {
          // Sync failure shouldn't block login
        }
      }
      return null;
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<void> setupChurch({
    required String churchName,
    required String churchAddress,
    required String churchPhone,
    required String churchEmail,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String adminPhone,
  }) async {
    final result = await AuthService.setupChurch(
      churchName: churchName,
      churchAddress: churchAddress,
      churchPhone: churchPhone,
      churchEmail: churchEmail,
      adminName: adminName,
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      adminPhone: adminPhone,
    );
    state = AppState(
      initState: AppInitState.authenticated,
      user: result.admin,
      church: result.church,
    );
    TenantContext.setActiveChurch(result.church.id);
  }

  Future<void> logout() async {
    await AuthService.logout();
    TenantContext.clear();
    final church = LocalDb.getChurch();
    state =
        AppState(initState: AppInitState.unauthenticated, church: church);
  }

  void refreshUser() {
    final user = AuthService.currentUser();
    final church = LocalDb.getChurch();
    if (user != null && church != null) {
      state = state.copyWith(user: user, church: church);
    }
  }

  /// Switches the active role for the current user.
  /// The role must be in the user's roles array or assigned via access control.
  /// Returns true on success, false on failure.
  Future<bool> switchRole(String role) async {
    final updated = await AuthService.switchRole(role);
    if (updated != null) {
      state = state.copyWith(user: updated);
      return true;
    }
    return false;
  }

  void refresh() => _init();
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);
