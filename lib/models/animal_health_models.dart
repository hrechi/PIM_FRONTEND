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
      temperature:   (json['temperature']   as num?)?.toDouble() ?? 38.5,
      heartRate:     (json['heartRate']     as num?)?.toDouble() ?? 70.0,
      activityScore: (json['activityScore'] as num?)?.toDouble() ?? 60.0,
      lyingPct6h:    (json['lyingPct6h']    as num?)?.toDouble() ?? 45.0,
      accAsymmetry:  (json['accAsymmetry']  as num?)?.toDouble() ?? 0.05,
      deltaTemp:     (json['deltaTemp']     as num?)?.toDouble() ?? 0.0,
      deltaHr:       (json['deltaHr']       as num?)?.toDouble() ?? 0.0,
      activityDrop:  (json['activityDrop']  as num?)?.toDouble() ?? 0.0,
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
      normalRange: json['normalRange']?.toString() ?? '',
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
    return DiagnosisExplanation(
      summary:         json['summary']?.toString()         ?? '',
      recommendation:  json['recommendation']?.toString()  ?? '',
      anomalyScorePct: (json['anomalyScorePct'] as num?)?.toDouble() ?? 0.0,
      sensorReadings: json['sensorReadings'] != null
          ? SensorSnapshot.fromJson(json['sensorReadings'] as Map<String, dynamic>)
          : const SensorSnapshot(
              temperature: 38.5, heartRate: 70, activityScore: 60,
              lyingPct6h: 45, accAsymmetry: 0.05,
              deltaTemp: 0, deltaHr: 0, activityDrop: 0,
            ),
      triggers: (json['triggers'] as List<dynamic>?)
              ?.map((e) => DiagnosisTrigger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      diseaseInfo: json['diseaseInfo'] != null
          ? DiseaseInfo.fromJson(json['diseaseInfo'] as Map<String, dynamic>)
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
    required this.allProbabilities,
    this.explanation,
    required this.timestamp,
  });

  /// Risk score in [0, 1] — derived from healthScore (100 = no risk → 0.0, 0 = max risk → 1.0).
  double get riskScore => (1.0 - (healthScore / 100.0)).clamp(0.0, 1.0);

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    // Parse allProbabilities — values may come as int or double
    final rawProbs = json['allProbabilities'] as Map<String, dynamic>? ?? {};
    final probs = rawProbs.map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );

    return DiagnosisResult(
      animalId:        json['animalId']?.toString()        ?? '',
      healthScore:     (json['healthScore'] as num?)?.toDouble() ?? 100.0,
      alertLevel:      json['alertLevel']?.toString()      ?? 'healthy',
      predictedDisease: json['predictedDisease']?.toString(),
      confidence:      (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isoScore:        (json['isoScore'] as num?)?.toDouble() ?? 0.0,
      isStaticFallback: json['isStaticFallback'] as bool? ?? false,
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
