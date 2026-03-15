import '../models/vaccine_models.dart';
import 'api_service.dart';

class VaccineService {
  // ── Référentiel ─────────────────────────────────────────────

  Future<List<Vaccine>> getVaccines({String? species}) async {
    String endpoint = '/vaccines';
    if (species != null) endpoint += '?species=$species';
    final data = await ApiService.get(endpoint, withAuth: true);
    return (data as List).map((j) => Vaccine.fromJson(j)).toList();
  }

  Future<List<Map<String, dynamic>>> getCountries() async {
    final data = await ApiService.get('/countries', withAuth: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<VaccineRegulation>> getCountryRegulations(String countryCode, {String? species, String? regionCode}) async {
    final params = <String, String>{};
    if (species != null) params['species'] = species;
    if (regionCode != null) params['region'] = regionCode;
    final query = params.isNotEmpty ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
    final endpoint = '/countries/$countryCode/regulations$query';
    final data = await ApiService.get(endpoint, withAuth: true);
    return (data as List).map((j) => VaccineRegulation.fromJson(j)).toList();
  }
  /// Get regulations for a field — auto-resolves country from GPS on backend
  Future<List<VaccineRegulation>> getFieldRegulations(String fieldId, {String? species}) async {
    String endpoint = '/fields/$fieldId/regulations';
    if (species != null) endpoint += '?species=$species';
    final data = await ApiService.get(endpoint, withAuth: true);
    return (data as List).map((j) => VaccineRegulation.fromJson(j)).toList();
  }
  // ── Records ─────────────────────────────────────────────────

  Future<List<VaccineRecord>> getRecords(String animalId) async {
    final data = await ApiService.get('/vaccine-records?animalId=$animalId', withAuth: true);
    return (data as List).map((j) => VaccineRecord.fromJson(j)).toList();
  }
  Future<VaccineRecord> createRecord({
    required String animalId,
    required String vaccineCode,
    required String administeredBy,
    required DateTime administeredAt,
    required double doseGiven,
    String doseUnit = 'ml',
    String? lotNumber,
    double? bodyWeight,
    String? scheduleId,
    String? notes,
  }) async {
    final data = await ApiService.post('/vaccine-records', {
      'animalId': animalId,
      'vaccineCode': vaccineCode,
      'administeredBy': administeredBy,
      'administeredAt': administeredAt.toIso8601String(),
      'doseGiven': doseGiven,
      'doseUnit': doseUnit,
      if (lotNumber != null) 'lotNumber': lotNumber,
      if (bodyWeight != null) 'bodyWeight': bodyWeight,
      if (scheduleId != null) 'scheduleId': scheduleId,
      if (notes != null) 'notes': notes,
    }, withAuth: true);
    return VaccineRecord.fromJson(data);
  }

  // ── Schedules ────────────────────────────────────────────────

  Future<List<VaccineSchedule>> getSchedules(String animalId) async {
    final data = await ApiService.get('/vaccine-schedules?animalId=$animalId', withAuth: true);
    return (data as List).map((j) => VaccineSchedule.fromJson(j)).toList();
  }

  Future<List<VaccineSchedule>> getUpcoming(String fieldId, {int days = 30}) async {
    final data = await ApiService.get(
      '/vaccine-schedules/upcoming?fieldId=$fieldId&days=$days',
      withAuth: true,
    );
    return (data as List).map((j) => VaccineSchedule.fromJson(j)).toList();
  }

  Future<List<VaccineSchedule>> getGlobalSchedules() async {
    final data = await ApiService.get('/vaccine-schedules/all', withAuth: true);
    return (data as List).map((j) => VaccineSchedule.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> generateSmartPlan(String animalId) async {
    final data = await ApiService.post('/vaccine-schedules/generate/$animalId', {}, withAuth: true);
    return Map<String, dynamic>.from(data);
  }

  Future<VaccineSchedule> updateSchedule(String id, DateTime date) async {
    final data = await ApiService.patch('/vaccine-schedules/$id', {
      'scheduledDate': date.toIso8601String(),
    }, withAuth: true);
    return VaccineSchedule.fromJson(data);
  }

  Future<VaccineRecord> markDone(String scheduleId, {
    required String administeredBy,
    required double doseGiven,
    String? lotNumber,
  }) async {
    final data = await ApiService.patch('/vaccine-schedules/$scheduleId/done', {
      'administeredBy': administeredBy,
      'doseGiven': doseGiven,
      if (lotNumber != null) 'lotNumber': lotNumber,
    }, withAuth: true);
    return VaccineRecord.fromJson(data);
  }

  Future<bool> bulkMarkDone({
    required List<String> animalIds,
    required String vaccineCode,
    required String administeredBy,
    required DateTime administeredAt,
    required double doseGiven,
    String? lotNumber,
  }) async {
    try {
      await ApiService.post('/vaccine-schedules/bulk-done', {
        'animalIds': animalIds,
        'vaccineCode': vaccineCode,
        'administeredBy': administeredBy,
        'administeredAt': administeredAt.toIso8601String(),
        'doseGiven': doseGiven,
        if (lotNumber != null) 'lotNumber': lotNumber,
      }, withAuth: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
