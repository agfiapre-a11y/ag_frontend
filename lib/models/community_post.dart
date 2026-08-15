/// A social feed post in the Community.
///
/// Supports text status updates, photo posts, and video posts. Likes are
/// stored as a list of user IDs so we can show who liked without a separate
/// table (offline-first friendly).
class CommunityPost {
  final String id;
  final String churchId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String text;
  final String mediaUrl;
  final String mediaType; // 'text' | 'image' | 'video'
  final List<String> likes; // user IDs who liked
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommunityPost({
    required this.id,
    required this.churchId,
    required this.authorId,
    required this.authorName,
    this.authorRole = '',
    required this.text,
    this.mediaUrl = '',
    this.mediaType = CommunityMediaType.text,
    this.likes = const [],
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasMedia => mediaUrl.isNotEmpty && mediaType != CommunityMediaType.text;
  bool get isImage => mediaType == CommunityMediaType.image;
  bool get isVideo => mediaType == CommunityMediaType.video;
  int get likeCount => likes.length;
  bool likedBy(String userId) => likes.contains(userId);

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'likes': likes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory CommunityPost.fromMap(Map<dynamic, dynamic> map) => CommunityPost(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        authorId: map['authorId'] as String,
        authorName: map['authorName'] as String,
        authorRole: (map['authorRole'] as String?) ?? '',
        text: (map['text'] as String?) ?? '',
        mediaUrl: (map['mediaUrl'] as String?) ?? '',
        mediaType: (map['mediaType'] as String?) ?? CommunityMediaType.text,
        likes: map['likes'] != null
            ? List<String>.from(map['likes'] as List)
            : const [],
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: map['updatedAt'] != null
            ? DateTime.parse(map['updatedAt'] as String)
            : null,
      );

  CommunityPost copyWith({
    String? text,
    String? mediaUrl,
    String? mediaType,
    List<String>? likes,
    DateTime? updatedAt,
  }) =>
      CommunityPost(
        id: id,
        churchId: churchId,
        authorId: authorId,
        authorName: authorName,
        authorRole: authorRole,
        text: text ?? this.text,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        mediaType: mediaType ?? this.mediaType,
        likes: likes ?? this.likes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class CommunityMediaType {
  static const text = 'text';
  static const image = 'image';
  static const video = 'video';

  static const all = [text, image, video];
}
