class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String aiExplanation;
  final String? parcelAdvice;
  final String topic;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.aiExplanation,
    this.parcelAdvice,
    required this.topic,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] ?? '',
      aiExplanation: json['aiExplanation'] ?? '',
      parcelAdvice: json['parcelAdvice'],
      topic: json['topic'] ?? 'general',
    );
  }
}

class QuizStats {
  final int streak;
  final List<Badge> badges;
  final List<String> weakAreas;
  final int totalQuizzes;

  QuizStats({
    required this.streak,
    required this.badges,
    required this.weakAreas,
    required this.totalQuizzes,
  });

  factory QuizStats.fromJson(Map<String, dynamic> json) {
    return QuizStats(
      streak: json['streak'] ?? 0,
      badges: (json['badges'] as List?)?.map((e) => Badge.fromJson(e)).toList() ?? [],
      weakAreas: List<String>.from(json['weakAreas'] ?? []),
      totalQuizzes: json['totalQuizzes'] ?? 0,
    );
  }
}

class Badge {
  final String id;
  final String name;
  final String type;
  final DateTime unlockedAt;

  Badge({
    required this.id,
    required this.name,
    required this.type,
    required this.unlockedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      unlockedAt: DateTime.parse(json['unlockedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
