import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/ministry.dart';
import '../../models/event.dart';
import '../../models/attendance_record.dart';
import '../../models/ministry_finance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';
import '../../widgets/responsive_scaffold.dart';

const _uuid = Uuid();
final _dateFmt = DateFormat('MMM d, yyyy');

class MinistryDashboardScreen extends ConsumerStatefulWidget {
  final String ministryType;

  const MinistryDashboardScreen({super.key, required this.ministryType});

  @override
  ConsumerState<MinistryDashboardScreen> createState() =>
      _MinistryDashboardScreenState();
}

class _MinistryDashboardScreenState
    extends ConsumerState<MinistryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _ensureMinistryExists();
  }

  void _ensureMinistryExists() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = ref.read(appStateProvider);
      final user = appState.user!;
      final churchId = appState.church?.id ?? '';
      final branchId = user.branchId;

      final existing = LocalDb.getAllMinistries(
        churchId: churchId,
        branchId: branchId,
        ministryType: widget.ministryType,
      );

      if (existing.isEmpty) {
        final ministry = Ministry(
          id: _uuid.v4(),
          churchId: churchId,
          branchId: branchId,
          name: MinistryType.label(widget.ministryType),
          ministryType: widget.ministryType,
          description: MinistryType.description(widget.ministryType),
          headId: user.id,
          isActive: true,
          createdAt: DateTime.now(),
          organizationId: user.organizationId,
          regionId: user.regionId,
          districtId: user.districtId,
          areaId: user.areaId,
        );
        await LocalDb.saveMinistry(ministry);
        ref.read(ministryProvider.notifier).refresh();
      } else if (existing.first.headId.isEmpty) {
        await LocalDb.saveMinistry(existing.first.copyWith(headId: user.id));
        ref.read(ministryProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ministries = ref.watch(ministryProvider);
    final members = ref.watch(memberProvider);
    final events = ref.watch(eventProvider);
    final attendance = ref.watch(attendanceProvider);
    final user = ref.watch(appStateProvider).user!;
    final church = ref.watch(appStateProvider).church;

    final ministry = ministries
        .where((m) => m.ministryType == widget.ministryType)
        .firstOrNull;

    // Auto-assign members based on age and gender
    final ministryMembers =
        MinistryAssignment.getMembersForMinistry(members, widget.ministryType);
    final financeTx = ref.watch(ministryFinanceProvider);
    final announcements = ref.watch(ministryAnnouncementProvider);
    final ministryFinanceTx =
        financeTx.where((t) => t.ministryType == widget.ministryType).toList();
    final ministryAnnouncements =
        announcements.where((a) => a.ministryType == widget.ministryType).toList();

    final totalIncome =
        ministryFinanceTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalExpense =
        ministryFinanceTx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;

    final now = DateTime.now();
    final monthTx = ministryFinanceTx.where((t) =>
        t.date.month == now.month && t.date.year == now.year).toList();
    final monthIncome =
        monthTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final monthExpense =
        monthTx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

    // Ministry-specific events (by ministryType field, fallback to category)
    final ministryEvents = events
        .where((e) => e.ministryType == widget.ministryType ||
            (e.ministryType == null && e.category == _eventCategoryForMinistry(widget.ministryType)))
        .toList();
    final upcomingEvents = (ministryEvents
            .where((e) => e.endDate.isAfter(now))
            .toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate)))
        .take(5)
        .toList();
    final todayEvents = ministryEvents.where((e) => e.isToday).toList();

    // Attendance rate for ministry members (ministry-specific + general)
    final ministryAttendance = attendance
        .where((r) => r.ministryType == null || r.ministryType == widget.ministryType)
        .toList();
    final recentAttendance = ([...ministryAttendance]
          ..sort((a, b) => b.date.compareTo(a.date)))
        .take(4)
        .toList();
    final avgAttendance = recentAttendance.isEmpty
        ? 0.0
        : recentAttendance.fold<int>(0, (s, r) => s + r.presentCount) /
            recentAttendance.length;
    final attendanceRate = ministryMembers.isEmpty
        ? 0.0
        : (avgAttendance / ministryMembers.length * 100).clamp(0, 100);

    // Member demographics
    final maleCount = ministryMembers.where((m) => m.gender.toLowerCase() == 'male').length;
    final femaleCount = ministryMembers.where((m) => m.gender.toLowerCase() == 'female').length;
    final avgAge = ministryMembers.isEmpty
        ? 0.0
        : ministryMembers.fold<int>(0, (s, m) => s + MinistryAssignment.getAge(m)) /
            ministryMembers.length;

    // Recent announcements
    final recentAnnouncements = ([...ministryAnnouncements]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .take(3)
        .toList();

    // Recent finance transactions
    final recentTx = ([...ministryFinanceTx]
          ..sort((a, b) => b.date.compareTo(a.date)))
        .take(5)
        .toList();

    // Members with birthdays this month
    final birthdayMembers = ministryMembers
        .where((m) => m.dateOfBirth != null && m.dateOfBirth!.month == now.month)
        .toList()
      ..sort((a, b) => a.dateOfBirth!.day.compareTo(b.dateOfBirth!.day));

    final currency = church?.currency ?? 'GH₵';
    final ministryColor = MinistryType.color(widget.ministryType);
    final ministryIcon = MinistryType.icon(widget.ministryType);
    final ministryLabel = MinistryType.label(widget.ministryType);
    final financeRoute = _ministryRoute(widget.ministryType, 'finance');
    final announcementsRoute = _ministryRoute(widget.ministryType, 'announcements');
    final reportsRoute = _ministryRoute(widget.ministryType, 'reports');

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(ministryLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(ministryProvider.notifier).refresh();
              ref.read(memberProvider.notifier).refresh();
              ref.read(eventProvider.notifier).refresh();
              ref.read(attendanceProvider.notifier).refresh();
              ref.read(ministryFinanceProvider.notifier).refresh();
              ref.read(ministryAnnouncementProvider.notifier).refresh();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'profile') context.push('/profile');
              if (v == 'settings') context.push('/settings/church');
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: AppColors.champagneGold.withValues(alpha: 0.2),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.champagneGold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(ministryProvider.notifier).refresh();
          ref.read(memberProvider.notifier).refresh();
          ref.read(eventProvider.notifier).refresh();
          ref.read(attendanceProvider.notifier).refresh();
          ref.read(ministryFinanceProvider.notifier).refresh();
          ref.read(ministryAnnouncementProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ministryColor.withValues(alpha: 0.15),
                      ministryColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ministryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(ministryIcon,
                          size: 48, color: ministryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(ministryLabel,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldTextPrimary)),
                    const SizedBox(height: 4),
                    Text(
                        ministry?.description ??
                            MinistryType.description(widget.ministryType),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.emeraldTextSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: ministryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${ministryMembers.length} members',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ministryColor)),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: Responsive.statGridColumns(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: [
                    _StatTile(
                      icon: Icons.people,
                      label: 'Members',
                      value: '${ministryMembers.length}',
                      color: ministryColor,
                      onTap: () => context.push('/members'),
                    ),
                    _StatTile(
                      icon: Icons.account_balance_wallet,
                      label: 'Balance',
                      value: '$currency${balance.toStringAsFixed(0)}',
                      color: balance >= 0 ? Colors.green : Colors.red,
                      onTap: () => context.push(financeRoute),
                    ),
                    _StatTile(
                      icon: Icons.campaign,
                      label: 'Announcements',
                      value: '${ministryAnnouncements.length}',
                      color: ministryColor,
                      onTap: () => context.push(announcementsRoute),
                    ),
                  ],
                ),
              ),

              // Finance Summary Card
              _SectionHeader(title: 'Finance Summary',
                  actionLabel: 'Details',
                  onAction: () => context.push(financeRoute)),
              _MinistryFinanceSummary(
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                balance: balance,
                monthIncome: monthIncome,
                monthExpense: monthExpense,
                currency: currency,
                color: ministryColor,
                recentTx: recentTx,
              ),

              // Attendance Card
              _SectionHeader(title: 'Attendance',
                  actionLabel: 'Take',
                  onAction: () => context.push('/attendance/take')),
              _MinistryAttendanceCard(
                attendanceRate: attendanceRate.toDouble(),
                avgAttendees: avgAttendance,
                recentRecords: recentAttendance,
                color: ministryColor,
              ),

              // Member Demographics
              _SectionHeader(title: 'Member Demographics'),
              _MinistryDemographics(
                total: ministryMembers.length,
                male: maleCount,
                female: femaleCount,
                avgAge: avgAge,
                color: ministryColor,
              ),

              // Quick Actions
              _SectionHeader(title: 'Quick Actions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: Responsive.actionGridColumns(context),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                    _QuickActionTile(
                      icon: Icons.people,
                      label: 'Members',
                      color: ministryColor,
                      onTap: () => context.push('/members'),
                    ),
                    _QuickActionTile(
                      icon: Icons.fact_check,
                      label: 'Attendance',
                      color: ministryColor,
                      onTap: () => context.push('/attendance'),
                    ),
                    _QuickActionTile(
                      icon: Icons.event,
                      label: 'Events',
                      color: ministryColor,
                      onTap: () => context.push('/events'),
                    ),
                    _QuickActionTile(
                      icon: Icons.video_library,
                      label: 'Sermons',
                      color: ministryColor,
                      onTap: () => context.push('/sermons'),
                    ),
                    _QuickActionTile(
                      icon: Icons.account_balance_wallet,
                      label: 'Finance',
                      color: ministryColor,
                      onTap: () => context.push(financeRoute),
                    ),
                    _QuickActionTile(
                      icon: Icons.assessment,
                      label: 'Reports',
                      color: ministryColor,
                      onTap: () => context.push(reportsRoute),
                    ),
                    _QuickActionTile(
                      icon: Icons.campaign,
                      label: 'Announce',
                      color: ministryColor,
                      onTap: () => context.push(announcementsRoute),
                    ),
                    _QuickActionTile(
                      icon: Icons.settings,
                      label: 'Settings',
                      color: ministryColor,
                      onTap: () => _showMinistrySettings(ministry),
                    ),
                  ],
                ),
              ),

              // Today's Events
              if (todayEvents.isNotEmpty) ...[
                _SectionHeader(title: 'Today'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: todayEvents.map((e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ministryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.event_available, color: ministryColor),
                        ),
                        title: Text(e.title,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${e.location.isNotEmpty ? '${e.location} · ' : ''}${DateFormat('h:mm a').format(e.startDate)}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[600])),
                        onTap: () => context.push('/events/${e.id}'),
                      ),
                    )).toList(),
                  ),
                ),
              ],

              // Upcoming Events
              _SectionHeader(title: 'Upcoming Events',
                  actionLabel: 'See all',
                  onAction: () => context.push('/events')),
              if (upcomingEvents.isEmpty)
                const _EmptyState(
                    icon: Icons.event_available,
                    message: 'No upcoming ministry events')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: upcomingEvents.map((e) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ministryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.event, color: ministryColor),
                          ),
                          title: Text(e.title,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${_dateFmt.format(e.startDate)} · ${e.category}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[600])),
                          onTap: () => context.push('/events/${e.id}'),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Ministry Members
              _SectionHeader(
                  title: 'Ministry Members',
                  actionLabel: 'View all',
                  onAction: () => context.push('/members')),
              if (ministryMembers.isEmpty)
                const _EmptyState(
                    icon: Icons.people_outline,
                    message: 'No members match this ministry\'s criteria. Ensure members have date of birth set.')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: ministryMembers.take(8).map((m) {
                      final age = MinistryAssignment.getAge(m);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                ministryColor.withValues(alpha: 0.15),
                            child: Text(m.name.isNotEmpty
                                ? m.name[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(m.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${m.gender} · $age yrs | ${m.phone.isNotEmpty ? m.phone : 'No phone'}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[600])),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Recent Announcements
              _SectionHeader(title: 'Recent Announcements',
                  actionLabel: 'View all',
                  onAction: () => context.push(announcementsRoute)),
              if (recentAnnouncements.isEmpty)
                const _EmptyState(
                    icon: Icons.campaign_outlined,
                    message: 'No announcements yet')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: recentAnnouncements.map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ministryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.campaign, color: ministryColor, size: 20),
                        ),
                        title: Text(a.title,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                            '${a.message.length > 60 ? '${a.message.substring(0, 60)}...' : a.message}\n${DateFormat('MMM d, yyyy').format(a.createdAt)}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[600])),
                        isThreeLine: true,
                        onTap: () => context.push(announcementsRoute),
                      ),
                    )).toList(),
                  ),
                ),

              // Birthdays This Month
              if (birthdayMembers.isNotEmpty) ...[
                _SectionHeader(title: 'Birthdays This Month'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: EmeraldTheme.cardDecoration,
                    child: Column(
                      children: birthdayMembers.map((m) {
                        final isToday = m.dateOfBirth!.month == now.month &&
                            m.dateOfBirth!.day == now.day;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Icon(isToday ? Icons.cake : Icons.cake_outlined,
                                size: 18,
                                color: isToday ? Colors.pink : ministryColor),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                              Text(DateFormat('MMM d').format(m.dateOfBirth!),
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.emeraldTextMuted)),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showMinistrySettings(Ministry? ministry) {
    if (ministry == null) return;
    final nameCtrl = TextEditingController(text: ministry.name);
    final descCtrl = TextEditingController(text: ministry.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${MinistryType.label(widget.ministryType)} Settings'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ministry Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active'),
                value: ministry.isActive,
                onChanged: (v) async {
                  final updated = ministry.copyWith(isActive: v);
                  await ref
                      .read(ministryProvider.notifier)
                      .update(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = ministry.copyWith(
                name: nameCtrl.text,
                description: descCtrl.text,
              );
              await ref
                  .read(ministryProvider.notifier)
                  .update(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

String _ministryRoute(String ministryType, String suffix) {
  final slug = ministryType == MinistryType.youth
      ? 'youth'
      : ministryType == MinistryType.menFellowship
          ? 'men'
          : ministryType == MinistryType.womenFellowship
              ? 'women'
              : 'children';
  return '/ministry/$slug/$suffix';
}

String _eventCategoryForMinistry(String ministryType) {
  switch (ministryType) {
    case MinistryType.youth:
      return EventCategory.youthEvent;
    case MinistryType.menFellowship:
      return EventCategory.mensMeeting;
    case MinistryType.womenFellowship:
      return EventCategory.womensMeeting;
    case MinistryType.children:
      return EventCategory.other;
    default:
      return EventCategory.other;
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _MinistryFinanceSummary extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double monthIncome;
  final double monthExpense;
  final String currency;
  final Color color;
  final List<MinistryFinance> recentTx;

  const _MinistryFinanceSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
    required this.currency,
    required this.color,
    required this.recentTx,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: EmeraldTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _FinanceMiniCard(
                    label: 'Income',
                    amount: totalIncome,
                    color: Colors.green,
                    icon: Icons.trending_up,
                    currency: currency,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FinanceMiniCard(
                    label: 'Expense',
                    amount: totalExpense,
                    color: Colors.red,
                    icon: Icons.trending_down,
                    currency: currency,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FinanceMiniCard(
                    label: 'Balance',
                    amount: balance,
                    color: balance >= 0 ? Colors.blue : Colors.red,
                    icon: Icons.account_balance_wallet,
                    currency: currency,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: color),
                  const SizedBox(width: 8),
                  Text('This Month',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emeraldTextPrimary)),
                  const Spacer(),
                  Flexible(
                    child: Text(
                        '+$currency${monthIncome.toStringAsFixed(0)} / -$currency${monthExpense.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.emeraldTextSecondary)),
                  ),
                ],
              ),
            ),
            if (recentTx.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Recent Transactions',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emeraldTextSecondary)),
              const SizedBox(height: 6),
              ...recentTx.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(t.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 14,
                          color: t.isIncome ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t.description.isNotEmpty ? t.description : t.category,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.emeraldTextPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                          '$currency${t.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.isIncome ? Colors.green : Colors.red)),
                    ]),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinanceMiniCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final String currency;

  const _FinanceMiniCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.currency,
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
              '$currency${amount.toStringAsFixed(0)}',
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

class _MinistryAttendanceCard extends StatelessWidget {
  final double attendanceRate;
  final double avgAttendees;
  final List<AttendanceRecord> recentRecords;
  final Color color;

  const _MinistryAttendanceCard({
    required this.attendanceRate,
    required this.avgAttendees,
    required this.recentRecords,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final rateColor = attendanceRate >= 75
        ? Colors.green
        : attendanceRate >= 50
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              ...recentRecords.take(3).map((r) => Padding(
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

class _MinistryDemographics extends StatelessWidget {
  final int total;
  final int male;
  final int female;
  final double avgAge;
  final Color color;

  const _MinistryDemographics({
    required this.total,
    required this.male,
    required this.female,
    required this.avgAge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: EmeraldTheme.cardDecoration,
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.man, color: Colors.blue, size: 24),
                  const SizedBox(height: 4),
                  Text('$male',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldTextPrimary)),
                  Text('Male',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.emeraldTextSecondary)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.woman, color: Colors.pink, size: 24),
                  const SizedBox(height: 4),
                  Text('$female',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldTextPrimary)),
                  Text('Female',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.emeraldTextSecondary)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.cake, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(avgAge.toStringAsFixed(0),
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldTextPrimary)),
                  Text('Avg Age',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.emeraldTextSecondary)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.people, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text('$total',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldTextPrimary)),
                  Text('Total',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.emeraldTextSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 12),
      child: Row(children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.emeraldTextPrimary)),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.champagneGold,
                    fontWeight: FontWeight.w500)),
          ),
      ]),
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
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(message,
                style: GoogleFonts.poppins(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
