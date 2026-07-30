import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../services/api_config.dart';
import '../../models/tenant_config.dart';
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
  final _scrollController = ScrollController();
  bool _loading = false;
  bool _obscure = true;
  String _view = 'home'; // 'home' = landing page, 'portal' = login form

  List<TenantConfig> _churches = [];
  bool _loadingChurches = true;

  @override
  void initState() {
    super.initState();
    _loadChurches();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChurches() async {
    if (!ApiConfig.isConfigured) {
      setState(() {
        _loadingChurches = false;
        _churches = [_defaultChurch()];
      });
      return;
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/tenants/public/all');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _churches = list
              .map((e) => TenantConfig.fromJson(e as Map<String, dynamic>))
              .toList();
          _loadingChurches = false;
        });
      } else {
        setState(() {
          _loadingChurches = false;
          _churches = [_defaultChurch()];
        });
      }
    } catch (_) {
      setState(() {
        _loadingChurches = false;
        _churches = [_defaultChurch()];
      });
    }
  }

  TenantConfig _defaultChurch() {
    return TenantConfig(
      id: 'default',
      name: 'Assemblies of Ghana',
      slug: 'assemblies-of-ghana',
      primaryColor: '#2E7D32',
      secondaryColor: '#FFD600',
      subscriptionTier: 'basic',
      isActive: true,
      motto: 'Reflecting Christ, Transforming Lives',
    );
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

  void _openPortal() {
    setState(() => _view = 'portal');
  }

  void _goHome() {
    setState(() => _view = 'home');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    if (_view == 'portal') {
      return _buildPortalView(context, isMobile);
    }
    return _buildHomeView(context, isMobile);
  }

  // ── Portal View (Login Form) ──────────────────────────────────────────────
  Widget _buildPortalView(BuildContext context, bool isMobile) {
    final tenantConfig = ref.watch(tenantConfigProvider);
    final appName = tenantConfig?.appName ?? tenantConfig?.name ?? 'Paradise AG';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 400 ? 16.0 : 24.0;
    final formMaxWidth = 525.0;

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: _goHome,
                                      icon: const Icon(Icons.arrow_back, size: 18),
                                      label: Text('Home',
                                          style: GoogleFonts.poppins(fontSize: 13)),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                                _buildLoginForm(context, appName),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

  // ── Home View (Landing Page with Church Directory) ────────────────────────
  Widget _buildHomeView(BuildContext context, bool isMobile) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildHeroSection(isMobile),
          _buildStatsSection(isMobile),
          _buildAboutSection(isMobile),
          _buildChurchesSection(isMobile),
          _buildCallToAction(isMobile),
          _buildFooterSliver(isMobile),
        ],
      ),
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildHeroSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            height: isMobile ? 480 : 620,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.85),
                  const Color(0xFF1B5E20),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: Image.asset(
                      'assets/images/banner2.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 80,
                      vertical: isMobile ? 20 : 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.church,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Paradise AG',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 18 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            if (!isMobile)
                              TextButton(
                                onPressed: _openPortal,
                                child: Text('Sign In',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'The General Council of the Assemblies of God, Ghana',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 24 : 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Reflecting Christ, Transforming Lives — A Pentecostal movement committed to evangelism, discipleship, and community impact across Ghana and beyond.',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 17,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: _openPortal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: Colors.black87,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 24 : 36,
                                        vertical: isMobile ? 12 : 16,
                                      ),
                                    ),
                                    child: Text('Get Started',
                                        style: GoogleFonts.poppins(
                                            fontSize: isMobile ? 14 : 16,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent * 0.5,
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.white70),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 20 : 32,
                                        vertical: isMobile ? 12 : 16,
                                      ),
                                    ),
                                    child: Text('Find a Church',
                                        style: GoogleFonts.poppins(
                                            fontSize: isMobile ? 14 : 16)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Section ─────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildStatsSection(bool isMobile) {
    final stats = [
      _StatData(icon: Icons.church, value: '6,000+', label: 'Local Churches'),
      _StatData(icon: Icons.people, value: '500,000+', label: 'Members'),
      _StatData(icon: Icons.public, value: '16', label: 'Regions'),
      _StatData(icon: Icons.map, value: '200+', label: 'Districts'),
    ];

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 32 : 48,
        ),
        color: const Color(0xFFF5F5F0),
        child: isMobile
            ? Column(
                children: stats
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StatCard(stat: s),
                        ))
                    .toList(),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: stats
                    .map((s) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _StatCard(stat: s),
                          ),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  // ── About Section ─────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildAboutSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 40 : 64,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About Assemblies of God, Ghana',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 22 : 30,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Text(
                'A Pentecostal fellowship devoted to reflecting Christ and transforming lives',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 13 : 15, color: Colors.grey[600])),
            const SizedBox(height: 32),
            Text(
              'The Assemblies of God, Ghana is a vibrant Pentecostal movement with a rich history of evangelism, discipleship, and community transformation. Founded with a vision to reach every corner of Ghana with the Gospel, the church has grown from humble beginnings to become one of the largest Protestant denominations in the country.',
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 13 : 15,
                  color: Colors.grey[700],
                  height: 1.7),
            ),
            const SizedBox(height: 16),
            Text(
              'With over 6,000 local churches across 16 regions, the Assemblies of God, Ghana is committed to planting churches, training leaders, and serving communities through education, healthcare, and social outreach programs.',
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 13 : 15,
                  color: Colors.grey[700],
                  height: 1.7),
            ),
          ],
        ),
      ),
    );
  }

  // ── Churches Directory Section ────────────────────────────────────────────
  SliverToBoxAdapter _buildChurchesSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 40 : 64,
        ),
        color: const Color(0xFFF5F5F0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find Your Church',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 22 : 30,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Text(
                'Browse churches on the Paradise AG platform. Click to visit a church portal.',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 13 : 15, color: Colors.grey[600])),
            const SizedBox(height: 32),
            if (_loadingChurches)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_churches.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('No churches found.',
                      style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),
              )
            else
              isMobile
                  ? Column(
                      children: _churches
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ChurchCard(tenant: c, isMobile: true, onTap: _openPortal),
                              ))
                          .toList(),
                    )
                  : Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: _churches
                          .map((c) => SizedBox(
                                width: 340,
                                child: _ChurchCard(tenant: c, isMobile: false, onTap: _openPortal),
                              ))
                          .toList(),
                    ),
          ],
        ),
      ),
    );
  }

  // ── Call To Action ────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildCallToAction(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 48 : 72,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              const Color(0xFF1B5E20),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Join Our Community',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 24 : 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Whether you\'re looking for a church home, seeking to grow in your faith, or wanting to serve your community, there\'s a place for you in the Assemblies of God family.',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 14 : 16,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _openPortal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 32 : 48,
                  vertical: isMobile ? 14 : 18,
                ),
              ),
              child: Text('Sign In to Your Church',
                  style: GoogleFonts.poppins(
                      fontSize: isMobile ? 15 : 17,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer (Sliver version for home view) ─────────────────────────────────
  SliverToBoxAdapter _buildFooterSliver(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: 32,
        ),
        color: const Color(0xFF1B3A1B),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paradise AG — Church Information Management System',
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Designed by Echendaa Educational and Research Unit',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              'Distributed by Nung A Bibile Foundation under the Digital Literacy Program',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              '© ${DateTime.now().year} Assemblies of God, Ghana. All rights reserved.',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ],
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
              onPressed: _goHome,
              child: Text(
                '← Back to Home',
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

  // ── Footer (for portal view) ──────────────────────────────────────────────
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

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  _StatData({required this.icon, required this.value, required this.label});
}

class _StatCard extends StatelessWidget {
  final _StatData stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.value,
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20))),
              Text(stat.label,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChurchCard extends StatelessWidget {
  final TenantConfig tenant;
  final bool isMobile;
  final VoidCallback onTap;
  const _ChurchCard({required this.tenant, required this.isMobile, required this.onTap});

  Color get _primaryColor {
    final hex = tenant.primaryColor.replaceAll('#', '');
    if (hex.length != 6) return AppColors.primary;
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    (tenant.name.isNotEmpty ? tenant.name[0] : 'C'),
                    style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              (tenant.name.isNotEmpty ? tenant.name[0] : 'C'),
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tenant.name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1B5E20)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              if (tenant.motto != null)
                                Text('"${tenant.motto}"',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (tenant.address != null && tenant.address!.isNotEmpty)
                          _Chip(icon: Icons.location_on, text: tenant.address!),
                        _Chip(
                            icon: Icons.star,
                            text: tenant.subscriptionTier.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Visit Portal',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor)),
                        Icon(Icons.arrow_forward, color: _primaryColor, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
