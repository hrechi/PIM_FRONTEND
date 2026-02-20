/// Data model representing an animal in the farm
/// Used for tracking livestock health, location, and status
class Animal {
  final String id;
  final String name;
  final String type; // e.g., "Cow", "Sheep", "Goat"
  final double temperature; // in Celsius
  final int heartRate; // beats per minute
  final String status; // e.g., "Healthy", "Warning", "Critical"
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final DateTime lastUpdated;

  const Animal({
    required this.id,
    required this.name,
    required this.type,
    required this.temperature,
    required this.heartRate,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.lastUpdated,
  });

  /// Check if the animal's vitals are healthy
  bool get isHealthy => status == 'Healthy';

  /// Check if the animal requires attention
  bool get requiresAttention =>
      status == 'Warning' || status == 'Critical';

  /// Get formatted temperature with unit
  String get formattedTemperature => '${temperature.toStringAsFixed(1)}°C';

  /// Get formatted heart rate
  String get formattedHeartRate => '$heartRate BPM';

  /// Mock data generator for testing
  static List<Animal> getMockData() {
    return [
      Animal(
        id: 'COW-102',
        name: 'Cow #102',
        type: 'Cow',
        temperature: 39.2,
        heartRate: 78,
        status: 'Warning',
        latitude: 37.7749,
        longitude: -122.4194,
        imageUrl: null,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Animal(
        id: 'SHEEP-45',
        name: 'Sheep #45',
        type: 'Sheep',
        temperature: 39.5,
        heartRate: 82,
        status: 'Healthy',
        latitude: 37.7750,
        longitude: -122.4190,
        imageUrl: null,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Animal(
        id: 'COW-087',
        name: 'Cow #087',
        type: 'Cow',
        temperature: 38.8,
        heartRate: 72,
        status: 'Healthy',
        latitude: 37.7755,
        longitude: -122.4200,
        imageUrl: null,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      Animal(
        id: 'GOAT-23',
        name: 'Goat #23',
        type: 'Goat',
        temperature: 39.0,
        heartRate: 85,
        status: 'Healthy',
        latitude: 37.7748,
        longitude: -122.4198,
        imageUrl: null,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      Animal(
        id: 'SHEEP-67',
        name: 'Sheep #67',
        type: 'Sheep',
        temperature: 38.9,
        heartRate: 80,
        status: 'Healthy',
        latitude: 37.7752,
        longitude: -122.4195,
        imageUrl: null,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    ];
  }

  /// Copy with method for updating specific fields
  Animal copyWith({
    String? id,
    String? name,
    String? type,
    double? temperature,
    int? heartRate,
    String? status,
    double? latitude,
    double? longitude,
    String? imageUrl,
    DateTime? lastUpdated,
  }) {
    return Animal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
