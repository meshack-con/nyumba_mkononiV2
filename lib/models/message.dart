class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.propertyId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.readAt,
  });
  final int id;
  final int propertyId;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  bool get isRead => readAt != null;
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int,
        propertyId: json['property_id'] as int,
        senderId: json['sender_id'] as int,
        receiverId: json['receiver_id'] as int,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt: json['read_at'] == null ? null : DateTime.tryParse(json['read_at'] as String),
      );
}
