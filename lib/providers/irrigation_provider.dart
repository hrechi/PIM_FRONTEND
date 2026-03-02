import 'package:flutter/foundation.dart';
import '../models/irrigation_schedule.dart';
import '../models/field_model.dart';
import '../services/irrigation_service.dart';
import '../services/field_service.dart';

class IrrigationProvider extends ChangeNotifier {
  final IrrigationService _irrigationService = IrrigationService();
  final FieldService _fieldService = FieldService();

  // ── State ──────────────────────────────────────────────────
  IrrigationScheduleResponse? _schedule;
  List<FieldModel> _fields = [];
  String? _selectedFieldId;
  bool _isLoading = false;
  bool _isLoadingFields = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────
  IrrigationScheduleResponse? get schedule => _schedule;
  List<FieldModel> get fields => _fields;
  String? get selectedFieldId => _selectedFieldId;
  bool get isLoading => _isLoading;
  bool get isLoadingFields => _isLoadingFields;
  String? get error => _error;

  FieldModel? get selectedField {
    if (_selectedFieldId == null) return null;
    try {
      return _fields.firstWhere((f) => f.id == _selectedFieldId);
    } catch (_) {
      return null;
    }
  }

  // ── Actions ────────────────────────────────────────────────

  /// Load all user fields for the field selector.
  Future<void> loadFields() async {
    _isLoadingFields = true;
    notifyListeners();

    try {
      _fields = await _fieldService.getFields();
      if (_selectedFieldId == null && _fields.isNotEmpty) {
        _selectedFieldId = _fields.first.id;
      }
    } catch (e) {
      debugPrint('Error loading fields: $e');
    } finally {
      _isLoadingFields = false;
      notifyListeners();
    }
  }

  /// Select a field (clears previous schedule).
  void selectField(String fieldId) {
    _selectedFieldId = fieldId;
    _schedule = null;
    _error = null;
    notifyListeners();
  }

  /// Generate the 7-day irrigation schedule via AI.
  Future<void> generateSchedule(String fieldId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _schedule = await _irrigationService.generateSchedule(fieldId);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Irrigation schedule error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all state.
  void clear() {
    _schedule = null;
    _fields = [];
    _selectedFieldId = null;
    _error = null;
    notifyListeners();
  }
}
