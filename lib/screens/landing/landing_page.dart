import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../services/api_config.dart';
import '../../models/tenant_config.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  List<TenantConfig> _churches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChurches();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChurches() async {
    if (!ApiConfig.isConfigured) {
      setState(() {
        _loading = false;
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
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _churches = [_defaultChurch()];
        });
      }
    } catch (_) {
      setState(() {
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildHeroSection(isMobile),
          _buildStatsSection(isMobile),
          _buildAboutSection(isMobile, isTablet),
          _buildCoreValuesSection(isMobile),
          _buildMinistriesSection(isMobile),
          _buildChurchesSection(isMobile),
          _buildLeadershipSection(isMobile),
          _buildCallToAction(isMobile),
          _buildFooter(isMobile),
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
                                onPressed: () => context.go('/login'),
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
                                    onPressed: () => context.go('/login'),
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
                                      // Scroll down to churches section
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent * 0.6,
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

  final _scrollController = ScrollController();

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
  SliverToBoxAdapter _buildAboutSection(bool isMobile, bool isTablet) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 40 : 64,
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAboutContent(),
                  const SizedBox(height: 32),
                  _buildAboutImage(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: isTablet ? 1 : 1, child: _buildAboutContent()),
                  const SizedBox(width: 48),
                  Expanded(flex: isTablet ? 1 : 1, child: _buildAboutImage()),
                ],
              ),
      ),
    );
  }

  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('About Us',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ),
        const SizedBox(height: 16),
        Text(
          'A Movement of Faith, Hope, and Love',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The Assemblies of God, Ghana is a Pentecostal denomination founded on the principles of the full gospel, evangelism, and missions. Since its establishment in Ghana, the church has grown from a small fellowship to a nationwide movement with thousands of congregations.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.7,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We are part of the World Assemblies of God Fellowship, one of the largest Pentecostal fellowships in the world, with over 67 million adherents across more than 150 countries.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey[700],
            height: 1.7,
          ),
        ),
        const SizedBox(height: 20),
        _buildHighlightItem(Icons.flag, 'Our Mission',
            'To evangelize the lost, worship God, and equip believers for ministry through the power of the Holy Spirit.'),
        const SizedBox(height: 12),
        _buildHighlightItem(Icons.visibility, 'Our Vision',
            'To see every community in Ghana transformed by the gospel of Jesus Christ through vibrant local churches.'),
        const SizedBox(height: 12),
        _buildHighlightItem(Icons.favorite, 'Our Values',
            'Faith, Integrity, Compassion, Excellence, and Unity in the body of Christ.'),
      ],
    );
  }

  Widget _buildHighlightItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(desc,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600], height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutImage() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/banner2.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.church, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"Go therefore and make disciples of all the nations..." — Matthew 28:19',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Core Values Section ───────────────────────────────────────────────────
  SliverToBoxAdapter _buildCoreValuesSection(bool isMobile) {
    final values = [
      _CoreValue(
        icon: Icons.volunteer_activism,
        title: 'Evangelism',
        desc: 'Sharing the gospel with every creature, fulfilling the Great Commission.',
        color: const Color(0xFFE65100),
      ),
      _CoreValue(
        icon: Icons.school,
        title: 'Discipleship',
        desc: 'Nurturing believers to spiritual maturity through teaching and mentoring.',
        color: const Color(0xFF1565C0),
      ),
      _CoreValue(
        icon: Icons.groups,
        title: 'Fellowship',
        desc: 'Building Christ-centered communities that support and encourage one another.',
        color: const Color(0xFF6A1B9A),
      ),
      _CoreValue(
        icon: Icons.public,
        title: 'Missions',
        desc: 'Sending missionaries across Ghana, Africa, and the ends of the earth.',
        color: const Color(0xFF00838F),
      ),
      _CoreValue(
        icon: Icons.handshake,
        title: 'Compassion',
        desc: 'Demonstrating Christ\'s love through welfare, healthcare, and community service.',
        color: const Color(0xFFC62828),
      ),
      _CoreValue(
        icon: Icons.auto_awesome,
        title: 'Worship',
        desc: 'Experiencing God\'s presence through Spirit-filled worship and prayer.',
        color: const Color(0xFF2E7D32),
      ),
    ];

    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFFF5F5F0),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 40 : 64,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our Core Values',
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Text('The pillars that guide our ministry and community',
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.grey[600])),
            const SizedBox(height: 32),
            isMobile
                ? Column(
                    children: values
                        .map((v) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _CoreValueCard(value: v),
                            ))
                        .toList(),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: values
                        .map((v) => _CoreValueCard(value: v))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Ministries Section ────────────────────────────────────────────────────
  SliverToBoxAdapter _buildMinistriesSection(bool isMobile) {
    final ministries = [
      _MinistryData(
        icon: Icons.lightbulb,
        title: 'Youth Ministry',
        desc: 'Empowering young people to live Christ-centered lives.',
        color: Colors.orange,
      ),
      _MinistryData(
        icon: Icons.man,
        title: "Men's Fellowship",
        desc: 'Equipping men to be godly leaders in their homes and communities.',
        color: Colors.blue.shade700,
      ),
      _MinistryData(
        icon: Icons.woman,
        title: "Women's Fellowship",
        desc: 'Inspiring women to walk in faith, wisdom, and grace.',
        color: Colors.pink,
      ),
      _MinistryData(
        icon: Icons.child_care,
        title: "Children's Ministry",
        desc: 'Nurturing the next generation in the knowledge of God.',
        color: Colors.teal,
      ),
      _MinistryData(
        icon: Icons.volunteer_activism,
        title: 'Welfare & Outreach',
        desc: 'Caring for the vulnerable and reaching out to communities in need.',
        color: Colors.deepPurple,
      ),
      _MinistryData(
        icon: Icons.menu_book,
        title: 'Bible Study & Discipleship',
        desc: 'Deepening faith through systematic study of God\'s Word.',
        color: Colors.indigo,
      ),
    ];

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 40 : 64,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our Ministries',
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Text('Serving every age group and walk of life',
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.grey[600])),
            const SizedBox(height: 32),
            isMobile
                ? Column(
                    children: ministries
                        .map((m) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MinistryCard(ministry: m),
                            ))
                        .toList(),
                  )
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.0,
                    children: ministries
                        .map((m) => _MinistryCard(ministry: m))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Churches Section ──────────────────────────────────────────────────────
  SliverToBoxAdapter _buildChurchesSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        key: const ValueKey('churches-section'),
        color: const Color(0xFFF5F5F0),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 40 : 64,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find a Church Near You',
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Text('Connect with a local assembly in your community',
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.grey[600])),
            const SizedBox(height: 32),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_churches.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('No churches available yet.',
                      style: GoogleFonts.poppins(
                          fontSize: 15, color: Colors.grey[500])),
                ),
              )
            else
              isMobile
                  ? Column(
                      children: _churches
                          .map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ChurchCard(tenant: c, isMobile: true),
                              ))
                          .toList(),
                    )
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.8,
                      children: _churches
                          .map((c) => _ChurchCard(tenant: c, isMobile: false))
                          .toList(),
                    ),
          ],
        ),
      ),
    );
  }

  // ── Leadership Section ────────────────────────────────────────────────────
  SliverToBoxAdapter _buildLeadershipSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 80,
          vertical: isMobile ? 40 : 64,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our Leadership',
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B5E20))),
            const SizedBox(height: 8),
            Text('Guiding the flock with wisdom and integrity',
                style: GoogleFonts.poppins(
                    fontSize: 15, color: Colors.grey[600])),
            const SizedBox(height: 32),
            isMobile
                ? Column(
                    children: [
                      _LeaderCard(
                        name: 'General Superintendent',
                        role: 'Assemblies of God, Ghana',
                        isMobile: true,
                      ),
                      const SizedBox(height: 12),
                      _LeaderCard(
                        name: 'General Secretary',
                        role: 'Assemblies of God, Ghana',
                        isMobile: true,
                      ),
                      const SizedBox(height: 12),
                      _LeaderCard(
                        name: 'Treasurer',
                        role: 'Assemblies of God, Ghana',
                        isMobile: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _LeaderCard(
                          name: 'General Superintendent',
                          role: 'Assemblies of God, Ghana',
                          isMobile: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _LeaderCard(
                          name: 'General Secretary',
                          role: 'Assemblies of God, Ghana',
                          isMobile: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _LeaderCard(
                          name: 'Treasurer',
                          role: 'Assemblies of God, Ghana',
                          isMobile: false,
                        ),
                      ),
                    ],
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
              onPressed: () => context.go('/login'),
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

  // ── Footer ────────────────────────────────────────────────────────────────
  SliverToBoxAdapter _buildFooter(bool isMobile) {
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
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFooterBrand(),
                      const SizedBox(height: 24),
                      _buildFooterLinks(isMobile),
                      const SizedBox(height: 24),
                      _buildFooterContact(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildFooterBrand()),
                      const SizedBox(width: 40),
                      Expanded(flex: 2, child: _buildFooterLinks(isMobile)),
                      const SizedBox(width: 40),
                      Expanded(flex: 2, child: _buildFooterContact()),
                    ],
                  ),
            const SizedBox(height: 32),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              '© ${DateTime.now().year} Assemblies of God, Ghana. All rights reserved.\nDesigned by Echendaa Educational and Research Unit · Distributed by Nung A Bibile Foundation',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.church, color: Colors.white70, size: 24),
            const SizedBox(width: 8),
            Text('Paradise AG',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'The General Council of the Assemblies of God, Ghana — Reflecting Christ, Transforming Lives.',
          style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildFooterLinks(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Links',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 12),
        _footerLink('About Us'),
        _footerLink('Find a Church'),
        _footerLink('Our Ministries'),
        _footerLink('Sign In'),
      ],
    );
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
    );
  }

  Widget _buildFooterContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Us',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 12),
        _contactItem(Icons.location_on, 'P.O. Box, Accra, Ghana'),
        _contactItem(Icons.phone, '+233 (0) 30 000 0000'),
        _contactItem(Icons.email, 'info@assembliesofgod.org.gh'),
      ],
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────────────────────

