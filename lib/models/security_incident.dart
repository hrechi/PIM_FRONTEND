class SecurityIncident {
  final String id;
  final String type; // 'intruder' or 'animal'
  final String imagePath;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  SecurityIncident({
    required this.id,
    required this.type,
    required this.imagePath,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  factory SecurityIncident.fromJson(Map<String, dynamic> json) {
    return SecurityIncident(
      id: json['id'],
      type: json['type'],
      imagePath: json['imagePath'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}
