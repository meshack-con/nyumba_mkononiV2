import 'api_client.dart';

/// Inatuma maoni ya mtumiaji kwenye seva.
class FeedbackService {
  static Future<void> send(String message) async {
    await ApiClient.instance.sendFeedback(message);
  }
}
