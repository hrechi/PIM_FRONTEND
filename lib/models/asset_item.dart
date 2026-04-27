class AssetItem {
  final String id;
  final String name;
  final String brand;
  final String? model;
  final int? modelYear;
  final double? mileage;
  final double? operatingHours;
  final String category;
  final String status;
  final String serialNumber;
  final String? imageUrl;
  final DateTime? lastServiceDate;
  final Map<String, dynamic>? assignedTo;
  final String? fieldId;
  final Map<String, dynamic>? field;
  final Map<String, dynamic>? diagnosis;
  final String? usageCondition;
  final Map<String, dynamic>? activeSession;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssetItem({
    required this.id,
    required this.name,
    required this.brand,
    this.model,
    this.modelYear,
    this.mileage,
    this.operatingHours,
    required this.category,
    required this.status,
    required this.serialNumber,
    this.imageUrl,
    this.lastServiceDate,
    this.assignedTo,
    this.fieldId,
    this.field,
    this.diagnosis,
    this.usageCondition,
    this.activeSession,
    this.createdAt,
    this.updatedAt,
  });

  String? get assignedToName => assignedTo?['name'] as String?;
  String? get fieldName => field?['name'] as String?;
  String? get activeUsageWorkerId =>
      activeSession?['farmerId']?.toString() ??
      activeSession?['farmer']?['id']?.toString();
  String? get activeUsageWorkerName =>
      activeSession?['farmerName']?.toString() ??
      activeSession?['farmer']?['name']?.toString();
  bool get hasAvailabilityWarning =>
      usageCondition == 'WARNING' || usageCondition == 'CRITICAL';
  bool get isInUse => status == 'IN_USE';

  factory AssetItem.fromJson(Map<String, dynamic> json) {
    return AssetItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      model: json['model']?.toString(),
      modelYear: json['modelYear'] is num
          ? (json['modelYear'] as num).toInt()
          : null,
      mileage: json['mileage'] is num
          ? (json['mileage'] as num).toDouble()
          : null,
      operatingHours: json['operatingHours'] is num
          ? (json['operatingHours'] as num).toDouble()
          : null,
      category: (json['category'] ?? '').toString(),
      status: (json['status'] ?? 'AVAILABLE').toString(),
      serialNumber: (json['serial_number'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      lastServiceDate: json['last_service_date'] != null
          ? DateTime.tryParse(json['last_service_date'].toString())
          : null,
      assignedTo: json['assignedTo'] is Map<String, dynamic>
          ? json['assignedTo'] as Map<String, dynamic>
          : null,
      fieldId: json['field_id']?.toString(),
      field: json['field'] is Map<String, dynamic>
          ? json['field'] as Map<String, dynamic>
          : null,
      diagnosis: json['diagnosis'] is Map<String, dynamic>
          ? json['diagnosis'] as Map<String, dynamic>
          : null,
      usageCondition: json['usageCondition']?.toString(),
      activeSession: json['activeSession'] is Map<String, dynamic>
          ? json['activeSession'] as Map<String, dynamic>
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'modelYear': modelYear,
      'mileage': mileage,
      'operatingHours': operatingHours,
      'category': category,
      'status': status,
      'serial_number': serialNumber,
      'image_url': imageUrl,
      'last_service_date': lastServiceDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'field_id': fieldId,
      'field': field,
      'diagnosis': diagnosis,
      'usageCondition': usageCondition,
      'activeSession': activeSession,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
