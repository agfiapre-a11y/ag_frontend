/// A comment on a Community feed post.
class Comment {
  final String id;
  final String churchId;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.churchId,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorRole = '',
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Comment.fromMap(Map<dynamic, dynamic> map) => Comment(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        postId: map['postId'] as String,
        authorId: map['authorId'] as String,
        authorName: map['authorName'] as String,
        authorRole: (map['authorRole'] as String?) ?? '',
        text: (map['text'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
