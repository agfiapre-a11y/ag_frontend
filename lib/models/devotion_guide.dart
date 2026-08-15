class DevotionGuide {
  final String id;
  final String churchId;
  final String title;
  final String scriptureReference;
  final String scriptureText;
  final String content;
  final List<String> prayerPoints;
  final String author;
  final DateTime date;
  final String addedById;
  final DateTime createdAt;

  const DevotionGuide({
    required this.id,
    required this.churchId,
    required this.title,
    required this.scriptureReference,
    this.scriptureText = '',
    required this.content,
    this.prayerPoints = const [],
    this.author = '',
    required this.date,
    required this.addedById,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'title': title,
        'scriptureReference': scriptureReference,
        'scriptureText': scriptureText,
        'content': content,
        'prayerPoints': prayerPoints,
        'author': author,
        'date': date.toIso8601String(),
        'addedById': addedById,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DevotionGuide.fromMap(Map<dynamic, dynamic> map) => DevotionGuide(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        title: map['title'] as String,
        scriptureReference: (map['scriptureReference'] as String?) ?? '',
        scriptureText: (map['scriptureText'] as String?) ?? '',
        content: (map['content'] as String?) ?? '',
        prayerPoints: map['prayerPoints'] != null
            ? List<String>.from(map['prayerPoints'] as List)
            : const [],
        author: (map['author'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        addedById: (map['addedById'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  DevotionGuide copyWith({
    String? title,
    String? scriptureReference,
    String? scriptureText,
    String? content,
    List<String>? prayerPoints,
    String? author,
    DateTime? date,
  }) =>
      DevotionGuide(
        id: id,
        churchId: churchId,
        title: title ?? this.title,
        scriptureReference: scriptureReference ?? this.scriptureReference,
        scriptureText: scriptureText ?? this.scriptureText,
        content: content ?? this.content,
        prayerPoints: prayerPoints ?? this.prayerPoints,
        author: author ?? this.author,
        date: date ?? this.date,
        addedById: addedById,
        createdAt: createdAt,
      );
}
