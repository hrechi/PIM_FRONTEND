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
  });

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

  /// Get weather icon name based on condition
  String get weatherIcon {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return '☀️';
      case 'partly cloudy':
      case 'partly sunny':
        return '⛅';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'rainy':
      case 'rain':
        return '🌧️';
      case 'stormy':
      case 'thunderstorm':
        return '⛈️';
      case 'snowy':
      case 'snow':
        return '❄️';
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
    );
  }
}
