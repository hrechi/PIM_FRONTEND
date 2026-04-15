class UserModel {
  final String id;
  final String? email;
  final String name;
  final String? phone;
  final String farmName;
  final String? profilePicture;
  final String role;
  final String? username;
  final String? assignedFieldId;
  final String? ownerId;
  final String? staffId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.email,
    required this.name,
    this.phone,
    required this.farmName,
    this.profilePicture,
    required this.role,
    this.username,
    this.assignedFieldId,
    this.ownerId,
    this.staffId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] as String?)?.toUpperCase() ?? 'OWNER';
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      farmName: json['farmName'] as String,
      profilePicture: json['profilePicture'] as String?,
      role: rawRole == 'FARMER' ? 'WORKER' : rawRole,
      username: json['username'] as String?,
      assignedFieldId: json['assignedFieldId'] as String?,
      ownerId: json['ownerId'] as String?,
      staffId: json['staffId'] as String? ?? json['workerId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'farmName': farmName,
      'profilePicture': profilePicture,
      'role': role,
      'username': username,
      'assignedFieldId': assignedFieldId,
      'ownerId': ownerId,
      'staffId': staffId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? farmName,
    String? profilePicture,
    String? role,
    String? username,
    String? assignedFieldId,
    String? ownerId,
    String? staffId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      farmName: farmName ?? this.farmName,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      username: username ?? this.username,
      assignedFieldId: assignedFieldId ?? this.assignedFieldId,
      ownerId: ownerId ?? this.ownerId,
      staffId: staffId ?? this.staffId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
