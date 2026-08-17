class LibraryBook {
  final String id;
  final String churchId;
  final String title;
  final String author;
  final String category;
  final String description;
  final String url;
  final String coverColor;
  final String source;
  final String addedById;
  final String content;
  final int pageCount;
  final int wordCount;
  final DateTime createdAt;

  const LibraryBook({
    required this.id,
    required this.churchId,
    required this.title,
    this.author = '',
    required this.category,
    this.description = '',
    required this.url,
    this.coverColor = '',
    this.source = '',
    required this.addedById,
    this.content = '',
    this.pageCount = 0,
    this.wordCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'title': title,
        'author': author,
        'category': category,
        'description': description,
        'url': url,
        'coverColor': coverColor,
        'source': source,
        'addedById': addedById,
        'content': content,
        'pageCount': pageCount,
        'wordCount': wordCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LibraryBook.fromMap(Map<dynamic, dynamic> map) => LibraryBook(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        title: map['title'] as String,
        author: (map['author'] as String?) ?? '',
        category: (map['category'] as String?) ?? LibraryBookCategory.other,
        description: (map['description'] as String?) ?? '',
        url: (map['url'] as String?) ?? '',
        coverColor: (map['coverColor'] as String?) ?? '',
        source: (map['source'] as String?) ?? '',
        addedById: (map['addedById'] as String?) ?? '',
        content: (map['content'] as String?) ?? '',
        pageCount: (map['pageCount'] as int?) ?? 0,
        wordCount: (map['wordCount'] as int?) ?? 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  LibraryBook copyWith({
    String? title,
    String? author,
    String? category,
    String? description,
    String? url,
    String? coverColor,
    String? source,
    String? content,
    int? pageCount,
    int? wordCount,
  }) =>
      LibraryBook(
        id: id,
        churchId: churchId,
        title: title ?? this.title,
        author: author ?? this.author,
        category: category ?? this.category,
        description: description ?? this.description,
        url: url ?? this.url,
        coverColor: coverColor ?? this.coverColor,
        source: source ?? this.source,
        addedById: addedById,
        content: content ?? this.content,
        pageCount: pageCount ?? this.pageCount,
        wordCount: wordCount ?? this.wordCount,
        createdAt: createdAt,
      );
}

class LibraryBookCategory {
  static const christianClassic = 'Christian Classic';
  static const devotional = 'Devotional';
  static const prayer = 'Prayer';
  static const theology = 'Theology';
  static const pentecostalFaith = 'Pentecostal & Faith';
  static const churchHistory = 'Church History';
  static const discipleship = 'Discipleship';
  static const scripture = 'Bible & Scripture';
  static const commentary = 'Bible Commentary & Reference';
  static const other = 'Other';

  static const all = [
    christianClassic,
    devotional,
    prayer,
    theology,
    pentecostalFaith,
    churchHistory,
    discipleship,
    scripture,
    commentary,
    other,
  ];
}
