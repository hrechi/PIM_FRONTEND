import 'field_model.dart';

class UserModel {
  final String id;
  final String? email;
  final String name;
  final String? phone;
  final String farmName;
  final String? profilePicture;
  final List<FieldModel> fields;
  final String currency;
  final String currencySymbol;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.email,
    required this.name,
    this.phone,
    required this.farmName,
    this.profilePicture,
    required this.fields,
    required this.currency,
    required this.currencySymbol,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      farmName: json['farmName'] as String,
      profilePicture: json['profilePicture'] as String?,
      fields: (json['fields'] as List<dynamic>?)
          ?.map((field) => FieldModel.fromJson(field as Map<String, dynamic>))
          .toList() ?? [],
      currency: json['currency'] as String? ?? 'USD',
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
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
      'fields': fields.map((field) => field.toJson()).toList(),
      'currency': currency,
      'currencySymbol': currencySymbol,
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
    List<FieldModel>? fields,
    String? currency,
    String? currencySymbol,
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
      fields: fields ?? this.fields,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
