import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/department.dart';
import '../../models/event.dart';
import '../../models/member.dart';
import '../../models/sermon.dart';
import '../../models/welfare_case.dart';
import '../../models/welfare_statement.dart';
import '../../models/ministry.dart';
import '../../models/ministry_finance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/notification_center_button.dart';
import '../../widgets/my_welfare_cases.dart';
import '../../widgets/finance_dashboard_content.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/emerald_welcome_section.dart';
import '../ministry/ministry_dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    
    // System Level
    if (user.role == AppRoles.superSystemAdmin) return const _SuperSystemAdminHome();
    if (user.role == AppRoles.nationalAdmin) return const _NationalAdminHome();
    if (user.role == AppRoles.nationalExecutive) return const _NationalExecutiveHome();
    
    // Regional Level
    if (user.role == AppRoles.regionalAdmin) return const _RegionalAdminHome();
    if (user.role == AppRoles.regionalBishop) return const _RegionalBishopHome();
    
    // District Level
    if (user.role == AppRoles.districtAdmin) return const _DistrictAdminHome();
    if (user.role == AppRoles.districtPastor) return const _DistrictPastorHome();
    
    // Area Level
    if (user.role == AppRoles.areaAdmin) return const _AreaAdminHome();
    
    // Local Church Level
    if (user.role == AppRoles.localChurchAdmin) return const _LocalChurchAdminHome();
    if (user.role == AppRoles.seniorPastor) return const _SeniorPastorHome();
    if (user.role == AppRoles.associatePastor) return const _AssociatePastorHome();
    if (user.role == AppRoles.churchSecretary) return const _ChurchSecretaryHome();
    if (user.role == AppRoles.financeOfficer) return const _FinanceOfficerHome();
    if (user.role == AppRoles.ministryHead) return const _MinistryHeadHome();
    if (user.role == AppRoles.youthMinistryHead) return const MinistryDashboardScreen(ministryType: MinistryType.youth);
    if (user.role == AppRoles.menFellowshipHead) return const MinistryDashboardScreen(ministryType: MinistryType.menFellowship);
    if (user.role == AppRoles.womenFellowshipHead) return const MinistryDashboardScreen(ministryType: MinistryType.womenFellowship);
    if (user.role == AppRoles.childrenMinistryHead) return const MinistryDashboardScreen(ministryType: MinistryType.children);
    if (user.role == AppRoles.welfareHead) return const _WelfareHeadHome();
    
    // Member Level
    if (user.role == AppRoles.cellLeader) return const _CellLeaderHome();
    if (user.role == AppRoles.volunteer) return const _VolunteerHome();
    if (user.role == AppRoles.member) return const _MemberHome();
    if (user.role == AppRoles.guest) return const _GuestHome();

    return const _GuestHome();
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shared Components
// ────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle(this.title, {this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 12),
      child: Row(children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.warmWhite)),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: TextStyle(fontSize: 12, color: AppColors.champagneGold, fontWeight: FontWeight.w500)),
          ),
      ]),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8.0 : 14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: isMobile ? 16 : 20,
                backgroundColor: AppColors.dashboardCardLight,
                child: Icon(icon, color: AppColors.warmGray, size: isMobile ? 16 : 24),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 10 : 12,
                          color: AppColors.emeraldTextPrimary),
                      textAlign: TextAlign.center,
                      maxLines: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActions extends ConsumerWidget {
  final AppUser user;

  const _HeaderActions({required this.user});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(appStateProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const NotificationCenterButton(),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context, ref),
          tooltip: 'Logout',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white24,
            child: Text(
              user.name[0].toUpperCase(),
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberHome extends ConsumerWidget {
  const _MemberHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final user = appState.user!;
    final church = appState.church!;
    final events = ref.watch(eventProvider);
    final sermons = ref.watch(sermonProvider);
    final announcements = ref.watch(ministryAnnouncementProvider);
    final members = ref.watch(memberProvider);
    final financeTx = ref.watch(financeProvider);

    // Find this member's record to determine their ministry
    final memberRecord = members
        .where((m) => m.email.toLowerCase() == user.email.toLowerCase())
        .firstOrNull;
    final memberMinistryType = memberRecord != null
        ? MinistryAssignment.getMinistryTypeForMember(memberRecord)
        : null;
    final ministryAnnouncements = memberMinistryType != null
        ? announcements
            .where((a) => a.ministryType == memberMinistryType)
            .take(3)
            .toList()
        : <MinistryAnnouncement>[];

    // Finance summary for current month
    final now = DateTime.now();
    final monthTx = financeTx.where((t) {
      return t.date.month == now.month && t.date.year == now.year;
    }).toList();
    final monthIncome =
        monthTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final monthExpense =
        monthTx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final monthBalance = monthIncome - monthExpense;
    final recentTx = (financeTx.toList()..sort((a, b) => b.date.compareTo(a.date))).take(5).toList();

    final previewEvents = (events
            .where((e) => e.endDate.isAfter(now))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate)))
        .take(3)
        .toList();
    final previewSermons = sermons.take(3).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(church.name),
        actions: [_HeaderActions(user: user)],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(eventProvider.notifier).refresh();
          ref.read(sermonProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmeraldWelcomeSection(
                userName: user.name,
                role: 'Member',
              ),
              const SizedBox(height: AppColors.spacing24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
                child: GestureDetector(
                  onTap: () => context.push('/my-finance'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: EmeraldTheme.cardDecoration,
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: AppColors.goldWarm.withValues(alpha: 0.15),
                        child: Icon(Icons.account_balance_wallet, color: AppColors.goldWarm),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Finances',
                                style: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.w600,
                                    color: AppColors.emeraldTextPrimary)),
                            Text('Welfare, Tithe, Offering & Donations',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppColors.emeraldTextSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.emeraldTextMuted),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: AppColors.spacing24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
                child: Text(
                  'Upcoming Events',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emeraldTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppColors.spacing12),
              if (previewEvents.isEmpty)
                const _EmptyState(
                    icon: Icons.event_available,
                    message: 'No upcoming events')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
                  child: Column(
                      children: previewEvents
                          .map((e) => _EventPreviewTile(event: e))
                          .toList()),
                ),
              const SizedBox(height: AppColors.spacing24),
              _SectionTitle('Recent Sermons',
                  actionLabel: 'See all',
                  onAction: () => context.push('/sermons')),
              const SizedBox(height: AppColors.spacing12),
              if (previewSermons.isEmpty)
                const _EmptyState(
                    icon: Icons.video_library, message: 'No sermons yet')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
                  child: Column(
                      children: previewSermons
                          .map((s) => _SermonPreviewTile(sermon: s))
                          .toList()),
                ),
              const SizedBox(height: AppColors.spacing24),
              if (ministryAnnouncements.isNotEmpty) ...[
                _SectionTitle(
                    '${MinistryType.label(memberMinistryType!)} Announcements',
                    actionLabel: null,
                    onAction: null),
                const SizedBox(height: AppColors.spacing12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
                  child: Column(
                    children: ministryAnnouncements.map((ann) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MinistryType.color(memberMinistryType)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.campaign,
                                color: MinistryType.color(memberMinistryType),
                                size: 20),
                          ),
                          title: Text(ann.title,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                              '${ann.fromName} - ${ann.message.length > 60 ? '${ann.message.substring(0, 60)}...' : ann.message}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[600])),
                          isThreeLine: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppColors.spacing24),
              ],
              _SectionTitle('Finance',
                  actionLabel: 'View all',
                  onAction: () => context.push('/finance')),
              const SizedBox(height: AppColors.spacing12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
                child: Row(
                  children: [
                    Expanded(
                      child: _FinanceMiniCard(
                        label: 'Income',
                        amount: monthIncome,
                        color: Colors.green,
                        icon: Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FinanceMiniCard(
                        label: 'Expense',
                        amount: monthExpense,
                        color: Colors.red,
                        icon: Icons.trending_down,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FinanceMiniCard(
                        label: 'Balance',
                        amount: monthBalance,
                        color: monthBalance >= 0 ? Colors.blue : Colors.red,
                        icon: Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppColors.spacing12),
              if (recentTx.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
                  child: Column(
                    children: recentTx.map((t) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            t.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                            color: t.isIncome ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          title: Text(t.category,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${DateFormat('MMM d').format(t.date)} - ${t.description}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.grey[600])),
                          trailing: Text(
                            '${t.isIncome ? '+' : '-'}${NumberFormat('#,##0.00').format(t.amount)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: t.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: AppColors.spacing24),
              _SectionTitle('Welfare',
                  actionLabel: 'View all',
                  onAction: () => context.push('/welfare')),
              const SizedBox(height: AppColors.spacing12),
              _QuickActionsGrid(actions: [
                _QuickAction(Icons.add_circle, 'Request Welfare', '/welfare/request'),
                const _QuickAction(Icons.receipt_long, 'My Statement', '/welfare/finance/statements'),
              ]),
              const SizedBox(height: AppColors.spacing16),
              // My Welfare Cases
              MyWelfareCases(user: user, members: members),
              const SizedBox(height: AppColors.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Preview Tiles
// ────────────────────────────────────────────────────────────────────────────

class _EventPreviewTile extends StatelessWidget {
  final ChurchEvent event;

  const _EventPreviewTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _catColor(event.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM')
                          .format(event.startDate)
                          .toUpperCase(),
                      style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('d').format(event.startDate),
                      style: TextStyle(
                          fontSize: 18,
                          color: color,
                          fontWeight: FontWeight.bold,
                          height: 1.1),
                    ),
                  ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    event.isAllDay
                        ? 'All day · ${event.location.isNotEmpty ? event.location : event.category}'
                        : '${DateFormat('h:mm a').format(event.startDate)} · ${event.location.isNotEmpty ? event.location : event.category}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.grey),
          ]),
        ),
      ),
    );
  }

  Color _catColor(String cat) {
    switch (cat) {
      case EventCategory.sundayService:
        return AppColors.primary;
      case EventCategory.conference:
        return Colors.deepPurple;
      case EventCategory.outreach:
        return Colors.teal;
      case EventCategory.prayerNight:
        return Colors.indigo;
      case EventCategory.youthEvent:
        return Colors.orange;
      case EventCategory.womensMeeting:
        return Colors.pink;
      case EventCategory.mensMeeting:
        return Colors.blue.shade700;
      case EventCategory.specialService:
        return Colors.amber.shade800;
      case EventCategory.communityEvent:
        return Colors.green;
      default:
        return Colors.grey.shade600;
    }
  }
}

class _SermonPreviewTile extends StatelessWidget {
  final Sermon sermon;

  const _SermonPreviewTile({required this.sermon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/sermons/${sermon.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.mic, color: Colors.deepPurple, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sermon.title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${sermon.speaker} · ${DateFormat('MMM d, yyyy').format(sermon.date)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Center(
        child: Column(children: [
          Icon(icon, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(message,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 13)),
        ]),
      ),
    );
  }
}

class _FinanceMiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _FinanceMiniCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              NumberFormat('#,##0.00').format(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 9, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

/// Data holder for a single stat card in [_DashboardStatGrid].
class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final String? route;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    this.route,
  });
}

/// A responsive 2-column grid of [StatCard]s used across dashboards.
class _DashboardStatGrid extends StatelessWidget {
  final List<_StatCardData> cards;

  const _DashboardStatGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: Responsive.statGridColumns(context),
        mainAxisSpacing: AppColors.spacing12,
        crossAxisSpacing: AppColors.spacing16,
        childAspectRatio: Responsive.statCardAspectRatio(context),
        children: cards
            .map((c) => StatCard(
                  title: c.title,
                  value: c.value,
                  icon: c.icon,
                  onTap: c.route == null
                      ? null
                      : () => context.push(c.route!),
                ))
            .toList(),
      ),
    );
  }
}

/// A compact list tile for "recent items" sections on dashboards.
class _RecentItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _RecentItemTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppColors.spacing12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.ivoryLight,
          child: Icon(icon, color: AppColors.goldWarm, size: AppColors.iconSmall),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.emeraldTextPrimary)),
        subtitle: Text(subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.emeraldTextSecondary)),
        trailing: onTap == null
            ? null
            : const Icon(Icons.arrow_forward_ios,
                size: 12, color: AppColors.warmGray),
      ),
    );
  }
}

