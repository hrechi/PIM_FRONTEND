/// ============================================================
/// FINANCE DASHBOARD MODEL — Modèle du tableau de bord financier
/// ============================================================
///
/// Ce modèle représente les données agrégées du tableau de bord
/// financier pour un champ agricole sur une période donnée.
///
/// Données incluses :
///   • totalRevenue    = ventes animaux + revenus manuels (lait, cultures…)
///   • totalExpenses   = somme de toutes les dépenses (alimentation, vétérinaire…)
///   • netBalance      = totalRevenue - totalExpenses (positif = bénéfice)
///   • expensesByCategory → Map<catégorie, {montant, pourcentage}>
///   • revenueByType   → {animalSales: {count, total}, manualRevenues: {count, total}}
///   • topCostlyAnimals → Top 3 animaux les plus coûteux (dépenses + soins)
///   • recentExpenses  → 5 dernières dépenses enregistrées
///
/// Désérialisé depuis la réponse JSON de GET /finance/dashboard
/// ============================================================
class FinanceDashboardModel {
  /// Période analysée : 'month' | 'quarter' | 'year'
  final String period;

  /// Code devise ISO (ex: 'TND', 'EUR', 'USD')
  final String currency;

  /// Symbole de la devise (ex: 'DT', '€', '$')
  final String currencySymbol;

  /// Revenu total = ventes animaux + revenus manuels
  final double totalRevenue;

  /// Total des dépenses sur la période
  final double totalExpenses;

  /// Solde net = totalRevenue - totalExpenses
  final double netBalance;

  /// Répartition des dépenses par catégorie avec montant et pourcentage
  final Map<String, ExpenseCategory> expensesByCategory;

  /// Détail des revenus par type (ventes animaux + revenus manuels)
  final RevenueByType revenueByType;

  /// Top 3 animaux les plus coûteux sur la période
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
  final ManualRevenues manualRevenues;

  RevenueByType({
    required this.animalSales,
    required this.manualRevenues,
  });

  factory RevenueByType.fromJson(Map<String, dynamic> json) {
    return RevenueByType(
      animalSales: AnimalSales.fromJson(json['animalSales']),
      manualRevenues: json['manualRevenues'] != null
          ? ManualRevenues.fromJson(json['manualRevenues'])
          : const ManualRevenues(count: 0, totalAmount: 0),
    );
  }
}

class AnimalSales {
  final int count;
  final double totalAmount;

  const AnimalSales({
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

class ManualRevenues {
  final int count;
  final double totalAmount;

  const ManualRevenues({
    required this.count,
    required this.totalAmount,
  });

  factory ManualRevenues.fromJson(Map<String, dynamic> json) {
    return ManualRevenues(
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