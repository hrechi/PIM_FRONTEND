class HarvestOptimizationModel {
  final String crop;
  final String status;
  final String? bestHarvestDate;
  final int daysRemaining;
  final ProfitAnalysis profitAnalysis;
  final String recommendation;

  HarvestOptimizationModel({
    required this.crop,
    required this.status,
    this.bestHarvestDate,
    required this.daysRemaining,
    required this.profitAnalysis,
    required this.recommendation,
  });

  factory HarvestOptimizationModel.fromJson(Map<String, dynamic> json) {
    return HarvestOptimizationModel(
      crop: json['crop'] ?? 'Unknown',
      status: json['status'] ?? 'UNKNOWN',
      bestHarvestDate: json['bestHarvestDate'],
      daysRemaining: json['daysRemaining'] ?? 0,
      profitAnalysis: ProfitAnalysis.fromJson(json['profitAnalysis'] ?? {}),
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class ProfitAnalysis {
  final int profitNow;
  final int profitOptimal;
  final int difference;

  ProfitAnalysis({
    required this.profitNow,
    required this.profitOptimal,
    required this.difference,
  });

  factory ProfitAnalysis.fromJson(Map<String, dynamic> json) {
    return ProfitAnalysis(
      profitNow: json['profitNow'] ?? 0,
      profitOptimal: json['profitOptimal'] ?? 0,
      difference: json['difference'] ?? 0,
    );
  }
}
