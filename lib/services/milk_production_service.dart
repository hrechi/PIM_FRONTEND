import 'api_service.dart';
import '../models/milk_production.dart';

class MilkProductionService {
  Future<MilkProduction> createRecord(Map<String, dynamic> data) async {
    final response = await ApiService.post('/milk-production', data, withAuth: true);
    return MilkProduction.fromJson(response);
  }

  Future<List<MilkProduction>> getRecords({String? animalId}) async {
    String endpoint = '/milk-production';
    if (animalId != null) {
      endpoint += '?animalId=$animalId';
    }
    
    final response = await ApiService.get(endpoint, withAuth: true);
    final List<dynamic> data = response is List ? response : (response['data'] ?? []);
    
    return data.map((json) => MilkProduction.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    return await ApiService.get('/milk-production/stats', withAuth: true);
  }

  Future<Map<String, dynamic>> getAnalytics(String timeframe, {int? year, int? month}) async {
    String url = '/milk-production/analytics?timeframe=$timeframe';
    if (year != null) url += '&year=$year';
    if (month != null) url += '&month=$month';
    return await ApiService.get(url, withAuth: true);
  }

  Future<void> deleteRecord(String id) async {
    await ApiService.delete('/milk-production/$id', withAuth: true);
  }

  Future<MilkProduction> updateRecord(String id, Map<String, dynamic> data) async {
    final response = await ApiService.patch('/milk-production/$id', data, withAuth: true);
    return MilkProduction.fromJson(response);
  }
}
