import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/attendance_record.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

/// Active Attendance Sessions Banner
///
/// Shows active, non-expired attendance sessions on the dashboard so users
/// know they can check in. Displays:
/// - Service type + date
/// - Event title (if linked)
/// - Expiry countdown
/// - "Check In" button → navigates to self-check-in screen
/// - "Not Checked In" / "Checked In" status
///
/// Only shows if there are active sessions for today.
class ActiveAttendanceBanner extends ConsumerWidget {
  const ActiveAttendanceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(attendanceProvider);
    final user = ref.watch(appStateProvider).user!;

    // Filter to active, non-expired, today's sessions
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeSessions = records.where((r) {
      if (!r.canSelfCheckIn) return false;
      final rDate = DateTime(r.date.year, r.date.month, r.date.day);
      return rDate.isAtSameMomentAs(today);
    }).toList();

    if (activeSessions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Attendance',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.emeraldTextPrimary,
            ),
          ),
          const SizedBox(height: AppColors.spacing12),
          ...activeSessions.map((r) => _ActiveSessionCard(
                record: r,
                userId: user.id,
              )),
          const SizedBox(height: AppColors.spacing24),
        ],
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final AttendanceRecord record;
  final String userId;

  const _ActiveSessionCard({
    required this.record,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final alreadyCheckedIn = record.presentMemberIds.contains(userId);
    final hasGps = record.hasGpsLocation;
    final timeLeft = record.expiresAt != null
        ? record.expiresAt!.difference(DateTime.now())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alreadyCheckedIn
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alreadyCheckedIn
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alreadyCheckedIn ? Icons.check_circle : Icons.how_to_reg,
                    color: alreadyCheckedIn
                        ? AppColors.success
                        : AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.serviceType,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emeraldTextPrimary,
                        ),
                      ),
                      if (record.isLinkedToEvent &&
                          record.eventTitle != null)
                        Text(
                          record.eventTitle!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.accent,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: alreadyCheckedIn
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    alreadyCheckedIn ? 'Checked In' : 'Pending',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: alreadyCheckedIn
                          ? AppColors.success
                          : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Info row
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 13, color: AppColors.emeraldTextSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d').format(record.date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.emeraldTextSecondary,
                  ),
                ),
                if (hasGps) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.location_on,
                      size: 13, color: AppColors.emeraldTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'GPS · ${record.proximityRadius}m',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.emeraldTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
            // Expiry countdown
            if (timeLeft != null && timeLeft.inMinutes > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 13, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    timeLeft.inHours > 0
                        ? 'Expires in ${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m'
                        : 'Expires in ${timeLeft.inMinutes}m',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
            // Present count
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people,
                    size: 13, color: AppColors.emeraldTextSecondary),
                const SizedBox(width: 4),
                Text(
                  '${record.presentCount} checked in',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.emeraldTextSecondary,
                  ),
                ),
              ],
            ),
            // Action button
            if (!alreadyCheckedIn) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (hasGps) {
                      context.push('/attendance/self-checkin');
                    } else {
                      // No GPS — can't self check in, show message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'This session does not support self-check-in. Ask your admin to mark you present.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.how_to_reg, size: 18),
                  label: Text(
                    hasGps ? 'Check In Now' : 'Ask Admin to Mark Present',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasGps ? AppColors.accent : AppColors.surfaceLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
