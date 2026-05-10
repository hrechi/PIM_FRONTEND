import 'api_service.dart';

class RevenueService {
  static Future<Map<String, dynamic>> createRevenue(
      Map<String, dynamic> data) async {
    final response =
        await ApiService.post('/revenues', data, withAuth: true);
    return response as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getRevenues({
    required String fieldId,
    String? category,
    String? startDate,
    String? endDate,
    int? limit,
    int? offset,
  }) async {
    String endpoint = '/revenues?fieldId=$fieldId';
    if (category != null) endpoint += '&category=$category';
    if (startDate != null) endpoint += '&startDate=$startDate';
    if (endDate != null) endpoint += '&endDate=$endDate';
    if (limit != null) endpoint += '&limit=$limit';
    if (offset != null) endpoint += '&offset=$offset';

    final response = await ApiService.get(endpoint, withAuth: true);
    return response is List ? response : (response['data'] ?? []);
  }

  static Future<void> deleteRevenue(String id) async {
    await ApiService.delete('/revenues/$id', withAuth: true);
  }
}
