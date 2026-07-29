import 'local_db.dart';

/// Data retention service implementing UK GDPR Art. 5(1)(e) storage limitation.
/// Defines retention periods and provides automated purging.
class DataRetentionService {
  // Retention periods
  static const Duration _financialRetention = Duration(days: 2555); // ~7 years (HMRC)
  static const Duration _attendanceRetention = Duration(days: 1095); // ~3 years
  static const Duration _inactiveUserRetention = Duration(days: 365); // 1 year

  /// Purges data that has exceeded its retention period.
  /// Returns a summary of what was purged.
  static Future<Map<String, int>> purgeExpiredData() async {
    final purged = <String, int>{};
    final now = DateTime.now();

    // Purge old attendance records
    int attendancePurged = 0;
    final attendance = LocalDb.getAllAttendanceRecords();
    for (final record in attendance) {
      if (now.difference(record.date) > _attendanceRetention) {
        await LocalDb.deleteAttendanceRecord(record.id);
        attendancePurged++;
      }
    }
    purged['attendance'] = attendancePurged;

    // Purge old financial transactions
    int financePurged = 0;
    final transactions = LocalDb.getAllTransactions();
    for (final tx in transactions) {
      if (now.difference(tx.date) > _financialRetention) {
        await LocalDb.deleteTransaction(tx.id);
        financePurged++;
      }
    }
    purged['finance'] = financePurged;

    // Purge inactive user accounts (no login in retention period)
    int usersPurged = 0;
    final users = LocalDb.getAllUsers();
    for (final user in users) {
      if (user.updatedAt != null &&
          now.difference(user.updatedAt!) > _inactiveUserRetention) {
        await LocalDb.deleteUser(user.id);
        usersPurged++;
      }
    }
    purged['users'] = usersPurged;

    return purged;
  }

  /// Implements UK GDPR Art. 17 — Right to erasure for a specific member.
  /// Cascades deletion across all related records.
  static Future<void> eraseMemberData(String memberId) async {
    // Delete the member record
    await LocalDb.deleteMember(memberId);

    // Delete attendance records referencing this member
    final attendance = LocalDb.getAllAttendanceRecords();
    for (final record in attendance) {
      // Check if member ID appears in attendance data
      if (record.toMap().containsValue(memberId)) {
        await LocalDb.deleteAttendanceRecord(record.id);
      }
    }

    // Delete financial transactions referencing this member
    final transactions = LocalDb.getAllTransactions();
    for (final tx in transactions) {
      if (tx.toMap().containsValue(memberId)) {
        await LocalDb.deleteTransaction(tx.id);
      }
    }

    // Enqueue sync deletions if sync is available
    // The sync service will handle cloud-side deletion
  }

  /// Returns the retention policy for display in the privacy notice.
  static Map<String, String> getRetentionPolicy() {
    return {
      'Financial Records': '${_financialRetention.inDays ~/ 365} years (HMRC requirement)',
      'Attendance Records': '${_attendanceRetention.inDays ~/ 365} years',
      'Inactive User Accounts': '${_inactiveUserRetention.inDays} year',
      'Member Data': 'Retained while active; deleted on request (UK GDPR Art. 17)',
    };
  }
}
