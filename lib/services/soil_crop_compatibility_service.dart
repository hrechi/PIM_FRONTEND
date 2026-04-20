import 'api_service.dart';

/// Response model for crop compatibility check
class CropCompatibilityResult {
  final String cropName;
  final bool canPlant;
  final String reason;

  CropCompatibilityResult({
    required this.cropName,
    required this.canPlant,
    required this.reason,
  });

  factory CropCompatibilityResult.fromJson(Map<String, dynamic> json) {
    return CropCompatibilityResult(
      cropName: json['cropName'],
      canPlant: json['canPlant'],
      reason: json['reason'],
    );
  }
}

/// Response model for soil corrections
class SoilCorrectionAction {
  final String title;
  final String description;
  final List<String> steps;
  final String affectedCrops;
  final int priority;

  SoilCorrectionAction({
    required this.title,
    required this.description,
    required this.steps,
    required this.affectedCrops,
    required this.priority,
  });

  factory SoilCorrectionAction.fromJson(Map<String, dynamic> json) {
    return SoilCorrectionAction(
      title: json['title'],
      description: json['description'],
      steps: List<String>.from(json['steps']),
      affectedCrops: json['affectedCrops'],
      priority: json['priority'] ?? 0,
    );
  }
}

/// Response model for seasonal plan
class SeasonalSoilPlan {
  final String season;
  final List<String> tasks;
  final String? warning;
  final String? amendmentWindow;
  final List<String> canPlantNow;
  final List<String> riskyThisSeason;

  SeasonalSoilPlan({
    required this.season,
    required this.tasks,
    this.warning,
    this.amendmentWindow,
    this.canPlantNow = const [],
    this.riskyThisSeason = const [],
  });

  factory SeasonalSoilPlan.fromJson(Map<String, dynamic> json) {
    final cropAdvice = json['cropAdvice'] as Map<String, dynamic>?;

    return SeasonalSoilPlan(
      season: json['season'],
      tasks: List<String>.from(json['tasks']),
      warning: json['warning'],
      amendmentWindow: json['amendmentWindow'],
      canPlantNow: List<String>.from(cropAdvice?['canPlantNow'] ?? const []),
      riskyThisSeason: List<String>.from(cropAdvice?['riskyThisSeason'] ?? const []),
    );
  }
}

/// Service for soil-crop compatibility features
class SoilCropCompatibilityService {
  static Map<String, dynamic> _extractMapPayload(dynamic response) {
    if (response is Map<String, dynamic>) {
      final nested = response['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return response;
    }

    throw Exception('Unexpected response format (expected object payload)');
  }

  static List<dynamic> _extractListPayload(dynamic response) {
    if (response is List<dynamic>) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      final nested = response['data'];
      if (nested is List<dynamic>) {
        return nested;
      }
    }

    return const [];
  }

  /// Check if a single crop can be planted in given soil conditions
  static Future<CropCompatibilityResult> checkCropCompatibility({
    required String cropName,
    required double ph,
    required double moisture,
    required double temperature,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    String? season,
  }) async {
    try {
      final response = await ApiService.post(
        '/soil/crop-compatibility',
        {
          'cropName': cropName,
          'ph': ph,
          'moisture': moisture,
          'temperature': temperature,
          'nitrogen': nitrogen,
          'phosphorus': phosphorus,
          'potassium': potassium,
          if (season != null) 'season': season,
        },
        withAuth: true,
      );

      final payload = _extractMapPayload(response);
      return CropCompatibilityResult.fromJson(payload);
    } catch (e) {
      print('Error checking crop compatibility: $e');
      rethrow;
    }
  }

  /// Check compatibility for multiple crops
  static Future<List<CropCompatibilityResult>> checkCropsCompatibility({
    required List<String> cropNames,
    required double ph,
    required double moisture,
    required double temperature,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    String? season,
  }) async {
    try {
      final results = <CropCompatibilityResult>[];
      Object? lastError;
      
      for (final cropName in cropNames) {
        try {
          final result = await checkCropCompatibility(
            cropName: cropName,
            ph: ph,
            moisture: moisture,
            temperature: temperature,
            nitrogen: nitrogen,
            phosphorus: phosphorus,
            potassium: potassium,
            season: season,
          );
          results.add(result);
        } catch (e) {
          // If single crop check fails, continue with others
          lastError = e;
          print('Failed to check $cropName: $e');
        }
      }

      if (results.isEmpty && cropNames.isNotEmpty) {
        throw Exception(
          'Failed to analyze parcel crops. Ensure backend and AI service are running.${lastError != null ? ' Last error: $lastError' : ''}'
        );
      }
      
      return results;
    } catch (e) {
      print('Error checking crops compatibility: $e');
      rethrow;
    }
  }

  /// Get soil correction actions for failed crops
  static Future<List<SoilCorrectionAction>> getSoilCorrections({
    required List<String> failedCropNames,
    required double ph,
    required double moisture,
    required double temperature,
    required String soilType,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    String? season,
  }) async {
    try {
      final response = await ApiService.post(
        '/soil/fix-for-crops',
        {
          'failedCrops': failedCropNames,
          if (season != null) 'season': season,
          'soilData': {
            'ph': ph,
            'moisture': moisture,
            'temperature': temperature,
            'soilType': soilType,
            'nitrogen': nitrogen,
            'phosphorus': phosphorus,
            'potassium': potassium,
            if (season != null) 'season': season,
          },
        },
        withAuth: true,
      );

      final data = _extractListPayload(response);
      return data.map((json) => SoilCorrectionAction.fromJson(json)).toList();
    } catch (e) {
      print('Error getting soil corrections: $e');
      rethrow;
    }
  }

  /// Get seasonal soil care plan
  static Future<SeasonalSoilPlan> getSeasonalPlan({
    required String season,
    required double ph,
    required double moisture,
    required double temperature,
    required String soilType,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required List<String> cropNames,
    Map<String, dynamic>? weatherData,
  }) async {
    try {
      final response = await ApiService.post(
        '/soil/seasonal-plan',
        {
          'season': season,
          'soilData': {
            'ph': ph,
            'moisture': moisture,
            'temperature': temperature,
            'soilType': soilType,
            'nitrogen': nitrogen,
            'phosphorus': phosphorus,
            'potassium': potassium,
            if (weatherData != null) ...weatherData,
          },
          'crops': cropNames,
        },
        withAuth: true,
      );

      final payload = _extractMapPayload(response);
      return SeasonalSoilPlan.fromJson(payload);
    } catch (e) {
      print('Error getting seasonal plan: $e');
      rethrow;
    }
  }
}
