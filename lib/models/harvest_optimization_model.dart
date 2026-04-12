// ─── Harvest Status ─────────────────────────────────────────────────────────
enum HarvestStatus { notReady, optimal, overdue }

HarvestStatus harvestStatusFromString(String s) {
  switch (s) {
    case 'OPTIMAL':
      return HarvestStatus.optimal;
    case 'OVERDUE':
      return HarvestStatus.overdue;
    default:
      return HarvestStatus.notReady;
  }
}

// ─── Crop Profit Model ───────────────────────────────────────────────────────
class CropProfit {
  final String cropName;
  final String variety;
  final DateTime plantingDate;
  final int daysSincePlanting;
  final int optimalGrowthDuration;
  final int daysUntilOptimal;
  final HarvestStatus status;
  final double profitNow;
  final double profitOptimal;
  final double expectedYieldTons;
  final double pricePerTon;

  CropProfit({
    required this.cropName,
    required this.variety,
    required this.plantingDate,
    required this.daysSincePlanting,
    required this.optimalGrowthDuration,
    required this.daysUntilOptimal,
    required this.status,
    required this.profitNow,
    required this.profitOptimal,
    required this.expectedYieldTons,
    required this.pricePerTon,
  });

  factory CropProfit.fromJson(Map<String, dynamic> json) {
    return CropProfit(
      cropName: json['cropName'] ?? '',
      variety: json['variety'] ?? '',
      plantingDate: DateTime.parse(json['plantingDate']),
      daysSincePlanting: json['daysSincePlanting'] ?? 0,
      optimalGrowthDuration: json['optimalGrowthDuration'] ?? 90,
      daysUntilOptimal: json['daysUntilOptimal'] ?? 0,
      status: harvestStatusFromString(json['status'] ?? 'NOT_READY'),
      profitNow: (json['profitNow'] as num?)?.toDouble() ?? 0.0,
      profitOptimal: (json['profitOptimal'] as num?)?.toDouble() ?? 0.0,
      expectedYieldTons: (json['expectedYieldTons'] as num?)?.toDouble() ?? 0.0,
      pricePerTon: (json['pricePerTon'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get maturityPercent =>
      (daysSincePlanting / optimalGrowthDuration).clamp(0.0, 1.0);

  double get profitGap => profitOptimal - profitNow;
}

// ─── Main Result Model ────────────────────────────────────────────────────────
class HarvestOptimizationResult {
  final String parcelId;
  final String parcelName;
  final double areaSize;
  final CropProfit? activeCrop;
  final List<CropProfit> allCrops;
  final String aiExplanation;

  HarvestOptimizationResult({
    required this.parcelId,
    required this.parcelName,
    required this.areaSize,
    this.activeCrop,
    required this.allCrops,
    required this.aiExplanation,
  });

  factory HarvestOptimizationResult.fromJson(Map<String, dynamic> json) {
    return HarvestOptimizationResult(
      parcelId: json['parcelId'] ?? '',
      parcelName: json['parcelName'] ?? '',
      areaSize: (json['areaSize'] as num?)?.toDouble() ?? 0.0,
      activeCrop: json['activeCrop'] != null
          ? CropProfit.fromJson(json['activeCrop'])
          : null,
      allCrops: (json['allCrops'] as List<dynamic>?)
              ?.map((e) => CropProfit.fromJson(e))
              .toList() ??
          [],
      aiExplanation: json['aiExplanation'] ?? '',
    );
  }
}
