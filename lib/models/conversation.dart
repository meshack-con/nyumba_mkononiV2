class ConversationThread {
  const ConversationThread({
    required this.propertyId,
    required this.propertyName,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.unreadCount,
  });
  final int propertyId;
  final String propertyName;
  final int otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int lastSenderId;
  final int unreadCount;
  factory ConversationThread.fromJson(Map<String, dynamic> json) => ConversationThread(
        propertyId: json['property_id'] as int,
        propertyName: json['property_name'] as String? ?? '',
        otherUserId: json['other_user_id'] as int,
        otherUserName: json['other_user_name'] as String? ?? '',
        lastMessage: json['last_message'] as String? ?? '',
        lastMessageAt: DateTime.parse(json['last_message_at'] as String),
        lastSenderId: json['last_sender_id'] as int,
        unreadCount: json['unread_count'] as int? ?? 0,
      );
}
