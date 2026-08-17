/// A Sunday School book with chapters mapped to specific Sundays.
///
/// When a book is uploaded with a start date and end date, the system
/// automatically splits the PDF into chapters and assigns each chapter
/// to a Sunday within that date range. Users can then read each chapter
/// on its assigned Sunday and discuss it in the Community.
class SundaySchoolBook {
  final String id;
  final String churchId;
  final String title;
  final String author;
  final String description;
  final String url; // PDF download URL
  final String coverColor;
  final String addedById;
  final String addedByName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalChapters;
  final DateTime createdAt;

  const SundaySchoolBook({
    required this.id,
    required this.churchId,
    required this.title,
    this.author = '',
    this.description = '',
    required this.url,
    this.coverColor = '',
    required this.addedById,
    this.addedByName = '',
    required this.startDate,
    required this.endDate,
    this.totalChapters = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'title': title,
        'author': author,
        'description': description,
        'url': url,
        'coverColor': coverColor,
        'addedById': addedById,
        'addedByName': addedByName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalChapters': totalChapters,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SundaySchoolBook.fromMap(Map<dynamic, dynamic> map) => SundaySchoolBook(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        title: map['title'] as String,
        author: (map['author'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        url: (map['url'] as String?) ?? '',
        coverColor: (map['coverColor'] as String?) ?? '',
        addedById: (map['addedById'] as String?) ?? '',
        addedByName: (map['addedByName'] as String?) ?? '',
        startDate: DateTime.parse(map['startDate'] as String),
        endDate: DateTime.parse(map['endDate'] as String),
        totalChapters: (map['totalChapters'] as int?) ?? 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  SundaySchoolBook copyWith({
    String? title,
    String? author,
    String? description,
    String? url,
    String? coverColor,
    DateTime? startDate,
    DateTime? endDate,
    int? totalChapters,
  }) =>
      SundaySchoolBook(
        id: id,
        churchId: churchId,
        title: title ?? this.title,
        author: author ?? this.author,
        description: description ?? this.description,
        url: url ?? this.url,
        coverColor: coverColor ?? this.coverColor,
        addedById: addedById,
        addedByName: addedByName,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        totalChapters: totalChapters ?? this.totalChapters,
        createdAt: createdAt,
      );
}

/// A single chapter of a Sunday School book, mapped to a specific Sunday.
class SundaySchoolChapter {
  final String id;
  final String bookId;
  final String churchId;
  final int chapterNumber;
  final String title;
  final String content;
  final DateTime sundayDate;
  final String discussionPostId; // linked community post for discussion
  final String memoryVerseRef; // e.g., "Jude 1:3" (empty if not found)
  final String memoryVerseText; // the verse text (empty if not found)
  final DateTime createdAt;

  const SundaySchoolChapter({
    required this.id,
    required this.bookId,
    required this.churchId,
    required this.chapterNumber,
    this.title = '',
    this.content = '',
    required this.sundayDate,
    this.discussionPostId = '',
    this.memoryVerseRef = '',
    this.memoryVerseText = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookId': bookId,
        'churchId': churchId,
        'chapterNumber': chapterNumber,
        'title': title,
        'content': content,
        'sundayDate': sundayDate.toIso8601String(),
        'discussionPostId': discussionPostId,
        'memoryVerseRef': memoryVerseRef,
        'memoryVerseText': memoryVerseText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SundaySchoolChapter.fromMap(Map<dynamic, dynamic> map) =>
      SundaySchoolChapter(
        id: map['id'] as String,
        bookId: map['bookId'] as String,
        churchId: map['churchId'] as String,
        chapterNumber: (map['chapterNumber'] as int?) ?? 0,
        title: (map['title'] as String?) ?? '',
        content: (map['content'] as String?) ?? '',
        sundayDate: DateTime.parse(map['sundayDate'] as String),
        discussionPostId: (map['discussionPostId'] as String?) ?? '',
        memoryVerseRef: (map['memoryVerseRef'] as String?) ?? '',
        memoryVerseText: (map['memoryVerseText'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  SundaySchoolChapter copyWith({
    String? title,
    String? content,
    String? discussionPostId,
    String? memoryVerseRef,
    String? memoryVerseText,
  }) =>
      SundaySchoolChapter(
        id: id,
        bookId: bookId,
        churchId: churchId,
        chapterNumber: chapterNumber,
        title: title ?? this.title,
        content: content ?? this.content,
        sundayDate: sundayDate,
        discussionPostId: discussionPostId ?? this.discussionPostId,
        memoryVerseRef: memoryVerseRef ?? this.memoryVerseRef,
        memoryVerseText: memoryVerseText ?? this.memoryVerseText,
        createdAt: createdAt,
      );

  /// Returns true if this chapter's Sunday has already passed.
  bool get isPast => sundayDate.isBefore(DateTime.now());

  /// Returns true if this chapter's Sunday is today.
  bool get isToday {
    final now = DateTime.now();
    return sundayDate.year == now.year &&
        sundayDate.month == now.month &&
        sundayDate.day == now.day;
  }

  /// Returns true if this chapter's Sunday is in the future.
  bool get isUpcoming => sundayDate.isAfter(DateTime.now()) && !isToday;
}
