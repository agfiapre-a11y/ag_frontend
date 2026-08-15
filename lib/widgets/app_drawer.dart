import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final user = appState.user!;
    final church = appState.church;
    final role = user.role;

    return Drawer(
      child: Column(
        children: [
          // ── Branding Header (80px height) ─────────────────────────────────
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: const BoxDecoration(
              color: AppColors.emeraldDeep,
            ),
            child: Row(
              children: [
                const Icon(Icons.church, color: AppColors.goldWarm, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        church != null && church.name.isNotEmpty
                            ? church.name
                            : 'Paradise AG',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cardWhite,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation Items ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                // Dashboard — all roles
                _EmeraldNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/home'),

                // Library — available to every authenticated user
                _EmeraldNavItem(
                    icon: Icons.local_library_outlined,
                    label: 'Library',
                    route: '/library'),

                // Community — social networking for every authenticated user
                _EmeraldNavItem(
                    icon: Icons.groups_outlined,
                    label: 'Community',
                    route: '/community'),

                const SizedBox(height: 16),

                // ── Super System Administrator ───────────────────────────
                if (role == AppRoles.superSystemAdmin) ...[
                  _EmeraldNavItem(
                      icon: Icons.church_outlined,
                      label: 'Churches',
                      route: '/super-admin/churches'),
                  _EmeraldNavItem(
                      icon: Icons.business_outlined,
                      label: 'Organizations',
                      route: '/organizations'),
                  _EmeraldNavItem(
                      icon: Icons.map_outlined,
                      label: 'Regions',
                      route: '/regions'),
                  _EmeraldNavItem(
                      icon: Icons.location_city_outlined,
                      label: 'Districts',
                      route: '/districts'),
                  _EmeraldNavItem(
                      icon: Icons.place_outlined,
                      label: 'Areas',
                      route: '/areas'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.settings_outlined,
                      label: 'Church Settings',
                      route: '/settings/church'),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Users',
                      route: '/users'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── National Administrator ───────────────────────────────
                if (role == AppRoles.nationalAdmin) ...[
                  _EmeraldNavItem(
                      icon: Icons.map_outlined,
                      label: 'Regions',
                      route: '/regions'),
                  _EmeraldNavItem(
                      icon: Icons.location_city_outlined,
                      label: 'Districts',
                      route: '/districts'),
                  _EmeraldNavItem(
                      icon: Icons.place_outlined,
                      label: 'Areas',
                      route: '/areas'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Users',
                      route: '/users'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── National Executive ─────────────────────────────────────
                if (role == AppRoles.nationalExecutive) ...[
                  _EmeraldNavItem(
                      icon: Icons.map_outlined,
                      label: 'Regions',
                      route: '/regions'),
                  _EmeraldNavItem(
                      icon: Icons.location_city_outlined,
                      label: 'Districts',
                      route: '/districts'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance Reports',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                ],

                // ── Regional Administrator ───────────────────────────────────
                if (role == AppRoles.regionalAdmin) ...[
                  _EmeraldNavItem(
                      icon: Icons.location_city_outlined,
                      label: 'Districts',
                      route: '/districts'),
                  _EmeraldNavItem(
                      icon: Icons.place_outlined,
                      label: 'Areas',
                      route: '/areas'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Users',
                      route: '/users'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Regional Bishop ────────────────────────────────────────
                if (role == AppRoles.regionalBishop) ...[
                  _EmeraldNavItem(
                      icon: Icons.location_city_outlined,
                      label: 'Districts',
                      route: '/districts'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance Reports',
                      route: '/finance'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── District Administrator ───────────────────────────────────
                if (role == AppRoles.districtAdmin) ...[
                  _EmeraldNavItem(
                      icon: Icons.place_outlined,
                      label: 'Areas',
                      route: '/areas'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Users',
                      route: '/users'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── District Pastor ────────────────────────────────────────
                if (role == AppRoles.districtPastor) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance Reports',
                      route: '/finance'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Area Administrator ───────────────────────────────────────
                if (role == AppRoles.areaAdmin) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Users',
                      route: '/users'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Local Church Administrator ───────────────────────────────
                if (role == AppRoles.localChurchAdmin) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Users',
                      route: '/users'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.favorite,
                      label: 'Tithes & Offerings',
                      route: '/finance/tithes-offerings-donations'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  _EmeraldNavItem(
                      icon: Icons.church,
                      label: 'Ministry',
                      route: '/ministry'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.settings_outlined,
                      label: 'Church Settings',
                      route: '/settings/church'),
                  _EmeraldNavItem(
                      icon: Icons.storage_outlined,
                      label: 'Data Management',
                      route: '/settings/data-management'),
                ],

                // ── Senior Pastor ────────────────────────────────────────────
                if (role == AppRoles.seniorPastor) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Users',
                      route: '/users'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.sports_basketball,
                      label: 'Youth Ministry',
                      route: '/ministry/youth'),
                  _EmeraldNavItem(
                      icon: Icons.man,
                      label: 'Men\'s Fellowship',
                      route: '/ministry/men'),
                  _EmeraldNavItem(
                      icon: Icons.woman,
                      label: 'Women\'s Fellowship',
                      route: '/ministry/women'),
                  _EmeraldNavItem(
                      icon: Icons.child_care,
                      label: 'Children\'s Ministry',
                      route: '/ministry/children'),
                  _EmeraldNavItem(
                      icon: Icons.assignment_outlined,
                      label: 'Reports',
                      route: '/finance'),
                ],

                // ── Associate Pastor ────────────────────────────────────────
                if (role == AppRoles.associatePastor) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/finance'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.sports_basketball,
                      label: 'Youth Ministry',
                      route: '/ministry/youth'),
                  _EmeraldNavItem(
                      icon: Icons.man,
                      label: 'Men\'s Fellowship',
                      route: '/ministry/men'),
                  _EmeraldNavItem(
                      icon: Icons.woman,
                      label: 'Women\'s Fellowship',
                      route: '/ministry/women'),
                  _EmeraldNavItem(
                      icon: Icons.child_care,
                      label: 'Children\'s Ministry',
                      route: '/ministry/children'),
                  _EmeraldNavItem(
                      icon: Icons.assignment_outlined,
                      label: 'Reports',
                      route: '/finance'),
                ],

                // ── Church Secretary ────────────────────────────────────────
                if (role == AppRoles.churchSecretary) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare',
                      route: '/welfare'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                ],

                // ── Finance Officer ──────────────────────────────────────────
                if (role == AppRoles.financeOfficer) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Finance', route: '/finance'),
                  _EmeraldNavItem(icon: Icons.favorite, label: 'Tithes & Offerings', route: '/finance/tithes-offerings-donations'),
                  _EmeraldNavItem(icon: Icons.savings, label: 'Budget & Spending', route: '/finance/budget-spending'),
                  _EmeraldNavItem(icon: Icons.add_circle, label: 'Income Entry', route: '/finance/income-entry'),
                  _EmeraldNavItem(icon: Icons.approval, label: 'Approvals', route: '/finance/approvals'),
                  _EmeraldNavItem(icon: Icons.assessment, label: 'Reports', route: '/finance/reports'),
                  _EmeraldNavItem(icon: Icons.people_outline, label: 'Members', route: '/members'),
                ],

                // ── Ministry Head ────────────────────────────────────────────
                if (role == AppRoles.ministryHead) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Departments',
                      route: '/departments'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Youth Ministry Head ───────────────────────────────────────
                if (role == AppRoles.youthMinistryHead) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Youth Dashboard',
                      route: '/ministry/youth'),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/ministry/youth/finance'),
                  _EmeraldNavItem(
                      icon: Icons.assessment_outlined,
                      label: 'Reports',
                      route: '/ministry/youth/reports'),
                  _EmeraldNavItem(
                      icon: Icons.campaign_outlined,
                      label: 'Announcements',
                      route: '/ministry/youth/announcements'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Men's Fellowship Head ─────────────────────────────────────
                if (role == AppRoles.menFellowshipHead) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Men\'s Dashboard',
                      route: '/ministry/men'),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/ministry/men/finance'),
                  _EmeraldNavItem(
                      icon: Icons.assessment_outlined,
                      label: 'Reports',
                      route: '/ministry/men/reports'),
                  _EmeraldNavItem(
                      icon: Icons.campaign_outlined,
                      label: 'Announcements',
                      route: '/ministry/men/announcements'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Women's Fellowship Head ───────────────────────────────────
                if (role == AppRoles.womenFellowshipHead) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Women\'s Dashboard',
                      route: '/ministry/women'),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/ministry/women/finance'),
                  _EmeraldNavItem(
                      icon: Icons.assessment_outlined,
                      label: 'Reports',
                      route: '/ministry/women/reports'),
                  _EmeraldNavItem(
                      icon: Icons.campaign_outlined,
                      label: 'Announcements',
                      route: '/ministry/women/announcements'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Children's Ministry Head ──────────────────────────────────
                if (role == AppRoles.childrenMinistryHead) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Children\'s Dashboard',
                      route: '/ministry/children'),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Finance',
                      route: '/ministry/children/finance'),
                  _EmeraldNavItem(
                      icon: Icons.assessment_outlined,
                      label: 'Reports',
                      route: '/ministry/children/reports'),
                  _EmeraldNavItem(
                      icon: Icons.campaign_outlined,
                      label: 'Announcements',
                      route: '/ministry/children/announcements'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Welfare Head ───────────────────────────────────────────────
                if (role == AppRoles.welfareHead) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.handshake_outlined,
                      label: 'Welfare Cases',
                      route: '/welfare'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Welfare Finance',
                      route: '/welfare/finance'),
                  _EmeraldNavItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Transactions',
                      route: '/welfare/finance/transactions'),
                  _EmeraldNavItem(
                      icon: Icons.calendar_month_outlined,
                      label: 'Contributions',
                      route: '/welfare/finance/contributions'),
                  _EmeraldNavItem(
                      icon: Icons.payment_outlined,
                      label: 'Make Payment',
                      route: '/welfare/finance/payment'),
                  _EmeraldNavItem(
                      icon: Icons.groups_2_outlined,
                      label: 'Dept Welfare',
                      route: '/welfare/finance/departments'),
                  _EmeraldNavItem(
                      icon: Icons.assessment_outlined,
                      label: 'Reports',
                      route: '/welfare/finance/reports'),
                  _EmeraldNavItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Statements',
                      route: '/welfare/finance/statements'),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                ],

                // ── Cell Leader ───────────────────────────────────────────────
                if (role == AppRoles.cellLeader) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.people_outline,
                      label: 'Members',
                      route: '/members'),
                  _EmeraldNavItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Attendance',
                      route: '/attendance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                ],

                // ── Volunteer ────────────────────────────────────────────────
                if (role == AppRoles.volunteer) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],

                // ── Member ────────────────────────────────────────────────
                if (role == AppRoles.member) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.how_to_reg,
                      label: 'Self Check-In',
                      route: '/attendance/self-checkin'),
                  _EmeraldNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'My Finances',
                      route: '/my-finance'),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                  _EmeraldNavItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'My Welfare Statement',
                      route: '/welfare/finance/statements'),
                ],

                // ── Guest ────────────────────────────────────────────────
                if (role == AppRoles.guest) ...[
                  const SizedBox(height: 16),
                  _EmeraldNavItem(
                      icon: Icons.event_outlined,
                      label: 'Events',
                      route: '/events'),
                  _EmeraldNavItem(
                      icon: Icons.video_library_outlined,
                      label: 'Sermons',
                      route: '/sermons'),
                ],
              ],
            ),
          ),

          // ── Bottom Section (Help & Support) ─────────────────────────────
          const Divider(color: AppColors.emeraldForest, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.goldWarm,
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                            color: AppColors.emeraldDeep,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.poppins(
                              color: AppColors.cardWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            AppRoles.label(role),
                            style: GoogleFonts.poppins(
                              color: AppColors.cardWhite.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/profile');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, 
                          color: AppColors.cardWhite.withValues(alpha: 0.8),
                          size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.poppins(
                            color: AppColors.cardWhite.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(appStateProvider.notifier).logout();
                    context.go('/login');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.logout,
                          color: AppColors.cardWhite.withValues(alpha: 0.8),
                          size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: GoogleFonts.poppins(
                            color: AppColors.cardWhite.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EmeraldNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _EmeraldNavItem(
      {required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    final currentLoc = GoRouterState.of(context).matchedLocation;
    final active = currentLoc == route ||
        (route != '/home' && currentLoc.startsWith(route));

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: active ? EmeraldTheme.activeNavDecoration : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon,
            color: active ? AppColors.cardWhite : AppColors.cardWhite.withValues(alpha: 0.6),
            size: AppColors.iconSmall),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: active ? AppColors.cardWhite : AppColors.cardWhite.withValues(alpha: 0.8),
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (!active) context.go(route);
        },
      ),
    );
  }
}
