import 'animal.dart';

class CatalogueSettings {
  final bool showPhotos;
  final bool showDetails;
  final bool showHealth;
  final bool showVaccinations;
  final bool showProduction;
  final bool showGenetics;
  final bool twoColumnLayout;
  final bool showQrCodes;
  final bool showContactInfo;
  final bool showPrices;
  final bool showNotes;
  final bool compactMode;

  const CatalogueSettings({
    this.showPhotos = true,
    this.showDetails = true,
    this.showHealth = false,
    this.showVaccinations = false,
    this.showProduction = false,
    this.showGenetics = false,
    this.twoColumnLayout = false,
    this.showQrCodes = false,
    this.showContactInfo = false,
    this.showPrices = false,
    this.showNotes = false,
    this.compactMode = false,
  });

  factory CatalogueSettings.defaultSettings() {
    return const CatalogueSettings(
      showPhotos: true,
      showDetails: true,
      showHealth: false,
      showVaccinations: false,
      showProduction: false,
      showGenetics: false,
      twoColumnLayout: false,
      showQrCodes: false,
      showContactInfo: false,
      showPrices: false,
      showNotes: false,
      compactMode: false,
    );
  }

  CatalogueSettings copyWith({
    bool? showPhotos,
    bool? showDetails,
    bool? showHealth,
    bool? showVaccinations,
    bool? showProduction,
    bool? showGenetics,
    bool? twoColumnLayout,
    bool? showQrCodes,
    bool? showContactInfo,
    bool? showPrices,
    bool? showNotes,
    bool? compactMode,
  }) {
    return CatalogueSettings(
      showPhotos: showPhotos ?? this.showPhotos,
      showDetails: showDetails ?? this.showDetails,
      showHealth: showHealth ?? this.showHealth,
      showVaccinations: showVaccinations ?? this.showVaccinations,
      showProduction: showProduction ?? this.showProduction,
      showGenetics: showGenetics ?? this.showGenetics,
      twoColumnLayout: twoColumnLayout ?? this.twoColumnLayout,
      showQrCodes: showQrCodes ?? this.showQrCodes,
      showContactInfo: showContactInfo ?? this.showContactInfo,
      showPrices: showPrices ?? this.showPrices,
      showNotes: showNotes ?? this.showNotes,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showPhotos': showPhotos,
      'showDetails': showDetails,
      'showHealth': showHealth,
      'showVaccinations': showVaccinations,
      'showProduction': showProduction,
      'showGenetics': showGenetics,
      'twoColumnLayout': twoColumnLayout,
      'showQrCodes': showQrCodes,
      'showContactInfo': showContactInfo,
      'showPrices': showPrices,
      'showNotes': showNotes,
      'compactMode': compactMode,
    };
  }

  factory CatalogueSettings.fromJson(Map<String, dynamic> json) {
    return CatalogueSettings(
      showPhotos: json['showPhotos'] ?? true,
      showDetails: json['showDetails'] ?? true,
      showHealth: json['showHealth'] ?? false,
      showVaccinations: json['showVaccinations'] ?? false,
      showProduction: json['showProduction'] ?? false,
      showGenetics: json['showGenetics'] ?? false,
      twoColumnLayout: json['twoColumnLayout'] ?? false,
      showQrCodes: json['showQrCodes'] ?? false,
      showContactInfo: json['showContactInfo'] ?? false,
      showPrices: json['showPrices'] ?? false,
      showNotes: json['showNotes'] ?? false,
      compactMode: json['compactMode'] ?? false,
    );
  }
}

class SaleCatalogue {
  final String id;
  final String farmerId;
  final String title;
  final DateTime? saleDate;
  final String? location;
  final String currency;
  final bool showPrices;
  final CatalogueSettings settings;
  final String? shareToken;
  final DateTime? shareExpiresAt;
  final int shareViewCount;
  final String status; // DRAFT, PUBLISHED, CLOSED, ARCHIVED
  final List<CatalogueAnimal> animals;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SaleCatalogue({
    required this.id,
    required this.farmerId,
    required this.title,
    this.saleDate,
    this.location,
    this.currency = "TND",
    this.showPrices = false,
    required this.settings,
    this.shareToken,
    this.shareExpiresAt,
    this.shareViewCount = 0,
    this.status = "DRAFT",
    this.animals = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleCatalogue.fromJson(Map<String, dynamic> json) {
    return SaleCatalogue(
      id: json['id'],
      farmerId: json['farmerId'],
      title: json['title'],
      saleDate: json['saleDate'] != null ? DateTime.parse(json['saleDate']) : null,
      location: json['location'],
      currency: json['currency'] ?? "TND",
      showPrices: json['showPrices'] ?? false,
      settings: CatalogueSettings.fromJson(json['settings'] ?? {}),
      shareToken: json['shareToken'],
      shareExpiresAt: json['shareExpiresAt'] != null ? DateTime.parse(json['shareExpiresAt']) : null,
      shareViewCount: json['shareViewCount'] ?? 0,
      status: json['status'] ?? "DRAFT",
      animals: (json['animals'] as List<dynamic>?)
          ?.map((animal) => CatalogueAnimal.fromJson(animal))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmerId': farmerId,
      'title': title,
      'saleDate': saleDate?.toIso8601String(),
      'location': location,
      'currency': currency,
      'showPrices': showPrices,
      'settings': settings.toJson(),
      'shareToken': shareToken,
      'shareExpiresAt': shareExpiresAt?.toIso8601String(),
      'shareViewCount': shareViewCount,
      'status': status,
      'animals': animals.map((animal) => animal.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class CatalogueAnimal {
  final String id;
  final String catalogueId;
  final String animalId;
  final int sortOrder;
  final double? priceOverride;
  final String? notes;
  final Animal? animal; // Populated when including animal data

  const CatalogueAnimal({
    required this.id,
    required this.catalogueId,
    required this.animalId,
    this.sortOrder = 0,
    this.priceOverride,
    this.notes,
    this.animal,
  });

  factory CatalogueAnimal.fromJson(Map<String, dynamic> json) {
    return CatalogueAnimal(
      id: json['id'],
      catalogueId: json['catalogueId'],
      animalId: json['animalId'],
      sortOrder: json['sortOrder'] ?? 0,
      priceOverride: json['priceOverride']?.toDouble(),
      notes: json['notes'],
      animal: json['animal'] != null ? Animal.fromJson(json['animal']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catalogueId': catalogueId,
      'animalId': animalId,
      'sortOrder': sortOrder,
      'priceOverride': priceOverride,
      'notes': notes,
      'animal': animal?.toJson(),
    };
  }

  CatalogueAnimal copyWith({
    String? id,
    String? catalogueId,
    String? animalId,
    int? sortOrder,
    double? priceOverride,
    String? notes,
    Animal? animal,
  }) {
    return CatalogueAnimal(
      id: id ?? this.id,
      catalogueId: catalogueId ?? this.catalogueId,
      animalId: animalId ?? this.animalId,
      sortOrder: sortOrder ?? this.sortOrder,
      priceOverride: priceOverride ?? this.priceOverride,
      notes: notes ?? this.notes,
      animal: animal ?? this.animal,
    );
  }

  // Helper getters for catalogue display
  String? get species => animal?.animalType;
  String? get color => null; // Not available in current model
  DateTime? get birthDate => animal?.createdAt; // Using createdAt as approximation
  double? get price => priceOverride ?? animal?.estimatedValue ?? animal?.salePrice;
  String? get imageUrl => animal?.profileImage;
}