/// Shows a breakdown of how many users hold each role.
class _RoleBreakdownCard extends StatelessWidget {
  final List<AppUser> users;

  const _RoleBreakdownCard({required this.users});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final u in users) {
      counts[u.role] = (counts[u.role] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const _EmptyState(
          icon: Icons.manage_accounts, message: 'No users yet');
    }

    return Container(
      padding: const EdgeInsets.all(AppColors.spacing16),
      decoration: EmeraldTheme.cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              const Divider(height: AppColors.spacing16, thickness: 0.5),
            Row(
              children: [
                Icon(Icons.badge_outlined,
                    size: 18, color: AppColors.goldWarm),
                const SizedBox(width: AppColors.spacing12),
                Expanded(
                  child: Text(
                    AppRoles.label(entries[i].key),
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.emeraldTextPrimary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.ivoryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${entries[i].value}',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldTextPrimary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A single quick-action definition (icon + label + destination route).
class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final String? module;

  const _QuickAction(this.icon, this.label, this.route, {this.module});
}

/// A 2-column grid of quick-action tiles.
class _QuickActionsGrid extends StatelessWidget {
  final List<_QuickAction> actions;

  const _QuickActionsGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: Responsive.actionGridColumns(context),
        mainAxisSpacing: AppColors.spacing12,
        crossAxisSpacing: AppColors.spacing12,
        childAspectRatio: Responsive.isMobile(context) ? 1.2 : 2.5,
        children: actions
            .map((a) => _QuickActionTile(
                  icon: a.icon,
                  label: a.label,
                  onTap: () => context.push(a.route),
                ))
            .toList(),
      ),
    );
  }
}

/// Shared dashboard scaffold: app bar, drawer, welcome header, refresh, and
/// a scrolling column of [children] sections.
class _DashboardScaffold extends StatelessWidget {
  final AppUser user;
  final String appBarTitle;
  final String roleLabel;
  final Future<void> Function()? onRefresh;
  final List<Widget> children;
  final Color? primaryColor;

  const _DashboardScaffold({
    required this.user,
    required this.appBarTitle,
    required this.roleLabel,
    required this.children,
    this.onRefresh,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: primaryColor,
        actions: [_HeaderActions(user: user)],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmeraldWelcomeSection(userName: user.name, role: roleLabel),
              const SizedBox(height: AppColors.spacing12),
              ...children,
              const SizedBox(height: AppColors.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Parses a hex color string (e.g. '#2E7D32') to a [Color], or returns [fallback].
Color? _parseHexColor(String hex, Color? fallback) {
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length != 6) return fallback;
  return Color(int.parse('FF$cleaned', radix: 16));
}

/// Formats a double as a simple currency string.
String _money(double v) {
  final s = v.toStringAsFixed(2);
  final parts = s.split('.');
  final intPart = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '\$$intPart.${parts[1]}';
}

// ────────────────────────────────────────────────────────────────────────────
// New Hierarchical Role Dashboards
// ────────────────────────────────────────────────────────────────────────────

class _SuperSystemAdminHome extends ConsumerWidget {
  const _SuperSystemAdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final organizations = ref.watch(organizationProvider);
    final regions = ref.watch(regionProvider);
    final districts = ref.watch(districtProvider);
    final areas = ref.watch(areaProvider);
    final branches = ref.watch(branchProvider);
    final users = ref.watch(userProvider);
    final members = ref.watch(memberProvider);

    final activeMembers = members.where((m) => m.isActive).length;
    final recentOrgs = ([...organizations]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .take(4)
        .toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('System Dashboard'),
        actions: [_HeaderActions(user: user)],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(organizationProvider.notifier).refresh();
          ref.read(regionProvider.notifier).refresh();
          ref.read(districtProvider.notifier).refresh();
          ref.read(areaProvider.notifier).refresh();
          ref.read(branchProvider.notifier).refresh();
          ref.read(userProvider.notifier).refresh();
          ref.read(memberProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmeraldWelcomeSection(
                userName: user.name,
                role: 'Super System Administrator',
              ),
              const SizedBox(height: AppColors.spacing12),

              // ── System Overview ──────────────────────────────────────────
              _SectionTitle('System Overview'),
              _DashboardStatGrid(
                cards: [
                  _StatCardData(
                    title: 'Organizations',
                    value: '${organizations.length}',
                    icon: Icons.business,
                    route: '/organizations',
                  ),
                  _StatCardData(
                    title: 'Regions',
                    value: '${regions.length}',
                    icon: Icons.public,
                    route: '/regions',
                  ),
                  _StatCardData(
                    title: 'Districts',
                    value: '${districts.length}',
                    icon: Icons.map,
                    route: '/districts',
                  ),
                  _StatCardData(
                    title: 'Areas',
                    value: '${areas.length}',
                    icon: Icons.place,
                    route: '/areas',
                  ),
                  _StatCardData(
                    title: 'Branches',
                    value: '${branches.length}',
                    icon: Icons.account_tree,
                    route: '/branches',
                  ),
                  _StatCardData(
                    title: 'App Users',
                    value: '${users.length}',
                    icon: Icons.manage_accounts,
                    route: '/users',
                  ),
                ],
              ),

              // ── Membership ───────────────────────────────────────────────
              _SectionTitle('Membership'),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacing24),
                child: Row(children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Members',
                      value: '${members.length}',
                      icon: Icons.people,
                      onTap: () => context.push('/members'),
                    ),
                  ),
                  const SizedBox(width: AppColors.spacing16),
                  Expanded(
                    child: StatCard(
                      title: 'Active Members',
                      value: '$activeMembers',
                      icon: Icons.how_to_reg,
                    ),
                  ),
                ]),
              ),

              // ── Hierarchy Management ─────────────────────────────────────
              _SectionTitle('Hierarchy Management'),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacing24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: Responsive.actionGridColumns(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: Responsive.isMobile(context) ? 1.2 : 2.5,
                  children: [
                    _QuickActionTile(
                        icon: Icons.business,
                        label: 'Organizations',
                        onTap: () => context.push('/organizations')),
                    _QuickActionTile(
                        icon: Icons.public,
                        label: 'Regions',
                        onTap: () => context.push('/regions')),
                    _QuickActionTile(
                        icon: Icons.map,
                        label: 'Districts',
                        onTap: () => context.push('/districts')),
                    _QuickActionTile(
                        icon: Icons.place,
                        label: 'Areas',
                        onTap: () => context.push('/areas')),
                  ],
                ),
              ),

              // ── System Management ────────────────────────────────────────
              _SectionTitle('System Management'),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacing24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: Responsive.actionGridColumns(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: Responsive.isMobile(context) ? 1.2 : 2.5,
                  children: [
                    _QuickActionTile(
                        icon: Icons.church,
                        label: 'Churches',
                        onTap: () => context.push('/super-admin/churches')),
                    _QuickActionTile(
                        icon: Icons.manage_accounts,
                        label: 'Users',
                        onTap: () => context.push('/users')),
                    _QuickActionTile(
                        icon: Icons.account_tree,
                        label: 'Branches',
                        onTap: () => context.push('/branches')),
                    _QuickActionTile(
                        icon: Icons.groups_2,
                        label: 'Departments',
                        onTap: () => context.push('/departments')),
                    _QuickActionTile(
                        icon: Icons.settings,
                        label: 'Church Settings',
                        onTap: () => context.push('/settings/church')),
                  ],
                ),
              ),

              // ── Recent Organizations ─────────────────────────────────────
              _SectionTitle('Recent Organizations',
                  actionLabel: 'View all',
                  onAction: () => context.push('/organizations')),
              if (recentOrgs.isEmpty)
                const _EmptyState(
                    icon: Icons.business,
                    message: 'No organizations yet')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppColors.spacing24),
                  child: Column(
                    children: recentOrgs
                        .map((org) => _RecentItemTile(
                              icon: Icons.business,
                              title: org.name,
                              subtitle: org.address.isNotEmpty
                                  ? org.address
                                  : (org.email.isNotEmpty
                                      ? org.email
                                      : 'No address'),
                              onTap: () =>
                                  context.push('/organizations/edit/${org.id}'),
                            ))
                        .toList(),
                  ),
                ),

              // ── User Role Distribution ───────────────────────────────────
              _SectionTitle('User Roles'),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppColors.spacing24),
                child: _RoleBreakdownCard(users: users),
              ),
              const SizedBox(height: AppColors.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}

