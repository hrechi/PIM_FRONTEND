import 'package:flutter/foundation.dart';
import '../models/animal_health_models.dart';
import '../services/animal_health_service.dart';

export '../models/animal_health_models.dart';

enum DiagnosisState { idle, loading, success, error }

class AnimalHealthProvider extends ChangeNotifier {
  // ── Per-animal diagnosis cache ────────────────────────────
  final Map<String, DiagnosisResult> _results = {};
  final Map<String, DiagnosisState>  _states  = {};
  final Map<String, String>          _errors  = {};

  // ── Global alerts ─────────────────────────────────────────
  List<HealthAlert> _alerts = [];
  bool _alertsLoading = false;
  String? _alertsError;

  // ── AI status ─────────────────────────────────────────────
  bool? _aiOnline;

  // ── Getters ───────────────────────────────────────────────

  DiagnosisResult? resultFor(String animalId) => _results[animalId];
  DiagnosisState   stateFor(String animalId)  => _states[animalId] ?? DiagnosisState.idle;
  String?          errorFor(String animalId)  => _errors[animalId];
  bool isLoading(String animalId)             => stateFor(animalId) == DiagnosisState.loading;

  List<HealthAlert> get alerts        => _alerts;
  bool              get alertsLoading => _alertsLoading;
  String?           get alertsError   => _alertsError;
  bool?             get aiOnline      => _aiOnline;

  // ── Diagnose ──────────────────────────────────────────────

  Future<DiagnosisResult?> runDiagnostic(String animalId) async {
    _states[animalId] = DiagnosisState.loading;
    _errors.remove(animalId);
    notifyListeners();

    try {
      final result = await AnimalHealthService.diagnose(animalId);
      _results[animalId] = result;
      _states[animalId]  = DiagnosisState.success;
      notifyListeners();
      return result;
    } catch (e) {
      _states[animalId] = DiagnosisState.error;
      _errors[animalId] = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Alerts ────────────────────────────────────────────────

  Future<void> loadAlerts({int limit = 20}) async {
    _alertsLoading = true;
    _alertsError   = null;
    notifyListeners();
    try {
      _alerts = await AnimalHealthService.getAlerts(limit: limit);
    } catch (e) {
      _alertsError = e.toString();
    } finally {
      _alertsLoading = false;
      notifyListeners();
    }
  }

  // ── AI status ─────────────────────────────────────────────

  Future<void> checkAiStatus() async {
    try {
      await AnimalHealthService.getAiStatus();
      _aiOnline = true;
    } catch (_) {
      _aiOnline = false;
    }
    notifyListeners();
  }

  // ── Clear ─────────────────────────────────────────────────

  void clearAnimal(String animalId) {
    _results.remove(animalId);
    _states.remove(animalId);
    _errors.remove(animalId);
    notifyListeners();
  }
}
