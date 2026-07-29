import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/church.dart';
import '../services/auth_service.dart';
import '../services/local_db.dart';
import '../services/tenant_context.dart';
import '../services/rate_limiter.dart';
import '../services/api_config.dart';
import '../services/auth_token_manager.dart';

enum AppInitState { loading, needsSetup, unauthenticated, authenticated }

class AppState {
  final AppInitState initState;
  final AppUser? user;
  final Church? church;

  const AppState({
    required this.initState,
    this.user,
    this.church,
  });

  AppState copyWith({
    AppInitState? initState,
    AppUser? user,
    Church? church,
  }) =>
      AppState(
        initState: initState ?? this.initState,
        user: user ?? this.user,
        church: church ?? this.church,
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
      return 'Too many failed attempts. Account locked for 15 minutes.';
    }
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
        church: result.church);
    return null;
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

  void refresh() => _init();
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);