class _NationalAdminHome extends ConsumerWidget {
  const _NationalAdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final regions = ref.watch(regionProvider);
    final districts = ref.watch(districtProvider);
    final branches = ref.watch(branchProvider);
    final members = ref.watch(memberProvider);
    final recentRegions = ([...regions]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .take(4)
        .toList();

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'National Dashboard',
      roleLabel: 'National Administrator',
      onRefresh: () async {
        ref.read(regionProvider.notifier).refresh();
        ref.read(districtProvider.notifier).refresh();
        ref.read(branchProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('National Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Regions', value: '${regions.length}', icon: Icons.public, route: '/regions'),
          _StatCardData(title: 'Districts', value: '${districts.length}', icon: Icons.map, route: '/districts'),
          _StatCardData(title: 'Branches', value: '${branches.length}', icon: Icons.account_tree, route: '/branches'),
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
        ]),
        _SectionTitle('Management'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.public, 'Regions', '/regions'),
          _QuickAction(Icons.map, 'Districts', '/districts'),
          _QuickAction(Icons.account_tree, 'Branches', '/branches'),
          _QuickAction(Icons.manage_accounts, 'Users', '/users'),
        ]),
        _SectionTitle('Recent Regions',
            actionLabel: 'View all', onAction: () => context.push('/regions')),
        if (recentRegions.isEmpty)
          const _EmptyState(icon: Icons.public, message: 'No regions yet')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: recentRegions
                  .map((r) => _RecentItemTile(
                        icon: Icons.public,
                        title: r.name,
                        subtitle: r.address.isNotEmpty ? r.address : 'No address',
                        onTap: () => context.push('/regions/edit/${r.id}'),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _NationalExecutiveHome extends ConsumerWidget {
  const _NationalExecutiveHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final regions = ref.watch(regionProvider);
    final districts = ref.watch(districtProvider);
    final members = ref.watch(memberProvider);
    final users = ref.watch(userProvider);
    final txns = ref.watch(financeProvider);
    final activeMembers = members.where((m) => m.isActive).length;
    final balance = txns.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount) -
        txns.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Executive Dashboard',
      roleLabel: 'National Executive',
      onRefresh: () async {
        ref.read(regionProvider.notifier).refresh();
        ref.read(districtProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
        ref.read(userProvider.notifier).refresh();
        ref.read(financeProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('National Snapshot'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Regions', value: '${regions.length}', icon: Icons.public, route: '/regions'),
          _StatCardData(title: 'Districts', value: '${districts.length}', icon: Icons.map, route: '/districts'),
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Active', value: '$activeMembers', icon: Icons.how_to_reg),
          _StatCardData(title: 'National Balance', value: _money(balance), icon: Icons.account_balance_wallet, route: '/finance'),
        ]),
        _SectionTitle('Reports'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.public, 'Regions', '/regions'),
          _QuickAction(Icons.map, 'Districts', '/districts'),
          _QuickAction(Icons.people, 'Members', '/members'),
          _QuickAction(Icons.account_balance_wallet, 'Finance Reports', '/finance'),
          _QuickAction(Icons.event, 'Events', '/events'),
        ]),
        _SectionTitle('Leadership Distribution'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
          child: _RoleBreakdownCard(users: users),
        ),
      ],
    );
  }
}

class _RegionalAdminHome extends ConsumerWidget {
  const _RegionalAdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final districts = ref.watch(districtProvider);
    final areas = ref.watch(areaProvider);
    final branches = ref.watch(branchProvider);
    final members = ref.watch(memberProvider);

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Regional Dashboard',
      roleLabel: 'Regional Administrator',
      onRefresh: () async {
        ref.read(districtProvider.notifier).refresh();
        ref.read(areaProvider.notifier).refresh();
        ref.read(branchProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('Regional Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Districts', value: '${districts.length}', icon: Icons.location_city, route: '/districts'),
          _StatCardData(title: 'Areas', value: '${areas.length}', icon: Icons.place, route: '/areas'),
          _StatCardData(title: 'Branches', value: '${branches.length}', icon: Icons.account_tree, route: '/branches'),
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
        ]),
        _SectionTitle('Management'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.location_city, 'Districts', '/districts'),
          _QuickAction(Icons.place, 'Areas', '/areas'),
          _QuickAction(Icons.account_tree, 'Branches', '/branches'),
          _QuickAction(Icons.manage_accounts, 'Users', '/users'),
        ]),
      ],
    );
  }
}

class _RegionalBishopHome extends ConsumerWidget {
  const _RegionalBishopHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final districts = ref.watch(districtProvider);
    final branches = ref.watch(branchProvider);
    final members = ref.watch(memberProvider);
    final sermons = ref.watch(sermonProvider);
    final txns = ref.watch(financeProvider);
    final balance = txns.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount) -
        txns.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Regional Dashboard',
      roleLabel: 'Regional Bishop',
      onRefresh: () async {
        ref.read(districtProvider.notifier).refresh();
        ref.read(branchProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
        ref.read(financeProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('Regional Oversight'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Districts', value: '${districts.length}', icon: Icons.location_city, route: '/districts'),
          _StatCardData(title: 'Branches', value: '${branches.length}', icon: Icons.account_tree, route: '/branches'),
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Sermons', value: '${sermons.length}', icon: Icons.video_library, route: '/sermons'),
          _StatCardData(title: 'Regional Balance', value: _money(balance), icon: Icons.account_balance_wallet, route: '/finance'),
        ]),
        _SectionTitle('Pastoral'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.location_city, 'Districts', '/districts'),
          _QuickAction(Icons.account_tree, 'Branches', '/branches'),
          _QuickAction(Icons.video_library, 'Sermons', '/sermons'),
          _QuickAction(Icons.event, 'Events', '/events'),
          _QuickAction(Icons.account_balance_wallet, 'Finance Reports', '/finance'),
        ]),
      ],
    );
  }
}

class _DistrictAdminHome extends ConsumerWidget {
  const _DistrictAdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final areas = ref.watch(areaProvider);
    final branches = ref.watch(branchProvider);
    final members = ref.watch(memberProvider);
    final departments = ref.watch(departmentProvider);

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'District Dashboard',
      roleLabel: 'District Administrator',
      onRefresh: () async {
        ref.read(areaProvider.notifier).refresh();
        ref.read(branchProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
        ref.read(departmentProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('District Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Areas', value: '${areas.length}', icon: Icons.place, route: '/areas'),
          _StatCardData(title: 'Branches', value: '${branches.length}', icon: Icons.account_tree, route: '/branches'),
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Departments', value: '${departments.length}', icon: Icons.groups_2, route: '/departments'),
        ]),
        _SectionTitle('Management'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.place, 'Areas', '/areas'),
          _QuickAction(Icons.account_tree, 'Branches', '/branches'),
          _QuickAction(Icons.people, 'Members', '/members'),
          _QuickAction(Icons.groups_2, 'Departments', '/departments'),
        ]),
      ],
    );
  }
}

