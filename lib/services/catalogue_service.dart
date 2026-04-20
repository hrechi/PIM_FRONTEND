import '../models/catalogue_models.dart';
import '../models/animal.dart';
import 'api_service.dart';
import 'package:flutter/foundation.dart';

class CatalogueService {
  // Create a new catalogue
  Future<SaleCatalogue> createCatalogue({
    required String title,
    DateTime? saleDate,
    String? location,
    String currency = "TND",
    bool showPrices = false,
    CatalogueSettings? settings,
  }) async {
    final response = await ApiService.post('/catalogues', {
      'title': title,
      'saleDate': saleDate?.toIso8601String(),
      'location': location,
      'currency': currency,
      'showPrices': showPrices,
      'settings': (settings ?? CatalogueSettings.defaultSettings()).toJson(),
    }, withAuth: true);

    return SaleCatalogue.fromJson(response);
  }

  // Get all catalogues for the current farmer
  Future<List<SaleCatalogue>> getCatalogues({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.get(
      '/catalogues?page=$page&limit=$limit',
      withAuth: true,
    );

    final data = response['items'] as List<dynamic>? ?? [];
    return data.map((json) => SaleCatalogue.fromJson(json)).toList();
  }

  // Get a specific catalogue by ID
  Future<SaleCatalogue> getCatalogue(String id) async {
    final response = await ApiService.get('/catalogues/$id', withAuth: true);
    return SaleCatalogue.fromJson(response);
  }

  // Update a catalogue
  Future<SaleCatalogue> updateCatalogue(
    String id, {
    String? title,
    DateTime? saleDate,
    String? location,
    String? currency,
    bool? showPrices,
    CatalogueSettings? settings,
    String? status,
  }) async {
    final updateData = <String, dynamic>{};
    if (title != null) updateData['title'] = title;
    if (saleDate != null) updateData['saleDate'] = saleDate.toIso8601String();
    if (location != null) updateData['location'] = location;
    if (currency != null) updateData['currency'] = currency;
    if (showPrices != null) updateData['showPrices'] = showPrices;
    if (settings != null) updateData['settings'] = settings.toJson();
    if (status != null) updateData['status'] = status;

    final response = await ApiService.patch('/catalogues/$id', updateData, withAuth: true);
    return SaleCatalogue.fromJson(response);
  }

  // Delete a catalogue
  Future<void> deleteCatalogue(String id) async {
    await ApiService.delete('/catalogues/$id', withAuth: true);
  }

  // Add animals to a catalogue
  Future<List<CatalogueAnimal>> addAnimals(String catalogueId, List<String> animalIds) async {
    final response = await ApiService.post('/catalogues/$catalogueId/animals', {
      'animalIds': animalIds,
    }, withAuth: true);

    return (response as List<dynamic>).map((json) => CatalogueAnimal.fromJson(json)).toList();
  }

  // Remove an animal from a catalogue
  Future<void> removeAnimal(String catalogueId, String animalId) async {
    await ApiService.delete('/catalogues/$catalogueId/animals/$animalId', withAuth: true);
  }

  // Update an animal in a catalogue
  Future<CatalogueAnimal> updateCatalogueAnimal(
    String catalogueId,
    String animalId, {
    int? sortOrder,
    double? priceOverride,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{};
    if (sortOrder != null) updateData['sortOrder'] = sortOrder;
    if (priceOverride != null) updateData['priceOverride'] = priceOverride;
    if (notes != null) updateData['notes'] = notes;

    final response = await ApiService.patch(
      '/catalogues/$catalogueId/animals/$animalId',
      updateData,
      withAuth: true,
    );

    return CatalogueAnimal.fromJson(response);
  }

  // Preview filter animals for catalogue creation
  Future<List<Animal>> previewFilter({
    String? species,
    String? sex,
    String? fieldId,
    int? minAgeMonths,
    int? maxAgeMonths,
    double? minWeight,
    double? maxWeight,
    String? vaccinationStatus,
    String? reproductionStatus,
    String? tagNumber,
  }) async {
    final filterData = <String, dynamic>{};
    if (species != null) filterData['species'] = species;
    if (sex != null) filterData['sex'] = sex;
    if (fieldId != null) filterData['fieldId'] = fieldId;
    if (minAgeMonths != null) filterData['minAgeMonths'] = minAgeMonths;
    if (maxAgeMonths != null) filterData['maxAgeMonths'] = maxAgeMonths;
    if (minWeight != null) filterData['minWeight'] = minWeight;
    if (maxWeight != null) filterData['maxWeight'] = maxWeight;
    if (vaccinationStatus != null) filterData['vaccinationStatus'] = vaccinationStatus;
    if (reproductionStatus != null) filterData['reproductionStatus'] = reproductionStatus;
    if (tagNumber != null) filterData['tagNumber'] = tagNumber;

    final response = await ApiService.post('/catalogues/preview-filter', filterData, withAuth: true);

    return (response as List<dynamic>).map((json) => Animal.fromJson(json)).toList();
  }

  // Generate share link for a catalogue
  Future<SaleCatalogue> generateShareLink(String catalogueId) async {
    final response = await ApiService.post('/catalogues/$catalogueId/share', {}, withAuth: true);
    return SaleCatalogue.fromJson(response);
  }

  // Revoke share link
  Future<SaleCatalogue> revokeShareLink(String catalogueId) async {
    final response = await ApiService.delete('/catalogues/$catalogueId/share', withAuth: true);
    return SaleCatalogue.fromJson(response);
  }

  // Get public catalogue (no auth required)
  Future<SaleCatalogue> getPublicCatalogue(String shareToken) async {
    final response = await ApiService.get('/public/catalogues/$shareToken', withAuth: false);
    return SaleCatalogue.fromJson(response);
  }

  // Get catalogue PDF (returns download URL or direct PDF data)
  Future<String> getCataloguePdf(String catalogueId) async {
    final response = await ApiService.get('/catalogues/$catalogueId/pdf', withAuth: true);
    // Assuming the response contains a download URL or PDF data
    return response['pdfUrl'] ?? response['pdfData'];
  }
}