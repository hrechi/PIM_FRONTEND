/// AI Prediction Model
/// Represents the wilting risk prediction from the AI service

/// Risk level enum
enum RiskLevel {
  low,
  medium,
  high;

  /// Get display name
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }

  /// Get color based on risk level
  int get color {
    switch (this) {
      case RiskLevel.low:
        return 0xFF4CAF50; // Green
      case RiskLevel.medium:
        return 0xFFFF9800; // Orange
      case RiskLevel.high:
        return 0xFFF44336; // Red
    }
  }

  /// Get icon based on risk level
  String get icon {
    switch (this) {
      case RiskLevel.low:
        return '✅';
      case RiskLevel.medium:
        return '⚠️';
      case RiskLevel.high:
        return '🚨';
    }
  }

  /// Parse from string
  static RiskLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      default:
        return RiskLevel.medium;
    }
  }
}

/// AI Prediction model
class AiPrediction {
  final String measurementId;
  final double wiltingScore; // 0-100
  final RiskLevel riskLevel;
  final MeasurementData measurementData;

  const AiPrediction({
    required this.measurementId,
    required this.wiltingScore,
    required this.riskLevel,
    required this.measurementData,
  });

  /// Get percentage (0-1)
  double get scorePercentage => wiltingScore / 100;

  /// Get recommendations based on risk level
  List<String> get recommendations {
    switch (riskLevel) {
      case RiskLevel.low:
        return [
          '✅ Soil conditions are optimal',
          '✅ Continue current care routine',
          '✅ Maintain irrigation schedule',
          '💧 No immediate action needed',
        ];
      case RiskLevel.medium:
        return [
          '⚠️ Monitor soil moisture closely',
          '⚠️ Consider adjusting irrigation',
          '⚠️ Check temperature trends',
          '📊 Increase monitoring frequency',
          if (measurementData.soilMoisture < 0.25)
            '💧 Increase watering schedule',
          if (measurementData.temperature > 28)
            '🌡️ Consider shade during peak heat',
        ];
      case RiskLevel.high:
        return [
          '🚨 Immediate action required',
          '💧 Increase irrigation immediately',
          if (measurementData.temperature > 30)
            '🌡️ Provide shade or cooling',
          if (measurementData.ph < 6.0 || measurementData.ph > 7.5)
            '🧪 Adjust pH to 6.0-7.5 range',
          if (measurementData.soilMoisture < 0.20)
            '💦 Critical: Soil is too dry',
          '📞 Consider expert consultation',
        ];
    }
  }

  /// Get action priority
  String get actionPriority {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'No action needed';
      case RiskLevel.medium:
        return 'Monitor within 24 hours';
      case RiskLevel.high:
        return 'Take action immediately';
    }
  }

  /// From JSON
  factory AiPrediction.fromJson(Map<String, dynamic> json) {
    return AiPrediction(
      measurementId: json['measurementId'] as String,
      wiltingScore: (json['wilting_score'] as num).toDouble(),
      riskLevel: RiskLevel.fromString(json['risk_level'] as String),
      measurementData: MeasurementData.fromJson(
        json['measurement_data'] as Map<String, dynamic>,
      ),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'measurementId': measurementId,
      'wilting_score': wiltingScore,
      'risk_level': riskLevel.displayName,
      'measurement_data': measurementData.toJson(),
    };
  }
}

/// Measurement data from AI response
class MeasurementData {
  final double ph;
  final double soilMoisture;
  final double temperature;
  final double sunlight;
  final LocationData location;
  final DateTime measuredAt;

  const MeasurementData({
    required this.ph,
    required this.soilMoisture,
    required this.temperature,
    required this.sunlight,
    required this.location,
    required this.measuredAt,
  });

  factory MeasurementData.fromJson(Map<String, dynamic> json) {
    return MeasurementData(
      ph: (json['ph'] as num).toDouble(),
      soilMoisture: (json['soil_moisture'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      sunlight: (json['sunlight'] as num).toDouble(),
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      measuredAt: DateTime.parse(json['measured_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ph': ph,
      'soil_moisture': soilMoisture,
      'temperature': temperature,
      'sunlight': sunlight,
      'location': location.toJson(),
      'measured_at': measuredAt.toIso8601String(),
    };
  }
}

/// Location data
class LocationData {
  final double latitude;
  final double longitude;

  const LocationData({
    required this.latitude,
    required this.longitude,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
