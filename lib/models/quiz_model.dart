class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String aiExplanation;
  final String parcelAdvice;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.aiExplanation,
    required this.parcelAdvice,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      aiExplanation: json['aiExplanation'] ?? '',
      parcelAdvice: json['parcelAdvice'] ?? '',
    );
  }
}

class QuizResult {
  final List<QuizQuestion> questions;
  final String source; // 'ai' or 'fallback'
  final String? parcelId;

  QuizResult({required this.questions, required this.source, this.parcelId});

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      questions: (json['questions'] as List<dynamic>)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      source: json['source'] ?? 'fallback',
      parcelId: json['parcelId'],
    );
  }
}

class BadgeModel {
  final String id;
  final String title;
  final String emoji;
  final String description;
  bool earned;

  BadgeModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    this.earned = false,
  });

  static List<BadgeModel> allBadges() => [
    BadgeModel(id: 'first_quiz', title: 'First Steps', emoji: '🌱', description: 'Complete your first quiz'),
    BadgeModel(id: 'perfect_score', title: 'Perfect Farmer', emoji: '🏆', description: 'Score 5/5 on any quiz'),
    BadgeModel(id: 'irrigation', title: 'Irrigation Expert', emoji: '💧', description: 'Answer 3 irrigation questions correctly'),
    BadgeModel(id: 'fertilizer', title: 'Fertilizer Master', emoji: '⚗️', description: 'Answer 3 fertilizer questions correctly'),
    BadgeModel(id: 'crop_planner', title: 'Crop Planner', emoji: '🗓️', description: 'Complete 5 quiz sessions'),
  ];
}
