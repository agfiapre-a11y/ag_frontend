import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class DepartmentDetailScreen extends ConsumerWidget {
  final String deptId;

  const DepartmentDetailScreen({super.key, required this.deptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dept = LocalDb.getDepartmentById(deptId);

    if (dept == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Department')),
        body: const Center(child: Text('Department not found')),
      );
    }

    final user = ref.watch(appStateProvider).user!;
    final isSuperAdmin = AppRoles.structureManagerRoles.contains(user.role);
    final branches = ref.watch(branchProvider);
    final allUsers = ref.watch(userProvider);
    final events = ref.watch(eventProvider);
    final now = DateTime.now();

    final branchName = branches
            .where((b) => b.id == dept.branchId)
            .firstOrNull
            ?.name ??
        'Unknown Branch';

    // All members in this dept (direct DB query, not provider-filtered)
    final members = LocalDb.getAllMembers(departmentId: deptId);
    final activeCount = members.where((m) => m.isActive).length;

    // Department leader (user with deptLeader role + this deptId)
    final leaders = allUsers
        .where((u) =>
            u.role == AppRoles.deptLeader && u.departmentId == deptId)
        .toList();

    // Upcoming events for this dept
    final deptEvents = events
        .where((e) =>
            e.departmentId == deptId && e.endDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(dept.name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.groups_2,
                      size: 64, color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
            actions: [
              if (isSuperAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () =>
                      context.push('/departments/edit/$deptId'),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Overview Card ─────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            icon: Icons.account_tree_outlined,
                            label: 'Branch',
                            value: branchName,
                          ),
                          if (dept.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _InfoRow(
                              icon: Icons.notes_outlined,
                              label: 'Description',
                              value: dept.description,
                            ),
                          ],
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Created',
                            value: DateFormat('MMM d, yyyy')
                                .format(dept.createdAt),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Stats Row ─────────────────────────────────────────────
                  Row(children: [
                    _StatChip(
                      label: 'Members',
                      value: '${members.length}',
                      icon: Icons.people,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Active',
                      value: '$activeCount',
                      icon: Icons.how_to_reg,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Events',
                      value: '${deptEvents.length}',
                      icon: Icons.event_outlined,
                      color: Colors.pink.shade600,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Leaders ───────────────────────────────────────────────
                  _SectionHeader('Department Leaders'),
                  const SizedBox(height: 8),
                  if (leaders.isEmpty)
                    _EmptyNote('No leader assigned yet')
                  else
                    ...leaders.map((l) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              child: Text(l.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary)),
                            ),
                            title: Text(l.name,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text(l.email,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Leader',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        )),
                  const SizedBox(height: 20),

                  // ── Members ───────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionHeader('Members (${members.length})'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (members.isEmpty)
                    _EmptyNote(
                        'No members assigned to this department yet.\nAssign members from the Members screen.')
                  else
                    ...members
                        .take(5)
                        .map((m) => _MemberTile(member: m)),
                  if (members.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: () => context.push('/members'),
                        child: Text(
                            '+ ${members.length - 5} more members',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.primary)),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Upcoming Events ───────────────────────────────────────
                  _SectionHeader('Upcoming Events'),
                  const SizedBox(height: 8),
                  if (deptEvents.isEmpty)
                    _EmptyNote('No upcoming events for this department')
                  else
                    ...deptEvents.take(3).map((e) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => context.push('/events/${e.id}'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.event,
                                      color: Colors.pink.shade600, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                        DateFormat('EEE, MMM d')
                                            .format(e.startDate),
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 12, color: Colors.grey),
                              ]),
                            ),
                          ),
                        )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;

  const _EmptyNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: member.isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade200,
          child: Text(member.name[0].toUpperCase(),
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: member.isActive
                      ? AppColors.primary
                      : AppColors.textSecondary)),
        ),
        title: Text(member.name,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500, fontSize: 13)),
        subtitle: Text(
            member.phone.isNotEmpty ? member.phone : member.gender,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
        trailing: member.isActive
            ? null
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Inactive',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textSecondary)),
              ),
      ),
    );
  }
}
