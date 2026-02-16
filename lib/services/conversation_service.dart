import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/conversation_model.dart';

class ConversationService {
  static Future<List<Conversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/conversations'),
      headers: await ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getConversations();
    }

    throw Exception('Failed to load conversations: ${response.statusCode}');
  }

  static Future<Conversation> getConversationById(String conversationId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/conversations/$conversationId'),
      headers: await ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Conversation.fromJson(data);
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return getConversationById(conversationId);
    }

    throw Exception(
        'Failed to load conversation: ${response.statusCode}');
  }

  static Future<Conversation> createConversation(String title) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/conversations'),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Conversation.fromJson(data);
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return createConversation(title);
    }

    throw Exception('Failed to create conversation: ${response.statusCode}');
  }

  static Future<Conversation> updateConversationTitle(
    String conversationId,
    String title,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/conversations/$conversationId'),
      headers: await ApiService.getAuthHeaders(),
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Conversation.fromJson(data);
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return updateConversationTitle(conversationId, title);
    }

    throw Exception(
        'Failed to update conversation: ${response.statusCode}');
  }

  static Future<void> deleteConversation(String conversationId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/conversations/$conversationId'),
      headers: await ApiService.getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401) {
      await ApiService.refreshToken();
      return deleteConversation(conversationId);
    }

    throw Exception('Failed to delete conversation: ${response.statusCode}');
  }
}
