import 'quiz_model.dart';

class SkillTrainingPath {
  final String id;
  final String code;
  final String title;
  final String description;
  final String icon;
  final String? gradientStart;
  final String? gradientEnd;
  final String difficulty;
  final int estimatedMinutes;
  final int completionPercent;
  final int completedLessons;
  final int totalLessons;
  final String status;
  final bool certificateIssued;

  SkillTrainingPath({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.completionPercent,
    required this.completedLessons,
    required this.totalLessons,
    required this.status,
    required this.certificateIssued,
  });

  factory SkillTrainingPath.fromJson(Map<String, dynamic> json) {
    return SkillTrainingPath(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'school',
      gradientStart: json['gradientStart']?.toString(),
      gradientEnd: json['gradientEnd']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'FOUNDATIONAL',
      estimatedMinutes: json['estimatedMinutes'] is int
          ? json['estimatedMinutes'] as int
          : int.tryParse(json['estimatedMinutes']?.toString() ?? '') ?? 0,
      completionPercent: json['completionPercent'] is int
          ? json['completionPercent'] as int
          : int.tryParse(json['completionPercent']?.toString() ?? '') ?? 0,
      completedLessons: json['completedLessons'] is int
          ? json['completedLessons'] as int
          : int.tryParse(json['completedLessons']?.toString() ?? '') ?? 0,
      totalLessons: json['totalLessons'] is int
          ? json['totalLessons'] as int
          : int.tryParse(json['totalLessons']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'NOT_STARTED',
      certificateIssued: json['certificateIssued'] == true,
    );
  }
}

class SkillLessonItem {
  final String id;
  final String code;
  final String title;
  final String summary;
  final String microContent;
  final String skillTag;
  final int estimatedMinutes;
  final String status;
  final int completionPercent;
  final int attempts;
  final int? lastScore;
  final int? bestScore;

  SkillLessonItem({
    required this.id,
    required this.code,
    required this.title,
    required this.summary,
    required this.microContent,
    required this.skillTag,
    required this.estimatedMinutes,
    required this.status,
    required this.completionPercent,
    required this.attempts,
    required this.lastScore,
    required this.bestScore,
  });

  factory SkillLessonItem.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return SkillLessonItem(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      microContent: json['microContent']?.toString() ?? '',
      skillTag: json['skillTag']?.toString() ?? 'skill',
      estimatedMinutes: json['estimatedMinutes'] is int
          ? json['estimatedMinutes'] as int
          : int.tryParse(json['estimatedMinutes']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'NOT_STARTED',
      completionPercent: json['completionPercent'] is int
          ? json['completionPercent'] as int
          : int.tryParse(json['completionPercent']?.toString() ?? '') ?? 0,
      attempts: json['attempts'] is int
          ? json['attempts'] as int
          : int.tryParse(json['attempts']?.toString() ?? '') ?? 0,
      lastScore: parseNullableInt(json['lastScore']),
      bestScore: parseNullableInt(json['bestScore']),
    );
  }
}

class SkillPathDetail extends SkillTrainingPath {
  final List<SkillLessonItem> lessons;

  SkillPathDetail({
    required super.id,
    required super.code,
    required super.title,
    required super.description,
    required super.icon,
    required super.gradientStart,
    required super.gradientEnd,
    required super.difficulty,
    required super.estimatedMinutes,
    required super.completionPercent,
    required super.completedLessons,
    required super.totalLessons,
    required super.status,
    required super.certificateIssued,
    required this.lessons,
  });

  factory SkillPathDetail.fromJson(Map<String, dynamic> json) {
    final base = SkillTrainingPath.fromJson(json);
    final lessonsJson = (json['lessons'] as List?) ?? const [];

    return SkillPathDetail(
      id: base.id,
      code: base.code,
      title: base.title,
      description: base.description,
      icon: base.icon,
      gradientStart: base.gradientStart,
      gradientEnd: base.gradientEnd,
      difficulty: base.difficulty,
      estimatedMinutes: base.estimatedMinutes,
      completionPercent: base.completionPercent,
      completedLessons: base.completedLessons,
      totalLessons: base.totalLessons,
      status: base.status,
      certificateIssued: base.certificateIssued,
      lessons: lessonsJson
          .whereType<Map>()
          .map(
            (entry) =>
                SkillLessonItem.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(),
    );
  }
}

class SkillLessonQuizPayload {
  final SkillLessonItem lesson;
  final String languageCode;
  final List<QuizQuestion> questions;

  SkillLessonQuizPayload({
    required this.lesson,
    required this.languageCode,
    required this.questions,
  });

  factory SkillLessonQuizPayload.fromJson(Map<String, dynamic> json) {
    final lessonJson = Map<String, dynamic>.from(
      (json['lesson'] as Map?)?.cast<String, dynamic>() ?? const {},
    );

    final normalizedLesson = SkillLessonItem.fromJson({
      ...lessonJson,
      'code': lessonJson['code'] ?? lessonJson['id'] ?? 'lesson',
      'microContent': lessonJson['microContent'] ?? '',
      'status': lessonJson['status'] ?? 'IN_PROGRESS',
      'completionPercent': lessonJson['completionPercent'] ?? 0,
      'attempts': lessonJson['attempts'] ?? 0,
    });

    final rawQuestions = (json['questions'] as List?) ?? const [];
    final questions = rawQuestions
        .whereType<Map>()
        .map((entry) => QuizQuestion.fromJson(Map<String, dynamic>.from(entry)))
        .toList();

    return SkillLessonQuizPayload(
      lesson: normalizedLesson,
      languageCode: json['languageCode']?.toString() ?? 'en-US',
      questions: questions,
    );
  }
}

class SkillQuizSubmissionResult {
  final int scorePercent;
  final int correctAnswers;
  final int totalQuestions;
  final bool passed;
  final String feedback;
  final bool certificateIssued;
  final Map<String, dynamic> rawPathCompletion;

  SkillQuizSubmissionResult({
    required this.scorePercent,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.passed,
    required this.feedback,
    required this.certificateIssued,
    required this.rawPathCompletion,
  });

  factory SkillQuizSubmissionResult.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return SkillQuizSubmissionResult(
      scorePercent: parseInt(json['scorePercent']),
      correctAnswers: parseInt(json['correctAnswers']),
      totalQuestions: parseInt(json['totalQuestions']),
      passed: json['passed'] == true,
      feedback: json['feedback']?.toString() ?? '',
      certificateIssued: json['certificateIssued'] == true,
      rawPathCompletion: Map<String, dynamic>.from(
        (json['pathCompletion'] as Map?) ?? const {},
      ),
    );
  }
}

class SkillProgressOverview {
  final int overallPercent;
  final int completedPaths;
  final int totalPaths;
  final int completedLessons;
  final int inProgressLessons;
  final int certificatesUnlocked;

  SkillProgressOverview({
    required this.overallPercent,
    required this.completedPaths,
    required this.totalPaths,
    required this.completedLessons,
    required this.inProgressLessons,
    required this.certificatesUnlocked,
  });

  factory SkillProgressOverview.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return SkillProgressOverview(
      overallPercent: parseInt(json['overallPercent']),
      completedPaths: parseInt(json['completedPaths']),
      totalPaths: parseInt(json['totalPaths']),
      completedLessons: parseInt(json['completedLessons']),
      inProgressLessons: parseInt(json['inProgressLessons']),
      certificatesUnlocked: parseInt(json['certificatesUnlocked']),
    );
  }
}
