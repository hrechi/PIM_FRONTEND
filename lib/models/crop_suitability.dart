/// Crop suitability analysis models

/// Decision type for crop planting
enum CropDecision {
  canPlant,
  canPlantWithImprovement,
  cannotPlant;

  String get displayName {
    switch (this) {
      case CropDecision.canPlant:
        return 'Can Plant';
      case CropDecision.canPlantWithImprovement:
        return 'Can Plant With Improvement';
      case CropDecision.cannotPlant:
        return 'Cannot Plant';
    }
  }

  static CropDecision fromString(String value) {
    switch (value) {
      case 'CAN_PLANT':
        return CropDecision.canPlant;
      case 'CAN_PLANT_WITH_IMPROVEMENT':
        return CropDecision.canPlantWithImprovement;
      case 'CANNOT_PLANT':
        return CropDecision.cannotPlant;
      default:
        return CropDecision.cannotPlant;
    }
  }
}

/// Analysis result for a single crop
class CropAnalysisItem {
  final String crop;
  final bool regionAllowed;
  final double suitabilityScore;
  final CropDecision decision;
  final List<String> recommendations;

  const CropAnalysisItem({
    required this.crop,
    required this.regionAllowed,
    required this.suitabilityScore,
    required this.decision,
    required this.recommendations,
  });

  factory CropAnalysisItem.fromJson(Map<String, dynamic> json) {
    return CropAnalysisItem(
      crop: json['crop'] as String,
      regionAllowed: json['regionAllowed'] as bool,
      suitabilityScore: (json['suitabilityScore'] as num).toDouble(),
      decision: CropDecision.fromString(json['decision'] as String),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'regionAllowed': regionAllowed,
      'suitabilityScore': suitabilityScore,
      'decision': decision.toString().split('.').last,
      'recommendations': recommendations,
    };
  }
}

/// Response from analyze-existing-crops endpoint
class AnalyzeExistingCropsResponse {
  final double soilHealthScore;
  final String wiltingRisk;
  final List<CropAnalysisItem> cropsAnalysis;

  const AnalyzeExistingCropsResponse({
    required this.soilHealthScore,
    required this.wiltingRisk,
    required this.cropsAnalysis,
  });

  factory AnalyzeExistingCropsResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeExistingCropsResponse(
      soilHealthScore: (json['soilHealthScore'] as num).toDouble(),
      wiltingRisk: json['wiltingRisk'] as String,
      cropsAnalysis: (json['cropsAnalysis'] as List<dynamic>)
          .map((e) => CropAnalysisItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soilHealthScore': soilHealthScore,
      'wiltingRisk': wiltingRisk,
      'cropsAnalysis': cropsAnalysis.map((e) => e.toJson()).toList(),
    };
  }
}

/// Recommended crop item
class RecommendedCrop {
  final String crop;
  final double suitabilityScore;
  final CropDecision decision;
  final List<String> recommendations;

  const RecommendedCrop({
    required this.crop,
    required this.suitabilityScore,
    required this.decision,
    required this.recommendations,
  });

  factory RecommendedCrop.fromJson(Map<String, dynamic> json) {
    return RecommendedCrop(
      crop: json['crop'] as String,
      suitabilityScore: (json['suitabilityScore'] as num).toDouble(),
      decision: CropDecision.fromString(json['decision'] as String),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'suitabilityScore': suitabilityScore,
      'decision': decision.toString().split('.').last,
      'recommendations': recommendations,
    };
  }
}

/// Response from recommend-crops endpoint
class RecommendCropsResponse {
  final double soilHealthScore;
  final String wiltingRisk;
  final List<RecommendedCrop> recommendedCrops;

  const RecommendCropsResponse({
    required this.soilHealthScore,
    required this.wiltingRisk,
    required this.recommendedCrops,
  });

  factory RecommendCropsResponse.fromJson(Map<String, dynamic> json) {
    return RecommendCropsResponse(
      soilHealthScore: (json['soilHealthScore'] as num).toDouble(),
      wiltingRisk: json['wiltingRisk'] as String,
      recommendedCrops: (json['recommendedCrops'] as List<dynamic>)
          .map((e) => RecommendedCrop.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soilHealthScore': soilHealthScore,
      'wiltingRisk': wiltingRisk,
      'recommendedCrops': recommendedCrops.map((e) => e.toJson()).toList(),
    };
  }
}
