class Animal {
  final String id;
  final String nodeId;
  final String farmerId;
  final String name;
  final String animalType; // cow, horse, sheep, dog
  final String? breed;
  final int age;
  final int ageYears;
  final String sex; // male, female
  final double? weight;
  final String healthStatus;
  final int vitalityScore;
  final double? bodyTemp;
  final String activityLevel;
  final DateTime? lastVetCheck;
  final bool vaccination;
  final String? profileImage;
  final String? tagNumber;
  final String? notes;

  // New Reproduction & Health Fields
  final bool? isPregnant;
  final DateTime? lastInseminationDate;
  final DateTime? lastBirthDate;
  final DateTime? expectedBirthDate;
  final int birthCount;
  final String status; // active, sold, deceased
  final double? healthRiskScore;
  final int diseaseHistoryCount;

  // Evolution/Legacy (Keeping these for compatibility if needed, or nulling)
  final double? fatContent;
  final double? protein;
  final DateTime? feedIntakeRecorded;
  final DateTime? dewormingScheduled;
  final String? productionHabit;
  final List<Map<String, dynamic>>? vaccines; // Keep as JSON for now or use VaccineRecord?
  final List<Map<String, dynamic>>? birthHistory;

  // Species-specific: COW
  final double? dailyMilkAvgL;
  final DateTime? milkPeakDate;
  final int? lactationNumber;

  // Species-specific: HORSE
  final String? raceCategory; // course, loisir, sport
  final double? bestRaceTime;
  final String? trainingLevel;

  // Species-specific: SHEEP
  final DateTime? woolLastShearDate;
  final String? meatGrade; // A, B, C

  // Species-specific: DOG
  final String? dogRole; // garde, berger, compagnie

  // Finance & Value
  final double? purchasePrice;
  final DateTime? purchaseDate;
  final double? estimatedValue;
  final double? salePrice;
  final DateTime? saleDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Related models as IDs or placeholder Lists
  // (In a full implementation, these would be separate model classes)
  final List<VaccineRecord>? vaccineRecords;
  final List<MedicalEvent>? medicalEvents;

