/// API configuration for the NestJS backend.
///
/// Configure via --dart-define:
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
///
/// If not configured, the app falls back to offline/local mode.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.isNotEmpty && baseUrl != 'YOUR_API_BASE_URL';
}
