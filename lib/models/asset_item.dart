class AssetItem {
  final String id;
  final String name;
  final String category;
  final String status;
  final String serialNumber;
  final String? imageUrl;
  final DateTime? lastServiceDate;
  final Map<String, dynamic>? assignedTo;
  final String? fieldId;
  final Map<String, dynamic>? field;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssetItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.serialNumber,
    this.imageUrl,
    this.lastServiceDate,
    this.assignedTo,
    this.fieldId,
    this.field,
    this.createdAt,
    this.updatedAt,
  });

  String? get assignedToName => assignedTo?['name'] as String?;
  String? get fieldName => field?['name'] as String?;

  factory AssetItem.fromJson(Map<String, dynamic> json) {
    return AssetItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
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
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
