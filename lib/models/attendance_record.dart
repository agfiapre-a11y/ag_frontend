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
  final double? latitude;
  final double? longitude;
  final int proximityRadius;
  final bool isActive;

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
    this.latitude,
    this.longitude,
    this.proximityRadius = 100,
    this.isActive = true,
  });

  int get presentCount => presentMemberIds.length;

  bool get hasGpsLocation => latitude != null && longitude != null;

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
        'latitude': latitude,
        'longitude': longitude,
        'proximityRadius': proximityRadius,
        'isActive': isActive,
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
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        proximityRadius: (map['proximityRadius'] as num?)?.toInt() ?? 100,
        isActive: map['isActive'] as bool? ?? true,
      );

  factory AttendanceRecord.fromBackend(Map<dynamic, dynamic> map) =>
      AttendanceRecord(
        id: map['id'] as String,
        churchId: '',
        branchId: (map['branchId'] as String?) ?? '',
        serviceType: map['serviceType'] as String,
        date: DateTime.parse(map['date'] as String),
        presentMemberIds: List<String>.from(
            (map['presentMemberIds'] as List?) ?? []),
        recordedById: map['recordedById'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        ministryType: map['ministryType'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        proximityRadius: (map['proximityRadius'] as num?)?.toInt() ?? 100,
        isActive: map['isActive'] as bool? ?? true,
      );

  AttendanceRecord copyWith({
    List<String>? presentMemberIds,
    String? ministryType,
    double? latitude,
    double? longitude,
    int? proximityRadius,
    bool? isActive,
  }) =>
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
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        proximityRadius: proximityRadius ?? this.proximityRadius,
        isActive: isActive ?? this.isActive,
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