class _DistrictPastorHome extends ConsumerWidget {
  const _DistrictPastorHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final branches = ref.watch(branchProvider);
    final members = ref.watch(memberProvider);
    final sermons = ref.watch(sermonProvider);
    final events = ref.watch(eventProvider);

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'District Dashboard',
      roleLabel: 'District Pastor',
      onRefresh: () async {
        ref.read(branchProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('District Ministry'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Branches', value: '${branches.length}', icon: Icons.account_tree, route: '/branches'),
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Sermons', value: '${sermons.length}', icon: Icons.video_library, route: '/sermons'),
          _StatCardData(title: 'Events', value: '${events.length}', icon: Icons.event, route: '/events'),
        ]),
        _SectionTitle('Pastoral'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.account_tree, 'Branches', '/branches'),
          _QuickAction(Icons.video_library, 'Sermons', '/sermons'),
          _QuickAction(Icons.event, 'Events', '/events'),
          _QuickAction(Icons.people, 'Members', '/members'),
        ]),
      ],
    );
  }
}

class _AreaAdminHome extends ConsumerWidget {
  const _AreaAdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final branches = ref.watch(branchProvider);
    final members = ref.watch(memberProvider);
    final departments = ref.watch(departmentProvider);
    final events = ref.watch(eventProvider);

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Area Dashboard',
      roleLabel: 'Area Administrator',
      onRefresh: () async {
        ref.read(branchProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
        ref.read(departmentProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('Area Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Branches', value: '${branches.length}', icon: Icons.account_tree, route: '/branches'),
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Departments', value: '${departments.length}', icon: Icons.groups_2, route: '/departments'),
          _StatCardData(title: 'Events', value: '${events.length}', icon: Icons.event, route: '/events'),
        ]),
        _SectionTitle('Management'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.account_tree, 'Branches', '/branches'),
          _QuickAction(Icons.people, 'Members', '/members'),
          _QuickAction(Icons.groups_2, 'Departments', '/departments'),
          _QuickAction(Icons.event, 'Events', '/events'),
        ]),
      ],
    );
  }
}

class _LocalChurchAdminHome extends ConsumerWidget {
  const _LocalChurchAdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final user = appState.user!;
    final tenantConfig = appState.tenantConfig;
    final members = ref.watch(memberProvider);
    final departments = ref.watch(departmentProvider);
    final users = ref.watch(userProvider);
    final events = ref.watch(eventProvider);
    final activeMembers = members.where((m) => m.isActive).length;
    final upcoming = ([...events]
          ..sort((a, b) => a.startDate.compareTo(b.startDate)))
        .where((e) => e.isUpcoming)
        .take(3)
        .toList();

    final allActions = [
      const _QuickAction(Icons.people, 'Members', '/members', module: 'members'),
      const _QuickAction(Icons.account_tree, 'Branches', '/branches'),
      const _QuickAction(Icons.groups_2, 'Departments', '/departments'),
      const _QuickAction(Icons.fact_check, 'Attendance', '/attendance', module: 'attendance'),
      const _QuickAction(Icons.account_balance_wallet, 'Finance', '/finance', module: 'finance'),
      const _QuickAction(Icons.volunteer_activism, 'Welfare', '/welfare', module: 'welfare'),
      const _QuickAction(Icons.event, 'Events', '/events', module: 'events'),
      const _QuickAction(Icons.video_library, 'Sermons', '/sermons', module: 'sermons'),
      const _QuickAction(Icons.manage_accounts, 'Users', '/users'),
      const _QuickAction(Icons.church, 'Ministry', '/ministry'),
    ];
    final filteredActions = tenantConfig == null
        ? allActions
        : allActions.where((a) => a.module == null || tenantConfig.hasModule(a.module!)).toList();

    final tenantPrimaryColor = tenantConfig != null
        ? _parseHexColor(tenantConfig.primaryColor, null)
        : null;
    final churchName = tenantConfig?.name ?? 'Church';

