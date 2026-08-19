import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'secure_storage_wrapper.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Default timeout for regular API requests.
  static const defaultTimeout = Duration(seconds: 30);

  /// Timeout for auth requests (login, register). Generous enough to
  /// survive a Render free-tier cold start, which can take 30-60+ seconds
  /// when the backend has spun down after inactivity.
  static const authTimeout = Duration(seconds: 60);

  /// Storage key for persisted auth tokens (must match AuthTokenManager).
  static const _tokenKey = 'auth_tokens';

  String? _token;
  String? _tenantId;

  /// Guards against infinite refresh loops.
  bool _isRefreshing = false;

  void setAuth({String? token, String? tenantId}) {
    _token = token;
    _tenantId = tenantId;
  }

  void clearAuth() {
    _token = null;
    _tenantId = null;
  }

  /// Returns true if an access token is currently set (user is authenticated).
  /// Used to skip authenticated backend calls during seeding or offline mode.
  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) async {
    if (!ApiConfig.isConfigured) {
      throw StateError('API_BASE_URL is not configured');
    }

    final response = await _doRequest(method, path, body, extraHeaders, timeout);

    // On 401, try to refresh the token and retry once.
    if (response.statusCode == 401 && !_isRefreshing) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final retry = await _doRequest(method, path, body, extraHeaders, timeout);
        return _handleResponse(retry);
      }
    }

    return _handleResponse(response);
  }

  /// Executes a single HTTP request and returns the raw response.
  Future<http.Response> _doRequest(
    String method,
    String path,
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  ) async {
    final effectiveTimeout = timeout ?? defaultTimeout;
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?extraHeaders,
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (_tenantId != null) {
      headers['X-Tenant-Id'] = _tenantId!;
    }

    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: headers).timeout(effectiveTimeout);
      case 'POST':
        return http.post(uri, headers: headers, body: encodedBody)
            .timeout(effectiveTimeout);
      case 'PUT':
        return http.put(uri, headers: headers, body: encodedBody)
            .timeout(effectiveTimeout);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: encodedBody)
            .timeout(effectiveTimeout);
      case 'DELETE':
        return http.delete(uri, headers: headers).timeout(effectiveTimeout);
      default:
        throw UnsupportedError('HTTP method $method not supported');
    }
  }

  /// Handles a completed response: returns decoded JSON on 2xx, throws on error.
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, _parseError(response));
  }

  /// Attempts to refresh the access token using the stored refresh token.
  /// Returns true on success, false on failure.
  /// Sets `_isRefreshing` to prevent recursive refresh loops.
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final data = await SecureStorageWrapper.getSecureMap(_tokenKey);
      if (data == null) return false;
      final refreshToken = data['refreshToken'] as String?;
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
      final refreshResp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (refreshResp.statusCode != 200) return false;

      final decoded = jsonDecode(refreshResp.body) as Map<String, dynamic>;
      final newAccessToken = decoded['accessToken'] as String?;
      if (newAccessToken == null) return false;

      // Update in-memory state and persisted storage.
      _token = newAccessToken;
      data['accessToken'] = newAccessToken;
      await SecureStorageWrapper.setSecureMap(_tokenKey, data);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Map<String, dynamic>> get(String path) => request('GET', path);

  Future<List<dynamic>> getList(String path) async {
    if (!ApiConfig.isConfigured) {
      throw StateError('API_BASE_URL is not configured');
    }
    final response = await _doRequest('GET', path, null, null, null);

    // On 401, try refresh and retry.
    if (response.statusCode == 401 && !_isRefreshing) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final retry = await _doRequest('GET', path, null, null, null);
        return _handleListResponse(retry);
      }
    }

    return _handleListResponse(response);
  }

  List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic>) return [decoded];
      return [];
    }
    throw ApiException(response.statusCode, _parseError(response));
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic>? body) =>
      request('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic>? body) =>
      request('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic>? body) =>
      request('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path) => request('DELETE', path);

  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('error')) return data['error'].toString();
      return 'HTTP ${response.statusCode}';
    } catch (_) {
      return 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}
