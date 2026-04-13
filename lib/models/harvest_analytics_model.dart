// Harvest Analytics — Dart Data Models

class YieldTrend {
  final String month;
  final double totalYield;
  final double yieldPerHectare;
  final int harvestCount;

  const YieldTrend({
    required this.month,
    required this.totalYield,
    required this.yieldPerHectare,
    required this.harvestCount,
  });

  factory YieldTrend.fromJson(Map<String, dynamic> json) => YieldTrend(
        month: json['month'] as String,
        totalYield: (json['totalYield'] as num).toDouble(),
        yieldPerHectare: (json['yieldPerHectare'] as num).toDouble(),
        harvestCount: (json['harvestCount'] as num).toInt(),
      );
}

class CropComparison {
  final String parcelId;
  final String location;
  final double totalYield;
  final double avgYieldPerHectare;
  final int harvestCount;

  const CropComparison({
    required this.parcelId,
    required this.location,
    required this.totalYield,
    required this.avgYieldPerHectare,
    required this.harvestCount,
  });

  factory CropComparison.fromJson(Map<String, dynamic> json) => CropComparison(
        parcelId: json['parcelId'] as String,
        location: json['location'] as String,
        totalYield: (json['totalYield'] as num).toDouble(),
        avgYieldPerHectare: (json['avgYieldPerHectare'] as num).toDouble(),
        harvestCount: (json['harvestCount'] as num).toInt(),
      );
}

class BestParcel {
  final String id;
  final String location;
  final double totalYield;

  const BestParcel({
    required this.id,
    required this.location,
    required this.totalYield,
  });

  factory BestParcel.fromJson(Map<String, dynamic> json) => BestParcel(
        id: json['id'] as String,
        location: json['location'] as String,
        totalYield: (json['totalYield'] as num).toDouble(),
      );
}

class MonthlyTrend {
  final String month;
  final double totalYield;

  const MonthlyTrend({required this.month, required this.totalYield});

  factory MonthlyTrend.fromJson(Map<String, dynamic> json) => MonthlyTrend(
        month: json['month'] as String,
        totalYield: (json['totalYield'] as num).toDouble(),
      );
}

class YieldSummary {
  final double totalYield;
  final double avgYieldPerHectare;
  final int totalHarvests;
  final int parcelCount;
  final BestParcel? bestParcel;
  final List<MonthlyTrend> recentTrend;

  const YieldSummary({
    required this.totalYield,
    required this.avgYieldPerHectare,
    required this.totalHarvests,
    required this.parcelCount,
    this.bestParcel,
    required this.recentTrend,
  });

  factory YieldSummary.fromJson(Map<String, dynamic> json) => YieldSummary(
        totalYield: (json['totalYield'] as num).toDouble(),
        avgYieldPerHectare: (json['avgYieldPerHectare'] as num).toDouble(),
        totalHarvests: (json['totalHarvests'] as num).toInt(),
        parcelCount: (json['parcelCount'] as num).toInt(),
        bestParcel: json['bestParcel'] != null
            ? BestParcel.fromJson(json['bestParcel'] as Map<String, dynamic>)
            : null,
        recentTrend: (json['recentTrend'] as List<dynamic>)
            .map((e) => MonthlyTrend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
