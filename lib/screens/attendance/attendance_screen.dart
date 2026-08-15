import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/attendance_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String? _serviceFilter;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(attendanceProvider);
    final user = ref.watch(appStateProvider).user!;
    final canRecord = AppRoles.attendanceManagerRoles.contains(user.role);

    final filtered = records.where((r) {
      final matchService =
          _serviceFilter == null || r.serviceType == _serviceFilter;
      return matchService;
    }).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              _serviceFilter != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _serviceFilter != null
                  ? AppColors.accent
                  : Colors.white,
            ),
            tooltip: 'Filter',
            itemBuilder: (_) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Service Type',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ),
              const PopupMenuItem(value: 'svc:all', child: Text('All services')),
              ...ServiceTypes.all.map((s) =>
                  PopupMenuItem(value: 'svc:$s', child: Text(s))),
            ],
            onSelected: (v) {
              setState(() {
                if (v.startsWith('svc:')) {
                  _serviceFilter = v == 'svc:all' ? null : v.substring(4);
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: canRecord
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/attendance/take'),
              icon: const Icon(Icons.how_to_reg),
              label: const Text('Record Attendance'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Column(
        children: [
          if (_serviceFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                if (_serviceFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_serviceFilter!,
                          style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () =>
                          setState(() => _serviceFilter = null),
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Text(
                '${filtered.length} session${filtered.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ]),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fact_check_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No attendance records yet',
                            style: GoogleFonts.poppins(
                                color: AppColors.textSecondary)),
                        if (canRecord) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/attendance/take'),
                            icon: const Icon(Icons.how_to_reg),
                            label: const Text('Record First Attendance'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _AttendanceTile(
                      record: filtered[i],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTile extends ConsumerWidget {
  final AttendanceRecord record;

  const _AttendanceTile({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMembers = ref.watch(memberProvider);
    final totalMembers = allMembers.where((m) => m.isActive).length;
    final user = ref.watch(appStateProvider).user!;
    final canDelete = AppRoles.attendanceDeleteRoles.contains(user.role);

    final pct = totalMembers > 0
        ? (record.presentCount / totalMembers).clamp(0.0, 1.0)
        : 0.0;
    final pctColor = pct >= 0.75
        ? AppColors.success
        : pct >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Card(
      child: InkWell(
        onTap: () => context.push('/attendance/${record.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(record.serviceType,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: Colors.grey),
                    onSelected: (action) async {
                      if (action == 'edit') {
                        context.push('/attendance/edit/${record.id}');
                      } else if (action == 'delete') {
                        final ok = await _confirmDelete(context);
                        if (ok) {
                          await ref
                              .read(attendanceProvider.notifier)
                              .delete(record.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
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
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(record.date),
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(pctColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${record.presentCount}${totalMembers > 0 ? '/$totalMembers' : ''} present',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pctColor),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
            'Delete this attendance record? This cannot be undone.'),
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
}
