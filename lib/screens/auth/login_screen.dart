import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';
import 'privacy_notice_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final error = await ref
        .read(appStateProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (mounted) {
      setState(() => _loading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantConfig = ref.watch(tenantConfigProvider);
    final appName = tenantConfig?.appName ?? tenantConfig?.name ?? 'Paradise AG';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600; // Stack footer on mobile/tablet

    final formMaxWidth = 525.0;
    final horizontalPadding = screenWidth < 400 ? 16.0 : 24.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.backgroundLight,
              AppColors.background,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    // AspectRatio locked to actual image ratio (1330x400) so
                    // the banner scales perfectly on any screen with no
                    // stretch or crop.
                    AspectRatio(
                      aspectRatio: 1330 / 400,
                      child: Image.asset(
                        'assets/images/banner2.png',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.4),
                                  AppColors.backgroundLight,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // ── Body ──────────────────────────────────────────────────
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: formMaxWidth),
                        child: Transform.translate(
                          offset: const Offset(0, -30),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: _buildLoginForm(context, appName),
                          ),
                        ),
                      ),
                    ),
                    // ── Footer ────────────────────────────────────────────────
                    _buildFooter(context, isMobile, appName),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Shared login form fields ─────────────────────────────────────────────
  Widget _buildLoginForm(BuildContext context, String appName) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back',
            style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to $appName',
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Email is required'
                : null,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _loading ? null : _login(),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Password is required' : null,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: AppColors.background, strokeWidth: 2.5))
                  : Text('Sign In',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go('/landing'),
              child: Text(
                'Explore Assemblies of God, Ghana',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => PrivacyNoticeDialog.show(context),
              child: Text(
                'Privacy Notice',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, bool isMobile, String appName) {
    if (isMobile) {
      // Stack vertically on very small screens
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$appName — Church Information Management System • v1.0.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: AppColors.textSecondary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 2),
            Text(
              'Designed by Echendaa Educational and Research Unit',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: AppColors.textSecondary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 2),
            Text(
              'Distributed by Nung A Bibile Foundation under the Digital Literacy Program',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: AppColors.textSecondary.withValues(alpha: 0.45)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Column 1: App identity
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: Text(
                    '$appName — Church Information Management System • v1.0.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.7)),
                  ),
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.15),
            ),
            // Column 2: Designed by
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: Text(
                    'Designed by Echendaa Educational and Research Unit',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.15),
            ),
            // Column 3: Distributed by
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Center(
                  child: Text(
                    'Distributed by Nung A Bibile Foundation under the Digital Literacy Program',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 9,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.45)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
