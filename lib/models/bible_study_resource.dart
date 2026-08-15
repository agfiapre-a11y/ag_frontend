class BibleStudyResource {
  final String id;
  final String churchId;
  final String title;
  final String category;
  final String description;
  final String scriptureReferences;
  final String content;
  final List<String> discussionQuestions;
  final String addedById;
  final DateTime createdAt;

  const BibleStudyResource({
    required this.id,
    required this.churchId,
    required this.title,
    required this.category,
    required this.description,
    this.scriptureReferences = '',
    required this.content,
    this.discussionQuestions = const [],
    required this.addedById,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'title': title,
        'category': category,
        'description': description,
        'scriptureReferences': scriptureReferences,
        'content': content,
        'discussionQuestions': discussionQuestions,
        'addedById': addedById,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BibleStudyResource.fromMap(Map<dynamic, dynamic> map) =>
      BibleStudyResource(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        title: map['title'] as String,
        category: (map['category'] as String?) ?? BibleStudyCategory.other,
        description: (map['description'] as String?) ?? '',
        scriptureReferences: (map['scriptureReferences'] as String?) ?? '',
        content: (map['content'] as String?) ?? '',
        discussionQuestions: map['discussionQuestions'] != null
            ? List<String>.from(map['discussionQuestions'] as List)
            : const [],
        addedById: (map['addedById'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  BibleStudyResource copyWith({
    String? title,
    String? category,
    String? description,
    String? scriptureReferences,
    String? content,
    List<String>? discussionQuestions,
  }) =>
      BibleStudyResource(
        id: id,
        churchId: churchId,
        title: title ?? this.title,
        category: category ?? this.category,
        description: description ?? this.description,
        scriptureReferences: scriptureReferences ?? this.scriptureReferences,
        content: content ?? this.content,
        discussionQuestions: discussionQuestions ?? this.discussionQuestions,
        addedById: addedById,
        createdAt: createdAt,
      );
}

class BibleStudyCategory {
  static const foundations = 'Foundations of Faith';
  static const oldTestament = 'Old Testament';
  static const newTestament = 'New Testament';
  static const characterStudy = 'Character Study';
  static const topical = 'Topical Study';
  static const discipleship = 'Discipleship';
  static const other = 'Other';

  static const all = [
    foundations,
    oldTestament,
    newTestament,
    characterStudy,
    topical,
    discipleship,
    other,
  ];
}
