import 'api_client.dart';
import 'secure_storage_wrapper.dart';

class AuthTokenManager {
  static const _tokenKey = 'auth_tokens';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? tenantId,
  }) async {
    final data = <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
    if (tenantId != null) {
      data['tenantId'] = tenantId;
    }
    await SecureStorageWrapper.setSecureMap(_tokenKey, data);
    ApiClient().setAuth(token: accessToken, tenantId: tenantId);
  }

  static Future<void> loadTokens() async {
    final data = await SecureStorageWrapper.getSecureMap(_tokenKey);
    if (data == null) return;
    ApiClient().setAuth(
      token: data['accessToken'] as String?,
      tenantId: data['tenantId'] as String?,
    );
  }

  static Future<void> clearTokens() async {
    await SecureStorageWrapper.removeSecureMap(_tokenKey);
    ApiClient().clearAuth();
  }

  static Future<String?> getAccessToken() async {
    final data = await SecureStorageWrapper.getSecureMap(_tokenKey);
    return data?['accessToken'] as String?;
  }
}
