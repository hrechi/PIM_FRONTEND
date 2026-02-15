import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/field_model.dart';
import 'api_service.dart';

class FieldService {
  static const String endpointBase = 'field';

  Future<List<FieldModel>> getFields() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/$endpointBase'),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        return jsonData
            .map((field) => FieldModel.fromJson(field as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return getFields();
      } else {
        throw Exception('Failed to load fields: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching fields: $e');
    }
  }

  Future<FieldModel> getFieldById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$id'),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return FieldModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return getFieldById(id);
      } else {
        throw Exception('Failed to load field: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching field: $e');
    }
  }

  Future<FieldModel> createField({
    required String name,
    required List<List<double>> areaCoordinates,
    double? areaSize,
  }) async {
    try {
      final body = jsonEncode({
        'name': name,
        'areaCoordinates': areaCoordinates,
        if (areaSize != null) 'areaSize': areaSize,
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/$endpointBase'),
        headers: await ApiService.getAuthHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return FieldModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return createField(
          name: name,
          areaCoordinates: areaCoordinates,
          areaSize: areaSize,
        );
      } else {
        throw Exception('Failed to create field: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating field: $e');
    }
  }

  Future<FieldModel> updateField({
    required String id,
    String? name,
    String? cropType,
    List<List<double>>? areaCoordinates,
    double? areaSize,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (cropType != null) body['cropType'] = cropType;
      if (areaCoordinates != null) body['areaCoordinates'] = areaCoordinates;
      if (areaSize != null) body['areaSize'] = areaSize;

      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$id'),
        headers: await ApiService.getAuthHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return FieldModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return updateField(
          id: id,
          name: name,
          cropType: cropType,
          areaCoordinates: areaCoordinates,
          areaSize: areaSize,
        );
      } else {
        throw Exception('Failed to update field: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating field: $e');
    }
  }

  Future<bool> deleteField(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$id'),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return deleteField(id);
      } else {
        throw Exception('Failed to delete field: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting field: $e');
    }
  }
}
