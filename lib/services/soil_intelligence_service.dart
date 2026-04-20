import '../models/soil_intelligence.dart';
import 'api_service.dart';

class SoilIntelligenceService {
  Map<String, dynamic> _extractMapPayload(dynamic response) {
    if (response is Map<String, dynamic>) {
      final nested = response['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return response;
    }

    throw Exception('Unexpected response format for map payload.');
  }

  List<dynamic> _extractListPayload(dynamic response) {
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

  Future<List<SoilFingerprintMatch>> findSimilarSoils({
    required double ph,
    required double moisture,
    required double temperature,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required String soilType,
    String? soilMeasurementId,
    String? parcelLocation,
    String? region,
  }) async {
    final response = await ApiService.post(
      '/soil-intelligence/fingerprint',
      {
        if (soilMeasurementId != null) 'soilMeasurementId': soilMeasurementId,
        'ph': ph,
        'moisture': moisture,
        'temperature': temperature,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'soilType': soilType,
        if (parcelLocation != null) 'parcelLocation': parcelLocation,
        if (region != null) 'region': region,
      },
      withAuth: true,
    );

    final payload = _extractMapPayload(response);
    final matches = payload['matches'] as List<dynamic>? ?? const [];
    return matches
        .whereType<Map<String, dynamic>>()
        .map(SoilFingerprintMatch.fromJson)
        .toList();
  }

  Future<List<SoilWeatherAlert>> getActiveAlerts(String parcelId) async {
    final response = await ApiService.get(
      '/soil-intelligence/alerts/$parcelId',
      withAuth: true,
    );

    final items = _extractListPayload(response);
    return items
        .whereType<Map<String, dynamic>>()
        .map(SoilWeatherAlert.fromJson)
        .toList();
  }

  Future<void> triggerWeatherCheck(String parcelId, String measurementId) async {
    await ApiService.post(
      '/soil-intelligence/weather-alert',
      {
        'parcelId': parcelId,
        'soilMeasurementId': measurementId,
      },
      withAuth: true,
    );
  }

  Future<void> markAlertAsRead(String alertId) async {
    await ApiService.patch(
      '/soil-intelligence/alerts/$alertId/read',
      const {},
      withAuth: true,
    );
  }
}
