import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/dynamic_theme.dart';
import '../providers/tenant_provider.dart';
import '../models/tenant_config.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantConfig = ref.watch(tenantConfigProvider);
    final primaryColor = DynamicTheme.primaryColor(tenantConfig);
    final appName = tenantConfig?.appName ?? tenantConfig?.name ?? 'Paradise AG';
    final tagline = tenantConfig?.name != null && tenantConfig!.name != appName
        ? tenantConfig.name
        : 'Church Management';

    return Scaffold(
      body: Container(
        decoration: ParadiseTheme.splashBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: _buildLogo(tenantConfig),
              ),
              const SizedBox(height: 24),
              Text(
                appName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tagline,
                style: GoogleFonts.poppins(
                  color: AppColors.paradiseTextSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                color: AppColors.sunriseGold,
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(TenantConfig? config) {
    if (config?.logoUrl != null && config!.logoUrl!.isNotEmpty) {
      return Image.network(
        config.logoUrl!,
        width: 80,
        height: 80,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.church, size: 80, color: Colors.white);
        },
      );
    }
    return Image.asset(
      'assets/images/AG_logo.png',
      width: 80,
      height: 80,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.church, size: 80, color: Colors.white);
      },
    );
  }
}
