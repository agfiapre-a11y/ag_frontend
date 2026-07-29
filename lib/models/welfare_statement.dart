import 'package:flutter/material.dart';

class WelfareStatement {
  final String id;
  final String churchId;
  final String branchId;
  final String memberId;
  final String requestedById;
  final String? approvedById;
  final String status; // 'pending' | 'approved' | 'rejected' | 'generated'
  final String statementType; // 'contributions' | 'disbursements' | 'full_account'
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? generatedAt;
  final String? rejectionReason;

  const WelfareStatement({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.memberId,
    required this.requestedById,
    this.approvedById,
    required this.status,
    required this.statementType,
    required this.startDate,
    required this.endDate,
    this.notes,
    required this.requestedAt,
    this.approvedAt,
    this.generatedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'memberId': memberId,
        'requestedById': requestedById,
        'approvedById': approvedById,
        'status': status,
        'statementType': statementType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'notes': notes,
        'requestedAt': requestedAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'generatedAt': generatedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
      };

  factory WelfareStatement.fromMap(Map<dynamic, dynamic> map) =>
      WelfareStatement(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        memberId: map['memberId'] as String,
        requestedById: (map['requestedById'] as String?) ?? '',
        approvedById: map['approvedById'] as String?,
        status: (map['status'] as String?) ?? StatementStatus.pending,
        statementType: (map['statementType'] as String?) ??
            StatementType.contributions,
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: DateTime.parse(map['endDate'] as String),
        notes: map['notes'] as String?,
        requestedAt: DateTime.parse(map['requestedAt'] as String),
        approvedAt: map['approvedAt'] != null
            ? DateTime.parse(map['approvedAt'] as String)
            : null,
        generatedAt: map['generatedAt'] != null
            ? DateTime.parse(map['generatedAt'] as String)
            : null,
        rejectionReason: map['rejectionReason'] as String?,
      );

  WelfareStatement copyWith({
    String? status,
    String? approvedById,
    DateTime? approvedAt,
    DateTime? generatedAt,
    String? rejectionReason,
  }) =>
      WelfareStatement(
        id: id,
        churchId: churchId,
        branchId: branchId,
        memberId: memberId,
        requestedById: requestedById,
        approvedById: approvedById ?? this.approvedById,
        status: status ?? this.status,
        statementType: statementType,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        requestedAt: requestedAt,
        approvedAt: approvedAt ?? this.approvedAt,
        generatedAt: generatedAt ?? this.generatedAt,
        rejectionReason: rejectionReason ?? this.rejectionReason,
      );
}

class StatementStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const generated = 'generated';

  static const all = [pending, approved, rejected, generated];

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case generated:
        return 'Generated';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case pending:
        return Colors.amber;
      case approved:
        return Colors.blue;
      case rejected:
        return Colors.red;
      case generated:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static IconData icon(String status) {
    switch (status) {
      case pending:
        return Icons.pending;
      case approved:
        return Icons.check_circle;
      case rejected:
        return Icons.cancel;
      case generated:
        return Icons.picture_as_pdf;
      default:
        return Icons.receipt;
    }
  }
}

class StatementType {
  static const contributions = 'contributions';
  static const disbursements = 'disbursements';
  static const fullAccount = 'full_account';

  static const all = [contributions, disbursements, fullAccount];

  static String label(String type) {
    switch (type) {
      case contributions:
        return 'Contributions Only';
      case disbursements:
        return 'Disbursements Only';
      case fullAccount:
        return 'Full Account Statement';
      default:
        return type;
    }
  }
}

// ── Shared Report (for sharing reports to members) ───────────────────────────

class SharedReport {
  final String id;
  final String churchId;
  final String branchId;
  final String title;
  final String reportType;
  final String sharedById;
  final String sharedToMemberId;
  final DateTime sharedAt;
  final String? message;
  final Map<String, dynamic>? reportData;
  final bool isRead;

  const SharedReport({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.title,
    required this.reportType,
    required this.sharedById,
    required this.sharedToMemberId,
    required this.sharedAt,
    this.message,
    this.reportData,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'title': title,
        'reportType': reportType,
        'sharedById': sharedById,
        'sharedToMemberId': sharedToMemberId,
        'sharedAt': sharedAt.toIso8601String(),
        'message': message,
        'reportData': reportData,
        'isRead': isRead,
      };

  factory SharedReport.fromMap(Map<dynamic, dynamic> map) => SharedReport(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        reportType: (map['reportType'] as String?) ?? '',
        sharedById: (map['sharedById'] as String?) ?? '',
        sharedToMemberId: (map['sharedToMemberId'] as String?) ?? '',
        sharedAt: DateTime.parse(map['sharedAt'] as String),
        message: map['message'] as String?,
        reportData: map['reportData'] as Map<String, dynamic>?,
        isRead: (map['isRead'] as bool?) ?? false,
      );

  SharedReport copyWith({bool? isRead}) => SharedReport(
        id: id,
        churchId: churchId,
        branchId: branchId,
        title: title,
        reportType: reportType,
        sharedById: sharedById,
        sharedToMemberId: sharedToMemberId,
        sharedAt: sharedAt,
        message: message,
        reportData: reportData,
        isRead: isRead ?? this.isRead,
      );
}
