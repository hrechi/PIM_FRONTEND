class Vaccine {
  final String id;
  final String code;
  final String nameFr;
  final String nameEn;
  final String? nameAr;
  final List<String> targetSpecies;
  final int defaultIntervalDays;
  final bool isCoreVaccine;
  final String? notes;

  const Vaccine({
    required this.id,
    required this.code,
    required this.nameFr,
    required this.nameEn,
    this.nameAr,
    required this.targetSpecies,
    required this.defaultIntervalDays,
    this.isCoreVaccine = false,
    this.notes,
  });

  factory Vaccine.fromJson(Map<String, dynamic> json) => Vaccine(
        id: json['id'] ?? '',
        code: json['code'] ?? '',
        nameFr: json['nameFr'] ?? '',
        nameEn: json['nameEn'] ?? '',
        nameAr: json['nameAr'],
        targetSpecies: List<String>.from(json['targetSpecies'] ?? []),
        defaultIntervalDays: json['defaultIntervalDays'] ?? 365,
        isCoreVaccine: json['isCoreVaccine'] ?? false,
        notes: json['notes'],
      );
}

class VaccineSchedule {
  final String id;
  final String animalId;
  final String vaccineId;
  final Vaccine? vaccine;
  final dynamic animal;
  final DateTime scheduledDate;
  final String status; // PENDING, NOTIFIED, DONE, OVERDUE, CANCELLED
  final bool isMandatory;
  final bool isRecurring;
  final int? recurrenceDays;
  final String priority; // HIGH, MEDIUM, LOW
  final String? notes;

  const VaccineSchedule({
    required this.id,
    required this.animalId,
    required this.vaccineId,
    this.vaccine,
    this.animal,
    required this.scheduledDate,
    required this.status,
    required this.isMandatory,
    required this.isRecurring,
    this.recurrenceDays,
    required this.priority,
    this.notes,
  });

  factory VaccineSchedule.fromJson(Map<String, dynamic> json) => VaccineSchedule(
        id: json['id'] ?? '',
        animalId: json['animalId'] ?? '',
        vaccineId: json['vaccineId'] ?? '',
        vaccine: json['vaccine'] != null ? Vaccine.fromJson(json['vaccine']) : null,
        animal: json['animal'],
        scheduledDate: DateTime.parse(json['scheduledDate']),
        status: json['status'] ?? 'PENDING',
        isMandatory: json['isMandatory'] ?? false,
        isRecurring: json['isRecurring'] ?? false,
        recurrenceDays: json['recurrenceDays'],
        priority: json['priority'] ?? 'MEDIUM',
        notes: json['notes'],
      );

  bool get isOverdue => status == 'OVERDUE';
  bool get isDone => status == 'DONE';
  bool get isPending => status == 'PENDING' || status == 'NOTIFIED';

  int get daysUntil => scheduledDate.difference(DateTime.now()).inDays;

  bool get isUrgent => isPending && daysUntil <= 7 && daysUntil >= 0;
}

class VaccineRecord {
  final String id;
  final String animalId;
  final String vaccineId;
  final Vaccine? vaccine;
  final String? scheduleId;
  final String administeredBy;
  final DateTime administeredAt;
  final double doseGiven;
  final String doseUnit;
  final String? lotNumber;
  final double? bodyWeight;
  final DateTime? nextDueDate;
  final String? notes;

  const VaccineRecord({
    required this.id,
    required this.animalId,
    required this.vaccineId,
    this.vaccine,
    this.scheduleId,
    required this.administeredBy,
    required this.administeredAt,
    required this.doseGiven,
    required this.doseUnit,
    this.lotNumber,
    this.bodyWeight,
    this.nextDueDate,
    this.notes,
  });

  factory VaccineRecord.fromJson(Map<String, dynamic> json) => VaccineRecord(
        id: json['id'] ?? '',
        animalId: json['animalId'] ?? '',
        vaccineId: json['vaccineId'] ?? '',
        vaccine: json['vaccine'] != null ? Vaccine.fromJson(json['vaccine']) : null,
        scheduleId: json['scheduleId'],
        administeredBy: json['administeredBy'] ?? '',
        administeredAt: DateTime.parse(json['administeredAt']),
        doseGiven: (json['doseGiven'] ?? 0).toDouble(),
        doseUnit: json['doseUnit'] ?? 'ml',
        lotNumber: json['lotNumber'],
        bodyWeight: json['bodyWeight']?.toDouble(),
        nextDueDate: json['nextDueDate'] != null ? DateTime.tryParse(json['nextDueDate']) : null,
        notes: json['notes'],
      );
}

class VaccineRegulation {
  final String id;
  final String countryId;
  final String vaccineId;
  final Vaccine? vaccine;
  final String species;
  final String status;
  final String? frequency;
  final int intervalDays;
  final bool isFreeNational;
  final int? seasonalMonthStart;
  final int? seasonalMonthEnd;
  final String? notes;

  const VaccineRegulation({
    required this.id,
    required this.countryId,
    required this.vaccineId,
    this.vaccine,
    required this.species,
    required this.status,
    this.frequency,
    required this.intervalDays,
    required this.isFreeNational,
    this.seasonalMonthStart,
    this.seasonalMonthEnd,
    this.notes,
  });

  factory VaccineRegulation.fromJson(Map<String, dynamic> json) => VaccineRegulation(
        id: json['id'] ?? '',
        countryId: json['countryId'] ?? '',
        vaccineId: json['vaccineId'] ?? '',
        vaccine: json['vaccine'] != null ? Vaccine.fromJson(json['vaccine']) : null,
        species: json['species'] ?? '',
        status: json['status'] ?? '',
        frequency: json['frequency'],
        intervalDays: json['intervalDays'] ?? 365,
        isFreeNational: json['isFreeNational'] ?? false,
        seasonalMonthStart: json['seasonalMonthStart'],
        seasonalMonthEnd: json['seasonalMonthEnd'],
        notes: json['notes'],
      );

  bool get isForbidden => status == 'FORBIDDEN' || status == 'FORBIDDEN_ZONES';
  bool get isMandatory => status.startsWith('MANDATORY');
  bool get isUnderEradication => status == 'UNDER_ERADICATION';
}

class MedicalEvent {
  final String id;
  final String animalId;
  final DateTime eventDate;
  final String eventType; // VISIT, DISEASE, SURGERY, TREATMENT, CHECKUP, OTHER
  final String? diagnosis;
  final String? treatment;
  final String? vetName;
  final double? cost;
  final String? notes;

  const MedicalEvent({
    required this.id,
    required this.animalId,
    required this.eventDate,
    required this.eventType,
    this.diagnosis,
    this.treatment,
    this.vetName,
    this.cost,
    this.notes,
  });

  factory MedicalEvent.fromJson(Map<String, dynamic> json) => MedicalEvent(
        id: json['id'] ?? '',
        animalId: json['animalId'] ?? '',
        eventDate: DateTime.parse(json['eventDate']),
        eventType: json['eventType'] ?? 'visit',
        diagnosis: json['diagnosis'],
        treatment: json['treatment'],
        vetName: json['vetName'],
        cost: json['cost'] != null ? (json['cost'] as num).toDouble() : null,
        notes: json['notes'],
      );
}
