class SensorHistory {
  final AnimalInfo animal;
  final PeriodInfo period;
  final List<SensorDataPoint> data;
  final List<AlertZone> alertZones;
  final SensorSummary summary;

  SensorHistory({
    required this.animal,
    required this.period,
    required this.data,
    required this.alertZones,
    required this.summary,
  });

  factory SensorHistory.fromJson(Map<String, dynamic> json) {
    return SensorHistory(
      animal: AnimalInfo.fromJson(json['animal']),
      period: PeriodInfo.fromJson(json['period']),
      data: (json['data'] as List)
          .map((e) => SensorDataPoint.fromJson(e))
          .toList(),
      alertZones: (json['alertZones'] as List)
          .map((e) => AlertZone.fromJson(e))
          .toList(),
      summary: SensorSummary.fromJson(json['summary']),
    );
  }
}

class AnimalInfo {
  final String id;
  final String name;
  final String type;
  final String healthStatus;

  AnimalInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.healthStatus,
  });

  factory AnimalInfo.fromJson(Map<String, dynamic> json) {
    return AnimalInfo(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      healthStatus: json['healthStatus'],
    );
  }
}

class PeriodInfo {
  final int hours;
  final DateTime start;
  final DateTime end;

  PeriodInfo({
    required this.hours,
    required this.start,
    required this.end,
  });

  factory PeriodInfo.fromJson(Map<String, dynamic> json) {
    return PeriodInfo(
      hours: json['hours'],
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }
}

class SensorDataPoint {
  final DateTime timestamp;
  final MetricValue? temperature;
  final MetricValue? heartRate;
  final MetricValue? activity;
  final Accelerometer? accelerometer;
  final double lyingPercent;
  final int readingsCount;

  SensorDataPoint({
    required this.timestamp,
    this.temperature,
    this.heartRate,
    this.activity,
    this.accelerometer,
    required this.lyingPercent,
    required this.readingsCount,
  });

  factory SensorDataPoint.fromJson(Map<String, dynamic> json) {
    return SensorDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      temperature: json['temperature'] != null
          ? MetricValue.fromJson(json['temperature'])
          : null,
      heartRate: json['heartRate'] != null
          ? MetricValue.fromJson(json['heartRate'])
          : null,
      activity: json['activity'] != null
          ? MetricValue.fromJson(json['activity'])
          : null,
      accelerometer: json['accelerometer'] != null
          ? Accelerometer.fromJson(json['accelerometer'])
          : null,
      lyingPercent: (json['lyingPercent'] ?? 0).toDouble(),
      readingsCount: json['readingsCount'] ?? 0,
    );
  }
}

class MetricValue {
  final double? avg;
  final double? min;
  final double? max;

  MetricValue({this.avg, this.min, this.max});

  factory MetricValue.fromJson(Map<String, dynamic> json) {
    return MetricValue(
      avg: json['avg']?.toDouble(),
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
    );
  }
}

class Accelerometer {
  final double? x;
  final double? y;
  final double? z;

  Accelerometer({this.x, this.y, this.z});

  factory Accelerometer.fromJson(Map<String, dynamic> json) {
    return Accelerometer(
      x: json['x']?.toDouble(),
      y: json['y']?.toDouble(),
      z: json['z']?.toDouble(),
    );
  }
}

class AlertZone {
  final DateTime startTime;
  final DateTime endTime;
  final String level;
  final String? disease;
  final double? confidence;
  final double? anomalyScore;

  AlertZone({
    required this.startTime,
    required this.endTime,
    required this.level,
    this.disease,
    this.confidence,
    this.anomalyScore,
  });

  factory AlertZone.fromJson(Map<String, dynamic> json) {
    return AlertZone(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      level: json['level'],
      disease: json['disease'],
      confidence: json['confidence']?.toDouble(),
      anomalyScore: json['anomalyScore']?.toDouble(),
    );
  }
}

class SensorSummary {
  final int totalReadings;
  final int dataPoints;
  final int alertsCount;
  final double? avgTemperature;
  final double? avgHeartRate;
  final double? avgActivity;

  SensorSummary({
    required this.totalReadings,
    required this.dataPoints,
    required this.alertsCount,
    this.avgTemperature,
    this.avgHeartRate,
    this.avgActivity,
  });

  factory SensorSummary.fromJson(Map<String, dynamic> json) {
    return SensorSummary(
      totalReadings: json['totalReadings'] ?? 0,
      dataPoints: json['dataPoints'] ?? 0,
      alertsCount: json['alertsCount'] ?? 0,
      avgTemperature: json['avgTemperature']?.toDouble(),
      avgHeartRate: json['avgHeartRate']?.toDouble(),
      avgActivity: json['avgActivity']?.toDouble(),
    );
  }
}
