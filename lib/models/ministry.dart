import 'package:flutter/material.dart';
import '../core/constants.dart' show AppRoles;

class Ministry {
  final String id;
  final String churchId;
  final String branchId;
  final String name;
  final String ministryType;
  final String description;
  final String headId;
  final List<String> memberIds;
  final List<String> eventIds;
  final bool isActive;
  final DateTime createdAt;

  // Hierarchical fields
  final String? organizationId;
  final String? regionId;
  final String? districtId;
  final String? areaId;

  const Ministry({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.name,
    required this.ministryType,
    this.description = '',
    this.headId = '',
    this.memberIds = const [],
    this.eventIds = const [],
    this.isActive = true,
    required this.createdAt,
    this.organizationId,
    this.regionId,
    this.districtId,
    this.areaId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'name': name,
        'ministryType': ministryType,
        'description': description,
        'headId': headId,
        'memberIds': memberIds,
        'eventIds': eventIds,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'organizationId': organizationId,
        'regionId': regionId,
        'districtId': districtId,
        'areaId': areaId,
      };

  factory Ministry.fromMap(Map<dynamic, dynamic> map) => Ministry(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: (map['branchId'] as String?) ?? '',
        name: (map['name'] as String?) ?? '',
        ministryType: (map['ministryType'] as String?) ?? MinistryType.youth,
        description: (map['description'] as String?) ?? '',
        headId: (map['headId'] as String?) ?? '',
        memberIds: (map['memberIds'] as List?)?.cast<String>() ?? [],
        eventIds: (map['eventIds'] as List?)?.cast<String>() ?? [],
        isActive: (map['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(map['createdAt'] as String),
        organizationId: map['organizationId'] as String?,
        regionId: map['regionId'] as String?,
        districtId: map['districtId'] as String?,
        areaId: map['areaId'] as String?,
      );

  Ministry copyWith({
    String? name,
    String? description,
    String? headId,
    List<String>? memberIds,
    List<String>? eventIds,
    bool? isActive,
  }) =>
      Ministry(
        id: id,
        churchId: churchId,
        branchId: branchId,
        name: name ?? this.name,
        ministryType: ministryType,
        description: description ?? this.description,
        headId: headId ?? this.headId,
        memberIds: memberIds ?? this.memberIds,
        eventIds: eventIds ?? this.eventIds,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        organizationId: organizationId,
        regionId: regionId,
        districtId: districtId,
        areaId: areaId,
      );
}

class MinistryType {
  static const youth = 'youth';
  static const menFellowship = 'men_fellowship';
  static const womenFellowship = 'women_fellowship';
  static const children = 'children';

  static const all = [youth, menFellowship, womenFellowship, children];

  static String label(String type) {
    switch (type) {
      case youth:
        return 'Youth Ministry';
      case menFellowship:
        return "Men's Fellowship";
      case womenFellowship:
        return "Women's Fellowship";
      case children:
        return "Children's Ministry";
      default:
        return type;
    }
  }

  static String shortLabel(String type) {
    switch (type) {
      case youth:
        return 'Youth';
      case menFellowship:
        return 'Men';
      case womenFellowship:
        return 'Women';
      case children:
        return 'Children';
      default:
        return type;
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case youth:
        return Icons.sports_basketball;
      case menFellowship:
        return Icons.man;
      case womenFellowship:
        return Icons.woman;
      case children:
        return Icons.child_care;
      default:
        return Icons.groups;
    }
  }

  static Color color(String type) {
    switch (type) {
      case youth:
        return Colors.blue;
      case menFellowship:
        return Colors.indigo;
      case womenFellowship:
        return Colors.pink;
      case children:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  static String description(String type) {
    switch (type) {
      case youth:
        return 'Engaging young people in spiritual growth, mentorship, and activities';
      case menFellowship:
        return 'Building strong men of faith through fellowship and discipleship';
      case womenFellowship:
        return 'Empowering women in faith, service, and community';
      case children:
        return 'Nurturing children in God\'s word through Sunday school and programs';
      default:
        return '';
    }
  }

  static String roleFor(String type) {
    switch (type) {
      case youth:
        return AppRoles.youthMinistryHead;
      case menFellowship:
        return AppRoles.menFellowshipHead;
      case womenFellowship:
        return AppRoles.womenFellowshipHead;
      case children:
        return AppRoles.childrenMinistryHead;
      default:
        return AppRoles.ministryHead;
    }
  }
}
