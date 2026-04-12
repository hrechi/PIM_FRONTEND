import 'package:dio/dio.dart';
import '../models/aerotwin_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AeroTwinService {
  final Dio _dio;

  AeroTwinService() : _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000/api', 
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
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
  }) async {
     try {
       final response = await _dio.post('/aerotwin/simulate', data: {
         'fieldId': fieldId,
         'params': {
           'irrigationChange': irrigationChange,
           'temperature': temperature,
           'nitrogenLevel': nitrogenLevel,
         }
       });
       return SimulationResult.fromJson(response.data);
     } catch (e) {
       throw Exception('Failed to run simulation');
     }
  }
}
