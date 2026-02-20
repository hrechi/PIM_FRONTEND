import 'package:flutter/foundation.dart';
import '../models/parcel.dart';
import '../services/parcel_crud_service.dart';

class ParcelProvider with ChangeNotifier {
  final ParcelCrudService _service = ParcelCrudService();

  List<Parcel> _parcels = [];
  bool _isLoading = false;
  String? _error;

  List<Parcel> get parcels => _parcels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchParcels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _parcels = await _service.getParcels();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addParcel(Map<String, dynamic> parcelData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newParcel = await _service.createParcel(parcelData);
      _parcels.add(newParcel);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateParcel(String id, Map<String, dynamic> parcelData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedParcel = await _service.updateParcel(id, parcelData);
      final index = _parcels.indexWhere((p) => p.id == id);
      if (index != -1) {
        // preserve the nested fields (they aren't fully returned by the simple update query usually, 
        // but here we just re-fetch to be absolutely sure or let the service return them)
        // for simplicity, let's just trigger a re-fetch of all parcels or merge them.
        _parcels[index] = updatedParcel; 
      }
      await fetchParcels(); // force refresh to get nested lists
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteParcel(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteParcel(id);
      _parcels.removeWhere((p) => p.id == id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Nested Additions
  Future<void> addCropToParcel(String parcelId, Map<String, dynamic> data) async {
    try {
      await _service.addCrop(parcelId, data);
      await fetchParcels(); // Refresh data to show it
    } catch(e) { rethrow; }
  }

  Future<void> addFertilizationToParcel(String parcelId, Map<String, dynamic> data) async {
    try {
      await _service.addFertilization(parcelId, data);
      await fetchParcels(); // Refresh data to show it
    } catch(e) { rethrow; }
  }

  Future<void> addPestToParcel(String parcelId, Map<String, dynamic> data) async {
    try {
      await _service.addPest(parcelId, data);
      await fetchParcels(); // Refresh data to show it
    } catch(e) { rethrow; }
  }

  Future<void> addHarvestToParcel(String parcelId, Map<String, dynamic> data) async {
    try {
      await _service.addHarvest(parcelId, data);
      await fetchParcels(); // Refresh data to show it
    } catch(e) { rethrow; }
  }
}
