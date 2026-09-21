import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation.dart';
import '../models/listing_payment.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../models/property.dart';
import '../models/property_contact.dart';
import '../models/user.dart';

const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (_configuredApiBaseUrl.isNotEmpty) return _configuredApiBaseUrl;
  return 'http://127.0.0.1:8000';
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (authenticated) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _decode(http.Response response) async {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body is Map<String, dynamic> ? body['detail'] : null;
      throw ApiException(detail?.toString() ?? 'Kuna tatizo la kuwasiliana na server.', response.statusCode);
    }
    return body;
  }

  Future<List<Property>> getProperties({
    String? location,
    int? minPrice,
    int? maxPrice,
    String? propertyType,
    String? mode,
    bool? hasWifi,
    bool? carParking,
    bool? indoorToilet,
    bool? hasElectricity,
    bool? waterInside,
    bool? waterNearby,
    bool? furnished,
    bool? swimmingPool,
    String? postedWithin,
  }) async {
    final query = <String, String>{};
    if (location?.isNotEmpty == true) query['location'] = location!;
    if (minPrice != null) query['min_price'] = '$minPrice';
    if (maxPrice != null) query['max_price'] = '$maxPrice';
    if (propertyType != null) query['property_type'] = propertyType;
    if (mode != null) query['mode'] = mode;
    if (hasWifi != null) query['has_wifi'] = '$hasWifi';
    if (carParking != null) query['car_parking'] = '$carParking';
    if (indoorToilet != null) query['indoor_toilet'] = '$indoorToilet';
    if (hasElectricity != null) query['has_electricity'] = '$hasElectricity';
    if (waterInside != null) query['water_inside'] = '$waterInside';
    if (waterNearby != null) query['water_nearby'] = '$waterNearby';
    if (furnished != null) query['furnished'] = '$furnished';
    if (swimmingPool != null) query['swimming_pool'] = '$swimmingPool';
    if (postedWithin != null) query['posted_within'] = postedWithin;
    final uri = Uri.parse('$apiBaseUrl/properties').replace(queryParameters: query);
    final response = await http.get(uri, headers: await _headers());
    final data = await _decode(response) as List<dynamic>;
    return data.map((item) => Property.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Property> getProperty(int id) async {
    final response = await http.get(Uri.parse('$apiBaseUrl/properties/$id'), headers: await _headers());
    return Property.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<PropertyContact> getPropertyContact(int propertyId) async {
    final response = await http.get(Uri.parse('$apiBaseUrl/properties/$propertyId/contact'), headers: await _headers());
    return PropertyContact.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> getMessages(int propertyId, {int? withUserId}) async {
    final query = <String, String>{};
    if (withUserId != null) query['with_user_id'] = '$withUserId';
    final uri = Uri.parse('$apiBaseUrl/properties/$propertyId/messages')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await http.get(uri, headers: await _headers(authenticated: true));
    final data = await _decode(response) as List<dynamic>;
    return data.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> sendMessage(int propertyId, String content, {int? receiverId}) async {
    final headers = await _headers(authenticated: true);
    headers['Content-Type'] = 'application/json';
    final response = await http.post(
      Uri.parse('$apiBaseUrl/properties/$propertyId/messages'),
      headers: headers,
      body: jsonEncode({'content': content, if (receiverId != null) 'receiver_id': receiverId}),
    );
    return ChatMessage.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<List<ConversationThread>> getConversations() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/messages/conversations'), headers: await _headers(authenticated: true));
    final data = await _decode(response) as List<dynamic>;
    return data.map((item) => ConversationThread.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadMessagesCount() async {
    try {
      final threads = await getConversations();
      return threads.fold<int>(0, (sum, thread) => sum + thread.unreadCount);
    } catch (_) {
      return 0;
    }
  }

  Future<void> deleteMessage(int messageId) async {
    final response = await http.delete(Uri.parse('$apiBaseUrl/messages/$messageId'), headers: await _headers(authenticated: true));
    await _decode(response);
  }

  Future<List<FavoriteItem>> getFavorites() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/favorites'), headers: await _headers(authenticated: true));
    final data = await _decode(response) as List<dynamic>;
    return data.map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<FavoriteItem> addFavorite(int propertyId) async {
    final response = await http.post(Uri.parse('$apiBaseUrl/favorites/$propertyId'), headers: await _headers(authenticated: true));
    return FavoriteItem.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<void> removeFavorite(int propertyId) async {
    final response = await http.delete(Uri.parse('$apiBaseUrl/favorites/$propertyId'), headers: await _headers(authenticated: true));
    await _decode(response);
  }

  Future<AppUser> register({
    required String fullName,
    required String phone,
    required String username,
    required String password,
    required String role,
    String? email,
    String? area,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jina_kamili': fullName,
        'namba_ya_simu': phone,
        'username': username,
        'password': password,
        'role': role,
        if (email?.isNotEmpty == true) 'email': email,
        if (area?.isNotEmpty == true) 'eneo': area,
      }),
    );
    return _saveAuth(await _decode(response) as Map<String, dynamic>);
  }

  Future<AppUser> login({required String username, required String password}) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _saveAuth(await _decode(response) as Map<String, dynamic>);
  }

  Future<AppUser> _saveAuth(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> getMe() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/auth/me'), headers: await _headers(authenticated: true));
    return AppUser.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<void> sendFeedback(String message) async {
    final headers = await _headers(authenticated: true);
    headers['Content-Type'] = 'application/json';
    final response = await http.post(
      Uri.parse('$apiBaseUrl/feedback'),
      headers: headers,
      body: jsonEncode({'message': message}),
    );
    await _decode(response);
  }

  Future<AppUser> updateMe({
    String? fullName,
    String? phone,
    String? email,
    String? area,
  }) async {
    final headers = await _headers(authenticated: true);
    headers['Content-Type'] = 'application/json';
    final body = <String, dynamic>{};
    if (fullName != null) body['jina_kamili'] = fullName;
    if (phone != null) body['namba_ya_simu'] = phone;
    if (email != null) body['email'] = email.isEmpty ? null : email;
    if (area != null) body['eneo'] = area.isEmpty ? null : area;
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/auth/me'),
      headers: headers,
      body: jsonEncode(body),
    );
    return AppUser.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<AppUser> updateMyPhoto(Uint8List bytes, String filename) async {
    final request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/auth/me/photo'));
    request.headers.addAll(await _headers(authenticated: true));
    request.files.add(http.MultipartFile.fromBytes('photo', bytes, filename: filename));
    final response = await http.Response.fromStream(await request.send());
    return AppUser.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<List<NotificationItem>> getNotifications() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/notifications'), headers: await _headers(authenticated: true));
    final data = await _decode(response) as List<dynamic>;
    return data.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/notifications/$notificationId/read'),
      headers: await _headers(authenticated: true),
    );
    await _decode(response);
  }

  Future<List<Property>> getMyProperties() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/properties/mine'), headers: await _headers(authenticated: true));
    final data = await _decode(response) as List<dynamic>;
    return data.map((item) => Property.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Anaanzisha malipo ya ada ya kutangaza nyumba (TZS 5,000) kupitia
  /// Flutterwave. Inarudisha `txRef` (itahitajika baadaye kutuma tangazo)
  /// na `redirectLink` (ukurasa wa kufungua kwenye browser kukamilisha malipo).
  Future<ListingPayment> initiateListingFeePayment({required String phoneNumber}) async {
    final headers = await _headers(authenticated: true);
    headers['Content-Type'] = 'application/json';
    final response = await http.post(
      Uri.parse('$apiBaseUrl/payments/listing-fee/initiate'),
      headers: headers,
      body: jsonEncode({'phone_number': phoneNumber}),
    );
    return ListingPayment.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  /// Anaangalia hali ya malipo ya ada ya kutangaza nyumba (pending /
  /// successful / failed) - inaitwa mara kwa mara (polling) baada ya
  /// seller kurudi kutoka ukurasa wa Flutterwave.
  Future<ListingPayment> getListingFeePaymentStatus(String txRef) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/payments/listing-fee/$txRef/status'),
      headers: await _headers(authenticated: true),
    );
    return ListingPayment.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<Property> createProperty({
    required String name,
    required String type,
    required String mode,
    required int price,
    required String locationLabel,
    required double latitude,
    required double longitude,
    required bool hasWifi,
    required bool carParking,
    required bool indoorToilet,
    required bool hasElectricity,
    required bool waterInside,
    required bool waterNearby,
    required bool furnished,
    required bool swimmingPool,
    required String description,
    required String paymentRef,
    required List<Uint8List> photos,
    required List<String> photoNames,
    required Uint8List verificationDoc,
    required String verificationDocName,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/properties'));
    request.headers.addAll(await _headers(authenticated: true));
    request.fields.addAll({
      'jina': name,
      'aina': type,
      'mode': mode,
      'price': '$price',
      'location_label': locationLabel,
      'latitude': '$latitude',
      'longitude': '$longitude',
      'has_wifi': '$hasWifi',
      'car_parking': '$carParking',
      'indoor_toilet': '$indoorToilet',
      'has_electricity': '$hasElectricity',
      'water_inside': '$waterInside',
      'water_nearby': '$waterNearby',
      'furnished': '$furnished',
      'swimming_pool': '$swimmingPool',
      'description': description,
      'payment_ref': paymentRef,
    });
    for (var index = 0; index < photos.length; index++) {
      request.files.add(http.MultipartFile.fromBytes('photos', photos[index], filename: photoNames[index]));
    }
    request.files.add(http.MultipartFile.fromBytes('verification_doc', verificationDoc, filename: verificationDocName));
    final response = await http.Response.fromStream(await request.send());
    return Property.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<Property> updateProperty({
    required int id,
    String? name,
    String? type,
    String? mode,
    int? price,
    String? locationLabel,
    double? latitude,
    double? longitude,
    bool? hasWifi,
    bool? carParking,
    bool? indoorToilet,
    bool? hasElectricity,
    bool? waterInside,
    bool? waterNearby,
    bool? furnished,
    bool? swimmingPool,
    String? description,
  }) async {
    final headers = await _headers(authenticated: true);
    headers['Content-Type'] = 'application/json';
    final body = <String, dynamic>{
      if (name != null) 'jina': name,
      if (type != null) 'aina': type,
      if (mode != null) 'mode': mode,
      if (price != null) 'price': price,
      if (locationLabel != null) 'location_label': locationLabel,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (hasWifi != null) 'has_wifi': hasWifi,
      if (carParking != null) 'car_parking': carParking,
      if (indoorToilet != null) 'indoor_toilet': indoorToilet,
      if (hasElectricity != null) 'has_electricity': hasElectricity,
      if (waterInside != null) 'water_inside': waterInside,
      if (waterNearby != null) 'water_nearby': waterNearby,
      if (furnished != null) 'furnished': furnished,
      if (swimmingPool != null) 'swimming_pool': swimmingPool,
      if (description != null) 'description': description,
    };
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/properties/$id'),
      headers: headers,
      body: jsonEncode(body),
    );
    return Property.fromJson(await _decode(response) as Map<String, dynamic>);
  }

  Future<void> deleteProperty(int id) async {
    final response = await http.delete(Uri.parse('$apiBaseUrl/properties/$id'), headers: await _headers(authenticated: true));
    await _decode(response);
  }

  String assetUrl(String path) => path.startsWith('http') ? path : '$apiBaseUrl$path';
}
