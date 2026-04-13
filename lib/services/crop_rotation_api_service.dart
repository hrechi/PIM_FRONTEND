import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CropRotationApiService {
  static String get _baseUrl => ApiService.baseUrl; // Using base URL from main API service

  static Future<Map<String, dynamic>> getCropRotationPlan(String parcelId) async {
    try {
      final token = await ApiService.getAccessToken();
      if (token == null) {
        throw Exception('User is not authenticated');
      }

      final url = Uri.parse('$_baseUrl/parcels/$parcelId/crop-rotation');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load crop rotation plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching crop rotation: $e');
    }
  }
}
