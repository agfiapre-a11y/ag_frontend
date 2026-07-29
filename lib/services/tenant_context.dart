/// Central multi-tenant context that enforces church-scoped data isolation.
///
/// In Phase 1 (local SharedPreferences), this ensures all data is stored
/// under church-specific keys so multiple churches can coexist on one device.
///
/// In Phase 2 (Firebase), this will map to Firestore tenant-scoped queries
/// with row-level security rules.
class TenantContext {
  static String? _activeChurchId;

  /// The currently active church/tenant ID.
  /// Must be set before any data operations.
  static String get activeChurchId {
    if (_activeChurchId == null || _activeChurchId!.isEmpty) {
      throw StateError(
          'No active tenant. Call TenantContext.setActiveChurch() first.');
    }
    return _activeChurchId!;
  }

  /// Whether a tenant context is active.
  static bool get isActive => _activeChurchId != null && _activeChurchId!.isNotEmpty;

  /// Set the active church/tenant. Called on login or church setup.
  static void setActiveChurch(String churchId) {
    _activeChurchId = churchId;
  }

  /// Clear the active tenant. Called on logout.
  static void clear() {
    _activeChurchId = null;
  }

  /// Build a tenant-scoped storage key.
  /// e.g. tenantKey('users_box') => 'church_abc123:users_box'
  static String tenantKey(String baseKey) {
    return '$activeChurchId:$baseKey';
  }

  /// Build a tenant-scoped storage key with a specific churchId.
  /// Used during church setup before the active context is set.
  static String scopedKey(String churchId, String baseKey) {
    return '$churchId:$baseKey';
  }
}
