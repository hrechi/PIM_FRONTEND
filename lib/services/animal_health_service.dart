import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/animal_health_models.dart';
import '../models/sensor_history.dart';
import 'api_service.dart';

class AnimalHealthService {
  // Use a getter instead of const so ApiConfig.baseUrl (also a getter) is allowed.
  static String get baseUrl => '${ApiConfig.baseUrl}/animal-health';

  // ── Diagnose an animal ────────────────────────────────────

  /// Runs the AI diagnostic for a single animal and returns a [DiagnosisResult].
  static Future<DiagnosisResult> diagnose(String animalId) async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.post(
      Uri.parse('$baseUrl/diagnose/$animalId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DiagnosisResult.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to diagnose animal: ${response.statusCode}');
    }
  }

  // ── AI service status ─────────────────────────────────────

  /// Pings the AI service health endpoint. Throws if the service is offline.
  static Future<void> getAiStatus() async {
    final token = await ApiService.getAccessToken();

    final response = await http.get(
      Uri.parse('$baseUrl/ai-status'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('AI service offline: ${response.statusCode}');
    }
  }

  // ── Sensor history ────────────────────────────────────────

  /// Fetches hourly-aggregated sensor history for an animal.
  static Future<SensorHistory> getSensorHistory(
    String animalId, {
    int periodHours = 24,
  }) async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/sensors/$animalId/history?period=$periodHours'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return SensorHistory.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      throw Exception('Animal not found');
    } else {
      throw Exception('Failed to load sensor history: ${response.statusCode}');
    }
  }

  // ── Diagnose (raw map) ────────────────────────────────────

  /// Same as [diagnose] but returns the raw JSON map — kept for legacy callers.
  static Future<Map<String, dynamic>> diagnoseAnimal(String animalId) async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.post(
      Uri.parse('$baseUrl/diagnose/$animalId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to diagnose animal: ${response.statusCode}');
    }
  }

  // ── Herd dashboard ────────────────────────────────────────

  static Future<Map<String, dynamic>> getHerdDashboard() async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/herd-dashboard'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load herd dashboard: ${response.statusCode}');
    }
  }

  // ── Alerts ────────────────────────────────────────────────

  /// Returns a typed list of [HealthAlert].
  static Future<List<HealthAlert>> getAlerts({int limit = 20}) async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/alerts?limit=$limit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final list = json.decode(response.body) as List<dynamic>;
      return list
          .map((e) => HealthAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load alerts: ${response.statusCode}');
    }
  }
}

// ── Weight record model ───────────────────────────────────────────────────────

class WeightRecord {
  final String id;
  final DateTime date;
  final double weightKg;
  final String? measuredBy;

  const WeightRecord({
    required this.id,
    required this.date,
    required this.weightKg,
    this.measuredBy,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> j) => WeightRecord(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        weightKg: (j['weightKg'] as num).toDouble(),
        measuredBy: j['measuredBy'] as String?,
      );
}

class WeightStats {
  final int count;
  final double? minKg;
  final double? maxKg;
  final double? latestKg;
  final double? trendKgPerWeek;

  const WeightStats({
    required this.count,
    this.minKg,
    this.maxKg,
    this.latestKg,
    this.trendKgPerWeek,
  });

  factory WeightStats.fromJson(Map<String, dynamic> j) => WeightStats(
        count: (j['count'] as num).toInt(),
        minKg: (j['minKg'] as num?)?.toDouble(),
        maxKg: (j['maxKg'] as num?)?.toDouble(),
        latestKg: (j['latestKg'] as num?)?.toDouble(),
        trendKgPerWeek: (j['trendKgPerWeek'] as num?)?.toDouble(),
      );
}

class WeightLossAlert {
  final bool triggered;
  final double lossPercent;
  final String message;

  const WeightLossAlert({
    required this.triggered,
    required this.lossPercent,
    required this.message,
  });

  factory WeightLossAlert.fromJson(Map<String, dynamic> j) => WeightLossAlert(
        triggered: j['triggered'] as bool,
        lossPercent: (j['lossPercent'] as num).toDouble(),
        message: j['message'] as String,
      );
}

class WeightHistory {
  final List<WeightRecord> records;
  final WeightStats stats;
  final WeightLossAlert? weightLossAlert;

  const WeightHistory({
    required this.records,
    required this.stats,
    this.weightLossAlert,
  });

  factory WeightHistory.fromJson(Map<String, dynamic> j) {
    final alertJson = j['weightLossAlert'] as Map<String, dynamic>?;
    return WeightHistory(
      records: (j['records'] as List)
          .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: WeightStats.fromJson(j['stats'] as Map<String, dynamic>),
      weightLossAlert: alertJson != null && alertJson['triggered'] == true
          ? WeightLossAlert.fromJson(alertJson)
          : null,
    );
  }
}

// ── Weight API calls (appended to AnimalHealthService file) ──────────────────

class WeightService {
  static String get _base => '${ApiConfig.baseUrl}/animal-health';

  static Future<WeightHistory> getHistory(String animalId,
      {int days = 90}) async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final res = await http.get(
      Uri.parse('$_base/weight/$animalId?days=$days'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return WeightHistory.fromJson(
          json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load weight history: ${res.statusCode}');
  }

  static Future<WeightRecord> addRecord(
    String animalId, {
    required double weightKg,
    String? measuredBy,
    DateTime? measuredDate,
  }) async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final res = await http.post(
      Uri.parse('$_base/weight/$animalId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'weightKg': weightKg,
        if (measuredBy != null) 'measuredBy': measuredBy,
        if (measuredDate != null)
          'measuredDate': measuredDate.toIso8601String(),
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return WeightRecord.fromJson(
          json.decode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to add weight record: ${res.statusCode}');
  }

  static Future<void> deleteRecord(String recordId) async {
    final token = await ApiService.getAccessToken();
    if (token == null) throw Exception('No authentication token');

    final res = await http.delete(
      Uri.parse('$_base/weight/record/$recordId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete record: ${res.statusCode}');
    }
  }
}
