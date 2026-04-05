import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/harvest_optimization_model.dart';

class HarvestOptimizationApiService {
  static String get _baseUrl => ApiService.baseUrl;

  static Future<HarvestOptimizationResult> getHarvestOptimization(
      String parcelId) async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('User is not authenticated');

    final url = Uri.parse('$_baseUrl/parcels/$parcelId/harvest-optimization');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return HarvestOptimizationResult.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
          'Failed to load harvest optimization: ${response.statusCode}');
    }
  }
}
