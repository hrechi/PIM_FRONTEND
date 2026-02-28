import '../models/parcel.dart';
import '../models/crop_suitability.dart';
import 'api_service.dart';

/// Service for analyzing crops based on soil measurements
/// This service fetches crops from parcels and analyzes them using ML
class SoilCropAnalysisService {
  /// Analyze all farmer's crops based on soil measurement data
  /// 
  /// This method:
  /// 1. Fetches specified parcel (or all parcels if not specified) to get the list of planted crops
  /// 2. Calls the ML endpoint with soil measurement data to analyze those crops
  /// 3. Returns whether each crop can be planted in the given soil conditions
  static Future<CropAnalysisResult> analyzeCropsForSoilMeasurement({
    String? parcelId, // Optional: specify which parcel to analyze
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double temperature,
    required double humidity,
    required double rainfall,
  }) async {
    try {
      // Step 1: Fetch parcels (specific parcel if ID provided, otherwise all)
      Parcel parcelToAnalyze;
      
      if (parcelId != null) {
        // Fetch specific parcel by ID
        final parcelResponse = await ApiService.get('/parcels/$parcelId', withAuth: true);
        parcelToAnalyze = Parcel.fromJson(parcelResponse['data']);
      } else {
        // Fetch all parcels and use first one with crops
        final parcelsResponse = await ApiService.get('/parcels', withAuth: true);
        final List<dynamic> parcelsData = parcelsResponse['data'] ?? [];
        final parcels = parcelsData.map((json) => Parcel.fromJson(json)).toList();
        
        parcelToAnalyze = parcels.firstWhere(
          (p) => p.crops.isNotEmpty,
          orElse: () => parcels.first,
        );
      }
      
      // Step 2: Check if parcel has crops
      if (parcelToAnalyze.crops.isEmpty) {
        return CropAnalysisResult(
          cropsAnalysis: [],
          soilProfile: null,
          recommendations: ['No crops planted in this parcel yet. Add crops to see analysis.'],
          hasCrops: false,
        );
      }
      
      // Step 3: Call analyze endpoint with soil measurement data as query parameters
      final queryParams = {
        'N': nitrogen.toStringAsFixed(2),
        'P': phosphorus.toStringAsFixed(2),
        'K': potassium.toStringAsFixed(2),
        'ph': ph.toStringAsFixed(2),
        'temperature': temperature.toStringAsFixed(2),
        'humidity': humidity.toStringAsFixed(2),
        'rainfall': rainfall.toStringAsFixed(2),
      };
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      
      final response = await ApiService.get(
        '/parcels/${parcelToAnalyze.id}/analyze-existing-crops?$queryString',
        withAuth: true,
      );
      
      final analysisResponse = AnalyzeExistingCropsResponse.fromJson(response);
      
      return CropAnalysisResult(
        cropsAnalysis: analysisResponse.cropsAnalysis,
        soilProfile: analysisResponse.soilProfile,
        recommendations: analysisResponse.recommendations,
        hasCrops: true,
      );
      
    } catch (e) {
      print('Error analyzing crops for soil measurement: $e');
      rethrow;
    }
  }

  /// Get ML-based crop recommendations for soil measurement
  /// 
  /// This method:
  /// 1. Fetches parcels to get a parcel ID
  /// 2. Calls the ML recommend-crops endpoint with soil measurement data
  /// 3. Returns ML-recommended crops that can grow in these conditions
  static Future<MLCropRecommendations> getMLCropRecommendations({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double temperature,
    required double humidity,
    required double rainfall,
  }) async {
    try {
      // Step 1: Fetch parcels to get a parcel ID (we need it for the endpoint)
      final parcelsResponse = await ApiService.get('/parcels', withAuth: true);
      final List<dynamic> parcelsData = parcelsResponse['data'] ?? [];
      
      if (parcelsData.isEmpty) {
        return MLCropRecommendations(
          recommendedCrops: [],
          recommendations: ['Create a parcel first to get ML crop recommendations.'],
          soilProfile: null,
        );
      }
      
      final parcels = parcelsData.map((json) => Parcel.fromJson(json)).toList();
      final firstParcel = parcels.first;
      
      // Step 2: Call recommend-crops endpoint with soil measurement data as query parameters
      final queryParams = {
        'N': nitrogen.toStringAsFixed(2),
        'P': phosphorus.toStringAsFixed(2),
        'K': potassium.toStringAsFixed(2),
        'ph': ph.toStringAsFixed(2),
        'temperature': temperature.toStringAsFixed(2),
        'humidity': humidity.toStringAsFixed(2),
        'rainfall': rainfall.toStringAsFixed(2),
      };
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      
      final response = await ApiService.get(
        '/parcels/${firstParcel.id}/recommend-crops?$queryString',
        withAuth: true,
      );
      
      final recommendResponse = RecommendCropsResponse.fromJson(response);
      
      return MLCropRecommendations(
        recommendedCrops: recommendResponse.recommendedCrops,
        recommendations: recommendResponse.recommendations,
        soilProfile: recommendResponse.soilProfile,
      );
      
    } catch (e) {
      print('Error getting ML crop recommendations: $e');
      rethrow;
    }
  }
}

/// Result of crop analysis for soil measurement
class CropAnalysisResult {
  final List<CropAnalysisItem> cropsAnalysis;
  final SoilProfile? soilProfile;
  final List<String> recommendations;
  final bool hasCrops;
  
  CropAnalysisResult({
    required this.cropsAnalysis,
    required this.soilProfile,
    required this.recommendations,
    required this.hasCrops,
  });
  
  /// Get crops that can be planted
  List<CropAnalysisItem> get cropsCanPlant => cropsAnalysis
      .where((c) => c.decision == CropDecision.canPlant)
      .toList();
  
  /// Get crops that cannot be planted
  List<CropAnalysisItem> get cropsCannotPlant => cropsAnalysis
      .where((c) => c.decision == CropDecision.cannotPlant)
      .toList();
  
  /// Get crops that can be planted with improvement
  List<CropAnalysisItem> get cropsNeedImprovement => cropsAnalysis
      .where((c) => c.decision == CropDecision.canPlantWithImprovement)
      .toList();
}

/// ML-based crop recommendations result
class MLCropRecommendations {
  final List<RecommendedCrop> recommendedCrops;
  final List<String> recommendations;
  final SoilProfile? soilProfile;
  
  MLCropRecommendations({
    required this.recommendedCrops,
    required this.recommendations,
    required this.soilProfile,
  });
  
  /// Get crops that can be planted (decision = canPlant)
  List<RecommendedCrop> get cropsCanPlant => recommendedCrops
      .where((c) => c.decision == CropDecision.canPlant)
      .toList();
  
  /// Get top recommended crops (at least 4, sorted by probability)
  List<RecommendedCrop> get topRecommendations {
    final canPlant = cropsCanPlant..sort((a, b) => b.probability.compareTo(a.probability));
    return canPlant.take(canPlant.length >= 4 ? canPlant.length : 4).toList();
  }
}
