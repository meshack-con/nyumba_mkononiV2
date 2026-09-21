class Property {
  const Property({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.mode,
    required this.price,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.hasWifi,
    required this.carParking,
    required this.indoorToilet,
    required this.hasElectricity,
    required this.waterInside,
    required this.waterNearby,
    required this.furnished,
    required this.swimmingPool,
    required this.viewCount,
    required this.description,
    required this.photoUrls,
    required this.status,
    this.verificationDocUrl,
    this.createdAt,
    this.expiresAt,
    this.favoritesCount = 0,
    this.unreadMessagesCount = 0,
  });
  final int id;
  final int ownerId;
  final String name;
  final String type;
  final String mode;
  final int price;
  final String locationLabel;
  final double latitude;
  final double longitude;
  final bool hasWifi;
  final bool carParking;
  final bool indoorToilet;
  final bool hasElectricity;
  final bool waterInside;
  final bool waterNearby;
  final bool furnished;
  final bool swimmingPool;
  final int viewCount;
  final String description;
  final List<String> photoUrls;
  final String? verificationDocUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final int favoritesCount;
  final int unreadMessagesCount;
  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id'] as int,
        ownerId: json['owner_id'] as int,
        name: json['jina'] as String,
        type: json['aina'] as String,
        mode: json['mode'] as String,
        price: json['price'] as int,
        locationLabel: json['location_label'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        hasWifi: json['has_wifi'] as bool? ?? false,
        carParking: json['car_parking'] as bool? ?? false,
        indoorToilet: json['indoor_toilet'] as bool? ?? false,
        hasElectricity: json['has_electricity'] as bool? ?? false,
        waterInside: json['water_inside'] as bool? ?? false,
        waterNearby: json['water_nearby'] as bool? ?? false,
        furnished: json['furnished'] as bool? ?? false,
        swimmingPool: json['swimming_pool'] as bool? ?? false,
        viewCount: json['view_count'] as int? ?? 0,
        description: json['description'] as String,
        photoUrls: List<String>.from(json['photo_urls'] as List<dynamic>),
        verificationDocUrl: json['verification_doc_url'] as String?,
        status: json['status'] as String,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.tryParse(json['created_at'] as String),
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.tryParse(json['expires_at'] as String),
        favoritesCount: json['favorites_count'] as int? ?? 0,
        unreadMessagesCount: json['unread_messages_count'] as int? ?? 0,
      );
  String get formattedPrice => 'TZS ${price.toString().replaceAllMapped(
      RegExp(r'(?<!^)(?=(\d{3})+$)'),
        (_) => ',',
      )}';
}
class FavoriteItem {
  const FavoriteItem({required this.id, required this.property});
  final int id;
  final Property property;
  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        id: json['id'] as int,
        property: Property.fromJson(json['property'] as Map<String, dynamic>),
      );
}
