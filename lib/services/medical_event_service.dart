import 'api_service.dart';

class MedicalEventService {
  static Future<List<Map<String, dynamic>>> getAll(
    String animalId, {
    String? type,
  }) async {
    final query = type != null ? '?type=$type' : '';
    final response = await ApiService.get(
      '/animals/$animalId/medical-events$query',
      withAuth: true,
    );
    return List<Map<String, dynamic>>.from(response as List);
  }

  static Future<Map<String, dynamic>> create(
    String animalId,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.post(
      '/animals/$animalId/medical-events',
      data,
      withAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  static Future<Map<String, dynamic>> update(
    String animalId,
    String eventId,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.patch(
      '/animals/$animalId/medical-events/$eventId',
      data,
      withAuth: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  static Future<void> delete(String animalId, String eventId) async {
    await ApiService.delete(
      '/animals/$animalId/medical-events/$eventId',
      withAuth: true,
    );
  }
}
