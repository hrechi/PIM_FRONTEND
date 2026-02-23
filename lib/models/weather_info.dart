/// Data model representing weather and soil conditions
/// Used for displaying environmental monitoring data
class WeatherInfo {
  final double temperature; // in Celsius
  final String condition; // e.g., "Partly Cloudy", "Sunny", "Rainy"
  final int humidity; // percentage
  final double soilMoisture; // percentage
  final double windSpeed; // in km/h
  final String windDirection; // e.g., "N", "NE", "E", etc.
  final int uvIndex;
  final double precipitation; // in mm
  final DateTime lastUpdated;
  final String location;
  final String? icon; // emoji icon from API

  const WeatherInfo({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.soilMoisture,
    required this.windSpeed,
    required this.windDirection,
    required this.uvIndex,
    required this.precipitation,
    required this.lastUpdated,
    required this.location,
    this.icon,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temperature: (json['temperature'] as num).toDouble(),
      condition: json['condition'] as String? ?? 'Unknown',
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
      soilMoisture: 0.0, // soil moisture comes from a different source
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0.0,
      windDirection: json['windDirection'] as String? ?? '',
      uvIndex: (json['uvIndex'] as num?)?.toInt() ?? 0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      location: json['location'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  /// Get formatted temperature with unit
  String get formattedTemperature => '${temperature.toStringAsFixed(0)}°C';

  /// Get formatted soil moisture with unit
  String get formattedSoilMoisture => '${soilMoisture.toStringAsFixed(0)}%';

  /// Get formatted humidity with unit
  String get formattedHumidity => '$humidity%';

  /// Get formatted wind speed with unit
  String get formattedWindSpeed => '${windSpeed.toStringAsFixed(1)} km/h';

  /// Get formatted precipitation with unit
  String get formattedPrecipitation => '${precipitation.toStringAsFixed(1)} mm';

  /// Get weather icon — uses API-provided emoji or falls back to condition mapping
  String get weatherIcon {
    if (icon != null && icon!.isNotEmpty) return icon!;
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
      case 'clear sky':
        return '☀️';
      case 'mainly clear':
        return '🌤️';
      case 'partly cloudy':
      case 'partly sunny':
        return '⛅';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'rainy':
      case 'rain':
      case 'slight rain':
      case 'moderate rain':
      case 'heavy rain':
        return '🌧️';
      case 'stormy':
      case 'thunderstorm':
        return '⛈️';
      case 'snowy':
      case 'snow':
        return '❄️';
      case 'foggy':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  /// Check if soil moisture is at healthy level
  bool get isSoilMoistureHealthy => soilMoisture >= 40 && soilMoisture <= 80;

  /// Check if soil moisture is low
  bool get isSoilMoistureLow => soilMoisture < 40;

  /// Check if soil moisture is high
  bool get isSoilMoistureHigh => soilMoisture > 80;

  /// Get soil moisture status
  String get soilMoistureStatus {
    if (isSoilMoistureLow) return 'Low';
    if (isSoilMoistureHigh) return 'High';
    return 'Optimal';
  }

  /// Check if temperature is suitable for farming activities
  bool get isFarmingWeather =>
      temperature >= 15 &&
      temperature <= 30 &&
      !condition.toLowerCase().contains('storm');

  /// Mock data generator for testing
  static WeatherInfo getMockData() {
    return WeatherInfo(
      temperature: 24.0,
      condition: 'Partly Cloudy',
      humidity: 68,
      soilMoisture: 65.0,
      windSpeed: 12.5,
      windDirection: 'NE',
      uvIndex: 6,
      precipitation: 0.0,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 10)),
      location: 'Farm Location',
    );
  }

  /// Generate multiple weather scenarios for testing
  static List<WeatherInfo> getMockScenarios() {
    return [
      WeatherInfo(
        temperature: 24.0,
        condition: 'Partly Cloudy',
        humidity: 68,
        soilMoisture: 65.0,
        windSpeed: 12.5,
        windDirection: 'NE',
        uvIndex: 6,
        precipitation: 0.0,
        lastUpdated: DateTime.now(),
        location: 'Farm Location',
      ),
      WeatherInfo(
        temperature: 18.0,
        condition: 'Rainy',
        humidity: 85,
        soilMoisture: 78.0,
        windSpeed: 18.0,
        windDirection: 'W',
        uvIndex: 2,
        precipitation: 12.5,
        lastUpdated: DateTime.now(),
        location: 'Farm Location',
      ),
      WeatherInfo(
        temperature: 29.0,
        condition: 'Sunny',
        humidity: 45,
        soilMoisture: 35.0,
        windSpeed: 8.0,
        windDirection: 'S',
        uvIndex: 9,
        precipitation: 0.0,
        lastUpdated: DateTime.now(),
        location: 'Farm Location',
      ),
    ];
  }

  /// Copy with method for updating specific fields
  WeatherInfo copyWith({
    double? temperature,
    String? condition,
    int? humidity,
    double? soilMoisture,
    double? windSpeed,
    String? windDirection,
    int? uvIndex,
    double? precipitation,
    DateTime? lastUpdated,
    String? location,
    String? icon,
  }) {
    return WeatherInfo(
      temperature: temperature ?? this.temperature,
      condition: condition ?? this.condition,
      humidity: humidity ?? this.humidity,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      uvIndex: uvIndex ?? this.uvIndex,
      precipitation: precipitation ?? this.precipitation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      location: location ?? this.location,
      icon: icon ?? this.icon,
    );
  }
}

// ─────────────────────────────────────────────
// DAILY FORECAST
// ─────────────────────────────────────────────

/// Represents one day in the 7-day forecast
class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final String condition;
  final String icon;
  final double precipitation;
  final double windSpeed;
  final int humidity;

  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.condition,
    required this.icon,
    required this.precipitation,
    required this.windSpeed,
    required this.humidity,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: DateTime.parse(json['date'] as String),
      tempMax: (json['tempMax'] as num).toDouble(),
      tempMin: (json['tempMin'] as num).toDouble(),
      condition: json['condition'] as String? ?? 'Unknown',
      icon: json['icon'] as String? ?? '🌡️',
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toInt() ?? 0,
    );
  }

  /// Get day label ("Today", "Tomorrow", or weekday name)
  String get dayLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDate = DateTime(date.year, date.month, date.day);

    if (thisDate == today) return 'Today';
    if (thisDate == today.add(const Duration(days: 1))) return 'Tomorrow';

    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return weekdays[date.weekday - 1];
  }
}

