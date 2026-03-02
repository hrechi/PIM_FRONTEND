import 'package:flutter/foundation.dart';
import '../models/weather_info.dart';
import '../models/field_model.dart';
import '../services/weather_service.dart';
import '../services/field_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final FieldService _fieldService = FieldService();

  // ── State ──────────────────────────────────────────────────
  WeatherForecastResponse? _forecast;
  RecommendationResponse? _recommendations;
  List<FieldModel> _fields = [];
  String? _selectedFieldId;
  bool _isLoading = false;
  bool _isLoadingRecs = false;
  bool _isLoadingFields = false;
  String? _error;
  String? _recsError;

  // ── Getters ────────────────────────────────────────────────
  WeatherForecastResponse? get forecast => _forecast;
  RecommendationResponse? get recommendations => _recommendations;
  List<FieldModel> get fields => _fields;
  String? get selectedFieldId => _selectedFieldId;
  bool get isLoading => _isLoading;
  bool get isLoadingRecs => _isLoadingRecs;
  bool get isLoadingFields => _isLoadingFields;
  String? get error => _error;
  String? get recsError => _recsError;

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
      // Auto-select the first field if none selected
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

  /// Select a field and automatically fetch its weather.
  Future<void> selectField(String fieldId) async {
    _selectedFieldId = fieldId;
    _recommendations = null; // Clear old recommendations
    _recsError = null;
    notifyListeners();
    await fetchWeather(fieldId);
  }

  /// Fetch 7-day weather forecast for a field.
  Future<void> fetchWeather(String fieldId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _forecast = await _weatherService.getWeatherForField(fieldId);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Weather fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch AI agricultural recommendations for a field.
  Future<void> fetchRecommendations(String fieldId) async {
    _isLoadingRecs = true;
    _recsError = null;
    notifyListeners();

    try {
      _recommendations = await _weatherService.getRecommendations(fieldId);
      _recsError = null;
    } catch (e) {
      _recsError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Recommendations fetch error: $e');
    } finally {
      _isLoadingRecs = false;
      notifyListeners();
    }
  }

  /// Clear all state (e.g., on logout).
  void clear() {
    _forecast = null;
    _recommendations = null;
    _fields = [];
    _selectedFieldId = null;
    _error = null;
    _recsError = null;
    notifyListeners();
  }
}
