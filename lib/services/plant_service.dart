import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PlantService {
  // 🚨 REPLACE THIS WITH YOUR MAC'S IP ADDRESS 🚨
  // Run 'ifconfig' (Mac) or 'ipconfig' (Windows) in terminal to find it.
  // Example: http://192.168.1.15:8000
  // Update this line:
  static const String baseUrl = 'http://192.168.1.12:8000';
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
