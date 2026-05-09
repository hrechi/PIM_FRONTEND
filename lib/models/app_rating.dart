class AppRating {
  final String id;
  final String userName;
  final String? avatarUrl;
  final int stars; // 1–5
  final String? message;
  final DateTime createdAt;

  const AppRating({
    required this.id,
    required this.userName,
    this.avatarUrl,
    required this.stars,
    this.message,
    required this.createdAt,
  });

  /// Short snippet shown in the marquee card (max 60 chars).
  String get snippet {
    if (message == null || message!.isEmpty) return '';
    return message!.length > 60 ? '${message!.substring(0, 57)}…' : message!;
  }

  factory AppRating.fromJson(Map<String, dynamic> json) {
    return AppRating(
      id: json['id'] as String,
      userName: json['userName'] as String? ?? 'Farmer',
      avatarUrl: json['avatarUrl'] as String?,
      stars: (json['stars'] as num).toInt(),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
