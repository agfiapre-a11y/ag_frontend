/// A 1:1 or group conversation in the Community chat.
///
/// `participantIds` holds the user IDs in the conversation. The conversation
/// ID is deterministic for 1:1 chats (sorted participant IDs joined) so the
/// same two users always reopen the same thread.
class Conversation {
  final String id;
  final String churchId;
  final List<String> participantIds;
  final Map<String, String> participantNames; // userId -> display name
  final String lastMessageText;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.churchId,
    required this.participantIds,
    this.participantNames = const {},
    this.lastMessageText = '',
    this.lastMessageAt,
    required this.createdAt,
  });

  /// Builds a deterministic conversation ID for a 1:1 chat between two users.
  static String oneOnOneId(String a, String b) {
    final sorted = [a, b]..sort();
    return 'dm_${sorted[0]}_${sorted[1]}';
  }

  /// Returns the display name of the "other" participant in a 1:1 chat,
  /// relative to [currentUserId]. Falls back to the raw ID.
  String otherDisplayName(String currentUserId) {
    for (final entry in participantNames.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    final other = participantIds.where((id) => id != currentUserId).toList();
    return other.isNotEmpty ? other.first : '';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'participantIds': participantIds,
        'participantNames': participantNames,
        'lastMessageText': lastMessageText,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Conversation.fromMap(Map<dynamic, dynamic> map) => Conversation(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        participantIds: map['participantIds'] != null
            ? List<String>.from(map['participantIds'] as List)
            : const [],
        participantNames: map['participantNames'] != null
            ? Map<String, String>.from(map['participantNames'] as Map)
            : const {},
        lastMessageText: (map['lastMessageText'] as String?) ?? '',
        lastMessageAt: map['lastMessageAt'] != null
            ? DateTime.parse(map['lastMessageAt'] as String)
            : null,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Conversation copyWith({
    String? lastMessageText,
    DateTime? lastMessageAt,
    Map<String, String>? participantNames,
  }) =>
      Conversation(
        id: id,
        churchId: churchId,
        participantIds: participantIds,
        participantNames: participantNames ?? this.participantNames,
        lastMessageText: lastMessageText ?? this.lastMessageText,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        createdAt: createdAt,
      );
}
