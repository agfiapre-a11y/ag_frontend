import 'package:flutter/material.dart';

class WelfareCase {
  final String id;
  final String churchId;
  final String branchId;
  final String memberId;
  final String welfareHeadId;
  final String type;
  final String status;
  final String priority;
  final String description;
  final double amountRequested;
  final double amountDisbursed;
  final DateTime dateRequested;
  final DateTime? dateClosed;
  final String notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Hierarchical fields
  final String? organizationId;
  final String? regionId;
  final String? districtId;
  final String? areaId;

  const WelfareCase({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.memberId,
    required this.welfareHeadId,
    required this.type,
    required this.status,
    required this.priority,
    required this.description,
    this.amountRequested = 0,
    this.amountDisbursed = 0,
    required this.dateRequested,
    this.dateClosed,
    this.notes = '',
    required this.createdAt,
    this.updatedAt,
    this.organizationId,
    this.regionId,
    this.districtId,
    this.areaId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'memberId': memberId,
        'welfareHeadId': welfareHeadId,
        'type': type,
        'status': status,
        'priority': priority,
        'description': description,
        'amountRequested': amountRequested,
        'amountDisbursed': amountDisbursed,
        'dateRequested': dateRequested.toIso8601String(),
        'dateClosed': dateClosed?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'organizationId': organizationId,
        'regionId': regionId,
        'districtId': districtId,
        'areaId': areaId,
      };

  factory WelfareCase.fromMap(Map<dynamic, dynamic> map) => WelfareCase(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        memberId: (map['memberId'] as String?) ?? '',
        welfareHeadId: (map['welfareHeadId'] as String?) ?? '',
        type: (map['type'] as String?) ?? WelfareType.financial,
        status: (map['status'] as String?) ?? WelfareStatus.open,
        priority: (map['priority'] as String?) ?? WelfarePriority.medium,
        description: (map['description'] as String?) ?? '',
        amountRequested: (map['amountRequested'] as num?)?.toDouble() ?? 0,
        amountDisbursed: (map['amountDisbursed'] as num?)?.toDouble() ?? 0,
        dateRequested: DateTime.parse(map['dateRequested'] as String),
        dateClosed: map['dateClosed'] != null
            ? DateTime.parse(map['dateClosed'] as String)
            : null,
        notes: (map['notes'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
        organizationId: map['organizationId'] as String?,
        regionId: map['regionId'] as String?,
        districtId: map['districtId'] as String?,
        areaId: map['areaId'] as String?,
      );

  WelfareCase copyWith({
    String? memberId,
    String? welfareHeadId,
    String? type,
    String? status,
    String? priority,
    String? description,
    double? amountRequested,
    double? amountDisbursed,
    DateTime? dateRequested,
    DateTime? dateClosed,
    String? notes,
    String? branchId,
    String? organizationId,
    String? regionId,
    String? districtId,
    String? areaId,
  }) =>
      WelfareCase(
        id: id,
        churchId: churchId,
        branchId: branchId ?? this.branchId,
        memberId: memberId ?? this.memberId,
        welfareHeadId: welfareHeadId ?? this.welfareHeadId,
        type: type ?? this.type,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        description: description ?? this.description,
        amountRequested: amountRequested ?? this.amountRequested,
        amountDisbursed: amountDisbursed ?? this.amountDisbursed,
        dateRequested: dateRequested ?? this.dateRequested,
        dateClosed: dateClosed ?? this.dateClosed,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        organizationId: organizationId ?? this.organizationId,
        regionId: regionId ?? this.regionId,
        districtId: districtId ?? this.districtId,
        areaId: areaId ?? this.areaId,
      );
}

class WelfareType {
  static const financial = 'financial';
  static const food = 'food';
  static const medical = 'medical';
  static const counseling = 'counseling';
  static const bereavement = 'bereavement';
  static const education = 'education';
  static const housing = 'housing';
  static const clothing = 'clothing';
  static const other = 'other';

  static const all = [
    financial,
    food,
    medical,
    counseling,
    bereavement,
    education,
    housing,
    clothing,
    other,
  ];

  static String label(String type) {
    switch (type) {
      case financial:
        return 'Financial Assistance';
      case food:
        return 'Food Support';
      case medical:
        return 'Medical Support';
      case counseling:
        return 'Counseling';
      case bereavement:
        return 'Bereavement Support';
      case education:
        return 'Education Support';
      case housing:
        return 'Housing Support';
      case clothing:
        return 'Clothing Support';
      case other:
        return 'Other';
      default:
        return type;
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case financial:
        return Icons.attach_money;
      case food:
        return Icons.restaurant;
      case medical:
        return Icons.medical_services;
      case counseling:
        return Icons.psychology;
      case bereavement:
        return Icons.church;
      case education:
        return Icons.school;
      case housing:
        return Icons.home;
      case clothing:
        return Icons.checkroom;
      case other:
        return Icons.handshake;
      default:
        return Icons.handshake;
    }
  }
}

class WelfareStatus {
  static const open = 'open';
  static const inProgress = 'inProgress';
  static const pending = 'pending';
  static const closed = 'closed';

  static const all = [open, inProgress, pending, closed];

  static String label(String status) {
    switch (status) {
      case open:
        return 'Open';
      case inProgress:
        return 'In Progress';
      case pending:
        return 'Pending Approval';
      case closed:
        return 'Closed';
      default:
        return status;
    }
  }

  static Color color(String status) {
    switch (status) {
      case open:
        return Colors.blue;
      case inProgress:
        return Colors.orange;
      case pending:
        return Colors.amber;
      case closed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class WelfarePriority {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
  static const urgent = 'urgent';

  static const all = [low, medium, high, urgent];

  static String label(String priority) {
    switch (priority) {
      case low:
        return 'Low';
      case medium:
        return 'Medium';
      case high:
        return 'High';
      case urgent:
        return 'Urgent';
      default:
        return priority;
    }
  }

  static Color color(String priority) {
    switch (priority) {
      case low:
        return Colors.green;
      case medium:
        return Colors.blue;
      case high:
        return Colors.orange;
      case urgent:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