  Animal({
    required this.id,
    required this.nodeId,
    required this.farmerId,
    required this.name,
    required this.animalType,
    this.breed,
    required this.age,
    required this.ageYears,
    required this.sex,
    this.weight,
    required this.healthStatus,
    required this.vitalityScore,
    this.bodyTemp,
    required this.activityLevel,
    this.lastVetCheck,
    required this.vaccination,
    this.profileImage,
    this.tagNumber,
    this.notes,
    this.isPregnant,
    this.lastInseminationDate,
    this.lastBirthDate,
    this.expectedBirthDate,
    this.birthCount = 0,
    required this.status,
    this.healthRiskScore,
    this.diseaseHistoryCount = 0,
    this.fatContent,
    this.protein,
    this.feedIntakeRecorded,
    this.dewormingScheduled,
    this.productionHabit,
    this.vaccines,
    this.birthHistory,
    this.dailyMilkAvgL,
    this.milkPeakDate,
    this.lactationNumber,
    this.raceCategory,
    this.bestRaceTime,
    this.trainingLevel,
    this.woolLastShearDate,
    this.meatGrade,
    this.dogRole,
    this.purchasePrice,
    this.purchaseDate,
    this.estimatedValue,
    this.salePrice,
    this.saleDate,
    required this.createdAt,
    required this.updatedAt,
    this.vaccineRecords,
    this.medicalEvents,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  factory Animal.fromJson(Map<String, dynamic> json) {
    // Backend now returns medicalEvents list, let's derive count if missing
    int historyCount = _toInt(json['diseaseHistoryCount']);
    if (historyCount == 0 && json['medicalEvents'] != null) {
      if (json['medicalEvents'] is List) {
        historyCount = (json['medicalEvents'] as List).length;
      }
    } else if (historyCount == 0 && json['_count'] != null) {
      historyCount = _toInt(json['_count']['medicalEvents']);
    }

    return Animal(
      id: json['id'],
      nodeId: json['nodeId'],
      farmerId: json['farmerId'],
      name: json['name'],
      animalType: json['animalType'],
      breed: json['breed'],
      age: _toInt(json['age']),
      ageYears: _toInt(json['ageYears']),
      sex: json['sex'],
      weight: _toDouble(json['weight']),
      healthStatus: json['healthStatus'] ?? 'OPTIMAL',
      vitalityScore: _toInt(json['vitalityScore'] ?? 100),
      bodyTemp: _toDouble(json['bodyTemp']),
      activityLevel: json['activityLevel'] ?? 'MODERATE',
      lastVetCheck: json['lastVetCheck'] != null ? DateTime.parse(json['lastVetCheck']) : null,
      vaccination: json['vaccination'] ?? false,
      profileImage: json['profileImage'],
      tagNumber: json['tagNumber'],
      notes: json['notes'],
      isPregnant: json['isPregnant'],
      lastInseminationDate: json['lastInseminationDate'] != null ? DateTime.parse(json['lastInseminationDate']) : null,
      lastBirthDate: json['lastBirthDate'] != null ? DateTime.parse(json['lastBirthDate']) : null,
      expectedBirthDate: json['expectedBirthDate'] != null ? DateTime.parse(json['expectedBirthDate']) : null,
      birthCount: _toInt(json['birthCount']),
      status: json['status'] ?? 'active',
      healthRiskScore: _toDouble(json['healthRiskScore']),
      diseaseHistoryCount: historyCount,
      fatContent: _toDouble(json['fatContent']),
      protein: _toDouble(json['protein']),
      feedIntakeRecorded: json['feedIntakeRecorded'] != null ? DateTime.parse(json['feedIntakeRecorded']) : null,
      dewormingScheduled: json['dewormingScheduled'] != null ? DateTime.parse(json['dewormingScheduled']) : null,
      productionHabit: json['productionHabit'],
      vaccines: json['vaccines'] != null ? (json['vaccines'] as List).map((v) => Map<String, dynamic>.from(v)).toList() : null,
      birthHistory: json['birthHistory'] != null ? (json['birthHistory'] as List).map((v) => Map<String, dynamic>.from(v)).toList() : null,
      dailyMilkAvgL: _toDouble(json['dailyMilkAvgL']),
      milkPeakDate: json['milkPeakDate'] != null ? DateTime.parse(json['milkPeakDate']) : null,
      lactationNumber: _toInt(json['lactationNumber']),
      raceCategory: json['raceCategory'],
      bestRaceTime: _toDouble(json['bestRaceTime']),
      trainingLevel: json['trainingLevel'],
      woolLastShearDate: json['woolLastShearDate'] != null ? DateTime.parse(json['woolLastShearDate']) : null,
      meatGrade: json['meatGrade'],
      dogRole: json['dogRole'],
      purchasePrice: _toDouble(json['purchasePrice']),
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : null,
      estimatedValue: _toDouble(json['estimatedValue']),
      salePrice: _toDouble(json['salePrice']),
      saleDate: json['saleDate'] != null ? DateTime.parse(json['saleDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      vaccineRecords: json['vaccineRecords'] != null 
          ? (json['vaccineRecords'] as List).map((v) => VaccineRecord.fromJson(v)).toList() 
          : null,
      medicalEvents: json['medicalEvents'] != null 
          ? (json['medicalEvents'] as List).map((v) => MedicalEvent.fromJson(v)).toList() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nodeId': nodeId,
      'farmerId': farmerId,
      'name': name,
      'animalType': animalType,
      'breed': breed,
      'age': age,
      'ageYears': ageYears,
      'sex': sex,
      'weight': weight,
      'healthStatus': healthStatus,
      'vitalityScore': vitalityScore,
      'bodyTemp': bodyTemp,
      'activityLevel': activityLevel,
      'lastVetCheck': lastVetCheck?.toIso8601String(),
      'vaccination': vaccination,
      'profileImage': profileImage,
      'tagNumber': tagNumber,
      'notes': notes,
      'isPregnant': isPregnant,
      'lastInseminationDate': lastInseminationDate?.toIso8601String(),
      'lastBirthDate': lastBirthDate?.toIso8601String(),
      'expectedBirthDate': expectedBirthDate?.toIso8601String(),
      'birthCount': birthCount,
      'status': status,
      'healthRiskScore': healthRiskScore,
      'diseaseHistoryCount': diseaseHistoryCount,
      'dailyMilkAvgL': dailyMilkAvgL,
      'milkPeakDate': milkPeakDate?.toIso8601String(),
      'lactationNumber': lactationNumber,
      'raceCategory': raceCategory,
      'bestRaceTime': bestRaceTime,
      'trainingLevel': trainingLevel,
      'woolLastShearDate': woolLastShearDate?.toIso8601String(),
      'meatGrade': meatGrade,
      'dogRole': dogRole,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'estimatedValue': estimatedValue,
      'salePrice': salePrice,
      'saleDate': saleDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Legacy Getters to fix compilation errors
  bool get isHealthy => healthStatus == 'OPTIMAL';
  String get formattedTemperature => bodyTemp != null ? '${bodyTemp!.toStringAsFixed(1)}°C' : '--°C';
  double get temperature => bodyTemp ?? 0.0;
  String get formattedHeartRate => '85 bpm'; // Mock value for now

  static List<Animal> getMockData() {
    return [
      Animal(
        id: '1',
        nodeId: 'COW-001',
        farmerId: 'FARMER-1',
        name: 'Marguerite',
        animalType: 'cow',
        breed: 'Holstein',
        age: 36,
        ageYears: 3,
        sex: 'female',
        weight: 650.0,
        healthStatus: 'OPTIMAL',
        vitalityScore: 92,
        bodyTemp: 38.5,
        activityLevel: 'MODERATE',
        vaccination: true,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Animal(
        id: '2',
        nodeId: 'HOR-002',
        farmerId: 'FARMER-1',
        name: 'Éclair',
        animalType: 'horse',
        breed: 'Pur-sang',
        age: 60,
        ageYears: 5,
        sex: 'male',
        weight: 520.0,
        healthStatus: 'WARNING',
        vitalityScore: 75,
        bodyTemp: 39.2,
        activityLevel: 'HIGH',
        vaccination: true,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

class VaccineRecord {
  final String id;
  final String vaccineName;
  final DateTime vaccineDate;
  final DateTime? nextDueDate;
  final String? vetName;
  final String? lotNumber;

  VaccineRecord({
    required this.id,
    required this.vaccineName,
    required this.vaccineDate,
    this.nextDueDate,
    this.vetName,
    this.lotNumber,
  });

  factory VaccineRecord.fromJson(Map<String, dynamic> json) {
    return VaccineRecord(
      id: json['id'],
      vaccineName: json['vaccineName'],
      vaccineDate: DateTime.parse(json['vaccineDate']),
      nextDueDate: json['nextDueDate'] != null ? DateTime.parse(json['nextDueDate']) : null,
      vetName: json['vetName'],
      lotNumber: json['lotNumber'],
    );
  }
}

class MedicalEvent {
  final String id;
  final DateTime eventDate;
  final String eventType;
  final String? diagnosis;
  final String? treatment;
  final String? vetName;
  final double? cost;
  final String? notes;

  MedicalEvent({
    required this.id,
    required this.eventDate,
    required this.eventType,
    this.diagnosis,
    this.treatment,
    this.vetName,
    this.cost,
    this.notes,
  });

  factory MedicalEvent.fromJson(Map<String, dynamic> json) {
    return MedicalEvent(
      id: json['id'],
      eventDate: DateTime.parse(json['eventDate']),
      eventType: json['eventType'],
      diagnosis: json['diagnosis'],
      treatment: json['treatment'],
      vetName: json['vetName'],
      cost: json['cost']?.toDouble(),
      notes: json['notes'],
    );
  }
}
