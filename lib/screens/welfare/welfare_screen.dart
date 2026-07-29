import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/welfare_case.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

final _currencyFmt = NumberFormat('#,##0.00');

class WelfareScreen extends ConsumerStatefulWidget {
  const WelfareScreen({super.key});

  @override
  ConsumerState<WelfareScreen> createState() => _WelfareScreenState();
}

class _WelfareScreenState extends ConsumerState<WelfareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _statusFilter;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<WelfareCase> _filter(List<WelfareCase> all) {
    var result = all;
    if (_statusFilter != null) {
      result = result.where((w) => w.status == _statusFilter).toList();
    }
    if (_typeFilter != null) {
      result = result.where((w) => w.type == _typeFilter).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final allCases = ref.watch(welfareProvider);
    final user = ref.watch(appStateProvider).user!;
    final members = ref.watch(memberProvider);
    final canManage = AppRoles.welfareManagerRoles.contains(user.role);
    final canDelete = AppRoles.welfareDeleteRoles.contains(user.role);

    final filtered = _filter(allCases);
    final openCases = filtered.where((w) => w.status == WelfareStatus.open).toList();
    final inProgressCases = filtered.where((w) => w.status == WelfareStatus.inProgress).toList();
    final closedCases = filtered.where((w) => w.status == WelfareStatus.closed).toList();

    final totalRequested = filtered.fold(0.0, (s, w) => s + w.amountRequested);
    final totalDisbursed = filtered.fold(0.0, (s, w) => s + w.amountDisbursed);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Welfare'),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              _statusFilter != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _statusFilter != null ? AppColors.accent : Colors.white,
            ),
            tooltip: 'Filter by status',
            onSelected: (v) => setState(() => _statusFilter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All statuses')),
              ...WelfareStatus.all.map((s) =>
                  PopupMenuItem(value: s, child: Text(WelfareStatus.label(s)))),
            ],
          ),
          PopupMenuButton<String?>(
            icon: Icon(
              _typeFilter != null ? Icons.category : Icons.category_outlined,
              color: _typeFilter != null ? AppColors.accent : Colors.white,
            ),
            tooltip: 'Filter by type',
            onSelected: (v) => setState(() => _typeFilter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All types')),
              ...WelfareType.all.map((t) =>
                  PopupMenuItem(value: t, child: Text(WelfareType.label(t)))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldWarm,
          labelColor: AppColors.emeraldTextPrimary,
          unselectedLabelColor: AppColors.emeraldTextSecondary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Closed'),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/welfare/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Welfare Case'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Column(
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Expanded(
                child: _WelfareSummaryCard(
                  label: 'Total Cases',
                  value: '${filtered.length}',
                  color: AppColors.primary,
                  icon: Icons.handshake,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WelfareSummaryCard(
                  label: 'Requested',
                  value: 'GH₵ ${_currencyFmt.format(totalRequested)}',
                  color: AppColors.warning,
                  icon: Icons.request_quote,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WelfareSummaryCard(
                  label: 'Disbursed',
                  value: 'GH₵ ${_currencyFmt.format(totalDisbursed)}',
                  color: AppColors.success,
                  icon: Icons.volunteer_activism,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WelfareCaseList(
                  cases: filtered,
                  members: members,
                  canManage: canManage,
                  canDelete: canDelete,
                ),
                _WelfareCaseList(
                  cases: openCases,
                  members: members,
                  canManage: canManage,
                  canDelete: canDelete,
                ),
                _WelfareCaseList(
                  cases: inProgressCases,
                  members: members,
                  canManage: canManage,
                  canDelete: canDelete,
                ),
                _WelfareCaseList(
                  cases: closedCases,
                  members: members,
                  canManage: canManage,
                  canDelete: canDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelfareSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _WelfareSummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WelfareCaseList extends ConsumerWidget {
  final List<WelfareCase> cases;
  final List<Member> members;
  final bool canManage;
  final bool canDelete;

  const _WelfareCaseList({
    required this.cases,
    required this.members,
    required this.canManage,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No welfare cases',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: cases.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _WelfareCaseTile(
        welfareCase: cases[i],
        member: members.where((m) => m.id == cases[i].memberId).firstOrNull,
        canManage: canManage,
        canDelete: canDelete,
      ),
    );
  }
}

class _WelfareCaseTile extends ConsumerWidget {
  final WelfareCase welfareCase;
  final Member? member;
  final bool canManage;
  final bool canDelete;

  const _WelfareCaseTile({
    required this.welfareCase,
    this.member,
    required this.canManage,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = WelfareStatus.color(welfareCase.status);
    final priorityColor = WelfarePriority.color(welfareCase.priority);
    final typeIcon = WelfareType.icon(welfareCase.type);

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(typeIcon, color: statusColor, size: 20),
        ),
        title: Row(children: [
          Expanded(
            child: Text(
              member?.name ?? 'Unknown Member',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              WelfarePriority.label(welfareCase.priority),
              style: GoogleFonts.poppins(
                  fontSize: 10, color: priorityColor, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  WelfareStatus.label(welfareCase.status),
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: statusColor, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                WelfareType.label(welfareCase.type),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              if (welfareCase.welfareHeadId.isEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Unassigned',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w500)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            if (welfareCase.description.isNotEmpty)
              Text(welfareCase.description,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Text(
                DateFormat('MMM d, yyyy').format(welfareCase.dateRequested),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              if (welfareCase.amountRequested > 0) ...[
                const SizedBox(width: 8),
                Text(
                  'GH₵ ${_currencyFmt.format(welfareCase.amountRequested)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning),
                ),
              ],
            ]),
          ],
        ),
        isThreeLine: true,
        onTap: () => context.push('/welfare/detail/${welfareCase.id}'),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
          onSelected: (action) async {
            if (action == 'edit') {
              context.push('/welfare/edit/${welfareCase.id}');
            } else if (action == 'delete') {
              final ok = await _confirmDelete(context);
              if (ok) {
                await ref.read(welfareProvider.notifier).delete(welfareCase.id);
              }
            } else if (action == 'status') {
              _showStatusUpdateDialog(context, ref);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'status',
              child: Row(children: [
                Icon(Icons.swap_horiz, size: 18),
                SizedBox(width: 8),
                Text('Update Status'),
              ]),
            ),
            if (canManage)
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ]),
              ),
            if (canDelete)
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ]),
              ),
            if (!canManage)
              const PopupMenuItem(
                enabled: false,
                value: 'view',
                child: Row(children: [
                  Icon(Icons.visibility_outlined, size: 18, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('View only', style: TextStyle(color: Colors.grey)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Update Status'),
        children: WelfareStatus.all.map((status) {
          return SimpleDialogOption(
            onPressed: () {
              final updated = welfareCase.copyWith(
                status: status,
                dateClosed: status == WelfareStatus.closed
                    ? DateTime.now()
                    : null,
              );
              ref.read(welfareProvider.notifier).update(updated);
              Navigator.pop(dialogContext);
            },
            child: Row(children: [
              Icon(Icons.circle, size: 10, color: WelfareStatus.color(status)),
              const SizedBox(width: 8),
              Text(WelfareStatus.label(status)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Welfare Case'),
        content: const Text(
            'Remove this welfare case? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
