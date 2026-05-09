import 'package:flutter/foundation.dart';
import '../models/asset_item.dart';
import '../services/api_service.dart';

class AssetProvider with ChangeNotifier {
  List<AssetItem> _assets = [];
  List<Map<String, dynamic>> _staffOptions = [];
  List<Map<String, dynamic>> _fieldOptions = [];
  List<Map<String, dynamic>> _brandSuggestions = [];
  List<Map<String, dynamic>> _weeklyUsageIntensity = [];
  final Map<String, dynamic> _assetDiagnosticsById = {};
  final Map<String, dynamic> _assetHistoryById = {};
  final Map<String, dynamic> _assetInsightsById = {};
  final Map<String, dynamic> _predictiveMaintenanceById = {};
  Map<String, dynamic>? _activeUsageSession;
  String? _activeAssetId;
  final Set<String> _sessionLoadingAssetIds = <String>{};
  bool _isLoading = false;
  String? _error;

  List<AssetItem> get assets => _assets;
  List<Map<String, dynamic>> get staffOptions => _staffOptions;
  List<Map<String, dynamic>> get fieldOptions => _fieldOptions;
  List<Map<String, dynamic>> get brandSuggestions => _brandSuggestions;
  List<Map<String, dynamic>> get weeklyUsageIntensity => _weeklyUsageIntensity;
  Map<String, dynamic> get assetDiagnosticsById => _assetDiagnosticsById;
  Map<String, dynamic> get assetHistoryById => _assetHistoryById;
  Map<String, dynamic> get assetInsightsById => _assetInsightsById;
  Map<String, dynamic> get predictiveMaintenanceById =>
      _predictiveMaintenanceById;
  Map<String, dynamic>? get activeUsageSession => _activeUsageSession;
  bool get isSessionActive => _activeUsageSession != null;
  String? get activeAssetId => _activeAssetId;
  bool isSessionActionLoading(String assetId) =>
      _sessionLoadingAssetIds.contains(assetId);
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

        // Keep worker/farmer session state in sync with server truth so UI can
        // correctly reflect IN_USE after refresh/relogin.
        final activeAsset = list.cast<AssetItem?>().firstWhere(
          (asset) =>
            asset != null &&
            asset.status == 'IN_USE' &&
            asset.activeSession != null,
          orElse: () => null,
          );
        _activeUsageSession = activeAsset?.activeSession;
        _activeAssetId = activeAsset?.id;

