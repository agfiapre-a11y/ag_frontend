import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tenant_config.dart';
import '../services/tenant_config_service.dart';

class TenantState {
  final TenantConfig? config;
  final bool isLoading;
  final String? error;

  const TenantState({
    this.config,
    this.isLoading = false,
    this.error,
  });

  TenantState copyWith({
    TenantConfig? config,
    bool? isLoading,
    String? error,
  }) {
    return TenantState(
      config: config ?? this.config,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TenantNotifier extends StateNotifier<TenantState> {
  TenantNotifier() : super(const TenantState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    try {
      final config = await TenantConfigService.loadTenantConfig();
      state = TenantState(config: config);
    } catch (e) {
      state = TenantState(error: e.toString());
    }
  }

  Future<void> loadBySlug(String slug) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final config = await TenantConfigService.fetchTenantBySlug(slug);
      await TenantConfigService.saveTenantConfig(config);
      state = TenantState(config: config);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setConfig(TenantConfig config) async {
    await TenantConfigService.saveTenantConfig(config);
    state = TenantState(config: config);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final tenantProvider = StateNotifierProvider<TenantNotifier, TenantState>(
  (ref) => TenantNotifier(),
);

final tenantConfigProvider = Provider<TenantConfig?>((ref) {
  return ref.watch(tenantProvider).config;
});
