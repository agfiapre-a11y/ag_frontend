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

  /// Optional link to an Event. When set, this attendance record is
  /// tied to a specific event rather than a standalone service type.
  final String? eventId;

  /// Optional event title (denormalized for display without a join).
  final String? eventTitle;

  /// When the attendance session expires. After this time, members can
  /// no longer self-check-in. Defaults to 2 hours after creation.
  final DateTime? expiresAt;

  /// Target audience for this attendance session (EventAudience constant).
  /// Controls which users see the session on their dashboard.
  final String audience;

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
    this.eventId,
    this.eventTitle,
    this.expiresAt,
    this.audience = 'everyone',
  });

  int get presentCount => presentMemberIds.length;

  bool get hasGpsLocation => latitude != null && longitude != null;

  /// Returns true if this attendance session has expired (can no longer
  /// accept self-check-ins).
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Returns true if the session is active AND not expired.
  bool get canSelfCheckIn => isActive && !isExpired;

  /// Returns true if this record is linked to an event.
  bool get isLinkedToEvent => eventId != null && eventId!.isNotEmpty;

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
        'eventId': eventId,
        'eventTitle': eventTitle,
        'expiresAt': expiresAt?.toIso8601String(),
        'audience': audience,
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
        eventId: map['eventId'] as String?,
        eventTitle: map['eventTitle'] as String?,
        expiresAt: map['expiresAt'] != null
            ? DateTime.parse(map['expiresAt'] as String)
            : null,
        audience: (map['audience'] as String?) ?? 'everyone',
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
        eventId: map['eventId'] as String?,
        eventTitle: map['eventTitle'] as String?,
        expiresAt: map['expiresAt'] != null
            ? DateTime.parse(map['expiresAt'] as String)
            : null,
        audience: (map['audience'] as String?) ?? 'everyone',
      );

  AttendanceRecord copyWith({
    List<String>? presentMemberIds,
    String? ministryType,
    double? latitude,
    double? longitude,
    int? proximityRadius,
    bool? isActive,
    String? eventId,
    String? eventTitle,
    DateTime? expiresAt,
    String? serviceType,
    DateTime? date,
    String? audience,
  }) =>
      AttendanceRecord(
        id: id,
        churchId: churchId,
        branchId: branchId,
        serviceType: serviceType ?? this.serviceType,
        date: date ?? this.date,
        presentMemberIds: presentMemberIds ?? this.presentMemberIds,
        recordedById: recordedById,
        createdAt: createdAt,
        ministryType: ministryType ?? this.ministryType,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        proximityRadius: proximityRadius ?? this.proximityRadius,
        isActive: isActive ?? this.isActive,
        eventId: eventId ?? this.eventId,
        eventTitle: eventTitle ?? this.eventTitle,
        expiresAt: expiresAt ?? this.expiresAt,
        audience: audience ?? this.audience,
      );
}

class ServiceTypes {
  static const sundayService = 'Sunday Service';
  static const bibleStudy = 'Bible Study';
  static const prayerMeeting = 'Prayer Meeting';
  static const youthService = 'Youth Service';
  static const specialService = 'Special Service';

  // Expanded service types
  static const fridayService = 'Friday Service';
  static const saturdayService = 'Saturday Service';
  static const communionService = 'Communion Service';
  static const revivalService = 'Revival Service';
  static const convention = 'Convention';
  static const conference = 'Conference';
  static const campMeeting = 'Camp Meeting';
  static const crusade = 'Crusade';
  static const workshop = 'Workshop';
  static const seminar = 'Seminar';
  static const leadershipMeeting = 'Leadership Meeting';
  static const workersMeeting = 'Workers Meeting';
  static const departmentMeeting = 'Department Meeting';
  static const cellGroupMeeting = 'Cell Group Meeting';
  static const choirPractice = 'Choir Practice';
  static const evangelism = 'Evangelism Outreach';
  static const funeralService = 'Funeral Service';
  static const weddingService = 'Wedding Service';
  static const baptismService = 'Baptism Service';
  static const dedicationService = 'Dedication Service';
  static const thanksgivingService = 'Thanksgiving Service';
  static const watchnightService = 'Watchnight Service';
  static const easterService = 'Easter Service';
  static const christmasService = 'Christmas Service';
  static const newYearService = 'New Year Service';
  static const fastingPrayer = 'Fasting & Prayer';
  static const deliveranceService = 'Deliverance Service';

  static const all = [
    sundayService,
    fridayService,
    saturdayService,
    bibleStudy,
    prayerMeeting,
    fastingPrayer,
    communionService,
    revivalService,
    youthService,
    specialService,
    convention,
    conference,
    campMeeting,
    crusade,
    workshop,
    seminar,
    leadershipMeeting,
    workersMeeting,
    departmentMeeting,
    cellGroupMeeting,
    choirPractice,
    evangelism,
    funeralService,
    weddingService,
    baptismService,
    dedicationService,
    thanksgivingService,
    watchnightService,
    easterService,
    christmasService,
    newYearService,
    deliveranceService,
  ];

  /// Default expiry duration for attendance sessions (2 hours).
  static const defaultExpiryDuration = Duration(hours: 2);
}
