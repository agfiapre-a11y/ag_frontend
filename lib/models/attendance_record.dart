class AttendanceRecord {
  final String id;
  final String churchId;
  final String branchId;
  final String serviceType;
  final DateTime date;
  final List<String> presentMemberIds;
  final String recordedById;
  final DateTime createdAt;
  final String? ministryType;

  const AttendanceRecord({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.serviceType,
    required this.date,
    required this.presentMemberIds,
    required this.recordedById,
    required this.createdAt,
    this.ministryType,
  });

  int get presentCount => presentMemberIds.length;

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'serviceType': serviceType,
        'date': date.toIso8601String(),
        'presentMemberIds': presentMemberIds,
        'recordedById': recordedById,
        'createdAt': createdAt.toIso8601String(),
        'ministryType': ministryType,
      };

  factory AttendanceRecord.fromMap(Map<dynamic, dynamic> map) =>
      AttendanceRecord(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: map['branchId'] as String,
        serviceType: map['serviceType'] as String,
        date: DateTime.parse(map['date'] as String),
        presentMemberIds: List<String>.from(map['presentMemberIds'] as List),
        recordedById: map['recordedById'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        ministryType: map['ministryType'] as String?,
      );

  AttendanceRecord copyWith({List<String>? presentMemberIds, String? ministryType}) =>
      AttendanceRecord(
        id: id,
        churchId: churchId,
        branchId: branchId,
        serviceType: serviceType,
        date: date,
        presentMemberIds: presentMemberIds ?? this.presentMemberIds,
        recordedById: recordedById,
        createdAt: createdAt,
        ministryType: ministryType ?? this.ministryType,
      );
}

class ServiceTypes {
  static const sundayService = 'Sunday Service';
  static const bibleStudy = 'Bible Study';
  static const prayerMeeting = 'Prayer Meeting';
  static const youthService = 'Youth Service';
  static const specialService = 'Special Service';

  static const all = [
    sundayService,
    bibleStudy,
    prayerMeeting,
    youthService,
    specialService,
  ];
}
