import 'api_service.dart';
import '../models/expense_model.dart';

class ExpenseService {
  static Future<Expense> createExpense(Map<String, dynamic> data) async {
    final response = await ApiService.post('/expenses', data, withAuth: true);
    return Expense.fromJson(response);
  }

  static Future<List<Expense>> getExpenses({
    required String fieldId,
    String? category,
    String? startDate,
    String? endDate,
    String? animalId,
    int? limit,
    int? offset,
  }) async {
    String endpoint = '/expenses?fieldId=$fieldId';
    if (category != null) endpoint += '&category=$category';
    if (startDate != null) endpoint += '&startDate=$startDate';
    if (endDate != null) endpoint += '&endDate=$endDate';
    if (animalId != null) endpoint += '&animalId=$animalId';
    if (limit != null) endpoint += '&limit=$limit';
    if (offset != null) endpoint += '&offset=$offset';

    final response = await ApiService.get(endpoint, withAuth: true);
    final List<dynamic> dataList = response is List ? response : (response['data'] ?? []);
    return dataList.map((json) => Expense.fromJson(json)).toList();
  }

  static Future<Expense> updateExpense(String id, Map<String, dynamic> data) async {
    final response = await ApiService.patch('/expenses/$id', data, withAuth: true);
    return Expense.fromJson(response);
  }

  static Future<void> deleteExpense(String id) async {
    await ApiService.delete('/expenses/$id', withAuth: true);
  }

  static Future<Map<String, dynamic>> getAnimalFinanceSummary(String animalId) async {
    final response = await ApiService.get('/expenses/animal-summary/$animalId', withAuth: true);
    return response as Map<String, dynamic>;
  }
}
