class FinanceApprovalStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';

  static String label(String status) {
    switch (status) {
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}

class FinanceApprovalRequest {
  final String id;
  final String churchId;
  final String branchId;
  final String type; // 'income' | 'expense'
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String requestedById;
  final String requestedByName;
  final String status;
  final String? approverId;
  final String? approverName;
  final String? rejectionReason;
  final DateTime? decidedAt;
  final DateTime createdAt;

  const FinanceApprovalRequest({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.requestedById,
    required this.requestedByName,
    this.status = FinanceApprovalStatus.pending,
    this.approverId,
    this.approverName,
    this.rejectionReason,
    this.decidedAt,
    required this.createdAt,
  });

  bool get isPending => status == FinanceApprovalStatus.pending;
  bool get isApproved => status == FinanceApprovalStatus.approved;
  bool get isRejected => status == FinanceApprovalStatus.rejected;

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'type': type,
        'category': category,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'requestedById': requestedById,
        'requestedByName': requestedByName,
        'status': status,
        'approverId': approverId,
        'approverName': approverName,
        'rejectionReason': rejectionReason,
        'decidedAt': decidedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FinanceApprovalRequest.fromMap(Map<dynamic, dynamic> map) =>
      FinanceApprovalRequest(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        type: map['type'] as String,
        category: map['category'] as String,
        amount: (map['amount'] as num).toDouble(),
        description: (map['description'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        requestedById: (map['requestedById'] as String?) ?? '',
        requestedByName: (map['requestedByName'] as String?) ?? '',
        status: (map['status'] as String?) ?? FinanceApprovalStatus.pending,
        approverId: map['approverId'] as String?,
        approverName: map['approverName'] as String?,
        rejectionReason: map['rejectionReason'] as String?,
        decidedAt: map['decidedAt'] != null
            ? DateTime.parse(map['decidedAt'] as String)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  FinanceApprovalRequest copyWith({
    String? status,
    String? approverId,
    String? approverName,
    String? rejectionReason,
    DateTime? decidedAt,
  }) =>
      FinanceApprovalRequest(
        id: id,
        churchId: churchId,
        branchId: branchId,
        type: type,
        category: category,
        amount: amount,
        description: description,
        date: date,
        requestedById: requestedById,
        requestedByName: requestedByName,
        status: status ?? this.status,
        approverId: approverId ?? this.approverId,
        approverName: approverName ?? this.approverName,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        decidedAt: decidedAt ?? this.decidedAt,
        createdAt: createdAt,
      );
}
