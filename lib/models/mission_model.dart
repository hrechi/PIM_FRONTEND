class MissionModel {
  final String id;
  final String userId;
  final String fieldId;
  final String title;
  final String? description;
  final String missionType;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final DateTime? assignedDate;
  final DateTime? completedAt;
  final int? estimatedDuration;
  final int? actualDuration;
  final int progress;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MissionModel({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.title,
    this.description,
    required this.missionType,
    required this.status,
    required this.priority,
    this.dueDate,
    this.assignedDate,
    this.completedAt,
    this.estimatedDuration,
    this.actualDuration,
    required this.progress,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fieldId: json['fieldId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      missionType: json['missionType'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate:
          json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      assignedDate: json['assignedDate'] != null
          ? DateTime.parse(json['assignedDate'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      estimatedDuration: json['estimatedDuration'] as int?,
      actualDuration: json['actualDuration'] as int?,
      progress: (json['progress'] as num).toInt(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fieldId': fieldId,
      'title': title,
      'description': description,
      'missionType': missionType,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'assignedDate': assignedDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'progress': progress,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MissionModel copyWith({
    String? id,
    String? userId,
    String? fieldId,
    String? title,
    String? description,
    String? missionType,
    String? status,
    String? priority,
    DateTime? dueDate,
    DateTime? assignedDate,
    DateTime? completedAt,
    int? estimatedDuration,
    int? actualDuration,
    int? progress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fieldId: fieldId ?? this.fieldId,
      title: title ?? this.title,
      description: description ?? this.description,
      missionType: missionType ?? this.missionType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assignedDate: assignedDate ?? this.assignedDate,
      completedAt: completedAt ?? this.completedAt,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
