import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/mission_model.dart';
import 'api_service.dart';

class MissionService {
  static const String endpointBase = 'mission';

  Future<List<MissionModel>> getMissions({String? fieldId}) async {
    try {
      String url = '${ApiService.baseUrl}/$endpointBase';
      if (fieldId != null) {
        url += '?fieldId=$fieldId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        return jsonData
            .map((mission) =>
                MissionModel.fromJson(mission as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return getMissions(fieldId: fieldId);
      } else {
        throw Exception('Failed to load missions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching missions: $e');
    }
  }

  Future<MissionModel> getMissionById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$id'),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return MissionModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return getMissionById(id);
      } else {
        throw Exception('Failed to load mission: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching mission: $e');
    }
  }

  Future<MissionModel> createMission({
    required String fieldId,
    required String title,
    String? description,
    String? missionType,
    String? status,
    String? priority,
    DateTime? dueDate,
    int? estimatedDuration,
    String? notes,
  }) async {
    try {
      final body = jsonEncode({
        'fieldId': fieldId,
        'title': title,
        'description': description,
        'missionType': missionType ?? 'OTHER',
        'status': status ?? 'PENDING',
        'priority': priority ?? 'MEDIUM',
        'dueDate': dueDate?.toIso8601String(),
        'estimatedDuration': estimatedDuration,
        'notes': notes,
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/$endpointBase'),
        headers: await ApiService.getAuthHeaders(),
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return MissionModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return createMission(
          fieldId: fieldId,
          title: title,
          description: description,
          missionType: missionType,
          status: status,
          priority: priority,
          dueDate: dueDate,
          estimatedDuration: estimatedDuration,
          notes: notes,
        );
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'Failed to create mission: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating mission: $e');
    }
  }

  Future<MissionModel> updateMission({
    required String id,
    String? title,
    String? description,
    String? missionType,
    String? status,
    String? priority,
    DateTime? dueDate,
    int? estimatedDuration,
    int? actualDuration,
    int? progress,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (missionType != null) body['missionType'] = missionType;
      if (status != null) body['status'] = status;
      if (priority != null) body['priority'] = priority;
      if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();
      if (estimatedDuration != null) body['estimatedDuration'] = estimatedDuration;
      if (actualDuration != null) body['actualDuration'] = actualDuration;
      if (progress != null) body['progress'] = progress;
      if (notes != null) body['notes'] = notes;

      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$id'),
        headers: await ApiService.getAuthHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return MissionModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return updateMission(
          id: id,
          title: title,
          description: description,
          missionType: missionType,
          status: status,
          priority: priority,
          dueDate: dueDate,
          estimatedDuration: estimatedDuration,
          actualDuration: actualDuration,
          progress: progress,
          notes: notes,
        );
      } else {
        throw Exception('Failed to update mission: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating mission: $e');
    }
  }

  Future<MissionModel> updateMissionStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$id/status'),
        headers: await ApiService.getAuthHeaders(),
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return MissionModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return updateMissionStatus(id: id, status: status);
      } else {
        throw Exception('Failed to update mission status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating mission status: $e');
    }
  }

  Future<MissionModel> updateMissionProgress({
    required String id,
    required int progress,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$id/progress'),
        headers: await ApiService.getAuthHeaders(),
        body: jsonEncode({'progress': progress}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return MissionModel.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return updateMissionProgress(id: id, progress: progress);
      } else {
        throw Exception('Failed to update mission progress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating mission progress: $e');
    }
  }

  Future<bool> deleteMission(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/$endpointBase/$id'),
        headers: await ApiService.getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return deleteMission(id);
      } else {
        throw Exception('Failed to delete mission: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting mission: $e');
    }
  }
}
