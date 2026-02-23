import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather_info.dart';
import 'api_service.dart';

class WeatherService {
  static const String endpointBase = 'weather';

  /// Fetch 7-day weather forecast for a specific field.
  Future<WeatherForecastResponse> getWeatherForField(String fieldId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$fieldId'),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return WeatherForecastResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return getWeatherForField(fieldId);
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  /// Get AI-powered agricultural recommendations for a field.
  Future<RecommendationResponse> getRecommendations(String fieldId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$fieldId/recommendations'),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return RecommendationResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return getRecommendations(fieldId);
      } else {
        throw Exception(
            'Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching recommendations: $e');
    }
  }
}
