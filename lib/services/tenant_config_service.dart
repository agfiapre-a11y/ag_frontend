import '../models/tenant_config.dart';
import 'api_config.dart';
import 'api_client.dart';
import 'secure_storage_wrapper.dart';

/// Loads and caches the active white-label tenant configuration.
///
/// Resolution order:
/// 1. Saved local cache
/// 2. `--dart-define=TENANT_SLUG=...` fetched from backend
/// 3. Default Paradise AG branding
class TenantConfigService {
  static const _cacheKey = 'tenant_config';
  static const _defaultPrimaryColor = '#2E7D32';

  static const String _tenantSlug = String.fromEnvironment(
    'TENANT_SLUG',
    defaultValue: '',
  );

  static Future<TenantConfig> loadTenantConfig() async {
    final cached = await _loadCachedConfig();
    if (cached != null) return cached;

    if (_tenantSlug.isNotEmpty && ApiConfig.isConfigured) {
      return fetchTenantBySlug(_tenantSlug);
    }

    return _defaultConfig();
  }

  static Future<TenantConfig?> _loadCachedConfig() async {
    final data = await SecureStorageWrapper.getSecureMap(_cacheKey);
    if (data == null) return null;
    try {
      return TenantConfig.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static Future<TenantConfig> fetchTenantBySlug(String slug) async {
    final response = await ApiClient().get('/tenants/$slug');
    final config = TenantConfig.fromJson(response);
    await saveTenantConfig(config);
    return config;
  }

  static Future<void> saveTenantConfig(TenantConfig config) async {
    await SecureStorageWrapper.setSecureMap(_cacheKey, config.toJson());
  }

  static Future<void> clearCache() async {
    await SecureStorageWrapper.removeSecureMap(_cacheKey);
  }

  static TenantConfig _defaultConfig() {
    return TenantConfig(
      id: 'default',
      name: 'Paradise AG',
      slug: 'paradise-ag',
      primaryColor: _defaultPrimaryColor,
      subscriptionTier: 'basic',
      isActive: true,
    );
  }
}
