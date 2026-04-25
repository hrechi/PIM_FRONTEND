import 'package:flutter/foundation.dart';
import '../models/asset_item.dart';
import '../services/api_service.dart';

class AssetProvider with ChangeNotifier {
  List<AssetItem> _assets = [];
  List<Map<String, dynamic>> _staffOptions = [];
  List<Map<String, dynamic>> _fieldOptions = [];
  List<Map<String, dynamic>> _brandSuggestions = [];
  List<Map<String, dynamic>> _weeklyUsageIntensity = [];
  Map<String, dynamic> _assetDiagnosticsById = {};
  Map<String, dynamic> _assetHistoryById = {};
  Map<String, dynamic>? _activeUsageSession;
  String? _activeAssetId;
  bool _isLoading = false;
  String? _error;

  List<AssetItem> get assets => _assets;
  List<Map<String, dynamic>> get staffOptions => _staffOptions;
  List<Map<String, dynamic>> get fieldOptions => _fieldOptions;
  List<Map<String, dynamic>> get brandSuggestions => _brandSuggestions;
  List<Map<String, dynamic>> get weeklyUsageIntensity => _weeklyUsageIntensity;
  Map<String, dynamic> get assetDiagnosticsById => _assetDiagnosticsById;
  Map<String, dynamic> get assetHistoryById => _assetHistoryById;
  Map<String, dynamic>? get activeUsageSession => _activeUsageSession;
  bool get isSessionActive => _activeUsageSession != null;
  String? get activeAssetId => _activeAssetId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _isRemoteAssetImage(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('/uploads/');
  }

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

