import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/harvest_optimization_model.dart';

class HarvestOptimizationApiService {
  static String get _baseUrl => ApiService.baseUrl;
  
  static Future<HarvestOptimizationModel> getOptimization(String parcelId, {String? cropId}) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) throw Exception('User is not authenticated');

      final urlString = '$_baseUrl/parcels/$parcelId/harvest-optimization' + (cropId != null ? '?cropId=$cropId' : '');
      final url = Uri.parse(urlString);
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HarvestOptimizationModel.fromJson(data);
      } else {
        throw Exception('Failed to load harvest optimization: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching harvest optimization: $e');
    }
  }
}
