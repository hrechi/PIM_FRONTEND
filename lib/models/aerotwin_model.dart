class NDVIRecordModel {
  final String id;
  final String fieldId;
  final DateTime date;
  final double avgNDVI;
  final List<List<double?>> gridData;

  NDVIRecordModel({
    required this.id,
    required this.fieldId,
    required this.date,
    required this.avgNDVI,
    required this.gridData,
  });

  factory NDVIRecordModel.fromJson(Map<String, dynamic> json) {
    var rawGrid = json['gridData'] as List;
    List<List<double?>> parsedGrid = rawGrid.map((row) {
      if (row is! List) return <double?>[];
      return (row).map((val) => val != null ? (val as num).toDouble() : null).toList();
    }).toList();

    return NDVIRecordModel(
      id: json['id'],
      fieldId: json['fieldId'],
      date: DateTime.parse(json['date']),
      avgNDVI: (json['avgNDVI'] as num).toDouble(),
      gridData: parsedGrid,
    );
  }
}

class AeroTwinAlert {
  final String issue;
  final double confidence;
  final String recommendation;

  AeroTwinAlert({
    required this.issue,
    required this.confidence,
    required this.recommendation,
  });

  factory AeroTwinAlert.fromJson(Map<String, dynamic> json) {
    return AeroTwinAlert(
      issue: json['issue'] ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class SimulationResult {
  final double predictedAvgNDVI;
  final List<List<double?>> predictedGrid;
  final int riskZonesCount;
  final int totalZones;
  
  SimulationResult({
    required this.predictedAvgNDVI,
    required this.predictedGrid,
    required this.riskZonesCount,
    required this.totalZones,
  });

  factory SimulationResult.fromJson(Map<String, dynamic> json) {
     var rawGrid = json['predictedGrid'] as List;
     List<List<double?>> parsedGrid = rawGrid.map((row) {
        if (row is! List) return <double?>[];
        return (row).map((val) => val != null ? (val as num).toDouble() : null).toList();
     }).toList();

     return SimulationResult(
       predictedAvgNDVI: (json['predictedAvgNDVI'] as num).toDouble(),
       predictedGrid: parsedGrid,
       riskZonesCount: json['riskZonesCount'] as int,
       totalZones: json['totalZones'] as int,
     );
  }
}
