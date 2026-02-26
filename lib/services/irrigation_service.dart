import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/irrigation_schedule.dart';
import 'api_service.dart';

class IrrigationService {
  static const String endpointBase = 'irrigation';

  /// Generate a 7-day smart irrigation schedule for a field.
  Future<IrrigationScheduleResponse> generateSchedule(String fieldId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$fieldId/schedule'),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 50));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return IrrigationScheduleResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return generateSchedule(fieldId);
      } else {
        throw Exception(
            'Failed to generate irrigation schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating irrigation schedule: $e');
    }
  }
}
