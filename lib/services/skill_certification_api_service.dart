import '../models/quiz_model.dart';
import '../models/skill_certification_model.dart';
import 'api_service.dart';

class SkillCertificationApiService {
  static const String _endpoint = '/quiz/skills';

  Future<List<SkillTrainingPath>> getPaths() async {
    final response = await ApiService.get('$_endpoint/paths', withAuth: true);
    final raw = (response as List?) ?? const [];

    return raw
        .whereType<Map>()
        .map(
          (entry) =>
              SkillTrainingPath.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
  }

  Future<SkillPathDetail> getPathDetails(String pathId) async {
    final response = await ApiService.get(
      '$_endpoint/paths/$pathId',
      withAuth: true,
    );
    return SkillPathDetail.fromJson(Map<String, dynamic>.from(response));
  }

  Future<SkillLessonQuizPayload> generateLessonQuiz(
    String lessonId, {
    required String languageCode,
    int questionCount = 6,
  }) async {
    final response = await ApiService.post(
      '$_endpoint/lessons/$lessonId/generate',
      {'languageCode': languageCode, 'questionCount': questionCount},
      withAuth: true,
    );

    return SkillLessonQuizPayload.fromJson(Map<String, dynamic>.from(response));
  }

  Future<SkillQuizSubmissionResult> submitLessonQuiz(
    String lessonId, {
    required String languageCode,
    required List<QuizQuestion> questions,
    required List<String> answers,
  }) async {
    final response = await ApiService.post(
      '$_endpoint/lessons/$lessonId/submit',
      {
        'languageCode': languageCode,
        'questions': questions
            .map(
              (question) => {
                'question': question.question,
                'options': question.options,
                'correctAnswer': question.correctAnswer,
                'aiExplanation': question.aiExplanation,
                'topic': question.topic,
              },
            )
            .toList(),
        'answers': answers,
      },
      withAuth: true,
    );

    return SkillQuizSubmissionResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<SkillProgressOverview> getProgressOverview() async {
    final response = await ApiService.get(
      '$_endpoint/progress',
      withAuth: true,
    );
    return SkillProgressOverview.fromJson(Map<String, dynamic>.from(response));
  }
}
