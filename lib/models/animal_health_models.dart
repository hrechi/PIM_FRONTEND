/// Models for the AI animal health diagnosis feature.

// ── SensorSnapshot ────────────────────────────────────────────────────────────

class SensorSnapshot {
  final double temperature;
  final double heartRate;
  final double activityScore;
  final double lyingPct6h;
  final double accAsymmetry;
  final double deltaTemp;
  final double deltaHr;
  final double activityDrop;

  const SensorSnapshot({
    required this.temperature,
    required this.heartRate,
    required this.activityScore,
    required this.lyingPct6h,
    required this.accAsymmetry,
    required this.deltaTemp,
    required this.deltaHr,
    required this.activityDrop,
  });

  factory SensorSnapshot.fromJson(Map<String, dynamic> json) {
    return SensorSnapshot(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 38.5,
      heartRate:
          ((json['heartRate'] ?? json['heart_rate']) as num?)?.toDouble() ?? 70.0,
      activityScore: ((json['activityScore'] ?? json['activity_score']) as num?)
              ?.toDouble() ??
          60.0,
      lyingPct6h: ((json['lyingPct6h'] ?? json['lying_pct_6h']) as num?)
              ?.toDouble() ??
          45.0,
      accAsymmetry: ((json['accAsymmetry'] ?? json['acc_asymmetry']) as num?)
              ?.toDouble() ??
          0.05,
      deltaTemp:
          ((json['deltaTemp'] ?? json['delta_temp']) as num?)?.toDouble() ?? 0.0,
      deltaHr:
          ((json['deltaHr'] ?? json['delta_hr']) as num?)?.toDouble() ?? 0.0,
      activityDrop: ((json['activityDrop'] ?? json['activity_drop']) as num?)
              ?.toDouble() ??
          0.0,
    );
  }
}

// ── DiagnosisTrigger ──────────────────────────────────────────────────────────

class DiagnosisTrigger {
  final String label;
  final double value;
  final String unit;
  final String normalRange;
  final String direction; // '↑' or '↓'
  final String severity;  // 'high' | 'medium'

  const DiagnosisTrigger({
    required this.label,
    required this.value,
    required this.unit,
    required this.normalRange,
    required this.direction,
    required this.severity,
  });

  factory DiagnosisTrigger.fromJson(Map<String, dynamic> json) {
    return DiagnosisTrigger(
      label:       json['label']?.toString()       ?? '',
      value:       (json['value'] as num?)?.toDouble() ?? 0.0,
      unit:        json['unit']?.toString()        ?? '',
      normalRange:
          json['normalRange']?.toString() ?? json['normal_range']?.toString() ?? '',
      direction:   json['direction']?.toString()   ?? '↑',
      severity:    json['severity']?.toString()    ?? 'medium',
    );
  }
}

// ── DiseaseInfo ───────────────────────────────────────────────────────────────

class DiseaseInfo {
  final String label;
  final String description;
  final List<String> symptoms;

