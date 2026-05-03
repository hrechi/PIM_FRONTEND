import 'package:flutter/foundation.dart';
import '../models/revenue_detail_model.dart';
import '../models/expense_detail_model.dart';
import './api_service.dart';

class FinanceDetailsService {
  FinanceDetailsService();

  Future<RevenuesResponse> getRevenuesDetails({
    required String fieldId,
    String period = 'month',
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final endpoint = '/finance/revenues?fieldId=$fieldId&period=$period&skip=$skip&take=$take';
      final response = await ApiService.get(
        endpoint,
        withAuth: true,
      );
      return RevenuesResponse.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching revenues: $e');
      rethrow;
    }
  }

  Future<ExpensesResponse> getExpensesDetails({
    required String fieldId,
    String period = 'month',
    int skip = 0,
    int take = 20,
  }) async {
    try {
      final endpoint = '/finance/expenses?fieldId=$fieldId&period=$period&skip=$skip&take=$take';
      final response = await ApiService.get(
        endpoint,
        withAuth: true,
      );
      return ExpensesResponse.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
      rethrow;
    }
  }
}
