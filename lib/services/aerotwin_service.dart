import 'package:dio/dio.dart';
import '../models/aerotwin_model.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AeroTwinService {
  final Dio _dio;

  AeroTwinService() : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl, 
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  )) {
     _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<NDVIRecordModel> getNDVI(String fieldId, {String? date}) async {
    try {
      final queryParams = {'fieldId': fieldId};
      if (date != null) queryParams['date'] = date;
      
      final response = await _dio.get('/aerotwin/ndvi', queryParameters: queryParams);
      return NDVIRecordModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load NDVI data');
    }
  }

  Future<List<NDVIRecordModel>> getHistory(String fieldId) async {
    try {
      final response = await _dio.get('/aerotwin/history', queryParameters: {'fieldId': fieldId});
      return (response.data as List).map((x) => NDVIRecordModel.fromJson(x)).toList();
    } catch (e) {
      throw Exception('Failed to load history');
    }
  }

  Future<AeroTwinAlert> getAlerts(String fieldId) async {
    try {
      final response = await _dio.get('/aerotwin/alerts', queryParameters: {'fieldId': fieldId});
      return AeroTwinAlert.fromJson(response.data);
    } catch (e) {
       throw Exception('Failed to load alerts');
    }
  }

  Future<SimulationResult> simulate(String fieldId, {
    required double irrigationChange,
    required double temperature,
    required double nitrogenLevel,
    required double pestRisk,
    required double sunlightHours,
  }) async {
     try {
       final response = await _dio.post('/aerotwin/simulate', data: {
         'fieldId': fieldId,
         'params': {
           'irrigationChange': irrigationChange,
           'temperature': temperature,
           'nitrogenLevel': nitrogenLevel,
           'pestRisk': pestRisk,
           'sunlightHours': sunlightHours,
         }
       });
       return SimulationResult.fromJson(response.data);
     } catch (e) {
       throw Exception('Failed to run simulation');
     }
  }
}
