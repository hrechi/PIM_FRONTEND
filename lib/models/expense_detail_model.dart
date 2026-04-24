class ExpenseDetail {
  final String id;
  final String animalName;
  final String? animalId;
  final String category;
  final double amount;
  final DateTime date;
  final String? description;

  ExpenseDetail({
    required this.id,
    required this.animalName,
    this.animalId,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
  });

  factory ExpenseDetail.fromJson(Map<String, dynamic> json) {
    return ExpenseDetail(
      id: json['id'],
      animalName: json['animalName'] ?? 'N/A',
      animalId: json['animalId'],
      category: json['category'] ?? 'other',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }
}

class ExpensesResponse {
  final List<ExpenseDetail> data;
  final int total;
  final int skip;
  final int take;

  ExpensesResponse({
    required this.data,
    required this.total,
    required this.skip,
    required this.take,
  });

  factory ExpensesResponse.fromJson(Map<String, dynamic> json) {
    return ExpensesResponse(
      data: (json['data'] as List).map((item) => ExpenseDetail.fromJson(item)).toList(),
      total: json['total'],
      skip: json['skip'],
      take: json['take'],
    );
  }
}
