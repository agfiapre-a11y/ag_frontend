class ChurchEvent {
  final String id;
  final String churchId;
  final String branchId;
  final String departmentId;
  final String title;
  final String description;
  final String category;
  final String location;
  final String organizer;
  final DateTime startDate;
  final DateTime endDate;
  final bool isAllDay;
  final String recordedById;
  final DateTime createdAt;
  final String? ministryType;

  /// Denormalized church/tenant name for cross-church display.
  /// Set when loading events across churches (for above-church roles).
  final String? churchName;

  /// Target audience for this event (EventAudience constant).
  /// Controls which users see the event. Defaults to 'everyone'.
  final String audience;

  const ChurchEvent({
    required this.id,
    required this.churchId,
    required this.branchId,
    this.departmentId = '',
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.organizer,
    required this.startDate,
    required this.endDate,
    required this.isAllDay,
    required this.recordedById,
    required this.createdAt,
    this.ministryType,
    this.churchName,
    this.audience = 'everyone',
  });

  bool get isUpcoming => endDate.isAfter(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;
  }

  bool get isMultiDay =>
      startDate.year != endDate.year ||
      startDate.month != endDate.month ||
      startDate.day != endDate.day;

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'departmentId': departmentId,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'organizer': organizer,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isAllDay': isAllDay,
        'recordedById': recordedById,
        'createdAt': createdAt.toIso8601String(),
        'ministryType': ministryType,
        'churchName': churchName,
        'audience': audience,
      };

  factory ChurchEvent.fromMap(Map<dynamic, dynamic> map) => ChurchEvent(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: map['branchId'] as String,
        departmentId: (map['departmentId'] as String?) ?? '',
        title: map['title'] as String,
        description: (map['description'] as String?) ?? '',
        category: (map['category'] as String?) ?? EventCategory.other,
        location: (map['location'] as String?) ?? '',
        organizer: (map['organizer'] as String?) ?? '',
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: DateTime.parse(map['endDate'] as String),
        isAllDay: (map['isAllDay'] as bool?) ?? false,
        recordedById: map['recordedById'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        ministryType: map['ministryType'] as String?,
        churchName: map['churchName'] as String?,
        audience: (map['audience'] as String?) ?? 'everyone',
      );

  ChurchEvent copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    String? organizer,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    String? branchId,
    String? departmentId,
    String? ministryType,
    String? churchName,
    String? audience,
  }) =>
      ChurchEvent(
        id: id,
        churchId: churchId,
        branchId: branchId ?? this.branchId,
        departmentId: departmentId ?? this.departmentId,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        location: location ?? this.location,
        organizer: organizer ?? this.organizer,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        isAllDay: isAllDay ?? this.isAllDay,
        recordedById: recordedById,
        createdAt: createdAt,
        ministryType: ministryType ?? this.ministryType,
        churchName: churchName ?? this.churchName,
        audience: audience ?? this.audience,
      );
}

class EventCategory {
  static const sundayService = 'Sunday Service';
  static const conference = 'Conference';
  static const outreach = 'Outreach';
  static const prayerNight = 'Prayer Night';
  static const youthEvent = 'Youth Event';
  static const womensMeeting = "Women's Meeting";
  static const mensMeeting = "Men's Meeting";
  static const specialService = 'Special Service';
  static const communityEvent = 'Community Event';
  static const other = 'Other';

  static const all = [
    sundayService,
    conference,
    outreach,
    prayerNight,
    youthEvent,
    womensMeeting,
    mensMeeting,
    specialService,
    communityEvent,
    other,
  ];
}
