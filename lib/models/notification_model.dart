import 'package:flutter/material.dart';

enum NotificationType {
  security,
  vaccine,
  health,
  system,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final Map<String, dynamic>? data;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.data,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.security:
        return Icons.security_rounded;
      case NotificationType.vaccine:
        return Icons.vaccines_rounded;
      case NotificationType.health:
        return Icons.health_and_safety_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.security:
        return const Color(0xFFEF4444); // Red
      case NotificationType.vaccine:
        return const Color(0xFF3B82F6); // Blue
      case NotificationType.health:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.system:
        return const Color(0xFF64748B); // Slate
    }
  }
}