    return _DashboardScaffold(
      user: user,
      appBarTitle: '$churchName Dashboard',
      roleLabel: 'Local Church Administrator',
      primaryColor: tenantPrimaryColor,
      onRefresh: () async {
        ref.read(memberProvider.notifier).refresh();
        ref.read(departmentProvider.notifier).refresh();
        ref.read(userProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
        ref.read(financeProvider.notifier).refresh();
        ref.read(welfareProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
        ref.read(attendanceProvider.notifier).refresh();
        ref.read(ministryProvider.notifier).refresh();
        ref.read(contributionProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('Church Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Active', value: '$activeMembers', icon: Icons.how_to_reg),
          _StatCardData(title: 'Departments', value: '${departments.length}', icon: Icons.groups_2, route: '/departments'),
          _StatCardData(title: 'Users', value: '${users.length}', icon: Icons.manage_accounts, route: '/users'),
        ]),
        _SectionTitle('Quick Actions'),
        _QuickActionsGrid(actions: filteredActions),
        if (tenantConfig == null || tenantConfig.hasModule('finance'))
          FinanceDashboardContent(user: user),
        _SectionTitle('Upcoming Events',
            actionLabel: 'View all', onAction: () => context.push('/events')),
        if (upcoming.isEmpty)
          const _EmptyState(icon: Icons.event, message: 'No upcoming events')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: upcoming
                  .map((e) => _RecentItemTile(
                        icon: Icons.event,
                        title: e.title,
                        subtitle: DateFormat('EEE, MMM d · h:mm a').format(e.startDate),
                        onTap: () => context.push('/events/${e.id}'),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

/// Shared pastor dashboard for Senior Pastor and Associate Pastor roles.
class _PastorDashboardContent extends ConsumerWidget {
  final bool isSenior;
  const _PastorDashboardContent({required this.isSenior});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final church = ref.watch(appStateProvider).church;
    final currency = church?.currency ?? 'GH₵';
    final members = ref.watch(memberProvider);
    final departments = ref.watch(departmentProvider);
    final sermons = ref.watch(sermonProvider);
    final events = ref.watch(eventProvider);
    final attendance = ref.watch(attendanceProvider);
    final finances = ref.watch(financeProvider);
    final welfareCases = ref.watch(welfareProvider);
    final ministries = ref.watch(ministryProvider);

    final activeMembers = members.where((m) => m.isActive).length;
    final inactiveMembers = members.length - activeMembers;
    final maleCount = members.where((m) => m.gender.toLowerCase() == 'male').length;
    final femaleCount = members.where((m) => m.gender.toLowerCase() == 'female').length;
    final now = DateTime.now();
    final todayEvents = events.where((e) => e.isToday).toList();
    final upcoming = ([...events]..sort((a, b) => a.startDate.compareTo(b.startDate)))
        .where((e) => e.endDate.isAfter(now)).take(5).toList();

    final totalIncome = finances.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalExpense = finances.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;
    final monthTx = finances.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
    final monthIncome = monthTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final monthExpense = monthTx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

    final recentAttendance = ([...attendance]..sort((a, b) => b.date.compareTo(a.date))).take(5).toList();
    final avgAttendance = recentAttendance.isEmpty
        ? 0.0
        : recentAttendance.fold<int>(0, (s, r) => s + r.presentCount) / recentAttendance.length;
    final attendanceRate = members.isEmpty
        ? 0.0
        : (avgAttendance / members.length * 100).clamp(0.0, 100.0).toDouble();

    // Attendance trend: compare this month's avg vs last month's avg
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthAttendance = attendance.where((r) =>
        r.date.month == lastMonth.month && r.date.year == lastMonth.year).toList();
    final lastMonthAvg = lastMonthAttendance.isEmpty
        ? 0.0
        : lastMonthAttendance.fold<int>(0, (s, r) => s + r.presentCount) / lastMonthAttendance.length;
    final attendanceTrendUp = avgAttendance >= lastMonthAvg;

    final openCases = welfareCases.where((c) => c.status == WelfareStatus.open).length;
    final pendingCases = welfareCases.where((c) => c.status == WelfareStatus.pending).length;
    final inProgressCases = welfareCases.where((c) => c.status == WelfareStatus.inProgress).length;

    final recentSermons = ([...sermons]..sort((a, b) => b.date.compareTo(a.date))).take(3).toList();

    Ministry? findMinistry(String type) {
      try { return ministries.firstWhere((m) => m.ministryType == type); }
      catch (_) { return null; }
    }

    final newThisMonth = members.where((m) => m.membershipDate.month == now.month && m.membershipDate.year == now.year).length;
    final birthdaysThisMonth = members.where((m) => m.dateOfBirth != null && m.dateOfBirth!.month == now.month)
        .toList()
      ..sort((a, b) => a.dateOfBirth!.day.compareTo(b.dateOfBirth!.day));

    return _DashboardScaffold(
      user: user,
      appBarTitle: isSenior ? 'Pastor Dashboard' : 'Associate Pastor Dashboard',
      roleLabel: isSenior ? 'Senior Pastor' : 'Associate Pastor',
      onRefresh: () async {
        ref.read(memberProvider.notifier).refresh();
        ref.read(departmentProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
        ref.read(attendanceProvider.notifier).refresh();
        ref.read(financeProvider.notifier).refresh();
        ref.read(welfareProvider.notifier).refresh();
        ref.read(ministryProvider.notifier).refresh();
      },
      children: [
        _PastorQuickAddRow(isSenior: isSenior),

        _SectionTitle('Church Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Active', value: '$activeMembers', icon: Icons.how_to_reg),
          _StatCardData(title: 'Departments', value: '${departments.length}', icon: Icons.groups_2, route: '/departments'),
          _StatCardData(title: 'Sermons', value: '${sermons.length}', icon: Icons.video_library, route: '/sermons'),
          _StatCardData(title: 'Events', value: '${events.length}', icon: Icons.event, route: '/events'),
          _StatCardData(title: 'Welfare Cases', value: '${welfareCases.length}', icon: Icons.handshake, route: '/welfare'),
          _StatCardData(title: 'New This Month', value: '$newThisMonth', icon: Icons.person_add),
          _StatCardData(title: 'Ministries', value: '${ministries.length}', icon: Icons.church, route: '/ministry'),
        ]),

        _SectionTitle('Finance Summary', actionLabel: 'View all', onAction: () => context.push('/finance')),
        _PastorFinanceSummary(currency: currency, totalIncome: totalIncome, totalExpense: totalExpense,
          balance: balance, monthIncome: monthIncome, monthExpense: monthExpense),

        _SectionTitle('Attendance Insights', actionLabel: 'View all', onAction: () => context.push('/attendance')),
        _PastorAttendanceCard(attendanceRate: attendanceRate, avgAttendance: avgAttendance,
          totalMembers: members.length, recentAttendance: recentAttendance,
          trendUp: attendanceTrendUp, lastMonthAvg: lastMonthAvg),

        _SectionTitle('Member Demographics'),
        _PastorDemographics(total: members.length, active: activeMembers, inactive: inactiveMembers,
          male: maleCount, female: femaleCount),

        _SectionTitle('Birthdays This Month', actionLabel: 'View all', onAction: () => context.push('/members')),
        if (birthdaysThisMonth.isEmpty)
          const _EmptyState(icon: Icons.cake, message: 'No birthdays this month')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(children: birthdaysThisMonth.take(5).map((m) => _RecentItemTile(
              icon: Icons.cake, title: m.name,
              subtitle: 'Birthday · ${DateFormat('MMM d').format(m.dateOfBirth!)}',
              onTap: () => context.push('/members/${m.id}'),
            )).toList()),
          ),

        _SectionTitle('Ministries', actionLabel: 'View all', onAction: () => context.push('/ministry')),
        _PastorMinistryCards(
          youthMinistry: findMinistry(MinistryType.youth),
          menMinistry: findMinistry(MinistryType.menFellowship),
          womenMinistry: findMinistry(MinistryType.womenFellowship),
          childrenMinistry: findMinistry(MinistryType.children),
        ),

        _SectionTitle('Welfare Overview', actionLabel: 'View all', onAction: () => context.push('/welfare')),
        _PastorWelfareCard(totalCases: welfareCases.length, openCases: openCases,
          pendingCases: pendingCases, inProgressCases: inProgressCases),

        if (todayEvents.isNotEmpty) ...[
          _SectionTitle("Today's Events"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(children: todayEvents.map((e) => _RecentItemTile(
              icon: Icons.event_available, title: e.title,
              subtitle: '${e.category} · ${DateFormat('h:mm a').format(e.startDate)}',
              onTap: () => context.push('/events/${e.id}'),
            )).toList()),
          ),
        ],

        _SectionTitle('Upcoming Events', actionLabel: 'View all', onAction: () => context.push('/events')),
        if (upcoming.isEmpty) const _EmptyState(icon: Icons.event, message: 'No upcoming events')
        else Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
          child: Column(children: upcoming.map((e) => _RecentItemTile(
            icon: Icons.event, title: e.title,
            subtitle: DateFormat('EEE, MMM d · h:mm a').format(e.startDate),
            onTap: () => context.push('/events/${e.id}'),
          )).toList()),
        ),

        _SectionTitle('Recent Sermons', actionLabel: 'View all', onAction: () => context.push('/sermons')),
        if (recentSermons.isEmpty) const _EmptyState(icon: Icons.video_library, message: 'No sermons yet')
        else Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
          child: Column(children: recentSermons.map((s) => _RecentItemTile(
            icon: Icons.video_library, title: s.title,
            subtitle: '${s.scriptureReference} · ${DateFormat('MMM d, y').format(s.date)}',
            onTap: () => context.push('/sermons/${s.id}'),
          )).toList()),
        ),

        _SectionTitle('Analytics'),
        _PastorAnalyticsCard(
          totalMembers: members.length,
          activeMembers: activeMembers,
          attendanceRate: attendanceRate,
          attendanceTrendUp: attendanceTrendUp,
          monthIncome: monthIncome,
          monthExpense: monthExpense,
          totalEvents: events.length,
          upcomingEvents: upcoming.length,
          welfareCases: welfareCases.length,
          openCases: openCases,
        ),

        _SectionTitle('Quick Actions'),
        _QuickActionsGrid(actions: [
          _QuickAction(Icons.people, 'Members', '/members'),
          _QuickAction(Icons.fact_check, 'Attendance', '/attendance'),
          _QuickAction(Icons.account_balance_wallet, 'Finance', '/finance'),
          _QuickAction(Icons.handshake, 'Welfare', '/welfare'),
          _QuickAction(Icons.event, 'Events', '/events'),
          _QuickAction(Icons.video_library, 'Sermons', '/sermons'),
          _QuickAction(Icons.groups_2, 'Departments', '/departments'),
          _QuickAction(Icons.church, 'Ministry', '/ministry'),
          if (isSenior) ...[
            _QuickAction(Icons.manage_accounts, 'Users', '/users'),
          ],
          _QuickAction(Icons.settings, 'Settings', '/settings/church'),
        ]),
      ],
    );
  }
}

class _SeniorPastorHome extends ConsumerWidget {
  const _SeniorPastorHome();
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _PastorDashboardContent(isSenior: true);
}

class _AssociatePastorHome extends ConsumerWidget {
  const _AssociatePastorHome();
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _PastorDashboardContent(isSenior: false);
}

// ── Pastor Dashboard Helper Widgets ─────────────────────────────────────────

class _PastorFinanceSummary extends StatelessWidget {
  final String currency;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double monthIncome;
  final double monthExpense;

  const _PastorFinanceSummary({
    required this.currency,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                Expanded(child: _FinanceMiniStat(label: 'Total Income', value: '$currency${_money(totalIncome)}', color: AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _FinanceMiniStat(label: 'Total Expense', value: '$currency${_money(totalExpense)}', color: Colors.red.shade400)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: balance >= 0 ? AppColors.success.withValues(alpha: 0.1) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(balance >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: balance >= 0 ? AppColors.success : Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('Balance: $currency${_money(balance)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
              const Divider(height: 24),
              Row(children: [
                Expanded(child: _FinanceMiniStat(label: 'This Month In', value: '$currency${_money(monthIncome)}', color: AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _FinanceMiniStat(label: 'This Month Out', value: '$currency${_money(monthExpense)}', color: Colors.red.shade400)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _FinanceMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
    ]);
  }
}

class _PastorAttendanceCard extends StatelessWidget {
  final double attendanceRate;
  final double avgAttendance;
  final int totalMembers;
  final List<AttendanceRecord> recentAttendance;
  final bool trendUp;
  final double lastMonthAvg;

  const _PastorAttendanceCard({
    required this.attendanceRate,
    required this.avgAttendance,
    required this.totalMembers,
    required this.recentAttendance,
    required this.trendUp,
    required this.lastMonthAvg,
  });

  @override
  Widget build(BuildContext context) {
    final rateColor = attendanceRate >= 75
        ? AppColors.success
        : attendanceRate >= 50
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              SizedBox(
                width: 56, height: 56,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: (attendanceRate / 100).clamp(0, 1),
                    strokeWidth: 6, backgroundColor: Colors.grey.shade200,
                    color: rateColor,
                  ),
                  Text('${attendanceRate.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Average Attendance', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                Text('${avgAttendance.toStringAsFixed(0)} of $totalMembers members',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 14, color: trendUp ? AppColors.success : Colors.red),
                  const SizedBox(width: 4),
                  Text('vs ${lastMonthAvg.toStringAsFixed(0)} last month',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
                ]),
              ])),
            ]),
            if (recentAttendance.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...recentAttendance.take(3).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.check_circle_outline, size: 16, color: rateColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.serviceType, style: GoogleFonts.inter(fontSize: 12))),
                  Text('${r.presentCount} present', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(width: 8),
                  Text(DateFormat('MMM d').format(r.date), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                ]),
              )),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PastorDemographics extends StatelessWidget {
  final int total;
  final int active;
  final int inactive;
  final int male;
  final int female;

  const _PastorDemographics({
    required this.total,
    required this.active,
    required this.inactive,
    required this.male,
    required this.female,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: _DemoStat(icon: Icons.people, label: 'Total', value: '$total', color: AppColors.success)),
            Expanded(child: _DemoStat(icon: Icons.how_to_reg, label: 'Active', value: '$active', color: Colors.blue)),
            Expanded(child: _DemoStat(icon: Icons.person_off, label: 'Inactive', value: '$inactive', color: Colors.grey)),
            Expanded(child: _DemoStat(icon: Icons.man, label: 'Male', value: '$male', color: Colors.indigo)),
            Expanded(child: _DemoStat(icon: Icons.woman, label: 'Female', value: '$female', color: Colors.pink)),
          ]),
        ),
      ),
    );
  }
}

