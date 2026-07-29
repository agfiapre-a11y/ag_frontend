import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for offline-first cloud sync.
///
/// SECURITY: Credentials are loaded via --dart-define env vars to avoid
/// hardcoding secrets in the compiled app (UK GDPR Art. 32, NCSC guidance).
///
/// Build with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// The app works fully offline without Supabase configured. When configured,
/// data will sync to/from Supabase when internet is available.
///
/// IMPORTANT: Row-Level Security (RLS) MUST be enabled on ALL tables in the
/// Supabase dashboard. The anon key is exposed in client-side code by design,
/// so RLS policies are the primary access control layer. At minimum:
///   - users table: SELECT only for authenticated users; no passwordHash column
///   - All tables: SELECT/INSERT/UPDATE/DELETE scoped by church_id
///   - No table should allow unauthenticated access
class SupabaseConfig {
  // ── Supabase credentials (from --dart-define env vars) ────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  // ──────────────────────────────────────────────────────────────────────────

  /// Whether Supabase has been configured with real credentials.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  /// Initialize Supabase. Call once at app startup.
  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }

  /// Get the Supabase client (null if not configured).
  static SupabaseClient? get client {
    if (!isConfigured) return null;
    return Supabase.instance.client;
  }
}
