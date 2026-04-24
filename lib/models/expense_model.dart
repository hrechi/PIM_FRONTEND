import '../models/animal.dart';

class Expense {
  final String id;
  final String? animalId;
  final Animal? animal;
  final String? farmId;
  final String? fieldId;
  final DateTime date;
  final String category;
  final double amount;
  final String? notes;
  final String? receiptUrl;
  final DateTime createdAt;

  Expense({
    required this.id,
    this.animalId,
    this.animal,
    this.farmId,
    this.fieldId,
    required this.date,
    required this.category,
    required this.amount,
    this.notes,
    this.receiptUrl,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      animalId: json['animalId'],
      animal: json['animal'] != null 
          ? Animal(
              id: json['animal']['id'] ?? '',
              name: json['animal']['name'] ?? '',
              nodeId: json['animal']['nodeId'] ?? '',
              tagNumber: json['animal']['tagNumber'],
              farmerId: '',
              animalType: 'unknown',
              age: 0,
              ageYears: 0,
              sex: 'unknown',
              healthStatus: 'OPTIMAL',
              vitalityScore: 100,
              activityLevel: 'unknown',
              vaccination: false,
              status: 'active',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : null,
      farmId: json['farmId'],
      fieldId: json['fieldId'],
      date: DateTime.parse(json['date']),
      category: json['category'],
      amount: json['amount'] is String ? double.parse(json['amount']) : (json['amount'] as num).toDouble(),
      notes: json['description'],
      receiptUrl: json['receiptUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animalId': animalId,
      'fieldId': fieldId,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': notes,
      'receiptUrl': receiptUrl,
    };
  }
}