class _DemoStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DemoStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
    ]);
  }
}

class _PastorMinistryCards extends StatelessWidget {
  final Ministry? youthMinistry;
  final Ministry? menMinistry;
  final Ministry? womenMinistry;
  final Ministry? childrenMinistry;

  const _PastorMinistryCards({
    this.youthMinistry,
    this.menMinistry,
    this.womenMinistry,
    this.childrenMinistry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: Responsive.gridColumns(context, baseCount: 2),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: Responsive.isMobile(context) ? 1.5 : 2.8,
        children: [
          _MinistryCard(ministry: youthMinistry, type: MinistryType.youth, route: '/ministry/youth'),
          _MinistryCard(ministry: menMinistry, type: MinistryType.menFellowship, route: '/ministry/men'),
          _MinistryCard(ministry: womenMinistry, type: MinistryType.womenFellowship, route: '/ministry/women'),
          _MinistryCard(ministry: childrenMinistry, type: MinistryType.children, route: '/ministry/children'),
        ],
      ),
    );
  }
}

class _MinistryCard extends StatelessWidget {
  final Ministry? ministry;
  final String type;
  final String route;

  const _MinistryCard({this.ministry, required this.type, required this.route});

  @override
  Widget build(BuildContext context) {
    final memberCount = ministry?.memberIds.length ?? 0;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: MinistryType.color(type).withValues(alpha: 0.15),
              child: Icon(MinistryType.icon(type), color: MinistryType.color(type), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(MinistryType.shortLabel(type), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('$memberCount members', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
            ])),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}

class _PastorWelfareCard extends StatelessWidget {
  final int totalCases;
  final int openCases;
  final int pendingCases;
  final int inProgressCases;

  const _PastorWelfareCard({
    required this.totalCases,
    required this.openCases,
    required this.pendingCases,
    required this.inProgressCases,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: _WelfareStat(label: 'Total', value: '$totalCases', color: AppColors.success)),
            Expanded(child: _WelfareStat(label: 'Open', value: '$openCases', color: Colors.blue)),
            Expanded(child: _WelfareStat(label: 'Pending', value: '$pendingCases', color: Colors.orange)),
            Expanded(child: _WelfareStat(label: 'In Progress', value: '$inProgressCases', color: Colors.purple)),
          ]),
        ),
      ),
    );
  }
}

class _WelfareStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _WelfareStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
    ]);
  }
}

class _PastorQuickAddRow extends StatelessWidget {
  final bool isSenior;
  const _PastorQuickAddRow({required this.isSenior});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _QuickAddChip(icon: Icons.person_add, label: 'Add Member', route: '/members/add'),
          const SizedBox(width: 8),
          _QuickAddChip(icon: Icons.fact_check, label: 'Take Attendance', route: '/attendance/take'),
          const SizedBox(width: 8),
          _QuickAddChip(icon: Icons.event_available, label: 'Add Event', route: '/events/add'),
          const SizedBox(width: 8),
          _QuickAddChip(icon: Icons.video_library_outlined, label: 'Add Sermon', route: '/sermons/add'),
          const SizedBox(width: 8),
          _QuickAddChip(icon: Icons.account_balance_wallet_outlined, label: 'Add Transaction', route: '/finance/add'),
          if (isSenior) ...[
            const SizedBox(width: 8),
            _QuickAddChip(icon: Icons.manage_accounts_outlined, label: 'Add User', route: '/users/add'),
          ],
        ]),
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  const _QuickAddChip({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => context.push(route),
      avatar: Icon(icon, size: 18, color: AppColors.success),
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
    );
  }
}

class _PastorAnalyticsCard extends StatelessWidget {
  final int totalMembers;
  final int activeMembers;
  final double attendanceRate;
  final bool attendanceTrendUp;
  final double monthIncome;
  final double monthExpense;
  final int totalEvents;
  final int upcomingEvents;
  final int welfareCases;
  final int openCases;

  const _PastorAnalyticsCard({
    required this.totalMembers,
    required this.activeMembers,
    required this.attendanceRate,
    required this.attendanceTrendUp,
    required this.monthIncome,
    required this.monthExpense,
    required this.totalEvents,
    required this.upcomingEvents,
    required this.welfareCases,
    required this.openCases,
  });

  @override
  Widget build(BuildContext context) {
    final engagementRate = totalMembers == 0
        ? 0.0
        : (activeMembers / totalMembers * 100).clamp(0.0, 100.0).toDouble();
    final netCashflow = monthIncome - monthExpense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Key Metrics', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            _AnalyticsRow(label: 'Member Engagement', value: '${engagementRate.toStringAsFixed(0)}% active',
                icon: Icons.how_to_reg, color: AppColors.success),
            _AnalyticsRow(label: 'Attendance Trend', value: attendanceTrendUp ? 'Improving' : 'Declining',
                icon: attendanceTrendUp ? Icons.trending_up : Icons.trending_down,
                color: attendanceTrendUp ? AppColors.success : Colors.red),
            _AnalyticsRow(label: 'Net Cashflow (Month)', value: '${netCashflow >= 0 ? '+' : ''}${_money(netCashflow)}',
                icon: netCashflow >= 0 ? Icons.south_west : Icons.north_east,
                color: netCashflow >= 0 ? AppColors.success : Colors.red),
            _AnalyticsRow(label: 'Upcoming Events', value: '$upcomingEvents of $totalEvents',
                icon: Icons.event, color: Colors.blue),
            _AnalyticsRow(label: 'Welfare Load', value: '$openCases open of $welfareCases total',
                icon: Icons.handshake, color: Colors.orange),
          ]),
        ),
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _AnalyticsRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700))),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
      ]),
    );
  }
}

class _ChurchSecretaryHome extends ConsumerWidget {
  const _ChurchSecretaryHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final members = ref.watch(memberProvider);
    final events = ref.watch(eventProvider);
    final departments = ref.watch(departmentProvider);
    final attendance = ref.watch(attendanceProvider);
    final now = DateTime.now();

    // ── Computed stats ──
    final activeMembers = members.where((m) => m.isActive).length;
    final newThisMonth = members.where((m) =>
        m.membershipDate.month == now.month &&
        m.membershipDate.year == now.year).length;

    // Recent attendance rate (last 4 records)
    final recentAttendance = ([...attendance]
          ..sort((a, b) => b.date.compareTo(a.date)))
        .take(4)
        .toList();
    final avgAttendance = recentAttendance.isEmpty
        ? 0.0
        : recentAttendance.fold<int>(0, (s, r) => s + r.presentCount) /
            recentAttendance.length;
    final attendanceRate = members.isEmpty
        ? 0.0
        : (avgAttendance / members.length * 100).clamp(0, 100);

    // Upcoming events
    final upcoming = ([...events]
          ..sort((a, b) => a.startDate.compareTo(b.startDate)))
        .where((e) => e.isUpcoming)
        .take(5)
        .toList();

    // Today's events
    final todayEvents = events.where((e) => e.isToday).toList();

    // Recent members (last 5)
    final recentMembers = ([...members]
          ..sort((a, b) => b.membershipDate.compareTo(a.membershipDate)))
        .take(5)
        .toList();

    // Birthdays this month
    final birthdayMembers = members
        .where((m) =>
            m.dateOfBirth != null &&
            m.dateOfBirth!.month == now.month)
        .toList()
      ..sort((a, b) =>
          a.dateOfBirth!.day.compareTo(b.dateOfBirth!.day));

    // Members without department
    final unassignedMembers = members.where((m) => m.departmentId.isEmpty).length;

    // Inactive members
    final inactiveMembers = members.where((m) => !m.isActive).length;

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Secretary Dashboard',
      roleLabel: 'Church Secretary',
      onRefresh: () async {
        ref.read(memberProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
        ref.read(departmentProvider.notifier).refresh();
        ref.read(attendanceProvider.notifier).refresh();
      },
      children: [
        // ── Records Overview ──
        _SectionTitle('Records Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(
              title: 'Total Members',
              value: '${members.length}',
              icon: Icons.people,
              route: '/members'),
          _StatCardData(
              title: 'Active Members',
              value: '$activeMembers',
              icon: Icons.people_alt,
              route: '/members'),
          _StatCardData(
              title: 'Departments',
              value: '${departments.length}',
              icon: Icons.groups_2,
              route: '/departments'),
          _StatCardData(
              title: 'Events',
              value: '${events.length}',
              icon: Icons.event,
              route: '/events'),
        ]),