// ─────────────────────────────────────────────
// WEATHER FORECAST RESPONSE (full API response)
// ─────────────────────────────────────────────

class WeatherForecastResponse {
  final WeatherInfo current;
  final List<DailyForecast> daily;
  final String? fieldName;
  final String? fieldId;
  final String? cropType;

  const WeatherForecastResponse({
    required this.current,
    required this.daily,
    this.fieldName,
    this.fieldId,
    this.cropType,
  });

  factory WeatherForecastResponse.fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as List<dynamic>;
    final fieldJson = json['field'] as Map<String, dynamic>?;

    return WeatherForecastResponse(
      current: WeatherInfo.fromJson(currentJson),
      daily: dailyJson
          .map((d) => DailyForecast.fromJson(d as Map<String, dynamic>))
          .toList(),
      fieldName: fieldJson?['name'] as String?,
      fieldId: fieldJson?['id'] as String?,
      cropType: fieldJson?['cropType'] as String?,
    );
  }
}

// ─────────────────────────────────────────────
// RECOMMENDATION RESPONSE
// ─────────────────────────────────────────────

class RecommendationResponse {
  final String summary;
  final List<String> recommendations;
  final List<String> riskAlerts;
  final bool shouldHarvest;
  final bool shouldPlant;
  final String irrigationAdvice;

  const RecommendationResponse({
    required this.summary,
    required this.recommendations,
    required this.riskAlerts,
    required this.shouldHarvest,
    required this.shouldPlant,
    required this.irrigationAdvice,
  });

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) {
    final recsJson = json['recommendations'] as Map<String, dynamic>;
    return RecommendationResponse(
      summary: recsJson['summary'] as String? ?? '',
      recommendations: (recsJson['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      riskAlerts: (recsJson['riskAlerts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      shouldHarvest: recsJson['shouldHarvest'] as bool? ?? false,
      shouldPlant: recsJson['shouldPlant'] as bool? ?? false,
      irrigationAdvice:
          recsJson['irrigationAdvice'] as String? ?? 'No specific advice.',
    );
  }
}
