import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class AttendanceDetailScreen extends ConsumerWidget {
  final String recordId;

  const AttendanceDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = LocalDb.getAttendanceRecordById(recordId);

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance Detail')),
        body: const Center(child: Text('Record not found')),
      );
    }

    final allMembers = ref.watch(memberProvider);
    final branches = ref.watch(branchProvider);
    final branchMembers =
        allMembers.where((m) => m.branchId == record.branchId).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final branchName = branches
        .where((b) => b.id == record.branchId)
        .firstOrNull
        ?.name;
    final recorder = LocalDb.getUserById(record.recordedById);

    final presentSet = record.presentMemberIds.toSet();
    final totalCount = branchMembers.length;
    final presentCount = record.presentCount;
    final absentCount = totalCount - presentCount;
    final pct = totalCount > 0 ? presentCount / totalCount : 0.0;
    final pctColor = pct >= 0.75
        ? AppColors.success
        : pct >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(record.serviceType),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(record.date),
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.serviceType,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  if (branchName != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.account_tree,
                          size: 13, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text(branchName,
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 12)),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  Row(children: [
                    _StatPill(
                        label: 'Present',
                        value: '$presentCount',
                        color: AppColors.success),
                    const SizedBox(width: 10),
                    _StatPill(
                        label: 'Absent',
                        value: '$absentCount',
                        color: Colors.red.shade300),
                    const SizedBox(width: 10),
                    _StatPill(
                        label: 'Total',
                        value: '$totalCount',
                        color: Colors.white54),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: Colors.white24,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(pctColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(pct * 100).toStringAsFixed(1)}% attendance rate',
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12),
                  ),
                  if (recorder != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text('Recorded by ${recorder.name}',
                          style: GoogleFonts.poppins(
                              color: Colors.white54, fontSize: 11)),
                    ]),
                  ],
                ],
              ),
            ),

            // Member list
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('Members',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            if (branchMembers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No members in this branch',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                itemCount: branchMembers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final member = branchMembers[i];
                  final isPresent = presentSet.contains(member.id);
                  return Card(
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: isPresent
                            ? AppColors.success.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(
                            color: isPresent
                                ? AppColors.success
                                : Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(member.name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: member.phone.isNotEmpty
                          ? Text(member.phone,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary))
                          : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPresent
                              ? AppColors.success.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPresent
                                ? AppColors.success
                                : Colors.red.shade400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(width: 4),
        Text(label,
            style:
                GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }
}
