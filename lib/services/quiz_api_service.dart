import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/quiz_model.dart';

class QuizApiService {
  static String get _baseUrl => ApiService.baseUrl;

  static Future<QuizResult> generateQuiz({String? parcelId}) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('$_baseUrl/quiz/generate');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'parcelId': parcelId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return QuizResult.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Quiz generation failed: $e');
    }
  }
}
