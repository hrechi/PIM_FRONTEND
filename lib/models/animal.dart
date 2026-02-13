class Animal {
  final String id;
  final String nodeId;
  final String farmerId;
  final String name;
  final String animalType;
  final String? breed;
  final int age;
  final int ageYears;
  final String sex;
  final double? weight;
  final String? color;
  final String healthStatus;
  final int vitalityScore;
  final double? bodyTemp;
  final String activityLevel;
  final DateTime? lastVetCheck;
  final bool vaccination;
  final double? milkYield;
  final double? fatContent;
  final double? protein;
  final DateTime? feedIntakeRecorded;
  final DateTime? dewormingScheduled;
  final String? profileImage;
  final String? tagNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.color,
    required this.healthStatus,
    required this.vitalityScore,
    this.bodyTemp,
    required this.activityLevel,
    this.lastVetCheck,
    required this.vaccination,
    this.milkYield,
    this.fatContent,
    this.protein,
    this.feedIntakeRecorded,
    this.dewormingScheduled,
    this.profileImage,
    this.tagNumber,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'],
      nodeId: json['nodeId'],
      farmerId: json['farmerId'],
      name: json['name'],
      animalType: json['animalType'],
      breed: json['breed'],
      age: json['age'],
      ageYears: json['ageYears'] ?? 0,
      sex: json['sex'],
      weight: json['weight']?.toDouble(),
      color: json['color'],
      healthStatus: json['healthStatus'] ?? 'OPTIMAL',
      vitalityScore: json['vitalityScore'] ?? 100,
      bodyTemp: json['bodyTemp']?.toDouble(),
      activityLevel: json['activityLevel'] ?? 'MODERATE',
      lastVetCheck: json['lastVetCheck'] != null 
          ? DateTime.parse(json['lastVetCheck']) 
          : null,
      vaccination: json['vaccination'] ?? false,
      milkYield: json['milkYield']?.toDouble(),
      fatContent: json['fatContent']?.toDouble(),
      protein: json['protein']?.toDouble(),
      feedIntakeRecorded: json['feedIntakeRecorded'] != null 
          ? DateTime.parse(json['feedIntakeRecorded']) 
          : null,
      dewormingScheduled: json['dewormingScheduled'] != null 
          ? DateTime.parse(json['dewormingScheduled']) 
          : null,
      profileImage: json['profileImage'],
      tagNumber: json['tagNumber'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
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
      'color': color,
      'healthStatus': healthStatus,
      'vitalityScore': vitalityScore,
      'bodyTemp': bodyTemp,
      'activityLevel': activityLevel,
      'lastVetCheck': lastVetCheck?.toIso8601String(),
      'vaccination': vaccination,
      'milkYield': milkYield,
      'fatContent': fatContent,
      'protein': protein,
      'feedIntakeRecorded': feedIntakeRecorded?.toIso8601String(),
      'dewormingScheduled': dewormingScheduled?.toIso8601String(),
      'profileImage': profileImage,
      'tagNumber': tagNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Animal copyWith({
    String? id,
    String? nodeId,
    String? farmerId,
    String? name,
    String? animalType,
    String? breed,
    int? age,
    int? ageYears,
    String? sex,
    double? weight,
    String? color,
    String? healthStatus,
    int? vitalityScore,
    double? bodyTemp,
    String? activityLevel,
    DateTime? lastVetCheck,
    bool? vaccination,
    double? milkYield,
    double? fatContent,
    double? protein,
    DateTime? feedIntakeRecorded,
    DateTime? dewormingScheduled,
    String? profileImage,
    String? tagNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Animal(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      farmerId: farmerId ?? this.farmerId,
      name: name ?? this.name,
      animalType: animalType ?? this.animalType,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      ageYears: ageYears ?? this.ageYears,
      sex: sex ?? this.sex,
      weight: weight ?? this.weight,
      color: color ?? this.color,
      healthStatus: healthStatus ?? this.healthStatus,
      vitalityScore: vitalityScore ?? this.vitalityScore,
      bodyTemp: bodyTemp ?? this.bodyTemp,
      activityLevel: activityLevel ?? this.activityLevel,
      lastVetCheck: lastVetCheck ?? this.lastVetCheck,
      vaccination: vaccination ?? this.vaccination,
      milkYield: milkYield ?? this.milkYield,
      fatContent: fatContent ?? this.fatContent,
      protein: protein ?? this.protein,
      feedIntakeRecorded: feedIntakeRecorded ?? this.feedIntakeRecorded,
      dewormingScheduled: dewormingScheduled ?? this.dewormingScheduled,
      profileImage: profileImage ?? this.profileImage,
      tagNumber: tagNumber ?? this.tagNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // --- UI Getters for compatibility with older widgets ---
  
  bool get isHealthy => healthStatus == 'OPTIMAL';
  
  String get type => animalType;
  
  double get temperature => bodyTemp ?? 38.5;
  
  String get formattedTemperature => '${temperature.toStringAsFixed(1)}°C';
  
  int get heartRate => vitalityScore; // mapping vitality to heart rate for now
  
  String get formattedHeartRate => '${heartRate} bpm';

  // --- Mock Data ---

  static List<Animal> getMockData() {
    final now = DateTime.now();
    return [
      Animal(
        id: '1',
        nodeId: 'COW-001',
        farmerId: 'farmer-1',
        name: 'Bessie',
        animalType: 'COW',
        breed: 'Holstein',
        age: 24,
        ageYears: 2,
        sex: 'FEMALE',
        weight: 650.0,
        healthStatus: 'OPTIMAL',
        vitalityScore: 82,
        bodyTemp: 38.6,
        activityLevel: 'MODERATE',
        vaccination: true,
        createdAt: now,
        updatedAt: now,
      ),
      Animal(
        id: '2',
        nodeId: 'COW-002',
        farmerId: 'farmer-1',
        name: 'Daisy',
        animalType: 'COW',
        breed: 'Jersey',
        age: 36,
        ageYears: 3,
        sex: 'FEMALE',
        weight: 580.0,
        healthStatus: 'WARNING',
        vitalityScore: 75,
        bodyTemp: 39.2,
        activityLevel: 'LOW',
        vaccination: true,
        createdAt: now,
        updatedAt: now,
      ),
      Animal(
        id: '3',
        nodeId: 'SHEEP-001',
        farmerId: 'farmer-1',
        name: 'Snowy',
        animalType: 'SHEEP',
        breed: 'Merino',
        age: 18,
        ageYears: 1,
        sex: 'FEMALE',
        weight: 55.0,
        healthStatus: 'OPTIMAL',
        vitalityScore: 88,
        bodyTemp: 38.8,
        activityLevel: 'HIGH',
        vaccination: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
