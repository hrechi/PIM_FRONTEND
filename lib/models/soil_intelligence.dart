import 'package:flutter/material.dart';

class SoilFingerprintMatch {
  final String id;
  final double similarityScore;
  final String parcelLocation;
  final String region;
  final String recoveryAction;
  final int recoveryDurationWeeks;
  final Map<String, dynamic> soilData;

  SoilFingerprintMatch({
    required this.id,
    required this.similarityScore,
    required this.parcelLocation,
    required this.region,
    required this.recoveryAction,
    required this.recoveryDurationWeeks,
    required this.soilData,
  });

  String get matchPercentage => '${(similarityScore * 100).toStringAsFixed(0)}%';

  Color get matchColor => similarityScore > 0.85
      ? Colors.green
      : similarityScore > 0.70
          ? Colors.orange
          : Colors.red;

  factory SoilFingerprintMatch.fromJson(Map<String, dynamic> json) {
    return SoilFingerprintMatch(
      id: (json['id'] ?? '').toString(),
      similarityScore: (json['similarity_score'] ?? json['similarityScore'] ?? 0) is num
          ? ((json['similarity_score'] ?? json['similarityScore'] ?? 0) as num).toDouble()
          : 0.0,
      parcelLocation: (json['parcel_location'] ?? json['parcelLocation'] ?? 'Unknown location').toString(),
      region: (json['region'] ?? 'Tunisia').toString(),
      recoveryAction: (json['recovery_action'] ?? json['recoveryAction'] ?? '').toString(),
      recoveryDurationWeeks:
          ((json['recovery_duration_weeks'] ?? json['recoveryDurationWeeks'] ?? 0) as num?)?.toInt() ?? 0,
      soilData: Map<String, dynamic>.from(json['soil_data'] ?? json['soilData'] ?? const {}),
    );
  }
}

class SoilWeatherAlert {
  final String id;
  final String parcelId;
  final String soilMeasurementId;
  final String type;
  final String severity;
  final String message;
  final String action;
  final DateTime triggeredAt;
  final bool isRead;
  final Map<String, dynamic> weatherData;
  final Map<String, dynamic> soilData;

  SoilWeatherAlert({
    required this.id,
    required this.parcelId,
    required this.soilMeasurementId,
    required this.type,
    required this.severity,
    required this.message,
    required this.action,
    required this.triggeredAt,
    required this.isRead,
    required this.weatherData,
    required this.soilData,
  });

  Color get backgroundColor {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFFFEBEE);
      case 'HIGH':
        return const Color(0xFFFFF3E0);
      case 'MEDIUM':
        return const Color(0xFFFFFDE7);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color get borderColor {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFF44336);
      case 'HIGH':
        return const Color(0xFFFF9800);
      case 'MEDIUM':
        return const Color(0xFFFFC107);
      default:
        return const Color(0xFF2196F3);
    }
  }

  String get alertIcon {
    switch (type) {
      case 'FLOOD_RISK':
        return '🌧️';
      case 'DROUGHT_RISK':
        return '🌵';
      case 'FROST_RISK':
        return '🥶';
      case 'HEAT_STRESS':
        return '🔥';
      default:
        return '⚠️';
    }
  }

  factory SoilWeatherAlert.fromJson(Map<String, dynamic> json) {
    final triggered = json['triggered_at'] ?? json['triggeredAt'];

    return SoilWeatherAlert(
      id: (json['id'] ?? '').toString(),
      parcelId: (json['parcel_id'] ?? json['parcelId'] ?? '').toString(),
      soilMeasurementId: (json['soil_measurement_id'] ?? json['soilMeasurementId'] ?? '').toString(),
      type: (json['type'] ?? json['alert_type'] ?? json['alertType'] ?? 'UNKNOWN').toString(),
      severity: (json['severity'] ?? 'LOW').toString(),
      message: (json['message'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      triggeredAt: triggered is String ? DateTime.tryParse(triggered) ?? DateTime.now() : DateTime.now(),
      isRead: (json['is_read'] ?? json['isRead'] ?? false) == true,
      weatherData: Map<String, dynamic>.from(json['weather_data'] ?? json['weatherData'] ?? const {}),
      soilData: Map<String, dynamic>.from(json['soil_data'] ?? json['soilData'] ?? const {}),
    );
  }
}