  Future<List<String>> searchBrands(String query) async {
    if (query.trim().isEmpty) {
      _brandSuggestions = [];
      notifyListeners();
      return [];
    }

    try {
      final response = await ApiService.get(
        '/assets/brands/search?query=${Uri.encodeComponent(query)}',
        withAuth: true,
      );

      final suggestions = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      _brandSuggestions = suggestions;
      notifyListeners();
      return suggestions
          .map((item) => item['brand']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addAsset({
    required String name,
    required String brand,
    required String category,
    required String serialNumber,
    required String fieldId,
    String? model,
    int? modelYear,
    double? mileage,
    double? operatingHours,
    String? imageUrl,
    String? assignedTo,
    DateTime? lastServiceDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? resolvedImageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final candidate = imageUrl.trim();
        if (_isRemoteAssetImage(candidate)) {
          resolvedImageUrl = candidate;
        } else {
          final uploadResult = await ApiService.uploadFile(
            '/assets/upload',
            candidate,
            fieldName: 'image',
          );
          resolvedImageUrl =
              uploadResult['image_url']?.toString() ??
              uploadResult['imagePath']?.toString();
        }
      }

      final body = <String, dynamic>{
        'name': name,
        'brand': brand,
        'category': category,
        'serial_number': serialNumber,
        'field_id': fieldId,
      };
      if (model != null && model.isNotEmpty) body['model'] = model;
      if (modelYear != null) body['modelYear'] = modelYear;
      if (mileage != null) body['mileage'] = mileage;
      if (operatingHours != null) body['operatingHours'] = operatingHours;
      if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty) {
        body['image_url'] = resolvedImageUrl;
      }
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
    String? imageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? resolvedImageUrl;
      if (imageUrl != null) {
        final candidate = imageUrl.trim();
        if (candidate.isNotEmpty) {
          if (_isRemoteAssetImage(candidate)) {
            resolvedImageUrl = candidate;
          } else {
            final uploadResult = await ApiService.uploadFile(
              '/assets/upload',
              candidate,
              fieldName: 'image',
            );
            resolvedImageUrl =
                uploadResult['image_url']?.toString() ??
                uploadResult['imagePath']?.toString();
          }
        } else {
          resolvedImageUrl = '';
        }
      }

      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (assignedTo != null) body['assignedTo'] = assignedTo;
      if (resolvedImageUrl != null) body['image_url'] = resolvedImageUrl;

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

  Future<Map<String, dynamic>> startUsageSession({
    required String assetId,
    required double startMileage,
    double? startOperatingHours,
    String? taskType,
    DateTime? startTime,
    String? notes,
  }) async {
    final response = await ApiService.post('/assets/session/start', {
      'assetId': assetId,
      'startMileage': startMileage,
      if (startOperatingHours != null)
        'startOperatingHours': startOperatingHours,
      if (taskType != null && taskType.trim().isNotEmpty)
        'taskType': taskType.trim(),
      if (startTime != null) 'startTime': startTime.toIso8601String(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    }, withAuth: true);

    _activeUsageSession = Map<String, dynamic>.from(response as Map);
    _activeAssetId = _activeUsageSession?['assetId']?.toString();
    notifyListeners();
    return _activeUsageSession!;
  }

  Future<Map<String, dynamic>> endUsageSession({
    required String usageLogId,
    required double endMileage,
    double? endOperatingHours,
    double? fuelLevel,
    String? conditionNote,
    DateTime? endTime,
    required bool returnConfirmation,
    String? issues,
    String? notes,
  }) async {
    final response = await ApiService.post('/assets/session/end', {
      'usageLogId': usageLogId,
      'endMileage': endMileage,
      if (endOperatingHours != null) 'endOperatingHours': endOperatingHours,
      if (fuelLevel != null) 'fuelLevel': fuelLevel,
      if (conditionNote != null && conditionNote.trim().isNotEmpty)
        'conditionNote': conditionNote.trim(),
      if (endTime != null) 'endTime': endTime.toIso8601String(),
      'returnConfirmation': returnConfirmation,
      if (issues != null && issues.trim().isNotEmpty) 'issues': issues.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    }, withAuth: true);

    final responseMap = Map<String, dynamic>.from(response as Map);
    final updatedAssetId = responseMap['assetId']?.toString();
    _activeUsageSession = null;
    _activeAssetId = null;
    _assets = _assets.map((asset) {
      if (updatedAssetId == null || asset.id != updatedAssetId) {
        return asset;
      }

      final updatedAsset = Map<String, dynamic>.from(asset.toJson())
        ..['mileage'] = endMileage
        ..['operatingHours'] = endOperatingHours ?? asset.operatingHours;
      return AssetItem.fromJson(updatedAsset);
    }).toList();
    notifyListeners();
    return responseMap;
  }

  Future<List<Map<String, dynamic>>> fetchWeeklyUsageIntensity() async {
    final response = await ApiService.get(
      '/assets/session/weekly',
      withAuth: true,
    );
    _weeklyUsageIntensity = List<Map<String, dynamic>>.from(response as List);
    notifyListeners();
    return _weeklyUsageIntensity;
  }

  Future<Map<String, dynamic>> fetchAssetHistory(String assetId) async {
    final response = await ApiService.get(
      '/assets/$assetId/history',
      withAuth: true,
    );
    final result = Map<String, dynamic>.from(response as Map);
    _assetHistoryById[assetId] = result;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> fetchAssetDiagnostics(String assetId) async {
    final response = await ApiService.get(
      '/assets/$assetId/diagnostics',
      withAuth: true,
    );
    final result = Map<String, dynamic>.from(response as Map);
    _assetDiagnosticsById[assetId] = result;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>?> getByQrValue(String rawValue) async {
    final qrData = rawValue.trim();
    if (qrData.isEmpty) return null;

    print('🔍 Scanning QR code: $qrData');

    // First, try to find locally by serial number
    try {
      final response = await ApiService.get(
        '/assets/scan/$qrData',
        withAuth: true,
      );
      final asset = AssetItem.fromJson(
        response['asset'] as Map<String, dynamic>,
      );

      final index = _assets.indexWhere((item) => item.id == asset.id);
      if (index == -1) {
        _assets.insert(0, asset);
      } else {
        _assets[index] = asset;
      }

      notifyListeners();

      return {
        'asset': asset,
        'aiMessage': response['aiMessage']?.toString() ?? '',
      };
    } catch (e) {
      print('❌ Asset not found with serial: $qrData ($e)');
      return null;
    }
  }
}