  const DiseaseInfo({
    required this.label,
    required this.description,
    required this.symptoms,
  });

  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    return DiseaseInfo(
      label:       json['label']?.toString()       ?? '',
      description: json['description']?.toString() ?? '',
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

// ── DiagnosisExplanation ──────────────────────────────────────────────────────

class DiagnosisExplanation {
  final String summary;
  final String recommendation;
  final double anomalyScorePct;
  final SensorSnapshot sensorReadings;
  final List<DiagnosisTrigger> triggers;
  final DiseaseInfo diseaseInfo;

  const DiagnosisExplanation({
    required this.summary,
    required this.recommendation,
    required this.anomalyScorePct,
    required this.sensorReadings,
    required this.triggers,
    required this.diseaseInfo,
  });

  factory DiagnosisExplanation.fromJson(Map<String, dynamic> json) {
    final sensorJson = json['sensorReadings'] ?? json['sensor_readings'];
    final diseaseJson = json['diseaseInfo'] ?? json['disease_info'];
    final anomaly = json['anomalyScorePct'] ?? json['anomaly_score_pct'];
    return DiagnosisExplanation(
      summary:         json['summary']?.toString()         ?? '',
      recommendation:  json['recommendation']?.toString()  ?? '',
      anomalyScorePct: (anomaly as num?)?.toDouble() ?? 0.0,
      sensorReadings: sensorJson != null
          ? SensorSnapshot.fromJson(sensorJson as Map<String, dynamic>)
          : const SensorSnapshot(
              temperature: 38.5, heartRate: 70, activityScore: 60,
              lyingPct6h: 45, accAsymmetry: 0.05,
              deltaTemp: 0, deltaHr: 0, activityDrop: 0,
            ),
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => DiagnosisTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      diseaseInfo: diseaseJson != null
          ? DiseaseInfo.fromJson(diseaseJson as Map<String, dynamic>)
          : const DiseaseInfo(label: '', description: '', symptoms: []),
    );
  }
}

// ── DiagnosisResult ───────────────────────────────────────────────────────────

class DiagnosisResult {
  final String animalId;
  final double healthScore;
  final String alertLevel;       // 'healthy' | 'medium' | 'critical'
  final String? predictedDisease;
  final double confidence;
  final double isoScore;
  final bool isStaticFallback;
  final bool bovineModelApplied;
  final String? speciesNote;
  final double? anomalyScoreNorm;
  final Map<String, double> allProbabilities;
  final DiagnosisExplanation? explanation;
  final DateTime timestamp;

  const DiagnosisResult({
    required this.animalId,
    required this.healthScore,
    required this.alertLevel,
    this.predictedDisease,
    required this.confidence,
    required this.isoScore,
    required this.isStaticFallback,
    this.bovineModelApplied = true,
    this.speciesNote,
    this.anomalyScoreNorm,
    required this.allProbabilities,
    this.explanation,
    required this.timestamp,
  });

  /// Risk score in [0, 1] — derived from healthScore (100 = no risk → 0.0, 0 = max risk → 1.0).
  double get riskScore => (1.0 - (healthScore / 100.0)).clamp(0.0, 1.0);

  static double _clampHealthScore(double score) => score.clamp(0.0, 100.0);

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    // Parse allProbabilities — values may come as int or double
    final rawProbs = json['allProbabilities'] ?? json['all_probabilities'];
    final probMap = rawProbs is Map<String, dynamic>
        ? rawProbs
        : <String, dynamic>{};
    final probs = probMap.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    final rawAlert =
        json['alertLevel']?.toString() ?? json['alert_level']?.toString() ?? 'healthy';
    final alertLevel =
        rawAlert == 'low' ? 'healthy' : rawAlert;

    final anomalyNorm = json['anomalyScoreNorm'] ?? json['anomaly_score_norm'];

    return DiagnosisResult(
      animalId:
          json['animalId']?.toString() ?? json['animal_id']?.toString() ?? '',
      healthScore: _clampHealthScore(
        ((json['healthScore'] ?? json['health_score']) as num?)?.toDouble() ??
            100.0,
      ),
      alertLevel: alertLevel,
      predictedDisease: json['predictedDisease']?.toString() ??
          json['predicted_disease']?.toString(),
      confidence:
          (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isoScore:
          ((json['isoScore'] ?? json['iso_score']) as num?)?.toDouble() ?? 0.0,
      isStaticFallback:
          json['isStaticFallback'] as bool? ??
              json['is_static_fallback'] as bool? ??
              false,
      bovineModelApplied:
          json['bovineModelApplied'] as bool? ??
              json['bovine_model_applied'] as bool? ??
              true,
      speciesNote: json['speciesNote']?.toString() ??
          json['species_note']?.toString(),
      anomalyScoreNorm: (anomalyNorm as num?)?.toDouble(),
      allProbabilities: probs,
      explanation: json['explanation'] != null
          ? DiagnosisExplanation.fromJson(
              json['explanation'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ── HealthAlert ───────────────────────────────────────────────────────────────

class HealthAlert {
  final String id;
  final String animalId;
  final String animalName;
  final String alertLevel;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const HealthAlert({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.alertLevel,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory HealthAlert.fromJson(Map<String, dynamic> json) {
    return HealthAlert(
      id:          json['id']?.toString()         ?? '',
      animalId:    json['animalId']?.toString()   ?? '',
      animalName:  json['animalName']?.toString() ?? '',
      alertLevel:  json['alertLevel']?.toString() ?? 'healthy',
      message:     json['message']?.toString()    ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
