import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  String? _categoryFilter;
  String? _branchFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ChurchEvent> _filter(List<ChurchEvent> events, bool upcoming) {
    final now = DateTime.now();
    return events.where((e) {
      final matchTime = upcoming ? e.endDate.isAfter(now) : !e.endDate.isAfter(now);
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.location.toLowerCase().contains(q) ||
          e.organizer.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q);
      final matchCat = _categoryFilter == null || e.category == _categoryFilter;
      final matchBranch = _branchFilter == null || e.branchId == _branchFilter;
      return matchTime && matchSearch && matchCat && matchBranch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventProvider);
    final user = ref.watch(appStateProvider).user!;
    final branches = ref.watch(branchProvider);
    final isSuperAdmin = AppRoles.crossBranchRoles.contains(user.role);
    final canAdd = AppRoles.eventManagerRoles.contains(user.role);

    final upcoming = _filter(events, true)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final past = _filter(events, false)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              (_categoryFilter != null || _branchFilter != null)
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: (_categoryFilter != null || _branchFilter != null)
                  ? AppColors.accent
                  : Colors.white,
            ),
            tooltip: 'Filter',
            itemBuilder: (_) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Category',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ),
              const PopupMenuItem(value: 'cat:all', child: Text('All categories')),
              ...EventCategory.all.map(
                  (c) => PopupMenuItem(value: 'cat:$c', child: Text(c))),
              if (isSuperAdmin && branches.isNotEmpty) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  enabled: false,
                  child: Text('Branch',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                ),
                const PopupMenuItem(
                    value: 'br:all', child: Text('All branches')),
                ...branches.map((b) =>
                    PopupMenuItem(value: 'br:${b.id}', child: Text(b.name))),
              ],
            ],
            onSelected: (v) => setState(() {
              if (v.startsWith('cat:')) {
                _categoryFilter = v == 'cat:all' ? null : v.substring(4);
              } else if (v.startsWith('br:')) {
                _branchFilter = v == 'br:all' ? null : v.substring(3);
              }
            }),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Upcoming (${upcoming.length})'),
            Tab(text: 'Past (${past.length})'),
          ],
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/events/add'),
              icon: const Icon(Icons.event_note),
              label: const Text('Add Event'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search events…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
              ),
            ),
          ),
          if (_categoryFilter != null || _branchFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(children: [
                if (_categoryFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_categoryFilter!,
                          style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _categoryFilter = null),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                if (_branchFilter != null)
                  Chip(
                    label: Text(
                      branches
                              .where((b) => b.id == _branchFilter)
                              .firstOrNull
                              ?.name ??
                          '',
                      style: const TextStyle(fontSize: 11),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _branchFilter = null),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
              ]),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _EventList(
                  events: upcoming,
                  upcoming: true,
                  isSuperAdmin: isSuperAdmin,
                  canAdd: canAdd,
                ),
                _EventList(
                  events: past,
                  upcoming: false,
                  isSuperAdmin: isSuperAdmin,
                  canAdd: canAdd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventList extends ConsumerWidget {
  final List<ChurchEvent> events;
  final bool upcoming;
  final bool isSuperAdmin;
  final bool canAdd;

  const _EventList({
    required this.events,
    required this.upcoming,
    required this.isSuperAdmin,
    required this.canAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              upcoming ? Icons.event_available : Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              upcoming ? 'No upcoming events' : 'No past events',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
            if (upcoming && canAdd) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push('/events/add'),
                icon: const Icon(Icons.event_note),
                label: const Text('Create Event'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _EventCard(
        event: events[i],
        isSuperAdmin: isSuperAdmin,
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final ChurchEvent event;
  final bool isSuperAdmin;

  const _EventCard({required this.event, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchProvider);
    final branchName =
        branches.where((b) => b.id == event.branchId).firstOrNull?.name;
    final appState = ref.watch(appStateProvider);
    final user = appState.user!;
    final canManage = AppRoles.eventManagerRoles.contains(user.role);
    final isCrossChurch = AppRoles.aboveChurchRoles.contains(user.activeRole);
    final isOwnChurch = event.churchId == appState.church?.id;

    final color = _categoryColor(event.category);
    final isToday = event.isToday;

    return Card(
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date sidebar
              Container(
                width: 62,
                decoration: BoxDecoration(
                  color: isToday ? color : color.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(event.startDate).toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isToday ? Colors.white : color,
                      ),
                    ),
                    Text(
                      DateFormat('d').format(event.startDate),
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : color,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      DateFormat('EEE').format(event.startDate),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isToday
                            ? Colors.white70
                            : color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _CategoryBadge(category: event.category, color: color),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          _CategoryBadge(
                              category: 'Today',
                              color: AppColors.success),
                        ],
                        const Spacer(),
                        if (canManage)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                size: 18, color: Colors.grey),
                            onSelected: (action) async {
                              if (action == 'edit') {
                                context.push('/events/edit/${event.id}');
                              } else if (action == 'delete') {
                                final ok = await _confirmDelete(
                                    context, event.title);
                                if (ok) {
                                  await ref
                                      .read(eventProvider.notifier)
                                      .delete(event.id);
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined,
                                      size: 18, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                          ),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        event.title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (!event.isAllDay)
                        _MetaRow(
                          icon: Icons.access_time,
                          text: event.isMultiDay
                              ? '${DateFormat('MMM d, h:mm a').format(event.startDate)} – ${DateFormat('MMM d, h:mm a').format(event.endDate)}'
                              : '${DateFormat('h:mm a').format(event.startDate)} – ${DateFormat('h:mm a').format(event.endDate)}',
                        )
                      else
                        _MetaRow(
                          icon: Icons.access_time,
                          text: event.isMultiDay
                              ? '${DateFormat('MMM d').format(event.startDate)} – ${DateFormat('MMM d').format(event.endDate)} · All day'
                              : 'All day',
                        ),
                      if (event.location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _MetaRow(
                            icon: Icons.location_on_outlined,
                            text: event.location),
                      ],
                      if (isSuperAdmin && branchName != null) ...[
                        const SizedBox(height: 3),
                        _MetaRow(
                            icon: Icons.account_tree_outlined,
                            text: branchName),
                      ],
                      // Tenant info for cross-church users
                      if (isCrossChurch && event.churchName != null) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(
                            isOwnChurch
                                ? Icons.home_work_outlined
                                : Icons.church_outlined,
                            size: 13,
                            color: isOwnChurch
                                ? AppColors.success
                                : AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isOwnChurch
                                  ? 'Your church'
                                  : event.churchName!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isOwnChurch
                                    ? AppColors.success
                                    : AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Remove "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case EventCategory.sundayService:
        return const Color(0xFF3B82F6);   // Bright blue
      case EventCategory.conference:
        return const Color(0xFFA855F7);   // Bright purple
      case EventCategory.outreach:
        return const Color(0xFF14B8A6);   // Bright teal
      case EventCategory.prayerNight:
        return const Color(0xFF6366F1);   // Bright indigo
      case EventCategory.youthEvent:
        return const Color(0xFFF97316);   // Bright orange
      case EventCategory.womensMeeting:
        return const Color(0xFFEC4899);   // Bright pink
      case EventCategory.mensMeeting:
        return const Color(0xFF0EA5E9);   // Sky blue
      case EventCategory.specialService:
        return const Color(0xFFF59E0B);   // Amber
      case EventCategory.communityEvent:
        return const Color(0xFF22C55E);   // Bright green
      default:
        return const Color(0xFF64748B);   // Slate gray
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  final Color color;

  const _CategoryBadge({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        category,
        style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 13, color: AppColors.textSecondary),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }
}