class _StatData {
  final IconData icon;
  final String value;
  final String label;

  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(stat.icon, color: AppColors.primary, size: 28),
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
      ),
    );
  }
}

class _CoreValue {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _CoreValue({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

class _CoreValueCard extends StatelessWidget {
  final _CoreValue value;

  const _CoreValueCard({required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(value.icon, color: value.color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(value.title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Expanded(
              child: Text(value.desc,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600], height: 1.5),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinistryData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _MinistryData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

class _MinistryCard extends StatelessWidget {
  final _MinistryData ministry;

  const _MinistryCard({required this.ministry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ministry.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ministry.icon, color: ministry.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ministry.title,
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(ministry.desc,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[600], height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChurchCard extends StatelessWidget {
  final TenantConfig tenant;
  final bool isMobile;

  const _ChurchCard({required this.tenant, required this.isMobile});

  Color _parseColor(String hex, Color fallback) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 7) buffer.write('FF');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = _parseColor(tenant.primaryColor, const Color(0xFF2E7D32));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/login'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: primary,
                    radius: 20,
                    child: tenant.logoUrl != null
                        ? ClipOval(
                            child: Image.network(tenant.logoUrl!,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                                errorBuilder: (_, __, ___) => Text(
                                    tenant.name.substring(0, 1).toUpperCase(),
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))))
                        : Text(tenant.name.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tenant.name,
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tenant.motto != null)
                Text('"${tenant.motto}"',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis)
              else if (tenant.address != null)
                Text(tenant.address!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(tenant.address ?? 'Ghana',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderCard extends StatelessWidget {
  final String name;
  final String role;
  final bool isMobile;

  const _LeaderCard({
    required this.name,
    required this.role,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: isMobile ? 36 : 44,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Icon(Icons.person, size: isMobile ? 36 : 44, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(role,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
