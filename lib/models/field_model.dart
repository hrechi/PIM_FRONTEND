class FieldModel {
  final String id;
  final String userId;
  final String name;
  final String? cropType;
  final List<List<double>> areaCoordinates;
  final double? areaSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  FieldModel({
    required this.id,
    required this.userId,
    required this.name,
    this.cropType,
    required this.areaCoordinates,
    this.areaSize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      cropType: json['cropType'] as String?,
      areaCoordinates: (json['areaCoordinates'] as List<dynamic>)
          .map((coord) => (coord as List<dynamic>)
              .map((val) => (val as num).toDouble())
              .toList())
          .toList(),
      areaSize: json['areaSize'] as double?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'cropType': cropType,
      'areaCoordinates': areaCoordinates,
      'areaSize': areaSize,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FieldModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? cropType,
    List<List<double>>? areaCoordinates,
    double? areaSize,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FieldModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      cropType: cropType ?? this.cropType,
      areaCoordinates: areaCoordinates ?? this.areaCoordinates,
      areaSize: areaSize ?? this.areaSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