        // ── Attendance Summary ──
        _SectionTitle('Attendance Summary',
            actionLabel: 'Take Attendance',
            onAction: () => context.push('/attendance/take')),
        _SecretaryAttendanceSummary(
          attendanceRate: attendanceRate.toDouble(),
          avgAttendees: avgAttendance,
          totalRecords: attendance.length,
          recentRecords: recentAttendance,
        ),

        // ── Member Insights ──
        _SectionTitle('Member Insights',
            actionLabel: 'View All', onAction: () => context.push('/members')),
        _SecretaryMemberInsights(
          newThisMonth: newThisMonth,
          unassigned: unassignedMembers,
          inactive: inactiveMembers,
          totalMembers: members.length,
        ),

        // ── Quick Actions ──
        _SectionTitle('Quick Actions'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.person_add, 'Add Member', '/members/add'),
          _QuickAction(Icons.edit_calendar, 'Add Event', '/events/add'),
          _QuickAction(Icons.fact_check, 'Take Attendance', '/attendance/take'),
          _QuickAction(Icons.groups_2, 'Departments', '/departments'),
          _QuickAction(Icons.people, 'Members', '/members'),
          _QuickAction(Icons.event, 'Events', '/events'),
        ]),

        // ── Today's Events ──
        if (todayEvents.isNotEmpty) ...[
          _SectionTitle('Today'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: todayEvents
                  .map((e) => _RecentItemTile(
                        icon: Icons.event_available,
                        title: e.title,
                        subtitle:
                            '${e.location.isNotEmpty ? '${e.location} · ' : ''}${DateFormat('h:mm a').format(e.startDate)}',
                        onTap: () => context.push('/events/${e.id}'),
                      ))
                  .toList(),
            ),
          ),
        ],

        // ── Upcoming Events ──
        _SectionTitle('Upcoming Events',
            actionLabel: 'View all',
            onAction: () => context.push('/events')),
        if (upcoming.isEmpty)
          const _EmptyState(icon: Icons.event, message: 'No upcoming events')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: upcoming
                  .map((e) => _RecentItemTile(
                        icon: Icons.event,
                        title: e.title,
                        subtitle:
                            '${DateFormat('EEE, MMM d').format(e.startDate)} · ${e.category}',
                        onTap: () => context.push('/events/${e.id}'),
                      ))
                  .toList(),
            ),
          ),

        // ── Recent Members ──
        _SectionTitle('Recent Members',
            actionLabel: 'View all',
            onAction: () => context.push('/members')),
        if (recentMembers.isEmpty)
          const _EmptyState(icon: Icons.person_add, message: 'No members yet')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: recentMembers
                  .map((m) => _RecentItemTile(
                        icon: Icons.person,
                        title: m.name,
                        subtitle:
                            'Joined ${DateFormat('MMM d, yyyy').format(m.membershipDate)}',
                        onTap: () => context.push('/members'),
                      ))
                  .toList(),
            ),
          ),

        // ── Birthdays This Month ──
        _SectionTitle('Birthdays This Month'),
        if (birthdayMembers.isEmpty)
          const _EmptyState(
              icon: Icons.cake_outlined, message: 'No birthdays this month')
        else
          _SecretaryBirthdayList(members: birthdayMembers),

        // ── Department Overview ──
        _SectionTitle('Departments',
            actionLabel: 'View all',
            onAction: () => context.push('/departments')),
        _SecretaryDepartmentSummary(
          departments: departments,
          members: members,
        ),
      ],
    );
  }
}

/// Attendance summary card with rate, average attendees, and recent records.
class _SecretaryAttendanceSummary extends StatelessWidget {
  final double attendanceRate;
  final double avgAttendees;
  final int totalRecords;
  final List<AttendanceRecord> recentRecords;

  const _SecretaryAttendanceSummary({
    required this.attendanceRate,
    required this.avgAttendees,
    required this.totalRecords,
    required this.recentRecords,
  });

  @override
  Widget build(BuildContext context) {
    final rateColor = attendanceRate >= 75
        ? Colors.green
        : attendanceRate >= 50
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: EmeraldTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: rateColor.withValues(alpha: 0.12),
                child: Icon(Icons.trending_up, color: rateColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avg Attendance Rate',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.emeraldTextSecondary)),
                    Text('${attendanceRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: rateColor)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Avg Attendees',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.emeraldTextSecondary)),
                  Text(avgAttendees.toStringAsFixed(0),
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emeraldTextPrimary)),
                  const SizedBox(height: 4),
                  Text('Records: $totalRecords',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.emeraldTextMuted)),
                ],
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: attendanceRate / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                color: rateColor,
              ),
            ),
            if (recentRecords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Recent Services',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emeraldTextSecondary)),
              const SizedBox(height: 6),
              ...recentRecords.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(Icons.circle, size: 6, color: rateColor),
                      const SizedBox(width: 8),
                      Text(r.serviceType,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.emeraldTextPrimary)),
                      const Spacer(),
                      Text(
                          '${r.presentCount} present · ${DateFormat('MMM d').format(r.date)}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.emeraldTextMuted)),
                    ]),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

/// Member insights card showing new, unassigned, and inactive counts.
class _SecretaryMemberInsights extends StatelessWidget {
  final int newThisMonth;
  final int unassigned;
  final int inactive;
  final int totalMembers;

  const _SecretaryMemberInsights({
    required this.newThisMonth,
    required this.unassigned,
    required this.inactive,
    required this.totalMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: EmeraldTheme.cardDecoration,
        child: Row(
          children: [
            Expanded(
              child: _InsightChip(
                icon: Icons.person_add,
                label: 'New This Month',
                value: '$newThisMonth',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InsightChip(
                icon: Icons.warning_amber,
                label: 'No Department',
                value: '$unassigned',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InsightChip(
                icon: Icons.person_off,
                label: 'Inactive',
                value: '$inactive',
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          radius: 18,
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.emeraldTextPrimary)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.emeraldTextSecondary)),
      ],
    );
  }
}

/// Birthday list for this month's celebrants.
class _SecretaryBirthdayList extends StatelessWidget {
  final List<Member> members;

  const _SecretaryBirthdayList({required this.members});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: EmeraldTheme.cardDecoration,
        child: Column(
          children: members.map((m) {
            final isToday = m.dateOfBirth!.month == now.month &&
                m.dateOfBirth!.day == now.day;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Icon(isToday ? Icons.cake : Icons.cake_outlined,
                    size: 18,
                    color: isToday ? Colors.pink : AppColors.goldWarm),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(m.name,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.emeraldTextPrimary)),
                ),
                if (isToday)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Today!',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.pink)),
                  )
                else
                  Text(
                      DateFormat('MMM d').format(m.dateOfBirth!),
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.emeraldTextMuted)),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Department summary showing member counts per department.
class _SecretaryDepartmentSummary extends StatelessWidget {
  final List<Department> departments;
  final List<Member> members;

  const _SecretaryDepartmentSummary({
    required this.departments,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    if (departments.isEmpty) {
      return const _EmptyState(
          icon: Icons.groups_2, message: 'No departments yet');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: EmeraldTheme.cardDecoration,
        child: Column(
          children: [
            ...departments.take(6).map((d) {
              final count =
                  members.where((m) => m.departmentId == d.id).length;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(Icons.groups_2, size: 16, color: AppColors.goldWarm),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(d.name,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.emeraldTextPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ivoryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldTextPrimary)),
                  ),
                ]),
              );
            }),
            if (departments.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('+${departments.length - 6} more departments',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.emeraldTextMuted)),
              ),
          ],
        ),
      ),
    );
  }
}

class _FinanceOfficerHome extends ConsumerWidget {
  const _FinanceOfficerHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Finance Dashboard',
      roleLabel: 'Finance Officer',
      onRefresh: () async {
        ref.read(financeProvider.notifier).refresh();
        ref.read(welfareFinanceProvider.notifier).refresh();
        ref.read(ministryFinanceProvider.notifier).refresh();
      },
      children: [
        FinanceDashboardContent(user: user),
      ],
    );
  }
}

class _MinistryHeadHome extends ConsumerWidget {
  const _MinistryHeadHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final members = ref.watch(memberProvider);
    final departments = ref.watch(departmentProvider);
    final events = ref.watch(eventProvider);
    final sermons = ref.watch(sermonProvider);

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Ministry Dashboard',
      roleLabel: 'Ministry Head',
      onRefresh: () async {
        ref.read(memberProvider.notifier).refresh();
        ref.read(departmentProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('Ministry Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Departments', value: '${departments.length}', icon: Icons.groups_2, route: '/departments'),
          _StatCardData(title: 'Events', value: '${events.length}', icon: Icons.event, route: '/events'),
          _StatCardData(title: 'Sermons', value: '${sermons.length}', icon: Icons.video_library, route: '/sermons'),
        ]),
        _SectionTitle('Quick Actions'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.groups_2, 'Departments', '/departments'),
          _QuickAction(Icons.people, 'Members', '/members'),
          _QuickAction(Icons.event, 'Events', '/events'),
          _QuickAction(Icons.fact_check, 'Attendance', '/attendance'),
          _QuickAction(Icons.video_library, 'Sermons', '/sermons'),
        ]),
      ],
    );
  }
}

