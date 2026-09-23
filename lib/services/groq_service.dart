import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_client.dart' show apiBaseUrl;

/// Msaidizi wa AI sasa unapita kwenye backend yetu (`/ai/chat`) badala ya
/// kuita Groq moja kwa moja kutoka humu ndani ya Flutter. GROQ_API_KEY
/// inakaa Render pekee - haiwahi kuingizwa kwenye programu hii, hivyo
/// haionekani kwenye JS bundle ya web wala kwenye browser ya mtumiaji.
class GroqException implements Exception {
  const GroqException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GroqService {
  static Future<String> ask(List<Map<String, String>> history) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': history}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = 'kosa ${response.statusCode}';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['detail'] != null) detail = body['detail'].toString();
      } catch (_) {}
      throw GroqException('Imeshindikana kuwasiliana na msaidizi ($detail). Jaribu tena.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['content'] as String).trim();
  }
}
