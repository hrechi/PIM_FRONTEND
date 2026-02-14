import 'dart:math';

/// pH Status enum
enum PhStatus {
  acidic,
  neutral,
  alkaline,
}

/// Moisture Status enum
enum MoistureStatus {
  dry,
  optimal,
  wet,
}

/// Data model representing a soil measurement
/// Contains all environmental and soil parameters for a specific location
class SoilMeasurement {
  final String id;
  final double ph;
  final double soilMoisture; // percentage 0-100
  final double sunlight; // lux
  final Map<String, dynamic> nutrients; // e.g., {'nitrogen': 20, 'phosphorus': 15, 'potassium': 25}
  final double temperature; // Celsius
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SoilMeasurement({
    required this.id,
    required this.ph,
    required this.soilMoisture,
    required this.sunlight,
    required this.nutrients,
    required this.temperature,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get pH status: Acidic, Neutral, or Alkaline
  String get phStatus {
    if (ph < 6.0) return 'Acidic';
    if (ph > 7.5) return 'Alkaline';
    return 'Neutral';
  }

  /// Get pH status color
  PhStatus get phStatusEnum {
    if (ph < 6.0) return PhStatus.acidic;
    if (ph > 7.5) return PhStatus.alkaline;
    return PhStatus.neutral;
  }

  /// Get soil moisture status: Dry, Optimal, or Wet
  String get moistureStatus {
    if (soilMoisture < 30) return 'Dry';
    if (soilMoisture > 80) return 'Wet';
    return 'Optimal';
  }

  /// Get moisture status enum
  MoistureStatus get moistureStatusEnum {
    if (soilMoisture < 30) return MoistureStatus.dry;
    if (soilMoisture > 80) return MoistureStatus.wet;
    return MoistureStatus.optimal;
  }

  /// Check if measurement is healthy
  bool get isHealthy {
    return ph >= 6.0 &&
        ph <= 7.5 &&
        soilMoisture >= 30 &&
        soilMoisture <= 80 &&
        temperature >= 15 &&
        temperature <= 30;
  }

  /// Get overall health score (0-100)
  double get healthScore {
    double phScore = (ph >= 6.0 && ph <= 7.5) ? 100 : 50;
    double moistureScore = (soilMoisture >= 30 && soilMoisture <= 80) ? 100 : 50;
    double tempScore = (temperature >= 15 && temperature <= 30) ? 100 : 50;
    return (phScore + moistureScore + tempScore) / 3;
  }

  /// Format nutrients as string
  String get nutrientsString {
    return nutrients.entries.map((e) => '${e.key}: ${e.value}%').join(', ');
  }

  /// Get formatted date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// Get formatted time
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date and time
  String get formattedDateTime {
    return '$formattedDate at $formattedTime';
  }

  /// Copy with method
  SoilMeasurement copyWith({
    String? id,
    double? ph,
    double? soilMoisture,
    double? sunlight,
    Map<String, dynamic>? nutrients,
    double? temperature,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoilMeasurement(
      id: id ?? this.id,
      ph: ph ?? this.ph,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      sunlight: sunlight ?? this.sunlight,
      nutrients: nutrients ?? this.nutrients,
      temperature: temperature ?? this.temperature,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ph': ph,
      'soilMoisture': soilMoisture,
      'sunlight': sunlight,
      'nutrients': nutrients,
      'temperature': temperature,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (backend API response)
  factory SoilMeasurement.fromJson(Map<String, dynamic> json) {
    return SoilMeasurement(
      id: json['id'] as String,
      ph: (json['ph'] as num).toDouble(),
      soilMoisture: (json['soilMoisture'] as num).toDouble(),
      sunlight: (json['sunlight'] as num).toDouble(),
      nutrients: Map<String, dynamic>.from(json['nutrients'] as Map),
      temperature: (json['temperature'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Generate mock data for testing (deprecated - use API instead)
  @Deprecated('Use API instead')
  static List<SoilMeasurement> getMockData() {
    final random = Random();
    final now = DateTime.now();

    return List.generate(15, (index) {
      final createdAt = now.subtract(Duration(days: index * 2, hours: random.nextInt(24)));
      return SoilMeasurement(
        id: 'SM-${(1000 + index).toString()}',
        ph: 5.5 + random.nextDouble() * 3.0, // 5.5 to 8.5
        soilMoisture: 20.0 + random.nextDouble() * 70.0, // 20 to 90
        sunlight: 2000.0 + random.nextDouble() * 8000.0, // 2000 to 10000 lux
        nutrients: {
          'nitrogen': 10.0 + random.nextDouble() * 40.0,
          'phosphorus': 5.0 + random.nextDouble() * 30.0,
          'potassium': 10.0 + random.nextDouble() * 40.0,
        },
        temperature: 15.0 + random.nextDouble() * 20.0, // 15 to 35°C
        latitude: 37.7749 + (random.nextDouble() - 0.5) * 0.1,
        longitude: -122.4194 + (random.nextDouble() - 0.5) * 0.1,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    });
  }

  /// Generate historical data for charts (13 weeks)
  static List<SoilMeasurement> getHistoricalData() {
    final random = Random();
    final now = DateTime.now();

    return List.generate(13, (index) {
      final weeksAgo = 12 - index;
      final createdAt = now.subtract(Duration(days: weeksAgo * 7));
      return SoilMeasurement(
        id: 'SM-HIST-$index',
        ph: 6.5 + (random.nextDouble() - 0.5) * 1.5, // 5.75 to 7.25
        soilMoisture: 50.0 + (random.nextDouble() - 0.5) * 40.0, // 30 to 70
        sunlight: 5000.0 + (random.nextDouble() - 0.5) * 4000.0, // 3000 to 7000
        nutrients: {
          'nitrogen': 25.0 + (random.nextDouble() - 0.5) * 20.0,
          'phosphorus': 15.0 + (random.nextDouble() - 0.5) * 15.0,
          'potassium': 30.0 + (random.nextDouble() - 0.5) * 20.0,
        },
        temperature: 22.0 + (random.nextDouble() - 0.5) * 10.0,
        latitude: 37.7749,
        longitude: -122.4194,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    });
  }

  /// Generate specific measurement
  factory SoilMeasurement.generate({
    required String id,
    double? ph,
    double? soilMoisture,
    double? sunlight,
    Map<String, dynamic>? nutrients,
    double? temperature,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final random = Random();
    final created = createdAt ?? DateTime.now();
    return SoilMeasurement(
      id: id,
      ph: ph ?? 6.5 + (random.nextDouble() - 0.5) * 2.0,
      soilMoisture: soilMoisture ?? 50.0 + (random.nextDouble() - 0.5) * 40.0,
      sunlight: sunlight ?? 5000.0 + random.nextDouble() * 3000.0,
      nutrients: nutrients ??
          {
            'nitrogen': 20.0 + random.nextDouble() * 30.0,
            'phosphorus': 10.0 + random.nextDouble() * 25.0,
            'potassium': 20.0 + random.nextDouble() * 30.0,
          },
      temperature: temperature ?? 20.0 + random.nextDouble() * 10.0,
      latitude: latitude ?? 37.7749,
      longitude: longitude ?? -122.4194,
      createdAt: created,
      updatedAt: updatedAt ?? created,
    );
  }
}
