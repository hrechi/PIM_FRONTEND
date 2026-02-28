/// Crop suitability analysis models
import 'package:flutter/material.dart';

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

/// pH status categories
enum PhStatus {
  acidic,
  neutral,
  alkaline;

  String get displayName {
    switch (this) {
      case PhStatus.acidic:
        return 'Acidic';
      case PhStatus.neutral:
        return 'Neutral';
      case PhStatus.alkaline:
        return 'Alkaline';
    }
  }

  static PhStatus fromString(String value) {
    switch (value) {
      case 'ACIDIC':
        return PhStatus.acidic;
      case 'NEUTRAL':
        return PhStatus.neutral;
      case 'ALKALINE':
        return PhStatus.alkaline;
      default:
        return PhStatus.neutral;
    }
  }
}

/// Nutrient status categories
enum NutrientStatus {
  balanced,
  deficient;

  String get displayName {
    switch (this) {
      case NutrientStatus.balanced:
        return 'Balanced';
      case NutrientStatus.deficient:
        return 'Deficient';
    }
  }

  static NutrientStatus fromString(String value) {
    switch (value) {
      case 'BALANCED':
        return NutrientStatus.balanced;
      case 'DEFICIENT':
        return NutrientStatus.deficient;
      default:
        return NutrientStatus.balanced;
    }
  }
}

/// Unified soil profile from ML analysis
class SoilProfile {
  final double soilHealthScore;
  final double fertilityIndex;
  final PhStatus phStatus;
  final NutrientStatus nutrientStatus;

  const SoilProfile({
    required this.soilHealthScore,
    required this.fertilityIndex,
    required this.phStatus,
    required this.nutrientStatus,
  });

  factory SoilProfile.fromJson(Map<String, dynamic> json) {
    return SoilProfile(
      soilHealthScore: (json['soilHealthScore'] as num?)?.toDouble() ?? 0.0,
      fertilityIndex: (json['fertilityIndex'] as num?)?.toDouble() ?? 0.0,
      phStatus: PhStatus.fromString((json['phStatus'] as String?) ?? 'NEUTRAL'),
      nutrientStatus: NutrientStatus.fromString((json['nutrientStatus'] as String?) ?? 'BALANCED'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soilHealthScore': soilHealthScore,
      'fertilityIndex': fertilityIndex,
      'phStatus': phStatus.toString().split('.').last.toUpperCase(),
      'nutrientStatus': nutrientStatus.toString().split('.').last.toUpperCase(),
    };
  }
}

/// Analysis result for a single crop (from ML model)
class CropAnalysisItem {
  final String crop;
  final double probability;
  final CropDecision decision;
  final List<String> recommendations;

  const CropAnalysisItem({
    required this.crop,
    required this.probability,
    required this.decision,
    required this.recommendations,
  });

  factory CropAnalysisItem.fromJson(Map<String, dynamic> json) {
    return CropAnalysisItem(
      crop: json['crop'] as String? ?? '',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      decision: CropDecision.fromString((json['decision'] as String?) ?? 'CANNOT_PLANT'),
      recommendations: ((json['recommendations'] as List<dynamic>?) ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'probability': probability,
      'decision': decision.toString().split('.').last,
      'recommendations': recommendations,
    };
  }

  /// Get color based on decision
  Color getDecisionColor() {
    switch (decision) {
      case CropDecision.canPlant:
        return Colors.green;
      case CropDecision.canPlantWithImprovement:
        return Colors.orange;
      case CropDecision.cannotPlant:
        return Colors.red;
    }
  }

  /// Get suitability score (probability as percentage)
  double get suitabilityScore => probability * 100;
}

/// Response from analyze-existing-crops endpoint (with ML)
class AnalyzeExistingCropsResponse {
  final SoilProfile soilProfile;
  final List<CropAnalysisItem> cropsAnalysis;
  final List<String> recommendations;

  const AnalyzeExistingCropsResponse({
    required this.soilProfile,
    required this.cropsAnalysis,
    required this.recommendations,
  });

  factory AnalyzeExistingCropsResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeExistingCropsResponse(
      soilProfile: SoilProfile.fromJson(json['soilProfile'] as Map<String, dynamic>? ?? {}),
      cropsAnalysis: ((json['cropsAnalysis'] as List<dynamic>?) ?? [])
          .map((e) => CropAnalysisItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: ((json['recommendations'] as List<dynamic>?) ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soilProfile': soilProfile.toJson(),
      'cropsAnalysis': cropsAnalysis.map((e) => e.toJson()).toList(),
      'recommendations': recommendations,
    };
  }
}

/// Recommended crop from ML model
class RecommendedCrop {
  final String crop;
  final double probability;
  final CropDecision decision;

  const RecommendedCrop({
    required this.crop,
    required this.probability,
    required this.decision,
  });

  factory RecommendedCrop.fromJson(Map<String, dynamic> json) {
    return RecommendedCrop(
      crop: json['crop'] as String? ?? '',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      decision: CropDecision.fromString((json['decision'] as String?) ?? 'CANNOT_PLANT'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop': crop,
      'probability': probability,
      'decision': decision.toString().split('.').last,
    };
  }

  /// Get suitability score (probability as percentage)
  double get suitabilityScore => probability * 100;
}

/// Response from recommend-crops endpoint (with ML)
class RecommendCropsResponse {
  final SoilProfile soilProfile;
  final List<RecommendedCrop> recommendedCrops;
  final List<String> recommendations;

  const RecommendCropsResponse({
    required this.soilProfile,
    required this.recommendedCrops,
    required this.recommendations,
  });

  factory RecommendCropsResponse.fromJson(Map<String, dynamic> json) {
    return RecommendCropsResponse(
      soilProfile: SoilProfile.fromJson(json['soilProfile'] as Map<String, dynamic>? ?? {}),
      recommendedCrops: ((json['recommendedCrops'] as List<dynamic>?) ?? [])
          .map((e) => RecommendedCrop.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: ((json['recommendations'] as List<dynamic>?) ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soilProfile': soilProfile.toJson(),
      'recommendedCrops': recommendedCrops.map((e) => e.toJson()).toList(),
      'recommendations': recommendations,
    };
  }
}
