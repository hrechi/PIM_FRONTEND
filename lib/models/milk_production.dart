import '../models/animal.dart';

class MilkProduction {
  final String id;
  final String animalId;
  final Animal? animal;
  final DateTime date;
  final double morningL;
  final double eveningL;
  final double totalL;
  final String? notes;
  final DateTime createdAt;

  MilkProduction({
    required this.id,
    required this.animalId,
    this.animal,
    required this.date,
    required this.morningL,
    required this.eveningL,
    required this.totalL,
    this.notes,
    required this.createdAt,
  });

  factory MilkProduction.fromJson(Map<String, dynamic> json) {
    return MilkProduction(
      id: json['id'],
      animalId: json['animalId'],
      animal: json['animal'] != null ? Animal.fromJson(json['animal']) : null,
      date: DateTime.parse(json['date']),
      morningL: _toDouble(json['morningL']),
      eveningL: _toDouble(json['eveningL']),
      totalL: _toDouble(json['totalL']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
