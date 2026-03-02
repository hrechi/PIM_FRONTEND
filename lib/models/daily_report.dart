class DailyReport {
  final String id;
  final String summary;
  final int totalIncidents;
  final int criticalAlerts;
  final int peakActivityHour;
  final String averageThreatLevel;
  final DateTime createdAt;

  DailyReport({
    required this.id,
    required this.summary,
    required this.totalIncidents,
    required this.criticalAlerts,
    required this.peakActivityHour,
    required this.averageThreatLevel,
    required this.createdAt,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      id: json['id'],
      summary: json['summary'],
      totalIncidents: json['totalIncidents'] ?? 0,
      criticalAlerts: json['criticalAlerts'] ?? 0,
      peakActivityHour: json['peakActivityHour'] ?? 0,
      averageThreatLevel: json['averageThreatLevel'] ?? 'low',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
