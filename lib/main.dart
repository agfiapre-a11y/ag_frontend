import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/dynamic_theme.dart';
import 'core/web_url_strategy_stub.dart'
    if (dart.library.html) 'core/web_url_strategy.dart' as web_url;
import 'services/local_db.dart';
import 'services/access_control_service.dart';
import 'services/supabase_config.dart';
import 'services/seed_data_service.dart';
import 'services/seed_role_users.dart';
import 'services/seed_multi_church.dart';
import 'services/library_seed_data.dart';
import 'services/tenant_context.dart';
import 'providers/tenant_provider.dart';
import 'providers/sync_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface errors visually instead of showing blank screen
  FlutterError.onError = (details) {
    debugPrint('FLUTTER ERROR: ${details.exception}\n${details.stack}');
  };
  ErrorWidget.builder = (details) {
    return Material(
      child: Container(
        color: const Color(0xFF0F2E27),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Initialization Error',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${details.exception}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  };

  // Set web base URL for PWA support (web only)
  web_url.configureWebUrlStrategy();

  try {
    await LocalDb.init();
    await AccessControlService.init();
    await SupabaseConfig.initialize();

    final hasSeeded = LocalDb.prefs.getBool('has_seeded') ?? false;

    if (!hasSeeded) {
      try {
        final churches = LocalDb.getAllChurches();
        if (churches.isEmpty) {
          await SeedMultiChurch.seedAllChurches();
        }

        final allChurches = LocalDb.getAllChurches();
        if (allChurches.isNotEmpty) {
          await LocalDb.setActiveChurch(allChurches.first.id);
          TenantContext.setActiveChurch(allChurches.first.id);
          await SeedDataService.seedTrainingData(allChurches.first.id);

          for (final church in allChurches) {
            await LocalDb.setActiveChurch(church.id);
            TenantContext.setActiveChurch(church.id);
            await SeedRoleUsers.seedAllRoleUsers(
                church.id, churchEmail: church.email);
          }

          await LocalDb.setActiveChurch(allChurches.first.id);
          TenantContext.setActiveChurch(allChurches.first.id);
          await SeedRoleUsers.seedAboveChurchRoleUsers();
        }

        await LocalDb.prefs.setBool('has_seeded', true);
      } catch (e, st) {
        debugPrint('SEED ERROR: $e\n$st');
      }
    }

    // Seed the Library (digital books, devotions, Bible studies) once per
    // church — separate flag so it also backfills churches created before
    // this feature existed, without re-running the rest of the seed data.
    final hasSeededLibrary = LocalDb.prefs.getBool('has_seeded_library') ?? false;
    if (!hasSeededLibrary) {
      try {
        final allChurches = LocalDb.getAllChurches();
        for (final church in allChurches) {
          await LocalDb.setActiveChurch(church.id);
          TenantContext.setActiveChurch(church.id);
          if (LocalDb.getAllLibraryBooks(churchId: church.id).isEmpty) {
            await LibrarySeedData.seedForChurch(church.id);
          }
        }
        if (allChurches.isNotEmpty) {
          await LocalDb.setActiveChurch(allChurches.first.id);
          TenantContext.setActiveChurch(allChurches.first.id);
        }
        await LocalDb.prefs.setBool('has_seeded_library', true);
      } catch (e, st) {
        debugPrint('LIBRARY SEED ERROR: $e\n$st');
      }
    }

    // Do NOT clear session on startup — we want auto-login for returning users
  } catch (e, st) {
    debugPrint('INIT ERROR: $e\n$st');
  }

  runApp(const ProviderScope(child: ParadiseAGApp()));
}

class ParadiseAGApp extends ConsumerStatefulWidget {
  const ParadiseAGApp({super.key});

  @override
  ConsumerState<ParadiseAGApp> createState() => _ParadiseAGAppState();
}

class _ParadiseAGAppState extends ConsumerState<ParadiseAGApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sync when app returns to foreground
    if (state == AppLifecycleState.resumed) {
      ref.read(syncProvider.notifier).sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final tenantConfig = ref.watch(tenantConfigProvider);
    final appTitle = tenantConfig?.appName ?? tenantConfig?.name ?? 'Paradise AG';

    return MaterialApp.router(
      title: appTitle,
      theme: DynamicTheme.fromConfig(tenantConfig),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
