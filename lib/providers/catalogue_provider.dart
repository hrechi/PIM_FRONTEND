import 'package:flutter/foundation.dart';
import '../models/catalogue_models.dart';
import '../models/animal.dart';
import '../services/catalogue_service.dart';

class CatalogueProvider with ChangeNotifier {
  final CatalogueService _catalogueService = CatalogueService();

  // State
  List<SaleCatalogue> _catalogues = [];
  SaleCatalogue? _currentCatalogue;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SaleCatalogue> get catalogues => _catalogues;
  SaleCatalogue? get currentCatalogue => _currentCatalogue;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all catalogues
  Future<void> loadCatalogues({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _catalogues = await _catalogueService.getCatalogues(page: page, limit: limit);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load a specific catalogue
  Future<void> loadCatalogue(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentCatalogue = await _catalogueService.getCatalogue(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new catalogue
  Future<SaleCatalogue?> createCatalogue({
    required String title,
    DateTime? saleDate,
    String? location,
    String currency = "TND",
    bool showPrices = false,
    CatalogueSettings? settings,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final catalogue = await _catalogueService.createCatalogue(
        title: title,
        saleDate: saleDate,
        location: location,
        currency: currency,
        showPrices: showPrices,
        settings: settings,
      );

      _catalogues.insert(0, catalogue);
      _currentCatalogue = catalogue;
      return catalogue;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a catalogue
  Future<SaleCatalogue?> updateCatalogue(
    String id, {
    String? title,
    DateTime? saleDate,
    String? location,
    String? currency,
    bool? showPrices,
    CatalogueSettings? settings,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedCatalogue = await _catalogueService.updateCatalogue(
        id,
        title: title,
        saleDate: saleDate,
        location: location,
        currency: currency,
        showPrices: showPrices,
        settings: settings,
        status: status,
      );

      // Update in the list
      final index = _catalogues.indexWhere((c) => c.id == id);
      if (index != -1) {
        _catalogues[index] = updatedCatalogue;
      }

      if (_currentCatalogue?.id == id) {
        _currentCatalogue = updatedCatalogue;
      }

      return updatedCatalogue;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a catalogue
  Future<bool> deleteCatalogue(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _catalogueService.deleteCatalogue(id);
      _catalogues.removeWhere((c) => c.id == id);

      if (_currentCatalogue?.id == id) {
        _currentCatalogue = null;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add animals to catalogue
  Future<List<CatalogueAnimal>?> addAnimals(String catalogueId, List<String> animalIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final addedAnimals = await _catalogueService.addAnimals(catalogueId, animalIds);

      if (_currentCatalogue?.id == catalogueId) {
        _currentCatalogue!.animals.addAll(addedAnimals);
      }

      return addedAnimals;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove animal from catalogue
  Future<bool> removeAnimal(String catalogueId, String animalId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _catalogueService.removeAnimal(catalogueId, animalId);

      if (_currentCatalogue?.id == catalogueId) {
        _currentCatalogue!.animals.removeWhere((a) => a.animalId == animalId);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update catalogue animal
  Future<CatalogueAnimal?> updateCatalogueAnimal(
    String catalogueId,
    String animalId, {
    int? sortOrder,
    double? priceOverride,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedAnimal = await _catalogueService.updateCatalogueAnimal(
        catalogueId,
        animalId,
        sortOrder: sortOrder,
        priceOverride: priceOverride,
        notes: notes,
      );

      if (_currentCatalogue?.id == catalogueId) {
        final index = _currentCatalogue!.animals.indexWhere((a) => a.animalId == animalId);
        if (index != -1) {
          _currentCatalogue!.animals[index] = updatedAnimal;
        }
      }

      return updatedAnimal;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Preview filter animals
  Future<List<Animal>?> previewFilter({
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
    bool? isFattening,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _catalogueService.previewFilter(
        species: species,
        sex: sex,
        fieldId: fieldId,
        minAgeMonths: minAgeMonths,
        maxAgeMonths: maxAgeMonths,
        minWeight: minWeight,
        maxWeight: maxWeight,
        vaccinationStatus: vaccinationStatus,
        reproductionStatus: reproductionStatus,
        tagNumber: tagNumber,
        isFattening: isFattening,
      );
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate share link
  Future<SaleCatalogue?> generateShareLink(String catalogueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedCatalogue = await _catalogueService.generateShareLink(catalogueId);

      // Update in the list
      final index = _catalogues.indexWhere((c) => c.id == catalogueId);
      if (index != -1) {
        _catalogues[index] = updatedCatalogue;
      }

      if (_currentCatalogue?.id == catalogueId) {
        _currentCatalogue = updatedCatalogue;
      }

      return updatedCatalogue;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Revoke share link
  Future<SaleCatalogue?> revokeShareLink(String catalogueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedCatalogue = await _catalogueService.revokeShareLink(catalogueId);

      // Update in the list
      final index = _catalogues.indexWhere((c) => c.id == catalogueId);
      if (index != -1) {
        _catalogues[index] = updatedCatalogue;
      }

      if (_currentCatalogue?.id == catalogueId) {
        _currentCatalogue = updatedCatalogue;
      }

      return updatedCatalogue;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get public catalogue
  Future<SaleCatalogue?> getPublicCatalogue(String shareToken) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _catalogueService.getPublicCatalogue(shareToken);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get catalogue PDF
  Future<String?> getCataloguePdf(String catalogueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _catalogueService.getCataloguePdf(catalogueId);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear current catalogue
  void clearCurrentCatalogue() {
    _currentCatalogue = null;
    notifyListeners();
  }
}