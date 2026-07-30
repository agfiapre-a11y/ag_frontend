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
  String _view = 'home'; // 'home' = landing page, 'church_home' = per-church page, 'portal' = login form

  List<TenantConfig> _churches = [];
  bool _loadingChurches = true;
  TenantConfig? _selectedChurch;
  bool _loadingBranding = false;

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
    setState(() {
      _view = 'home';
      _selectedChurch = null;
    });
  }

  Future<void> _selectChurch(TenantConfig church) async {
    setState(() {
      _loadingBranding = true;
      _selectedChurch = church;
    });

    if (ApiConfig.isConfigured) {
      try {
        final uri = Uri.parse('${ApiConfig.baseUrl}/tenants/public/${church.slug}');
        final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            _selectedChurch = TenantConfig.fromJson(data);
            _loadingBranding = false;
          });
        } else {
          setState(() => _loadingBranding = false);
        }
      } catch (_) {
        setState(() => _loadingBranding = false);
      }
    } else {
      setState(() => _loadingBranding = false);
    }

    setState(() => _view = 'church_home');
  }

  void _openPortalForChurch() {
    if (_selectedChurch != null) {
      ref.read(tenantProvider.notifier).setConfig(_selectedChurch!);
    }
    setState(() => _view = 'portal');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    if (_view == 'portal') {
      return _buildPortalView(context, isMobile);
    }
    if (_view == 'church_home') {
      return _buildChurchHomeView(context, isMobile);
    }
    return _buildHomeView(context, isMobile);
  }

  // ── Portal View (Login Form) ──────────────────────────────────────────────
  Widget _buildPortalView(BuildContext context, bool isMobile) {
    final tenantConfig = ref.watch(tenantConfigProvider);
    final appName = tenantConfig?.appName ?? tenantConfig?.name ?? _selectedChurch?.name ?? 'Paradise AG';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 400 ? 16.0 : 24.0;
    final formMaxWidth = 525.0;
    final portalPrimaryColor = tenantConfig != null
        ? _parseColor(tenantConfig.primaryColor, AppColors.primary)
        : (_selectedChurch != null
            ? _parseColor(_selectedChurch!.primaryColor, AppColors.primary)
            : AppColors.primary);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              portalPrimaryColor,
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
                                      onPressed: () {
                                        if (_selectedChurch != null) {
                                          setState(() => _view = 'church_home');
                                        } else {
                                          _goHome();
                                        }
                                      },
                                      icon: const Icon(Icons.arrow_back, size: 18),
                                      label: Text(_selectedChurch != null ? 'Church' : 'Home',
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
          _buildNavBar(isMobile),
          _buildHeroSection(isMobile),
          _buildStatsSection(isMobile),
          _buildAboutSection(isMobile),
          _buildStrategySection(isMobile),
          _buildChurchesSection(isMobile),
          _buildLegacySection(isMobile),
          _buildContactSection(isMobile),
          _buildFooterSliver(isMobile),
        ],
      ),
    );
  }

  // ── Per-Church Branded Home View ──────────────────────────────────────────
  Widget _buildChurchHomeView(BuildContext context, bool isMobile) {
    if (_loadingBranding) {
      return Scaffold(
        body: Container(
          color: const Color(0xFF0B1D3A),
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
        ),
      );
    }

    final church = _selectedChurch!;
    final primaryColor = _parseColor(church.primaryColor, const Color(0xFF0B1D3A));
    final accentColor = _parseColor(church.secondaryColor, AppColors.secondary);
    final churchName = church.name;
    final motto = church.motto ?? 'Welcome to our church';
    final aboutText = church.aboutText ?? 'A Christ-centered community dedicated to worship, fellowship, and service.';
    final mission = church.mission ?? 'To make disciples of all nations, baptizing them in the name of the Father, Son, and Holy Spirit.';
    final vision = church.vision ?? 'A vibrant church transforming lives through the power of the Gospel.';
    final pastorMessage = church.pastorMessage;
    final address = church.address ?? 'Contact the church office for directions';
    final phone = church.phone;
    final email = church.email;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Church Nav Bar ──
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 80,
                vertical: 14,
              ),
              child: Row(
                children: [
                  _churchLogo(church, primaryColor, 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(churchName,
                            style: GoogleFonts.poppins(
                                fontSize: isMobile ? 14 : 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (motto.isNotEmpty)
                          Text(motto,
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: accentColor,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (!isMobile) ...[
                    TextButton(
                      onPressed: () => _scrollTo(200),
                      child: Text('About',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: () => _scrollTo(500),
                      child: Text('Mission',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: () => _scrollTo(800),
                      child: Text('Contact',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 20),
                  ],
                  ElevatedButton(
                    onPressed: _openPortalForChurch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Sign In',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          // ── Church Hero ──
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: isMobile ? 480 : 600,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.85),
                        primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (church.bannerUrl != null)
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.15,
                            child: Image.network(
                              church.bannerUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox(),
                            ),
                          ),
                        ),
                      SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 24 : 80,
                            vertical: isMobile ? 30 : 60,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.church, color: accentColor, size: 14),
                                    const SizedBox(width: 8),
                                    Text(churchName.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: accentColor,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Welcome to\n$churchName',
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 30 : 52,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 560),
                                child: Text(
                                  aboutText,
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 17,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    height: 1.6,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _openPortalForChurch,
                                    icon: const Icon(Icons.login, size: 18),
                                    label: Text('Access Portal',
                                        style: GoogleFonts.poppins(
                                            fontSize: isMobile ? 13 : 15,
                                            fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: primaryColor,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 24 : 36,
                                        vertical: isMobile ? 12 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () => _scrollTo(500),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 20 : 32,
                                        vertical: isMobile ? 12 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text('Learn More',
                                        style: GoogleFonts.poppins(
                                            fontSize: isMobile ? 13 : 15)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Church About / Mission / Vision ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 80,
                vertical: isMobile ? 48 : 80,
              ),
              color: const Color(0xFFF7F6F2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('ABOUT US',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Who We Are',
                      style: GoogleFonts.poppins(
                          fontSize: isMobile ? 26 : 38,
                          fontWeight: FontWeight.w800,
                          color: primaryColor)),
                  const SizedBox(height: 20),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Text(
                      aboutText,
                      style: GoogleFonts.poppins(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[700],
                          height: 1.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  isMobile
                      ? Column(
                          children: [
                            _churchValueCard(Icons.flag, 'Our Mission', mission, accentColor),
                            const SizedBox(height: 12),
                            _churchValueCard(Icons.visibility, 'Our Vision', vision, accentColor),
                            const SizedBox(height: 12),
                            _churchValueCard(Icons.format_quote, 'Our Motto', '"$motto"', accentColor),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _churchValueCard(Icons.flag, 'Our Mission', mission, accentColor)),
                            const SizedBox(width: 16),
                            Expanded(child: _churchValueCard(Icons.visibility, 'Our Vision', vision, accentColor)),
                            const SizedBox(width: 16),
                            Expanded(child: _churchValueCard(Icons.format_quote, 'Our Motto', '"$motto"', accentColor)),
                          ],
                        ),
                ],
              ),
            ),
          ),

          // ── Pastor's Message (if available) ──
          if (pastorMessage != null && pastorMessage.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 80,
                  vertical: isMobile ? 40 : 64,
                ),
                color: primaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text("PASTOR'S MESSAGE",
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Text(
                        '"$pastorMessage"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 16 : 20,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.7,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Church Contact ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 80,
                vertical: isMobile ? 40 : 64,
              ),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contact Us',
                      style: GoogleFonts.poppins(
                          fontSize: isMobile ? 20 : 28,
                          fontWeight: FontWeight.w800,
                          color: primaryColor)),
                  const SizedBox(height: 32),
                  isMobile
                      ? Column(
                          children: [
                            _contactItem(Icons.location_on, 'Address', address),
                            if (phone != null && phone.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _contactItem(Icons.phone, 'Phone', phone),
                            ],
                            if (email != null && email.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _contactItem(Icons.email, 'Email', email),
                            ],
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _contactItem(Icons.location_on, 'Address', address)),
                            if (phone != null && phone.isNotEmpty) ...[
                              const SizedBox(width: 32),
                              Expanded(child: _contactItem(Icons.phone, 'Phone', phone)),
                            ],
                            if (email != null && email.isNotEmpty) ...[
                              const SizedBox(width: 32),
                              Expanded(child: _contactItem(Icons.email, 'Email', email)),
                            ],
                          ],
                        ),
                  const SizedBox(height: 24),
                  // Social links
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (church.facebookUrl != null && church.facebookUrl!.isNotEmpty)
                        _socialChip(Icons.facebook, 'Facebook'),
                      if (church.instagramUrl != null && church.instagramUrl!.isNotEmpty)
                        _socialChip(Icons.camera_alt, 'Instagram'),
                      if (church.twitterUrl != null && church.twitterUrl!.isNotEmpty)
                        _socialChip(Icons.alternate_email, 'Twitter'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Church Footer ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 80,
                vertical: 32,
              ),
              color: primaryColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      _churchLogo(church, primaryColor, 36),
                      const SizedBox(width: 10),
                      Text(churchName,
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Spacer(),
                      TextButton(
                        onPressed: _goHome,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text('All Churches',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    '© ${DateTime.now().year} $churchName · Paradise AG Platform',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _churchLogo(TenantConfig church, Color fallbackColor, double size) {
    if (church.logoUrl != null && church.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          church.logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _churchLogoPlaceholder(church, fallbackColor, size),
        ),
      );
    }
    return _churchLogoPlaceholder(church, fallbackColor, size);
  }

  Widget _churchLogoPlaceholder(TenantConfig church, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Center(
        child: Text(
          church.name.isNotEmpty ? church.name[0] : 'C',
          style: GoogleFonts.poppins(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),
    );
  }

  Widget _churchValueCard(IconData icon, String title, String desc, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0B1D3A))),
          const SizedBox(height: 6),
          Text(desc,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }

  Color _parseColor(String hex, Color fallback) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return fallback;
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  // ── Navigation Bar ────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildNavBar(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1D3A),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 80,
          vertical: 14,
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/AG_logo.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.church, color: Color(0xFF0B1D3A), size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assemblies of God',
                    style: GoogleFonts.poppins(
                        fontSize: isMobile ? 14 : 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Ghana · #ShiftGrowTransform',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            if (!isMobile) ...[
              _navLink('About', () => _scrollTo(200)),
              const SizedBox(width: 28),
              _navLink('Strategy', () => _scrollTo(400)),
              const SizedBox(width: 28),
              _navLink('Churches', () => _scrollTo(600)),
              const SizedBox(width: 28),
              _navLink('Contact', () => _scrollTo(800)),
              const SizedBox(width: 28),
            ],
            ElevatedButton(
              onPressed: _openPortal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: const Color(0xFF0B1D3A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Sign In',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500)),
    );
  }

  void _scrollTo(double offset) {
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildHeroSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            height: isMobile ? 520 : 680,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1D3A),
                  Color(0xFF112D5C),
                  Color(0xFF0B1D3A),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'assets/images/banner2.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 80,
                      vertical: isMobile ? 30 : 60,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.secondary, size: 14),
                              const SizedBox(width: 8),
                              Text('2026 THEME · THE FAITH OF OUR FATHERS',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Assemblies of God,\nGhana',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 32 : 56,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 580),
                          child: Text(
                            'A dynamic Pentecostal church dedicated to embracing the entirety of the Gospel. We are committed to evangelism, missions, fervent prayer, social action, and nurturing fellowship.',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 17,
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _openPortal,
                              icon: const Icon(Icons.login, size: 18),
                              label: Text('Access Portal',
                                  style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 13 : 15,
                                      fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: const Color(0xFF0B1D3A),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 24 : 36,
                                  vertical: isMobile ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => _scrollTo(600),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 32,
                                  vertical: isMobile ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Find a Church',
                                  style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 13 : 15)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            _socialIcon(Icons.language, 'Website'),
                            const SizedBox(width: 20),
                            _socialIcon(Icons.facebook, 'Facebook'),
                            const SizedBox(width: 20),
                            _socialIcon(Icons.play_circle_filled, 'YouTube'),
                          ],
                        ),
                        const Spacer(),
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

  Widget _socialIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 18),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }

  // ── Stats Band ────────────────────────────────────────────────────────────
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
        color: Colors.white,
        child: isMobile
            ? Column(
                children: stats
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
          vertical: isMobile ? 48 : 80,
        ),
        color: const Color(0xFFF7F6F2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text('WHO WE ARE',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 16),
            Text('All The Gospel',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 26 : 38,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1D3A))),
            const SizedBox(height: 20),
            Container(
              constraints: BoxConstraints(maxWidth: 720),
              child: Text(
                'Assemblies of God, Ghana is a dynamic Pentecostal church dedicated to embracing the entirety of the Gospel. Committed to the belief in the divine Word of God, the church actively engages in evangelism, missions, fervent prayer, social action interventions and nurturing fellowship.',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey[700],
                    height: 1.8),
              ),
            ),
            const SizedBox(height: 32),
            isMobile
                ? Column(
                    children: [
                      _aboutValueCard(Icons.flag, 'Evangelism', 'Reaching every corner of Ghana with the Gospel of Jesus Christ.'),
                      const SizedBox(height: 12),
                      _aboutValueCard(Icons.public, 'Missions', 'Sending laborers into the harvest field, both locally and internationally.'),
                      const SizedBox(height: 12),
                      _aboutValueCard(Icons.volunteer_activism, 'Social Action', 'Serving communities through education, healthcare, and outreach.'),
                      const SizedBox(height: 12),
                      _aboutValueCard(Icons.groups, 'Fellowship', 'Nurturing believers in a Christ-centered community of faith.'),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _aboutValueCard(Icons.flag, 'Evangelism', 'Reaching every corner of Ghana with the Gospel.')),
                      const SizedBox(width: 16),
                      Expanded(child: _aboutValueCard(Icons.public, 'Missions', 'Sending laborers into the harvest field.')),
                      const SizedBox(width: 16),
                      Expanded(child: _aboutValueCard(Icons.volunteer_activism, 'Social Action', 'Serving communities through outreach.')),
                      const SizedBox(width: 16),
                      Expanded(child: _aboutValueCard(Icons.groups, 'Fellowship', 'Nurturing believers in Christ-centered community.')),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _aboutValueCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1D3A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 22),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0B1D3A))),
          const SizedBox(height: 6),
          Text(desc,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }

  // ── Strategy Section (Six Rs) ──────────────────────────────────────────────
  SliverToBoxAdapter _buildStrategySection(bool isMobile) {
    final strategies = [
      _StrategyData(icon: Icons.campaign, title: 'Reach', desc: 'Evangelize the lost and plant new churches across Ghana.'),
      _StrategyData(icon: Icons.construction, title: 'Rebuild', desc: 'Strengthen existing churches and restore fading congregations.'),
      _StrategyData(icon: Icons.healing, title: 'Restore', desc: 'Restore broken lives through prayer, counseling, and care.'),
      _StrategyData(icon: Icons.school, title: 'Reform', desc: 'Disciple believers in sound doctrine and holy living.'),
      _StrategyData(icon: Icons.trending_up, title: 'Reposition', desc: 'Position the church for greater impact and influence.'),
      _StrategyData(icon: Icons.auto_awesome, title: 'Rebrand', desc: 'Refresh our identity while honoring our Pentecostal heritage.'),
    ];

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 48 : 80,
        ),
        color: const Color(0xFF0B1D3A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text('TRANSFORMATION AGENDA',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 16),
            Text('The Six Rs Strategy',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 24 : 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                'Anchored on Micah 4:1, the Transformation Agenda calls us to Shift, Grow, and Transform the church through six strategic pillars.',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 13 : 15,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.6),
              ),
            ),
            const SizedBox(height: 40),
            isMobile
                ? Column(
                    children: strategies
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _strategyCard(s, true),
                            ))
                        .toList(),
                  )
                : Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: strategies
                        .map((s) => SizedBox(
                              width: 340,
                              child: _strategyCard(s, false),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _strategyCard(_StrategyData s, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Text(s.desc,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Churches Directory Section ────────────────────────────────────────────
  SliverToBoxAdapter _buildChurchesSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 48 : 80,
        ),
        color: const Color(0xFFF7F6F2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text('DIRECTORY',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Find Your Church',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 24 : 36,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1D3A))),
            const SizedBox(height: 12),
            Text(
                'Browse churches on the Paradise AG platform. Click a church to access its portal.',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 13 : 15, color: Colors.grey[600])),
            const SizedBox(height: 40),
            if (_loadingChurches)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(color: Color(0xFF0B1D3A)),
                ),
              )
            else if (_churches.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Text('No churches found.',
                      style: GoogleFonts.poppins(color: Colors.grey[500])),
                ),
              )
            else
              isMobile
                  ? Column(
                      children: _churches
                              .map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _ChurchCard(tenant: c, isMobile: true, onTap: () => _selectChurch(c)),
                                  ))
                          .toList(),
                    )
                  : Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: _churches
                          .map((c) => SizedBox(
                                width: 340,
                                child: _ChurchCard(tenant: c, isMobile: false, onTap: () => _selectChurch(c)),
                              ))
                          .toList(),
                    ),
          ],
        ),
      ),
    );
  }

  // ── Legacy Temple Project CTA ──────────────────────────────────────────────
  SliverToBoxAdapter _buildLegacySection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 48 : 72,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF112D5C),
              Color(0xFF0B1D3A),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Text('LEGACY TEMPLE PROJECT',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5)),
            ),
            const SizedBox(height: 24),
            Text(
              'Build a House for God',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 24 : 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Text(
                'The Legacy Temple Project Commission is on a mission to provide every Assemblies of God church with a dignified place of worship. Partner with us to make this vision a reality.',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _openPortal,
                  icon: const Icon(Icons.favorite, size: 18),
                  label: Text('Give to the Project',
                      style: GoogleFonts.poppins(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: const Color(0xFF0B1D3A),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 28 : 40,
                      vertical: isMobile ? 14 : 18,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Contact Section ────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildContactSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 40 : 64,
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Us',
                style: GoogleFonts.poppins(
                    fontSize: isMobile ? 20 : 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B1D3A))),
            const SizedBox(height: 32),
            isMobile
                ? Column(
                    children: [
                      _contactItem(Icons.location_on, 'The Head Office',
                          'P.O. Box AN 7644, Accra-North, Ghana\nDigital Address: GA-031-9533\nGamel Abdul Naser Rd'),
                      const SizedBox(height: 20),
                      _contactItem(Icons.phone, 'Phone',
                          '0302 788 583\n0302 788 588'),
                      const SizedBox(height: 20),
                      _contactItem(Icons.email, 'Email',
                          'agghanagc@gmail.com'),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _contactItem(Icons.location_on, 'The Head Office',
                          'P.O. Box AN 7644, Accra-North, Ghana\nDigital Address: GA-031-9533\nGamel Abdul Naser Rd')),
                      const SizedBox(width: 32),
                      Expanded(child: _contactItem(Icons.phone, 'Phone',
                          '0302 788 583\n0302 788 588')),
                      const SizedBox(width: 32),
                      Expanded(child: _contactItem(Icons.email, 'Email',
                          'agghanagc@gmail.com')),
                    ],
                  ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _socialChip(Icons.language, 'Website'),
                _socialChip(Icons.facebook, 'Facebook'),
                _socialChip(Icons.play_circle_filled, 'YouTube'),
                _socialChip(Icons.camera_alt, 'Instagram'),
                _socialChip(Icons.alternate_email, 'Twitter'),
                _socialChip(Icons.business_center, 'LinkedIn'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactItem(IconData icon, String title, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1D3A).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0B1D3A), size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B1D3A))),
              const SizedBox(height: 4),
              Text(detail,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D3A).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF0B1D3A).withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0B1D3A)),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF0B1D3A),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildFooterSliver(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: 40,
        ),
        color: const Color(0xFF0B1D3A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/AG_logo.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.church, color: Color(0xFF0B1D3A), size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Assemblies of God, Ghana',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _footerCol('Platform', ['About Us', 'Leadership', 'Locations', 'News & Updates']),
                      const SizedBox(height: 20),
                      _footerCol('Ministries', ['Agencies', 'Departments', 'Missions', 'Associations']),
                      const SizedBox(height: 20),
                      _footerCol('Resources', ['Legacy Temple Project', 'Give', 'Contact Us']),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _footerCol('Platform', ['About Us', 'Leadership', 'Locations', 'News & Updates'])),
                      const SizedBox(width: 40),
                      Expanded(flex: 2, child: _footerCol('Ministries', ['Agencies', 'Departments', 'Missions', 'Associations'])),
                      const SizedBox(width: 40),
                      Expanded(flex: 2, child: _footerCol('Resources', ['Legacy Temple Project', 'Give', 'Contact Us'])),
                    ],
                  ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              '© ${DateTime.now().year} Assemblies of God, Ghana. All rights reserved.',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 6),
            Text(
              'Paradise AG — Church Information Management System\nDesigned by Echendaa Educational and Research Unit · Distributed by Nung A Bibile Foundation',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.white.withValues(alpha: 0.3), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ...links.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
            )),
      ],
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
              onPressed: () {
                if (_selectedChurch != null) {
                  setState(() => _view = 'church_home');
                } else {
                  _goHome();
                }
              },
              child: Text(
                _selectedChurch != null ? '← Back to Church' : '← Back to Home',
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

class _StrategyData {
  final IconData icon;
  final String title;
  final String desc;
  _StrategyData({required this.icon, required this.title, required this.desc});
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
            child: Icon(stat.icon, color: const Color(0xFF0B1D3A), size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat.value,
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0B1D3A))),
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
    if (hex.length != 6) return const Color(0xFF0B1D3A);
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
                                      color: const Color(0xFF0B1D3A)),
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
