/// A single chat message inside a [Conversation].
class Message {
  final String id;
  final String churchId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.churchId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isRead = false,
    required this.createdAt,
  });

  bool get isFromMe => false; // resolved at call-site with current user id

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Message.fromMap(Map<dynamic, dynamic> map) => Message(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        conversationId: map['conversationId'] as String,
        senderId: map['senderId'] as String,
        senderName: map['senderName'] as String,
        text: (map['text'] as String?) ?? '',
        isRead: (map['isRead'] as bool?) ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Message copyWith({bool? isRead}) => Message(
        id: id,
        churchId: churchId,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
