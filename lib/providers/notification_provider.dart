import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/security_incident.dart';
import '../models/vaccine_models.dart';
import '../services/api_service.dart';
import '../services/vaccine_service.dart';

class NotificationProvider extends ChangeNotifier {
  final VaccineService _vaccineService = VaccineService();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchAllNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch Security Incidents
      final dynamic incidentData = await ApiService.get('/security/incidents', withAuth: true);
      final List<SecurityIncident> incidents = (incidentData as List)
          .map((json) => SecurityIncident.fromJson(json))
          .toList();

      // 2. Fetch Vaccine Schedules (Upcoming & Overdue)
      final List<VaccineSchedule> vaccineSchedules = await _vaccineService.getGlobalSchedules();

      // 3. Fetch Soil Weather Alerts (all parcels)
      List<dynamic> soilAlerts = [];
      try {
        final dynamic soilData = await ApiService.get('/soil-intelligence/alerts', withAuth: true);
        soilAlerts = soilData as List? ?? [];
      } catch (_) {
        // Non-fatal: soil alerts unavailable
      }

      // 4. Convert and Merge
      final List<AppNotification> combined = [];

      // Add Incidents
      for (var incident in incidents) {
        combined.add(AppNotification(
          id: 'incident_${incident.id}',
          title: incident.type == 'intruder' ? 'Security Alert: Intruder' : 'Security Alert: Animal Detected',
          body: 'Detected at ${incident.timestamp.hour}:${incident.timestamp.minute.toString().padLeft(2, '0')}',
          timestamp: incident.timestamp,
          type: NotificationType.security,
          data: incident.toJson(),
        ));
      }

      // Add Vaccine Reminders
      for (var schedule in vaccineSchedules) {
        if (schedule.isDone || schedule.status == 'CANCELLED') continue;

        String title = 'Vaccination Due';
        String body = '${schedule.animal?['name'] ?? 'Animal'} needs ${schedule.vaccine?.nameEn ?? 'vaccination'}';
        
        if (schedule.isOverdue) {
          title = '⚠️ Vaccine Overdue';
        } else if (schedule.isUrgent) {
          title = '🔔 Vaccine Reminder';
        }

        combined.add(AppNotification(
          id: 'vaccine_${schedule.id}',
          title: title,
          body: body,
          timestamp: schedule.scheduledDate,
          type: NotificationType.vaccine,
          data: schedule.toJson(),
        ));
      }

      // Add Soil Weather Alerts
      for (var alert in soilAlerts) {
        final map = alert as Map<String, dynamic>;
        final alertType = (map['type'] as String? ?? '').toLowerCase();
        final severity = (map['severity'] as String? ?? 'LOW').toUpperCase();

        String title;
        if (alertType == 'rain_incoming') {
          title = severity == 'HIGH'
              ? '🌧️ Heavy Rain Warning'
              : severity == 'MEDIUM'
                  ? '🌦️ Rain Incoming'
                  : '🌂 Light Rain Forecast';
        } else {
          title = 'Soil Alert: ${_formatAlertType(alertType)}';
        }

        DateTime timestamp;
        try {
          timestamp = DateTime.parse(map['triggered_at'] as String);
        } catch (_) {
          timestamp = DateTime.now();
        }

        combined.add(AppNotification(
          id: 'soil_${map['id']}',
          title: title,
          body: map['message'] as String? ?? 'Soil/weather condition detected',
          timestamp: timestamp,
          type: NotificationType.soil,
          data: map,
          isRead: map['is_read'] as bool? ?? false,
        ));
      }

      // 5. Sort by timestamp (newest first)
      combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _notifications = combined;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  String _formatAlertType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w)
        .join(' ');
  }
}
