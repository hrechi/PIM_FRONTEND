import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class PlantService {
  // Uses the same server host as the rest of the app
  // For Plant Doctor AI service (runs on port 8012)
  static String get baseUrl => 'http://${AppConfig.serverHost}:${AppConfig.plantDoctorPort}';
  @deprecated
  static const String baseUrl = 'http://process.env.API_BASE_URL:8000'; // Deprecated - use getter above
  static Future<Map<String, dynamic>> scanPlant(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"error": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": "Could not connect to server. Is Python running?"};
    }
  }
}
