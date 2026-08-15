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
    final members = ref.watch(memberProvider);
    final user = ref.watch(appStateProvider).user!;
    final canRecord = AppRoles.attendanceManagerRoles.contains(user.role);
    final activeMembers = members.where((m) => m.isActive).length;

    final filtered = records.where((r) {
      final matchService =
          _serviceFilter == null || r.serviceType == _serviceFilter;
      return matchService;
    }).toList();

    // Stats
    final totalPresent = filtered.isNotEmpty
        ? filtered.fold<int>(0, (sum, r) => sum + r.presentCount)
        : 0;
    final avgAttendance = filtered.isNotEmpty && activeMembers > 0
        ? (totalPresent / (filtered.length * activeMembers)).clamp(0.0, 1.0)
        : 0.0;
    final lastRecord = filtered.isNotEmpty ? filtered.first : null;

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats summary cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.fact_check,
                    label: 'Sessions',
                    value: '${filtered.length}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.people,
                    label: 'Active Members',
                    value: '$activeMembers',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.trending_up,
                    label: 'Avg Attendance',
                    value: '${(avgAttendance * 100).toStringAsFixed(0)}%',
                    color: avgAttendance >= 0.75
                        ? AppColors.success
                        : avgAttendance >= 0.5
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ],
              ),
            ),

            // Quick action buttons
            if (canRecord)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/attendance/take'),
                        icon: const Icon(Icons.how_to_reg, size: 20),
                        label: Text('Record Attendance',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/attendance/self-checkin'),
                      icon: const Icon(Icons.location_on, size: 20),
                      label: Text('GPS Check-In',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Last session info
            if (lastRecord != null) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(children: [
                  const Icon(Icons.history, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Last Session',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppColors.textSecondary)),
                        Text(
                          '${lastRecord.serviceType} - ${DateFormat('MMM d, yyyy').format(lastRecord.date)}',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${lastRecord.presentCount}/${activeMembers > 0 ? activeMembers : ''} present',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ]),
              ),
            ],

            // Filter chips
            if (_serviceFilter != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  Chip(
                    label: Text(_serviceFilter!,
                        style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () =>
                        setState(() => _serviceFilter = null),
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                  ),
                ]),
              ),

            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(children: [
                Text(
                  '${filtered.length} session${filtered.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                if (filtered.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        context.push('/attendance/self-checkin'),
                    child: Row(children: [
                      const Icon(Icons.location_on, size: 14),
                      const SizedBox(width: 4),
                      Text('Self Check-In',
                          style: GoogleFonts.poppins(fontSize: 12)),
                    ]),
                  ),
              ]),
            ),

            // Records list or empty state
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.fact_check_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No attendance records yet',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                          'Tap "Record Attendance" to create your first session',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade500, fontSize: 12)),
                      if (canRecord) ...[
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/attendance/take'),
                          icon: const Icon(Icons.how_to_reg),
                          label: const Text('Record First Attendance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _AttendanceTile(
                  record: filtered[i],
                ),
              ),
          ],
        ),
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
    final canRecord = AppRoles.attendanceManagerRoles.contains(user.role);

    final pct = totalMembers > 0
        ? (record.presentCount / totalMembers).clamp(0.0, 1.0)
        : 0.0;
    final pctColor = pct >= 0.75
        ? AppColors.success
        : pct >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                if (record.hasGpsLocation) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.location_on, size: 14, color: Colors.green),
                ],
                const Spacer(),
                // Quick edit button
                if (canRecord)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.primary,
                    tooltip: 'Edit',
                    onPressed: () =>
                        context.push('/attendance/edit/${record.id}'),
                  ),
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
                const SizedBox(width: 12),
                const Icon(Icons.people_outline,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${record.presentCount} present',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
