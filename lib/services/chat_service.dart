import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ChatService {
  static Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? conversationId,
  }) async {
    final body = {
      'message': message,
      if (conversationId != null) 'conversationId': conversationId,
    };

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/chat'),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'reply': (data['reply'] as String?) ?? '',
        'conversationId': (data['conversationId'] as String?) ?? '',
      };
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return sendMessage(message, conversationId: conversationId);
    }

    String details = 'Failed to send message: ${response.statusCode}';
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['message'] is String) {
        details = data['message'] as String;
      } else if (data['error'] is String) {
        details = data['error'] as String;
      }
    } catch (_) {
      // Ignore parsing errors and keep default details.
    }
    throw Exception(details);
  }
}

