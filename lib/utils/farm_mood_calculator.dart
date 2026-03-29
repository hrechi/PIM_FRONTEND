/// Farm Mood & Score Calculation Logic

class FarmMoodData {
  final int score;
  final String mood;
  final String emoji;
  final String message;

  FarmMoodData({
    required this.score,
    required this.mood,
    required this.emoji,
    required this.message,
  });
}

/// Calculate farm score based on soil health and wilting risk
/// farmScore = (soilHealthScore * 0.6) + (inverse wilting risk * 0.4)
int calculateFarmScore({
  required int soilHealthScore,
  required String wiltingRisk,
}) {
  // Map wilting risk to score
  final wiltingScore = _mapWiltingRiskToScore(wiltingRisk);

  // Calculate final score
  final score =
      (soilHealthScore * 0.6) + (wiltingScore * 0.4);

  return score.toInt().clamp(0, 100);
}

/// Map wilting risk level to numeric score
/// Low → 100, Moderate → 60, High → 30
int _mapWiltingRiskToScore(String wiltingRisk) {
  final risk = wiltingRisk.toLowerCase().trim();

  if (risk.contains('low')) {
    return 100;
  } else if (risk.contains('moderate')) {
    return 60;
  } else if (risk.contains('high')) {
    return 30;
  } else {
    // Default to moderate if unknown
    return 60;
  }
}

/// Get mood data based on farm score
FarmMoodData getMoodData(int farmScore) {
  if (farmScore >= 80) {
    return FarmMoodData(
      score: farmScore,
      mood: 'Happy',
      emoji: '😊',
      message: _getHappyMessage(),
    );
  } else if (farmScore >= 60) {
    return FarmMoodData(
      score: farmScore,
      mood: 'Good',
      emoji: '🙂',
      message: _getGoodMessage(),
    );
  } else if (farmScore >= 40) {
    return FarmMoodData(
      score: farmScore,
      mood: 'Stressed',
      emoji: '😐',
      message: _getStressedMessage(),
    );
  } else {
    return FarmMoodData(
      score: farmScore,
      mood: 'Critical',
      emoji: '😢',
      message: _getCriticalMessage(),
    );
  }
}

/// Get random message for HAPPY mood
String _getHappyMessage() {
  final messages = [
    'Your farm is living its best life 🌱✨',
    'Plants are vibing today 😎',
    'Everything is perfect! Keep it up! 🚀',
    'Your farm is a green paradise 🌿',
  ];
  return messages[DateTime.now().microsecond % messages.length];
}

/// Get random message for GOOD mood
String _getGoodMessage() {
  final messages = [
    'Not bad… but we can do better 👀',
    'Your farm says: I\'m okay 👍',
    'Pretty good! Let\'s make it excellent 💪',
    'On the right track! 🎯',
  ];
  return messages[DateTime.now().microsecond % messages.length];
}

/// Get random message for STRESSED mood
String _getStressedMessage() {
  final messages = [
    'I\'m a bit thirsty here 💧😅',
    'Something feels off… check me 😬',
    'Help! I need some TLC 🆘',
    'Attention needed! Don\'t ignore me 👀',
  ];
  return messages[DateTime.now().microsecond % messages.length];
}

/// Get random message for CRITICAL mood
String _getCriticalMessage() {
  final messages = [
    'Help me 😭 I\'m dying',
    'SOS 🚨 your farm needs attention NOW',
    'This is serious! Act immediately! 🚨',
    'CRITICAL: Your farm is in danger! ⚠️',
  ];
  return messages[DateTime.now().microsecond % messages.length];
}
