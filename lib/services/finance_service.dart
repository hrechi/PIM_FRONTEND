import 'dart:convert';
import '../models/finance_dashboard_model.dart';
import 'api_service.dart';

class FinanceService {
  Future<FinanceDashboardModel> getDashboard(String fieldId, String period) async {
    try {
      final data = await ApiService.get(
        '/finance/dashboard?fieldId=$fieldId&period=$period',
        withAuth: true,
      );
      return FinanceDashboardModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }
}