class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.propertyId,
    this.propertyName,
    this.otherUserId,
  });

  final String id;

  /// 'platform' - arifa kutoka Nyumba Mkononi yenyewe.
  /// 'owner' - ujumbe kutoka kwa mmiliki wa nyumba / mnunuzi.
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final int? propertyId;
  final String? propertyName;
  final int? otherUserId;

  bool get isPlatform => type == 'platform';
  bool get isOwnerMessage => type == 'owner';

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        read: json['read'] as bool? ?? false,
        propertyId: json['property_id'] as int?,
        propertyName: json['property_name'] as String?,
        otherUserId: json['other_user_id'] as int?,
      );
}
