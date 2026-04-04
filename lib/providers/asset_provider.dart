import 'package:flutter/foundation.dart';
import '../models/asset_item.dart';
import '../services/api_service.dart';

class AssetProvider with ChangeNotifier {
  List<AssetItem> _assets = [];
  List<Map<String, dynamic>> _staffOptions = [];
  List<Map<String, dynamic>> _fieldOptions = [];
  bool _isLoading = false;
  String? _error;

  List<AssetItem> get assets => _assets;
  List<Map<String, dynamic>> get staffOptions => _staffOptions;
  List<Map<String, dynamic>> get fieldOptions => _fieldOptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAssets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/assets', withAuth: true);
      final list = (response as List)
          .map((item) => AssetItem.fromJson(item as Map<String, dynamic>))
          .toList();
      _assets = list;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Unable to load assets';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchStaffOptions() async {
    try {
      final response = await ApiService.get('/staff', withAuth: true);
      _staffOptions = List<Map<String, dynamic>>.from(response as List);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to load staff list';
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchFieldOptions() async {
    try {
      final response = await ApiService.get('/field', withAuth: true);
      _fieldOptions = List<Map<String, dynamic>>.from(response as List);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to load fields list';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAsset({
    required String name,
    required String category,
    required String serialNumber,
    required String fieldId,
    String? imageUrl,
    String? assignedTo,
    DateTime? lastServiceDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'name': name,
        'category': category,
        'serial_number': serialNumber,
        'field_id': fieldId,
      };
      if (imageUrl != null && imageUrl.isNotEmpty) body['image_url'] = imageUrl;
      if (assignedTo != null && assignedTo.isNotEmpty)
        body['assignedTo'] = assignedTo;
      if (lastServiceDate != null) {
        body['last_service_date'] = lastServiceDate.toUtc().toIso8601String();
      }

      final data = await ApiService.post('/assets', body, withAuth: true);
      _assets.insert(0, AssetItem.fromJson(data as Map<String, dynamic>));
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to create asset';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAsset({
    required String assetId,
    String? status,
    String? assignedTo,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (assignedTo != null) body['assignedTo'] = assignedTo;

      final data = await ApiService.patch(
        '/assets/$assetId',
        body,
        withAuth: true,
      );
      final updated = AssetItem.fromJson(data as Map<String, dynamic>);
      final index = _assets.indexWhere((item) => item.id == assetId);
      if (index != -1) {
        _assets[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Unable to update asset';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<AssetItem?> getByQrValue(String rawValue) async {
    final qrData = rawValue.trim();
    if (qrData.isEmpty) return null;

    print('🔍 Scanning QR code: $qrData');

    // First, try to find locally by serial number
    AssetItem? localMatch;
    try {
      localMatch = _assets.firstWhere((asset) => asset.serialNumber == qrData);
      print('✅ Found locally: ${localMatch.name}');
      return localMatch;
    } catch (_) {
      print('ℹ️ Not found locally, fetching from server...');
      localMatch = null;
    }

    // If not found locally, refresh and try again
    try {
      await fetchAssets();
      print('🔄 Refreshed assets list');
    } catch (e) {
      print('❌ Error fetching assets: $e');
    }

    try {
      final match = _assets.firstWhere((asset) => asset.serialNumber == qrData);
      print('✅ Found after refresh: ${match.name}');
      return match;
    } catch (_) {
      print('❌ Asset not found with serial: $qrData');
      return null;
    }
  }
}
