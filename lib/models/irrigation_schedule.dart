/// Models for the Smart Irrigation Scheduler feature.

class DailyIrrigationPlan {
  final String date;
  final bool shouldIrrigate;
  final double waterAmountLiters;
  final String bestTimeOfDay;
  final int durationMinutes;
  final String reasoning;
  final String weatherSummary;

  DailyIrrigationPlan({
    required this.date,
    required this.shouldIrrigate,
    required this.waterAmountLiters,
    required this.bestTimeOfDay,
    required this.durationMinutes,
    required this.reasoning,
    required this.weatherSummary,
  });

  factory DailyIrrigationPlan.fromJson(Map<String, dynamic> json) {
    return DailyIrrigationPlan(
      date: json['date'] ?? '',
      shouldIrrigate: json['shouldIrrigate'] ?? false,
      waterAmountLiters: (json['waterAmountLiters'] ?? 0).toDouble(),
      bestTimeOfDay: json['bestTimeOfDay'] ?? 'N/A',
      durationMinutes: (json['durationMinutes'] ?? 0).toInt(),
      reasoning: json['reasoning'] ?? '',
      weatherSummary: json['weatherSummary'] ?? '',
    );
  }

  /// Nice day label: "Today", "Tomorrow", or weekday name.
  String get dayLabel {
    try {
      final d = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;

      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';

      const weekdays = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday',
      ];
      return weekdays[d.weekday - 1];
    } catch (_) {
      return date;
    }
  }

  /// Short date: "Feb 23"
  String get shortDate {
    try {
      final d = DateTime.parse(date);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return date;
    }
  }
}

class IrrigationScheduleResponse {
  final String weeklyOverview;
  final double totalWaterLiters;
  final List<DailyIrrigationPlan> schedule;
  final String? fieldName;
  final String? fieldId;
  final String? cropType;
  final double? areaSize;

  IrrigationScheduleResponse({
    required this.weeklyOverview,
    required this.totalWaterLiters,
    required this.schedule,
    this.fieldName,
    this.fieldId,
    this.cropType,
    this.areaSize,
  });

  factory IrrigationScheduleResponse.fromJson(Map<String, dynamic> json) {
    // The NestJS backend returns { weather, irrigation, field }
    final irrigation = json['irrigation'] as Map<String, dynamic>? ?? json;
    final field = json['field'] as Map<String, dynamic>?;

    final scheduleList = (irrigation['schedule'] as List<dynamic>?)
            ?.map((e) =>
                DailyIrrigationPlan.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return IrrigationScheduleResponse(
      weeklyOverview: irrigation['weeklyOverview'] ?? 'No overview available.',
      totalWaterLiters: (irrigation['totalWaterLiters'] ?? 0).toDouble(),
      schedule: scheduleList,
      fieldName: field?['name'],
      fieldId: field?['id'],
      cropType: field?['cropType'],
      areaSize: (field?['areaSize'] as num?)?.toDouble(),
    );
  }

  /// Number of days that need irrigation.
  int get irrigationDays =>
      schedule.where((d) => d.shouldIrrigate).length;

  /// Number of rest (skip) days.
  int get restDays =>
      schedule.where((d) => !d.shouldIrrigate).length;
}
