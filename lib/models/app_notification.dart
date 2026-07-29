class AppNotification {
  final String id;
  final String churchId;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? route;
  final bool isRead;
  final DateTime createdAt;

  static const typeApproval = 'approval';
  static const typeEvent = 'event';
  static const typeWelfare = 'welfare';
  static const typeFinance = 'finance';
  static const typeMember = 'member';
  static const typeSystem = 'system';
  static const typeContribution = 'contribution';
  static const typeAttendance = 'attendance';

  const AppNotification({
    required this.id,
    required this.churchId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.route,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'route': route,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppNotification.fromMap(Map<dynamic, dynamic> map) => AppNotification(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        userId: map['userId'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        type: map['type'] as String,
        route: map['route'] as String?,
        isRead: (map['isRead'] as bool?) ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  AppNotification copyWith({
    bool? isRead,
  }) =>
      AppNotification(
        id: id,
        churchId: churchId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        route: route,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
