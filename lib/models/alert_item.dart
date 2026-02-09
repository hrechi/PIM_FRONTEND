/// Data model representing an alert or notification in the farm system
/// Used for tracking issues that require attention
class AlertItem {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertType type;
  final DateTime timestamp;
  final String? relatedEntityId; // ID of related animal, sensor, etc.
  final bool isRead;
  final bool isResolved;

  const AlertItem({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.type,
    required this.timestamp,
    this.relatedEntityId,
    this.isRead = false,
    this.isResolved = false,
  });

  /// Get time elapsed since the alert was created
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Mock data generator for testing
  static List<AlertItem> getMockData() {
    return [
      AlertItem(
        id: 'alert-001',
        title: 'Elevated Temperature',
        description: 'Cow #102 – elevated temperature (39.2°C)',
        severity: AlertSeverity.warning,
        type: AlertType.health,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        relatedEntityId: 'COW-102',
        isRead: false,
        isResolved: false,
      ),
      AlertItem(
        id: 'alert-002',
        title: 'Low Soil Moisture',
        description: 'Sheep #45 – low soil moisture in grazing area (32%)',
        severity: AlertSeverity.warning,
        type: AlertType.environment,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        relatedEntityId: 'SHEEP-45',
        isRead: false,
        isResolved: false,
      ),
      AlertItem(
        id: 'alert-003',
        title: 'Sensor Battery Low',
        description: 'Temperature sensor #12 battery at 15%',
        severity: AlertSeverity.info,
        type: AlertType.system,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        relatedEntityId: 'SENSOR-12',
        isRead: true,
        isResolved: false,
      ),
      AlertItem(
        id: 'alert-004',
        title: 'Irregular Heartbeat',
        description: 'Cow #087 showing irregular heartbeat pattern',
        severity: AlertSeverity.critical,
        type: AlertType.health,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        relatedEntityId: 'COW-087',
        isRead: false,
        isResolved: false,
      ),
    ];
  }

  /// Get alerts that require immediate attention (unresolved and critical/warning)
  static List<AlertItem> getAttentionRequired(List<AlertItem> alerts) {
    return alerts
        .where((alert) =>
            !alert.isResolved &&
            (alert.severity == AlertSeverity.critical ||
                alert.severity == AlertSeverity.warning))
        .toList();
  }

  /// Copy with method for updating specific fields
  AlertItem copyWith({
    String? id,
    String? title,
    String? description,
    AlertSeverity? severity,
    AlertType? type,
    DateTime? timestamp,
    String? relatedEntityId,
    bool? isRead,
    bool? isResolved,
  }) {
    return AlertItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

/// Severity levels for alerts
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// Types of alerts in the system
enum AlertType {
  health, // Animal health related
  environment, // Soil, weather, environmental
  system, // Technical/sensor issues
  security, // Security and access issues
}
