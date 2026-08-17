import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/attendance_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

/// Member Attendance Stats Screen
///
/// Shows a member their full attendance history and statistics:
/// - Total services attended
/// - Attendance rate (percentage)
/// - Attendance by service type
/// - Recent attendance history
/// - Streaks and patterns
class MemberAttendanceStatsScreen extends ConsumerWidget {
  const MemberAttendanceStatsScreen({super.key});

  List<Widget> _buildServiceTypeRows(Map<String, int> byServiceType) {
    final sorted = byServiceType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = byServiceType.values.fold(0, (a, b) => a > b ? a : b);
    return sorted
        .map((e) => _ServiceTypeRow(
              type: e.key,
              count: e.value,
              maxCount: maxCount,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final records = ref.watch(attendanceProvider);

    // Filter records where this user is present
    final myAttendance = records
        .where((r) => r.presentMemberIds.contains(user.id))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Total services held in the church
    final allServices = records;
    final totalServices = allServices.length;
    final attendedCount = myAttendance.length;
    final attendanceRate =
        totalServices > 0 ? (attendedCount / totalServices * 100).roundToDouble() : 0.0;

    // By service type
    final byServiceType = <String, int>{};
    for (final r in myAttendance) {
      byServiceType[r.serviceType] =
          (byServiceType[r.serviceType] ?? 0) + 1;
    }

    // By month (last 6 months)
    final now = DateTime.now();
    final monthlyData = <_MonthData>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final monthKey = DateFormat('MMM yyyy').format(month);
      final monthServices = allServices.where((r) =>
          r.date.year == month.year && r.date.month == month.month).length;
      final monthAttended = myAttendance.where((r) =>
          r.date.year == month.year && r.date.month == month.month).length;
      monthlyData.add(_MonthData(
        label: monthKey,
        attended: monthAttended,
        total: monthServices,
      ));
    }

    // Streak calculation
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;
    DateTime? lastAttendedDate;
    for (final r in myAttendance) {
      if (lastAttendedDate != null) {
        final diff = lastAttendedDate.difference(r.date).inDays;
        if (diff <= 7) {
          tempStreak++;
        } else {
          if (tempStreak > bestStreak) bestStreak = tempStreak;
          tempStreak = 1;
        }
      } else {
        tempStreak = 1;
      }
      lastAttendedDate = r.date;
    }
    if (tempStreak > bestStreak) bestStreak = tempStreak;
    // Current streak: count from most recent backwards
    currentStreak = 0;
    DateTime? checkDate = myAttendance.isNotEmpty ? myAttendance.first.date : null;
    for (final r in myAttendance) {
      if (checkDate == null) break;
      final diff = checkDate.difference(r.date).inDays;
      if (diff <= 7) {
        currentStreak++;
        checkDate = r.date;
      } else {
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Attended',
                    value: '$attendedCount',
                    icon: Icons.check_circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Total Services',
                    value: '$totalServices',
                    icon: Icons.event,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Rate',
                    value: '${attendanceRate.toStringAsFixed(0)}%',
                    icon: Icons.trending_up,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Current Streak',
                    value: '$currentStreak',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Best Streak',
                    value: '$bestStreak',
                    icon: Icons.emoji_events,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly chart
            Text(
              'Last 6 Months',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: monthlyData.map((m) => _MonthBar(data: m)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // By service type
            if (byServiceType.isNotEmpty) ...[
              Text(
                'By Service Type',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _buildServiceTypeRows(byServiceType),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Recent attendance history
            Text(
              'Recent Attendance',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (myAttendance.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No attendance records yet',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...myAttendance.take(20).map((r) => _AttendanceHistoryItem(record: r)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthData {
  final String label;
  final int attended;
  final int total;

  const _MonthData({
    required this.label,
    required this.attended,
    required this.total,
  });

  double get rate => total > 0 ? attended / total : 0;
}

class _MonthBar extends StatelessWidget {
  final _MonthData data;

  const _MonthBar({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              data.label,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                // Background bar
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Filled bar
                FractionallySizedBox(
                  widthFactor: data.rate.clamp(0.0, 1.0),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Text overlay
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${data.attended}/${data.total}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class _ServiceTypeRow extends StatelessWidget {
  final String type;
  final int count;
  final int maxCount;

  const _ServiceTypeRow({
    required this.type,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final rate = maxCount > 0 ? count / maxCount : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              type,
              style: GoogleFonts.poppins(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: rate.clamp(0.0, 1.0),
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHistoryItem extends StatelessWidget {
  final AttendanceRecord record;

  const _AttendanceHistoryItem({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success.withValues(alpha: 0.2),
          child: const Icon(Icons.check, color: AppColors.success),
        ),
        title: Text(
          record.serviceType,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, MMM d, yyyy').format(record.date),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (record.isLinkedToEvent && record.eventTitle != null)
              Text(
                'Event: ${record.eventTitle}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.accent,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
      ),
    );
  }
}
