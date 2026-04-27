import 'package:dio/dio.dart';
import '../utils/constants.dart';

class AssetAiService {
  final Dio _dio;
  final String _baseUrl;

  AssetAiService({Dio? dio, String? baseUrl})
    : _dio = dio ?? Dio(),

      _baseUrl = baseUrl ?? 'http://${AppConfig.serverHost}:${AppConfig.serverPort}/api/ai';


  Future<Map<String, dynamic>> validateAsset(
    Map<String, dynamic> assetData,
  ) async {
    final response = await _dio.post(
      '$_baseUrl/validate-asset',
      data: assetData,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> diagnoseAsset(
    Map<String, dynamic> diagnoseData,
  ) async {
    final response = await _dio.post(
      '$_baseUrl/diagnose-asset',
      data: diagnoseData,
    );
    return response.data;
  }

  /// Suggest realistic models, categories, and usage patterns based on partial input.
  /// Returns: {models: [...], categories: [...], suggestions: {usage: [...], notes: [...]}}
  Future<Map<String, dynamic>> suggestAsset({
    String? brand,
    String? model,
    String? category,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/suggest-asset',
      data: {'brand': brand, 'model': model, 'category': category},
    );
    return response.data;
  }
}
