import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart';

import '../config/app_config.dart';
import '../storage/storage_service.dart';
import 'api_exception.dart';

/// ApiClient ya jumla ya app - inatumia [ChopperClient] chini chini kwa ajili
/// ya usafirishaji wa HTTP, lakini haitumii chopper's code-generation
/// (@ChopperApi + build_runner) - badala yake tunajenga [Request] wenyewe
/// kwa kila method. Hii inafanya moduli mpya ziwe rahisi kuongeza bila
/// kuhitaji kusubiri `flutter pub run build_runner build`.
///
/// Kila "*Service" ya moduli (mfano AuthService, RulerService) inapokea
/// hii [ApiClient] moja (kupitia GetX DI - Get.find<ApiClient>()) na
/// kuitumia kupiga endpoints zake.
class ApiClient {
  final ChopperClient _client;
  final StorageService _storage;

  ApiClient({required StorageService storage})
      : _storage = storage,
        _client = ChopperClient(
          baseUrl: Uri.parse(AppConfig.baseUrl),
          // HAKUNA converter hapa kwa makusudi - tunafanya jsonEncode/jsonDecode
          // wenyewe (angalia post/put/_handle chini). Kuweka JsonConverter()
          // hapa PAMOJA na jsonEncode() yetu wenyewe kunasababisha JSON
          // kuandikwa mara MBILI (double-encoding) - hii ilikuwa ndiyo sababu
          // POST/PUT (fomu za Ongeza/Hariri) zilikuwa zinashindwa (422 kimya)
          // wakati GET (orodha/dashboard) zilifanya kazi vizuri.
        );

  Map<String, String> _headers({bool auth = true, bool multipart = false}) {
    final headers = <String, String>{};
    if (!multipart) headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
    if (auth) {
      final token = _storage.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    Map<String, String>? cleanQuery;
    if (query != null && query.isNotEmpty) {
      final mapped = <String, String>{};
      for (final entry in query.entries) {
        final value = entry.value;
        if (value != null) mapped[entry.key] = value.toString();
      }
      if (mapped.isNotEmpty) cleanQuery = mapped;
    }
    return Uri.parse('${AppConfig.baseUrl}$path').replace(queryParameters: cleanQuery);
  }

  Future<dynamic> _handle(Response response) {
    final code = response.statusCode;
    final bodyStr = _extractBodyString(response);

    if (code >= 200 && code < 300) {
      if (bodyStr.isEmpty) return Future.value(null);
      try {
        return Future.value(jsonDecode(bodyStr));
      } catch (_) {
        return Future.value(bodyStr);
      }
    }

    String message = 'Hitilafu ya mfumo (code $code)';
    try {
      final decoded = jsonDecode(bodyStr);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        // FastAPI validation errors (422) mara nyingi hurudisha 'detail' kama
        // list ya makosa badala ya string - tunaishughulikia pia.
        if (detail is List) {
          message = detail.map((e) => e is Map ? (e['msg'] ?? e.toString()) : e.toString()).join(', ');
        } else {
          message = detail.toString();
        }
      }
    } catch (_) {
      // body si JSON - tumia default message
    }
    throw ApiException(message: message, statusCode: code);
  }

  /// Inajaribu njia kadhaa kupata body ya response kama String, kwa
  /// usalama zaidi bila kutegemea property moja tu ya chopper.
  String _extractBodyString(Response response) {
    try {
      final s = response.bodyString;
      if (s.isNotEmpty) return s;
    } catch (_) {
      // endelea kujaribu njia nyingine
    }
    final body = response.body;
    if (body == null) return '';
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final request = Request('GET', _uri(path, query), _client.baseUrl, headers: _headers(auth: auth));
    final response = await _client.send(request);
    return _handle(response);
  }

  /// Kwa kuvuta faili halisi (picha/PDF) - siyo JSON.
  Future<List<int>> getBytes(String path, {bool auth = true, Map<String, dynamic>? query}) async {
    final request = Request('GET', _uri(path, query), _client.baseUrl, headers: _headers(auth: auth, multipart: true));
    final response = await _client.send(request);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw ApiException(message: 'Imeshindikana kupakua faili (code ${response.statusCode})', statusCode: response.statusCode);
  }

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, bool auth = true}) async {
    final request = Request(
      'POST',
      _uri(path, query),
      _client.baseUrl,
      body: body == null ? null : jsonEncode(body),
      headers: _headers(auth: auth),
    );
    final response = await _client.send(request);
    return _handle(response);
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    final request = Request(
      'PUT',
      _uri(path),
      _client.baseUrl,
      body: body == null ? null : jsonEncode(body),
      headers: _headers(auth: auth),
    );
    final response = await _client.send(request);
    return _handle(response);
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    final request = Request('DELETE', _uri(path), _client.baseUrl, headers: _headers(auth: auth));
    final response = await _client.send(request);
    return _handle(response);
  }
}
