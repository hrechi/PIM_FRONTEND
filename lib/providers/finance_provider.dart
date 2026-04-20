import 'package:flutter/material.dart';
import '../models/finance_dashboard_model.dart';
import '../services/finance_service.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceService _financeService = FinanceService();

  FinanceDashboardModel? _dashboard;
  bool _isLoading = false;
  String? _error;

  FinanceDashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard(String fieldId, String period) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _financeService.getDashboard(fieldId, period);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}