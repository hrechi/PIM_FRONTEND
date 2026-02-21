class Crop {
  final String id;
  final String cropName;
  final String variety;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final String parcelId;

  Crop({
    required this.id,
    required this.cropName,
    required this.variety,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.parcelId,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'],
      cropName: json['cropName'],
      variety: json['variety'],
      plantingDate: DateTime.parse(json['plantingDate']),
      expectedHarvestDate: DateTime.parse(json['expectedHarvestDate']),
      parcelId: json['parcelId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cropName': cropName,
      'variety': variety,
      'plantingDate': plantingDate.toIso8601String(),
      'expectedHarvestDate': expectedHarvestDate.toIso8601String(),
    };
  }
}

class Fertilization {
  final String id;
  final String fertilizerType;
  final double quantityUsed;
  final DateTime applicationDate;
  final String parcelId;

  Fertilization({
    required this.id,
    required this.fertilizerType,
    required this.quantityUsed,
    required this.applicationDate,
    required this.parcelId,
  });

  factory Fertilization.fromJson(Map<String, dynamic> json) {
    return Fertilization(
      id: json['id'],
      fertilizerType: json['fertilizerType'],
      quantityUsed: (json['quantityUsed'] as num).toDouble(),
      applicationDate: DateTime.parse(json['applicationDate']),
      parcelId: json['parcelId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fertilizerType': fertilizerType,
      'quantityUsed': quantityUsed,
      'applicationDate': applicationDate.toIso8601String(),
    };
  }
}

class PestDisease {
  final String id;
  final String? issueType;
  final String? treatmentUsed;
  final DateTime? treatmentDate;
  final String parcelId;

  PestDisease({
    required this.id,
    this.issueType,
    this.treatmentUsed,
    this.treatmentDate,
    required this.parcelId,
  });

  factory PestDisease.fromJson(Map<String, dynamic> json) {
    return PestDisease(
      id: json['id'],
      issueType: json['issueType'],
      treatmentUsed: json['treatmentUsed'],
      treatmentDate: json['treatmentDate'] != null ? DateTime.parse(json['treatmentDate']) : null,
      parcelId: json['parcelId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (issueType != null) 'issueType': issueType,
      if (treatmentUsed != null) 'treatmentUsed': treatmentUsed,
      if (treatmentDate != null) 'treatmentDate': treatmentDate!.toIso8601String(),
    };
  }
}

class Harvest {
  final String id;
  final DateTime? harvestDate;
  final double? totalYield;
  final double? yieldPerHectare;
  final String parcelId;

  Harvest({
    required this.id,
    this.harvestDate,
    this.totalYield,
    this.yieldPerHectare,
    required this.parcelId,
  });

  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      id: json['id'],
      harvestDate: json['harvestDate'] != null ? DateTime.parse(json['harvestDate']) : null,
      totalYield: json['totalYield'] != null ? (json['totalYield'] as num).toDouble() : null,
      yieldPerHectare: json['yieldPerHectare'] != null ? (json['yieldPerHectare'] as num).toDouble() : null,
      parcelId: json['parcelId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (harvestDate != null) 'harvestDate': harvestDate!.toIso8601String(),
      if (totalYield != null) 'totalYield': totalYield,
      if (yieldPerHectare != null) 'yieldPerHectare': yieldPerHectare,
    };
  }
}

class Parcel {
  final String id;
  final String location;
  final double areaSize;
  final String boundariesDescription;
  final String soilType;
  final double? soilPh;
  final double? nitrogenLevel;
  final double? phosphorusLevel;
  final double? potassiumLevel;
  final String waterSource;
  final String irrigationMethod;
  final String irrigationFrequency;
  
  final List<Crop> crops;
  final List<Fertilization> fertilizations;
  final List<PestDisease> pests;
  final List<Harvest> harvests;

  Parcel({
    required this.id,
    required this.location,
    required this.areaSize,
    required this.boundariesDescription,
    required this.soilType,
    this.soilPh,
    this.nitrogenLevel,
    this.phosphorusLevel,
    this.potassiumLevel,
    required this.waterSource,
    required this.irrigationMethod,
    required this.irrigationFrequency,
    this.crops = const [],
    this.fertilizations = const [],
    this.pests = const [],
    this.harvests = const [],
  });

  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'],
      location: json['location'],
      areaSize: (json['areaSize'] as num).toDouble(),
      boundariesDescription: json['boundariesDescription'],
      soilType: json['soilType'],
      soilPh: json['soilPh'] != null ? (json['soilPh'] as num).toDouble() : null,
      nitrogenLevel: json['nitrogenLevel'] != null ? (json['nitrogenLevel'] as num).toDouble() : null,
      phosphorusLevel: json['phosphorusLevel'] != null ? (json['phosphorusLevel'] as num).toDouble() : null,
      potassiumLevel: json['potassiumLevel'] != null ? (json['potassiumLevel'] as num).toDouble() : null,
      waterSource: json['waterSource'],
      irrigationMethod: json['irrigationMethod'],
      irrigationFrequency: json['irrigationFrequency'],
      crops: (json['crops'] as List<dynamic>?)?.map((e) => Crop.fromJson(e)).toList() ?? [],
      fertilizations: (json['fertilizations'] as List<dynamic>?)?.map((e) => Fertilization.fromJson(e)).toList() ?? [],
      pests: (json['pests'] as List<dynamic>?)?.map((e) => PestDisease.fromJson(e)).toList() ?? [],
      harvests: (json['harvests'] as List<dynamic>?)?.map((e) => Harvest.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'areaSize': areaSize,
      'boundariesDescription': boundariesDescription,
      'soilType': soilType,
      if (soilPh != null) 'soilPh': soilPh,
      if (nitrogenLevel != null) 'nitrogenLevel': nitrogenLevel,
      if (phosphorusLevel != null) 'phosphorusLevel': phosphorusLevel,
      if (potassiumLevel != null) 'potassiumLevel': potassiumLevel,
      'waterSource': waterSource,
      'irrigationMethod': irrigationMethod,
      'irrigationFrequency': irrigationFrequency,
    };
  }
}
