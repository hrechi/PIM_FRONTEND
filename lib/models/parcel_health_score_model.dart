class ParcelHealthScore {
  final String parcelId;
  final String parcelName;
  final int score;
  final Map<String, ScoreFactor> breakdown;
  final List<String> recommendations;

  ParcelHealthScore({
    required this.parcelId,
    required this.parcelName,
    required this.score,
    required this.breakdown,
    required this.recommendations,
  });

  factory ParcelHealthScore.fromJson(Map<String, dynamic> json) {
    final breakdownMap = Map<String, dynamic>.from(json['breakdown']);
    final Map<String, ScoreFactor> breakdown = {};
    
    breakdownMap.forEach((key, value) {
      breakdown[key] = ScoreFactor.fromJson(value);
    });

    return ParcelHealthScore(
      parcelId: json['parcelId'],
      parcelName: json['parcelName'],
      score: json['score'],
      breakdown: breakdown,
      recommendations: List<String>.from(json['recommendations']),
    );
  }
}

class ScoreFactor {
  final int score;
  final int max;

  ScoreFactor({required this.score, required this.max});

  factory ScoreFactor.fromJson(Map<String, dynamic> json) {
    return ScoreFactor(
      score: json['score'],
      max: json['max'],
    );
  }

  double get percentage => (score / max);
}