      for (final asset in list) {
        try {
          await fetchPredictiveMaintenance(asset.id, notify: false);
        } catch (_) {
          // Predictive maintenance should never block the asset list.
        }
      }
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
      if (model != null && model.isNotEmpty) {
        body['model'] = model;
      }
      if (modelYear != null) body['modelYear'] = modelYear;
      if (mileage != null) body['mileage'] = mileage;
      if (operatingHours != null) body['operatingHours'] = operatingHours;
      if (resolvedImageUrl != null && resolvedImageUrl.isNotEmpty) {
        body['image_url'] = resolvedImageUrl;
      }
      if (assignedTo != null && assignedTo.isNotEmpty) {
        body['assignedTo'] = assignedTo;
      }
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
    double? startMileage,
    double? startOperatingHours,
    String? taskType,
    DateTime? startTime,
    String? notes,
  }) async {
    if (_sessionLoadingAssetIds.contains(assetId)) {
      return {
        'success': false,
        'message': 'Session action already in progress',
      };
    }

    _sessionLoadingAssetIds.add(assetId);
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/assets/$assetId/start-session',
        {},
        withAuth: true,
      );
      final responseMap = Map<String, dynamic>.from(response as Map);
      final session = Map<String, dynamic>.from(
        (responseMap['session'] as Map?) ?? responseMap,
      );

      _activeUsageSession = session;
      _activeAssetId = assetId;
      _assets = _assets.map((asset) {
        if (asset.id != assetId) return asset;
        final updated = Map<String, dynamic>.from(asset.toJson())
          ..['status'] = 'IN_USE';
        return AssetItem.fromJson(updated);
      }).toList();

      return responseMap;
    } finally {
      _sessionLoadingAssetIds.remove(assetId);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> endUsageSession({
    String? assetId,
    String? usageLogId,
    double? distanceKm,
    String? issues,
    String? maintenanceNote,
    String? condition,
    double? endMileage,
    double? endOperatingHours,
    double? fuelLevel,
    String? conditionNote,
    DateTime? endTime,
    bool? returnConfirmation,
    String? notes,
  }) async {
    final resolvedAssetId = assetId ?? _activeAssetId;

    if (resolvedAssetId != null &&
        _sessionLoadingAssetIds.contains(resolvedAssetId)) {
      return {
        'success': false,
        'message': 'Session action already in progress',
      };
    }

    if (resolvedAssetId != null) {
      _sessionLoadingAssetIds.add(resolvedAssetId);
    }
    notifyListeners();

    try {
      late final dynamic response;
      if (resolvedAssetId != null && resolvedAssetId.isNotEmpty) {
        final payload = <String, dynamic>{
          'distanceKm': distanceKm ?? 0,
          'condition': (condition ?? 'GOOD').toUpperCase(),
        };
        if (issues != null && issues.trim().isNotEmpty) {
          payload['issues'] = issues.trim();
        }
        if (maintenanceNote != null && maintenanceNote.trim().isNotEmpty) {
          payload['maintenanceNote'] = maintenanceNote.trim();
        }

        response = await ApiService.post(
          '/assets/$resolvedAssetId/end-session',
          payload,
          withAuth: true,
        );
      } else {
        if (usageLogId == null || usageLogId.isEmpty) {
          throw ApiException('No active session to finish', 400);
        }
        final payload = <String, dynamic>{'usageLogId': usageLogId};
        if (endMileage != null) {
          payload['endMileage'] = endMileage;
        }
        if (endOperatingHours != null) {
          payload['endOperatingHours'] = endOperatingHours;
        }
        if (fuelLevel != null) {
          payload['fuelLevel'] = fuelLevel;
        }
        if (conditionNote != null && conditionNote.trim().isNotEmpty) {
          payload['conditionNote'] = conditionNote.trim();
        }
        if (endTime != null) {
          payload['endTime'] = endTime.toIso8601String();
        }
        if (returnConfirmation != null) {
          payload['returnConfirmation'] = returnConfirmation;
        }
        if (issues != null && issues.trim().isNotEmpty) {
          payload['issues'] = issues.trim();
        }
        if (notes != null && notes.trim().isNotEmpty) {
          payload['notes'] = notes.trim();
        }

        response = await ApiService.post('/assets/session/end', {
          ...payload,
        }, withAuth: true);
      }

      final responseMap = Map<String, dynamic>.from(response as Map);
      _activeUsageSession = null;
      _activeAssetId = null;
      _assets = _assets.map((asset) {
        final updatedAssetId =
            resolvedAssetId ??
            responseMap['assetId']?.toString() ??
            (responseMap['session'] as Map?)?['assetId']?.toString();
        if (updatedAssetId == null || asset.id != updatedAssetId) {
          return asset;
        }

        final updatedAsset = Map<String, dynamic>.from(asset.toJson())
          ..['status'] = 'AVAILABLE';
        return AssetItem.fromJson(updatedAsset);
      }).toList();

      return responseMap;
    } finally {
      if (resolvedAssetId != null) {
        _sessionLoadingAssetIds.remove(resolvedAssetId);
      }
      notifyListeners();
    }
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

  Future<Map<String, dynamic>> fetchAssetInsights(String assetId) async {
    final response = await ApiService.get(
      '/assets/$assetId/insights',
      withAuth: true,
    );
    final result = Map<String, dynamic>.from(response as Map);
    _assetInsightsById[assetId] = result;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> fetchPredictiveMaintenance(
    String assetId, {
    bool notify = false,
  }) async {
    try {
      final response = await ApiService.get(
        '/assets/$assetId/predictive-maintenance',
        withAuth: true,
      );
      final result = Map<String, dynamic>.from(response as Map);
      _predictiveMaintenanceById[assetId] = result;
      notifyListeners();
      return result;
    } catch (_) {
      final fallback = <String, dynamic>{
        'predictions': <String>[],
        'riskLevel': 'LOW',
        'recommendedActions': <String>[],
        'canUse': true,
      };
      _predictiveMaintenanceById[assetId] = fallback;
      notifyListeners();
      return fallback;
    }
  }

  Future<Map<String, dynamic>?> getByQrValue(String rawValue) async {
    final qrData = rawValue.trim();
    if (qrData.isEmpty) return null;

    debugPrint('🔍 Scanning QR code: $qrData');

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
      debugPrint('❌ Asset not found with serial: $qrData ($e)');
      return null;
    }
  }
}
