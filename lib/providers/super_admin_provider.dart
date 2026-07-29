import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tenant_config.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';

class SuperAdminState {
  final List<TenantConfig> tenants;
  final bool isLoading;
  final String? error;

  const SuperAdminState({
    this.tenants = const [],
    this.isLoading = false,
    this.error,
  });

  SuperAdminState copyWith({
    List<TenantConfig>? tenants,
    bool? isLoading,
    String? error,
  }) {
    return SuperAdminState(
      tenants: tenants ?? this.tenants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SuperAdminNotifier extends StateNotifier<SuperAdminState> {
  SuperAdminNotifier() : super(const SuperAdminState());

  Future<void> loadTenants() async {
    if (!ApiConfig.isConfigured) {
      state = const SuperAdminState(error: 'API not configured');
      return;
    }
    state = const SuperAdminState(isLoading: true);
    try {
      final response = await ApiClient().getList('/tenants');
      final list = response
          .map((e) => TenantConfig.fromJson(e as Map<String, dynamic>))
          .toList();
      state = SuperAdminState(tenants: list);
    } catch (e) {
      state = SuperAdminState(error: e.toString());
    }
  }

  Future<String?> createTenant({
    required String name,
    required String slug,
    String? address,
    String? phone,
    String? email,
    String? primaryColor,
    String? secondaryColor,
    int? maxMembers,
    int? maxBranches,
    String? subscriptionTier,
    String? subscriptionExpiry,
    List<String>? enabledModules,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'slug': slug,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (primaryColor != null) 'primaryColor': primaryColor,
        if (secondaryColor != null) 'secondaryColor': secondaryColor,
        if (maxMembers != null) 'maxMembers': maxMembers,
        if (maxBranches != null) 'maxBranches': maxBranches,
        if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
        if (subscriptionExpiry != null) 'subscriptionExpiry': subscriptionExpiry,
        if (enabledModules != null) 'enabledModules': enabledModules,
      };
      await ApiClient().post('/tenants', body);
      await loadTenants();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateTenant(String id, Map<String, dynamic> data) async {
    try {
      await ApiClient().patch('/tenants/$id', data);
      await loadTenants();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteTenant(String id) async {
    try {
      await ApiClient().delete('/tenants/$id');
      await loadTenants();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final superAdminProvider =
    StateNotifierProvider<SuperAdminNotifier, SuperAdminState>(
  (ref) => SuperAdminNotifier(),
);
