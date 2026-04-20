import 'api_service.dart';
import '../models/quiz_model.dart';

class QuizApiService {
  static const String _endpoint = '/quiz';

  Future<List<QuizQuestion>> generateQuiz({
    String? parcelId,
    int questionCount = 5,
    String difficulty = 'medium',
  }) async {
    final response = await ApiService.post(
      '$_endpoint/generate',
      {
        'parcelId': parcelId,
        'questionCount': questionCount,
        'difficulty': difficulty,
      },
      withAuth: true,
    );
    
    final List<dynamic> data = response;
    return data.map((json) => QuizQuestion.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> saveResult({
    required int score,
    required int totalQuestions,
    required String topic,
    String? parcelId,
  }) async {
    final response = await ApiService.post(
      '$_endpoint/save',
      {
        'score': score,
        'totalQuestions': totalQuestions,
        'topic': topic,
        'parcelId': parcelId,
      },
      withAuth: true,
    );
    
    return response;
  }

  Future<QuizStats> getStats() async {
    final response = await ApiService.get('$_endpoint/stats', withAuth: true);
    return QuizStats.fromJson(response);
  }
}
