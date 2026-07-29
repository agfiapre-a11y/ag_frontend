import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

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

  String? _token;
  String? _tenantId;

  void setAuth({String? token, String? tenantId}) {
    _token = token;
    _tenantId = tenantId;
  }

  void clearAuth() {
    _token = null;
    _tenantId = null;
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    if (!ApiConfig.isConfigured) {
      throw StateError('API_BASE_URL is not configured');
    }

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

    late final http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      case 'PATCH':
        response = await http.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw UnsupportedError('HTTP method $method not supported');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = _parseError(response);
    throw ApiException(response.statusCode, error);
  }

  Future<Map<String, dynamic>> get(String path) => request('GET', path);

  Future<List<dynamic>> getList(String path) async {
    if (!ApiConfig.isConfigured) {
      throw StateError('API_BASE_URL is not configured');
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (_tenantId != null) {
      headers['X-Tenant-Id'] = _tenantId!;
    }
    final response = await http.get(uri, headers: headers);
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
