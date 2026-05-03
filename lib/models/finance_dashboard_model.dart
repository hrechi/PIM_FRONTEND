class FinanceDashboardModel {
  final String period;
  final String currency;
  final String currencySymbol;
  final double totalRevenue;
  final double totalExpenses;
  final double netBalance;
  final Map<String, ExpenseCategory> expensesByCategory;
  final RevenueByType revenueByType;
  final List<CostlyAnimal> topCostlyAnimals;
  final List<RecentExpense> recentExpenses;

  FinanceDashboardModel({
    required this.period,
    required this.currency,
    required this.currencySymbol,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netBalance,
    required this.expensesByCategory,
    required this.revenueByType,
    required this.topCostlyAnimals,
    required this.recentExpenses,
  });

  factory FinanceDashboardModel.fromJson(Map<String, dynamic> json) {
    return FinanceDashboardModel(
      period: json['period'],
      currency: json['currency'],
      currencySymbol: json['currencySymbol'],
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      netBalance: (json['netBalance'] as num).toDouble(),
      expensesByCategory: (json['expensesByCategory'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, ExpenseCategory.fromJson(value)),
      ),
      revenueByType: RevenueByType.fromJson(json['revenueByType']),
      topCostlyAnimals: (json['topCostlyAnimals'] as List)
          .map((item) => CostlyAnimal.fromJson(item))
          .toList(),
      recentExpenses: (json['recentExpenses'] as List)
          .map((item) => RecentExpense.fromJson(item))
          .toList(),
    );
  }
}

class ExpenseCategory {
  final double amount;
  final int percentage;

  ExpenseCategory({
    required this.amount,
    required this.percentage,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      amount: (json['amount'] as num).toDouble(),
      percentage: json['percentage'],
    );
  }
}

class RevenueByType {
  final AnimalSales animalSales;

  RevenueByType({
    required this.animalSales,
  });

  factory RevenueByType.fromJson(Map<String, dynamic> json) {
    return RevenueByType(
      animalSales: AnimalSales.fromJson(json['animalSales']),
    );
  }
}

class AnimalSales {
  final int count;
  final double totalAmount;

  AnimalSales({
    required this.count,
    required this.totalAmount,
  });

  factory AnimalSales.fromJson(Map<String, dynamic> json) {
    return AnimalSales(
      count: json['count'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }
}

class CostlyAnimal {
  final String animalId;
  final String name;
  final double totalCost;

  CostlyAnimal({
    required this.animalId,
    required this.name,
    required this.totalCost,
  });

  factory CostlyAnimal.fromJson(Map<String, dynamic> json) {
    return CostlyAnimal(
      animalId: json['animalId'],
      name: json['name'],
      totalCost: (json['totalCost'] as num).toDouble(),
    );
  }
}

class RecentExpense {
  final String id;
  final String category;
  final double amount;
  final String date;
  final String? animalName;

  RecentExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.animalName,
  });

  factory RecentExpense.fromJson(Map<String, dynamic> json) {
    return RecentExpense(
      id: json['id'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      date: json['date'],
      animalName: json['animalName'],
    );
  }
}