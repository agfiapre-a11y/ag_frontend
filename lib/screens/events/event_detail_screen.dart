import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = LocalDb.getEventById(eventId);
    final user = ref.watch(appStateProvider).user!;
    final branches = ref.watch(branchProvider);
    final branchName =
        branches.where((b) => b.id == event?.branchId).firstOrNull?.name;

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event')),
        body: const Center(child: Text('Event not found')),
      );
    }

    final canManage = AppRoles.eventManagerRoles.contains(user.role);
    final color = _categoryColor(event.category);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: 0.9), color],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _CategoryPill(
                              label: event.category, color: Colors.white),
                          if (event.isToday) ...[
                            const SizedBox(width: 8),
                            _CategoryPill(
                                label: 'Today',
                                color: Colors.white.withValues(alpha: 0.9)),
                          ],
                        ]),
                        const SizedBox(height: 12),
                        Text(
                          event.title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _dateRangeText(event),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(event.title,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              titlePadding: const EdgeInsets.only(left: 50, bottom: 12),
            ),
            actions: [
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (action) async {
                    if (action == 'edit') {
                      context.push('/events/edit/$eventId').then((_) {
                        // force rebuild by popping back
                      });
                    } else if (action == 'delete') {
                      final ok = await _confirmDelete(context, event.title);
                      if (ok && context.mounted) {
                        await ref.read(eventProvider.notifier).delete(eventId);
                        if (context.mounted) context.pop();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit Event'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (event.location.isNotEmpty)
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: event.location,
                              color: color,
                            ),
                          if (event.organizer.isNotEmpty) ...[
                            if (event.location.isNotEmpty)
                              const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.person_outlined,
                              label: 'Organizer',
                              value: event.organizer,
                              color: color,
                            ),
                          ],
                          if (branchName != null &&
                              AppRoles.crossBranchRoles.contains(user.role)) ...[
                            if (event.location.isNotEmpty ||
                                event.organizer.isNotEmpty)
                              const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.account_tree_outlined,
                              label: 'Branch',
                              value: branchName,
                              color: color,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'About this event',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          event.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _RecordedBy(recordedById: event.recordedById,
                      createdAt: event.createdAt),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateRangeText(ChurchEvent event) {
    final df = DateFormat('EEE, MMM d, yyyy');
    final tf = DateFormat('h:mm a');

    if (event.isAllDay) {
      final text = event.isMultiDay
          ? '${df.format(event.startDate)} – ${df.format(event.endDate)}'
          : '${df.format(event.startDate)} · All day';
      return Row(children: [
        const Icon(Icons.calendar_today_outlined,
            size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]);
    }

    if (event.isMultiDay) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.play_arrow, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
              '${df.format(event.startDate)}  ${tf.format(event.startDate)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.stop, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text('${df.format(event.endDate)}  ${tf.format(event.endDate)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]);
    }

    return Row(children: [
      const Icon(Icons.access_time, size: 14, color: Colors.white70),
      const SizedBox(width: 6),
      Text(
          '${df.format(event.startDate)}  ·  ${tf.format(event.startDate)} – ${tf.format(event.endDate)}',
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordedBy extends ConsumerWidget {
  final String recordedById;
  final DateTime createdAt;

  const _RecordedBy({required this.recordedById, required this.createdAt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(userProvider);
    final recorder =
        users.where((u) => u.id == recordedById).firstOrNull;

    return Row(children: [
      const Icon(Icons.info_outline, size: 13, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          'Added by ${recorder?.name ?? 'Unknown'} · ${DateFormat('MMM d, yyyy').format(createdAt)}',
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textSecondary),
        ),
      ),
    ]);
  }
}
