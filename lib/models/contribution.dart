class MemberContribution {
  final String id, churchId, branchId, memberId, memberName, type, description;
  final String? departmentId;
  final String departmentName;
  final String welfareScope;
  final String? contributionMonth;
  final double amount;
  final DateTime date, createdAt;

  const MemberContribution({
    required this.id, required this.churchId, required this.branchId,
    required this.memberId, required this.memberName, required this.type,
    required this.amount, required this.description, this.departmentId,
    this.departmentName = '', this.welfareScope = WelfareScope.church,
    this.contributionMonth, required this.date, required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'churchId': churchId, 'branchId': branchId, 'memberId': memberId,
    'memberName': memberName, 'type': type, 'amount': amount,
    'description': description, 'departmentId': departmentId ?? '',
    'departmentName': departmentName, 'welfareScope': welfareScope,
    'contributionMonth': contributionMonth,
    'date': date.toIso8601String(), 'createdAt': createdAt.toIso8601String(),
  };

  factory MemberContribution.fromMap(Map<dynamic, dynamic> m) =>
    MemberContribution(
      id: m['id'], churchId: m['churchId'], branchId: m['branchId'],
      memberId: m['memberId'], memberName: m['memberName'], type: m['type'],
      amount: (m['amount'] as num).toDouble(),
      description: m['description'] ?? '', departmentId: m['departmentId'],
      departmentName: m['departmentName'] ?? '',
      welfareScope: m['welfareScope'] ?? WelfareScope.church,
      contributionMonth: m['contributionMonth'],
      date: DateTime.parse(m['date']), createdAt: DateTime.parse(m['createdAt']),
    );
}

class ContributionType {
  static const welfare = 'welfare';
  static const tithe = 'tithe';
  static const offering = 'offering';
  static const donation = 'donation';
  static const all = [welfare, tithe, offering, donation];
}

class WelfareScope {
  static const church = 'church';
  static const department = 'department';
  static const all = [church, department];
}

class BenefitRequest {
  final String id, churchId, branchId, memberId, memberName, type, description, status;
  final double amountRequested;
  final double? amountApproved;
  final DateTime requestDate;
  final DateTime? reviewedDate;
  final String? reviewedByName;
  final String adminNotes;
  final DateTime createdAt;

  const BenefitRequest({
    required this.id, required this.churchId, required this.branchId,
    required this.memberId, required this.memberName, required this.type,
    required this.description, required this.status,
    required this.amountRequested, this.amountApproved,
    required this.requestDate, this.reviewedDate, this.reviewedByName,
    this.adminNotes = '', required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'churchId': churchId, 'branchId': branchId, 'memberId': memberId,
    'memberName': memberName, 'type': type, 'description': description,
    'status': status, 'amountRequested': amountRequested,
    'amountApproved': amountApproved, 'requestDate': requestDate.toIso8601String(),
    'reviewedDate': reviewedDate?.toIso8601String(),
    'reviewedByName': reviewedByName, 'adminNotes': adminNotes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BenefitRequest.fromMap(Map<dynamic, dynamic> m) =>
    BenefitRequest(
      id: m['id'], churchId: m['churchId'], branchId: m['branchId'],
      memberId: m['memberId'], memberName: m['memberName'], type: m['type'],
      description: m['description'] ?? '', status: m['status'],
      amountRequested: (m['amountRequested'] as num).toDouble(),
      amountApproved: m['amountApproved'] != null ? (m['amountApproved'] as num).toDouble() : null,
      requestDate: DateTime.parse(m['requestDate']),
      reviewedDate: m['reviewedDate'] != null ? DateTime.parse(m['reviewedDate']) : null,
      reviewedByName: m['reviewedByName'],
      adminNotes: m['adminNotes'] ?? '',
      createdAt: DateTime.parse(m['createdAt']),
    );
}

class BenefitStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const disbursed = 'disbursed';
}

class BenefitType {
  static const medical = 'Medical Assistance';
  static const education = 'Education Support';
  static const funeral = 'Funeral Support';
  static const housing = 'Housing Assistance';
  static const emergency = 'Emergency Relief';
  static const other = 'Other';
  static const all = [medical, education, funeral, housing, emergency, other];
}
