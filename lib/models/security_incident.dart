class SecurityIncident {
  final String id;
  final String type; // 'intruder' or 'animal'
  final String imagePath;
  final DateTime timestamp;

  SecurityIncident({
    required this.id,
    required this.type,
    required this.imagePath,
    required this.timestamp,
  });

  factory SecurityIncident.fromJson(Map<String, dynamic> json) {
    return SecurityIncident(
      id: json['id'],
      type: json['type'],
      imagePath: json['imagePath'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
