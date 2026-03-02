import 'package:flutter/foundation.dart';
import '../models/vaccine_models.dart';
import '../services/vaccine_service.dart';

class VaccineProvider extends ChangeNotifier {
  final VaccineService _service = VaccineService();

  // ── State ───────────────────────────────────────────────────
  List<VaccineSchedule> _schedules = [];
  List<VaccineRecord> _records = [];
  List<VaccineSchedule> _upcoming = [];
  bool _isLoading = false;
  String? _error;
  String? _lastAnimalId;
  int _generatedCount = 0;

  // ── Getters ─────────────────────────────────────────────────
  List<VaccineSchedule> get schedules => _schedules;
  List<VaccineRecord> get records => _records;
  List<VaccineSchedule> get upcoming => _upcoming;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get generatedCount => _generatedCount;

  List<VaccineSchedule> get overdueSchedules =>
      _schedules.where((s) => s.isOverdue).toList();

  List<VaccineSchedule> get urgentSchedules =>
      _schedules.where((s) => s.isUrgent && s.isMandatory).toList();

  List<VaccineSchedule> get mandatorySchedules =>
      _schedules.where((s) => s.isMandatory && !s.isDone).toList();

  List<VaccineSchedule> get recommendedSchedules =>
      _schedules.where((s) => !s.isMandatory && !s.isDone).toList();

  // ── Load ─────────────────────────────────────────────────────

  Future<void> loadForAnimal(String animalId) async {
    if (_lastAnimalId == animalId && _schedules.isNotEmpty) return;
    _setLoading(true);
    try {
      final results = await Future.wait([
        _service.getSchedules(animalId),
        _service.getRecords(animalId),
      ]);
      _schedules = results[0] as List<VaccineSchedule>;
      _records = results[1] as List<VaccineRecord>;
      _lastAnimalId = animalId;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUpcoming(String fieldId, {int days = 30}) async {
    try {
      _upcoming = await _service.getUpcoming(fieldId, days: days);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> generatePlan(String animalId) async {
    _setLoading(true);
    try {
      final result = await _service.generateSmartPlan(animalId);
      _generatedCount = result['generatedCount'] ?? 0;
      await loadForAnimal(animalId);
      _lastAnimalId = null; // Force reload
      await loadForAnimal(animalId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markDone(String scheduleId, String animalId, {
    required String administeredBy,
    required double doseGiven,
    String? lotNumber,
  }) async {
    try {
      await _service.markDone(scheduleId,
          administeredBy: administeredBy, doseGiven: doseGiven, lotNumber: lotNumber);
      _lastAnimalId = null;
      await loadForAnimal(animalId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addRecord({
    required String animalId,
    required String vaccineCode,
    required String administeredBy,
    required DateTime administeredAt,
    required double doseGiven,
    String? lotNumber,
  }) async {
    try {
      await _service.createRecord(
        animalId: animalId,
        vaccineCode: vaccineCode,
        administeredBy: administeredBy,
        administeredAt: administeredAt,
        doseGiven: doseGiven,
        lotNumber: lotNumber,
      );
      _lastAnimalId = null;
      await loadForAnimal(animalId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
