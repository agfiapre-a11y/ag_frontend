import 'package:flutter/material.dart';

// ── Welfare Transaction ──────────────────────────────────────────────────────

class WelfareTransaction {
  final String id;
  final String churchId;
  final String branchId;
  final String type; // 'contribution' | 'disbursement' | 'expense'
  final String category;
  final double amount;
  final String description;
  final String memberId; // member associated (contributor or recipient)
  final String? departmentId; // if tied to a department welfare fund
  final String? welfareCaseId; // if tied to a welfare case
  final String recordedById;
  final DateTime date;
  final String paymentMethod; // 'cash' | 'bank' | 'mobile_money' | 'cheque'
  final String? referenceNumber;
  final DateTime createdAt;

  const WelfareTransaction({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.memberId,
    this.departmentId,
    this.welfareCaseId,
    required this.recordedById,
    required this.date,
    required this.paymentMethod,
    this.referenceNumber,
    required this.createdAt,
  });

  bool get isContribution => type == WelfareTxnType.contribution;
  bool get isDisbursement => type == WelfareTxnType.disbursement;
  bool get isExpense => type == WelfareTxnType.expense;

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'type': type,
        'category': category,
        'amount': amount,
        'description': description,
        'memberId': memberId,
        'departmentId': departmentId,
        'welfareCaseId': welfareCaseId,
        'recordedById': recordedById,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WelfareTransaction.fromMap(Map<dynamic, dynamic> map) =>
      WelfareTransaction(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        type: map['type'] as String,
        category: (map['category'] as String?) ?? '',
        amount: (map['amount'] as num).toDouble(),
        description: (map['description'] as String?) ?? '',
        memberId: (map['memberId'] as String?) ?? '',
        departmentId: map['departmentId'] as String?,
        welfareCaseId: map['welfareCaseId'] as String?,
        recordedById: (map['recordedById'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        paymentMethod: (map['paymentMethod'] as String?) ??
            WelfarePaymentMethod.cash,
        referenceNumber: map['referenceNumber'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

class WelfareTxnType {
  static const contribution = 'contribution';
  static const disbursement = 'disbursement';
  static const expense = 'expense';

  static const all = [contribution, disbursement, expense];

  static String label(String type) {
    switch (type) {
      case contribution:
        return 'Contribution';
      case disbursement:
        return 'Disbursement';
      case expense:
        return 'Expense';
      default:
        return type;
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case contribution:
        return Icons.savings;
      case disbursement:
        return Icons.volunteer_activism;
      case expense:
        return Icons.shopping_cart;
      default:
        return Icons.receipt_long;
    }
  }

  static Color color(String type) {
    switch (type) {
      case contribution:
        return Colors.green;
      case disbursement:
        return Colors.blue;
      case expense:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class WelfarePaymentMethod {
  static const cash = 'cash';
  static const bank = 'bank';
  static const mobileMoney = 'mobile_money';
  static const cheque = 'cheque';

  static const all = [cash, bank, mobileMoney, cheque];

  static String label(String method) {
    switch (method) {
      case cash:
        return 'Cash';
      case bank:
        return 'Bank Transfer';
      case mobileMoney:
        return 'Mobile Money';
      case cheque:
        return 'Cheque';
      default:
        return method;
    }
  }
}

// ── Department Welfare ───────────────────────────────────────────────────────

class DepartmentWelfare {
  final String id;
  final String churchId;
  final String branchId;
  final String departmentId;
  final String departmentName;
  final double fundBalance;
  final double totalContributions;
  final double totalDisbursements;
  final bool isActive;
  final String managedByWelfareHeadId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DepartmentWelfare({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.departmentId,
    required this.departmentName,
    this.fundBalance = 0,
    this.totalContributions = 0,
    this.totalDisbursements = 0,
    this.isActive = true,
    required this.managedByWelfareHeadId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'fundBalance': fundBalance,
        'totalContributions': totalContributions,
        'totalDisbursements': totalDisbursements,
        'isActive': isActive,
        'managedByWelfareHeadId': managedByWelfareHeadId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory DepartmentWelfare.fromMap(Map<dynamic, dynamic> map) =>
      DepartmentWelfare(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        departmentId: map['departmentId'] as String,
        departmentName: (map['departmentName'] as String?) ?? '',
        fundBalance: (map['fundBalance'] as num?)?.toDouble() ?? 0,
        totalContributions:
            (map['totalContributions'] as num?)?.toDouble() ?? 0,
        totalDisbursements:
            (map['totalDisbursements'] as num?)?.toDouble() ?? 0,
        isActive: (map['isActive'] as bool?) ?? true,
        managedByWelfareHeadId:
            (map['managedByWelfareHeadId'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );

  DepartmentWelfare copyWith({
    double? fundBalance,
    double? totalContributions,
    double? totalDisbursements,
    bool? isActive,
    String? managedByWelfareHeadId,
  }) =>
      DepartmentWelfare(
        id: id,
        churchId: churchId,
        branchId: branchId,
        departmentId: departmentId,
        departmentName: departmentName,
        fundBalance: fundBalance ?? this.fundBalance,
        totalContributions:
            totalContributions ?? this.totalContributions,
        totalDisbursements:
            totalDisbursements ?? this.totalDisbursements,
        isActive: isActive ?? this.isActive,
        managedByWelfareHeadId:
            managedByWelfareHeadId ?? this.managedByWelfareHeadId,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
