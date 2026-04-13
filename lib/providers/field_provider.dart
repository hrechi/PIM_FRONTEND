import 'package:flutter/material.dart';
import '../models/field_model.dart';
import '../services/field_service.dart';

class FieldProvider with ChangeNotifier {
  final FieldService _fieldService = FieldService();

  List<FieldModel> _fields = [];
  bool _isLoading = false;
  String? _error;

  List<FieldModel> get fields => _fields;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFields() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _fields = await _fieldService.getFields();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createField({
    required String name,
    required List<List<double>> areaCoordinates,
    double? areaSize,
    String? currency,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newField = await _fieldService.createField(
        name: name,
        areaCoordinates: areaCoordinates,
        areaSize: areaSize,
        currency: currency,
      );
      _fields.add(newField);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateField({
    required String id,
    String? name,
    String? cropType,
    List<List<double>>? areaCoordinates,
    double? areaSize,
    String? currency,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedField = await _fieldService.updateField(
        id: id,
        name: name,
        cropType: cropType,
        areaCoordinates: areaCoordinates,
        areaSize: areaSize,
        currency: currency,
      );
      final index = _fields.indexWhere((field) => field.id == id);
      if (index != -1) {
        _fields[index] = updatedField;
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
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