class _WelfareHeadHome extends ConsumerWidget {
  const _WelfareHeadHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final welfareCases = ref.watch(welfareProvider);
    final members = ref.watch(memberProvider);
    final welfareTxns = ref.watch(welfareFinanceProvider);
    final statements = ref.watch(welfareStatementProvider);

    final openCases = welfareCases.where((w) => w.status == WelfareStatus.open).length;
    final inProgressCases = welfareCases.where((w) => w.status == WelfareStatus.inProgress).length;
    final closedCases = welfareCases.where((w) => w.status == WelfareStatus.closed).length;
    final urgentCases = welfareCases.where((w) => w.priority == WelfarePriority.urgent && w.status != WelfareStatus.closed).length;
    final welfareContributions = welfareTxns.where((t) => t.isContribution).fold<double>(0, (s, t) => s + t.amount);
    final welfareDisbursements = welfareTxns.where((t) => !t.isContribution).fold<double>(0, (s, t) => s + t.amount);
    final fundBalance = welfareContributions - welfareDisbursements;
    final pendingStatements = statements.where((s) => s.status == StatementStatus.pending).length;

    final recentCases = ([...welfareCases]
          ..sort((a, b) => b.dateRequested.compareTo(a.dateRequested)))
        .take(5)
        .toList();

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Welfare Dashboard',
      roleLabel: 'Welfare Head',
      onRefresh: () async {
        ref.read(welfareProvider.notifier).refresh();
        ref.read(welfareFinanceProvider.notifier).refresh();
        ref.read(memberProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('Welfare Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Total Cases', value: '${welfareCases.length}', icon: Icons.handshake, route: '/welfare'),
          _StatCardData(title: 'Open', value: '$openCases', icon: Icons.folder_open, route: '/welfare'),
          _StatCardData(title: 'In Progress', value: '$inProgressCases', icon: Icons.pending_actions, route: '/welfare'),
          _StatCardData(title: 'Closed', value: '$closedCases', icon: Icons.check_circle_outline, route: '/welfare'),
        ]),
        if (urgentCases > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.priority_high, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$urgentCases urgent case(s) need attention',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/welfare'),
                  child: const Text('View'),
                ),
              ]),
            ),
          ),
        if (pendingStatements > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.receipt_long, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$pendingStatements statement request(s) pending approval',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[800]),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/welfare/finance/statements'),
                  child: const Text('Review'),
                ),
              ]),
            ),
          ),
        _SectionTitle('Financial Summary'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Fund Balance', value: _money(fundBalance), icon: Icons.account_balance_wallet, route: '/welfare/finance'),
          _StatCardData(title: 'Contributions', value: _money(welfareContributions), icon: Icons.savings, route: '/welfare/finance/contributions'),
          _StatCardData(title: 'Disbursed', value: _money(welfareDisbursements), icon: Icons.volunteer_activism, route: '/welfare/finance'),
          _StatCardData(title: 'Transactions', value: '${welfareTxns.length}', icon: Icons.receipt_long, route: '/welfare/finance/transactions'),
        ]),
        _SectionTitle('Quick Actions'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.add_task, 'Add Case', '/welfare/add'),
          _QuickAction(Icons.handshake, 'All Cases', '/welfare'),
          _QuickAction(Icons.account_balance_wallet, 'Finance', '/welfare/finance'),
          _QuickAction(Icons.payment, 'Make Payment', '/welfare/finance/payment'),
          _QuickAction(Icons.calendar_month, 'Contributions', '/welfare/finance/contributions'),
          _QuickAction(Icons.assessment, 'Reports', '/welfare/finance/reports'),
          _QuickAction(Icons.groups_2, 'Dept Welfare', '/welfare/finance/departments'),
          _QuickAction(Icons.receipt_long, 'Statements', '/welfare/finance/statements'),
          _QuickAction(Icons.people, 'Members', '/members'),
        ]),
        _SectionTitle('Recent Welfare Cases',
            actionLabel: 'View all', onAction: () => context.push('/welfare')),
        if (recentCases.isEmpty)
          const _EmptyState(icon: Icons.handshake, message: 'No welfare cases yet')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: recentCases
                  .map((w) {
                    final member = members.where((m) => m.id == w.memberId).firstOrNull;
                    return _RecentItemTile(
                      icon: WelfareType.icon(w.type),
                      title: member?.name ?? 'Unknown Member',
                      subtitle: '${WelfareType.label(w.type)} · ${WelfareStatus.label(w.status)} · ${DateFormat('MMM d, y').format(w.dateRequested)}',
                      onTap: () => context.push('/welfare/detail/${w.id}'),
                    );
                  })
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _CellLeaderHome extends ConsumerWidget {
  const _CellLeaderHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final members = ref.watch(memberProvider);
    final events = ref.watch(eventProvider);
    final upcoming = ([...events]
          ..sort((a, b) => a.startDate.compareTo(b.startDate)))
        .where((e) => e.isUpcoming)
        .take(3)
        .toList();

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Cell Leader Dashboard',
      roleLabel: 'Cell Leader',
      onRefresh: () async {
        ref.read(memberProvider.notifier).refresh();
        ref.read(eventProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('My Group'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Members', value: '${members.length}', icon: Icons.people, route: '/members'),
          _StatCardData(title: 'Events', value: '${events.length}', icon: Icons.event, route: '/events'),
        ]),
        _SectionTitle('Quick Actions'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.people, 'Members', '/members'),
          _QuickAction(Icons.fact_check, 'Attendance', '/attendance'),
          _QuickAction(Icons.event, 'Events', '/events'),
        ]),
        _SectionTitle('Upcoming Events'),
        if (upcoming.isEmpty)
          const _EmptyState(icon: Icons.event, message: 'No upcoming events')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: upcoming
                  .map((e) => _RecentItemTile(
                        icon: Icons.event,
                        title: e.title,
                        subtitle: DateFormat('EEE, MMM d · h:mm a').format(e.startDate),
                        onTap: () => context.push('/events/${e.id}'),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _VolunteerHome extends ConsumerWidget {
  const _VolunteerHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final events = ref.watch(eventProvider);
    final sermons = ref.watch(sermonProvider);
    final upcoming = ([...events]
          ..sort((a, b) => a.startDate.compareTo(b.startDate)))
        .where((e) => e.isUpcoming)
        .take(3)
        .toList();

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Volunteer Dashboard',
      roleLabel: 'Volunteer',
      onRefresh: () async {
        ref.read(eventProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('Overview'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Events', value: '${events.length}', icon: Icons.event, route: '/events'),
          _StatCardData(title: 'Sermons', value: '${sermons.length}', icon: Icons.video_library, route: '/sermons'),
        ]),
        _SectionTitle('Quick Actions'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.event, 'Events', '/events'),
          _QuickAction(Icons.video_library, 'Sermons', '/sermons'),
        ]),
        _SectionTitle('Upcoming Events'),
        if (upcoming.isEmpty)
          const _EmptyState(icon: Icons.event, message: 'No upcoming events')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: upcoming
                  .map((e) => _RecentItemTile(
                        icon: Icons.event,
                        title: e.title,
                        subtitle: DateFormat('EEE, MMM d · h:mm a').format(e.startDate),
                        onTap: () => context.push('/events/${e.id}'),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _GuestHome extends ConsumerWidget {
  const _GuestHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final events = ref.watch(eventProvider);
    final sermons = ref.watch(sermonProvider);
    final upcoming = ([...events]
          ..sort((a, b) => a.startDate.compareTo(b.startDate)))
        .where((e) => e.isUpcoming)
        .take(3)
        .toList();

    return _DashboardScaffold(
      user: user,
      appBarTitle: 'Welcome',
      roleLabel: 'Guest',
      onRefresh: () async {
        ref.read(eventProvider.notifier).refresh();
        ref.read(sermonProvider.notifier).refresh();
      },
      children: [
        _SectionTitle('Explore'),
        _DashboardStatGrid(cards: [
          _StatCardData(title: 'Events', value: '${events.length}', icon: Icons.event, route: '/events'),
          _StatCardData(title: 'Sermons', value: '${sermons.length}', icon: Icons.video_library, route: '/sermons'),
        ]),
        _SectionTitle('Quick Actions'),
        _QuickActionsGrid(actions: const [
          _QuickAction(Icons.video_library, 'Sermons', '/sermons'),
          _QuickAction(Icons.event, 'Events', '/events'),
        ]),
        _SectionTitle('Upcoming Events'),
        if (upcoming.isEmpty)
          const _EmptyState(icon: Icons.event, message: 'No upcoming events')
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: upcoming
                  .map((e) => _RecentItemTile(
                        icon: Icons.event,
                        title: e.title,
                        subtitle: DateFormat('EEE, MMM d · h:mm a').format(e.startDate),
                        onTap: () => context.push('/events/${e.id}'),
                      ))
                  .toList(),
            ),
          ),
        const SizedBox(height: AppColors.spacing12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
          child: Text(
            'Contact a church administrator to upgrade your access.',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.emeraldTextSecondary),
          ),
        ),
      ],
    );
  }
}
