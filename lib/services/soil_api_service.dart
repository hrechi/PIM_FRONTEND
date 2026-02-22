import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/api_config.dart';
import '../models/soil_measurement.dart';
import '../models/ai_prediction.dart';

/// API Service for Soil Measurements
/// Handles all HTTP communication with the backend
class SoilApiService {
  final Dio _dio;

  SoilApiService({Dio? dio}) : _dio = dio ?? _createDio();

  /// Create and configure Dio instance
  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.soilEndpoint,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ));

    // Add logger in debug mode
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );

    return dio;
  }

  /// Get paginated list of soil measurements
  /// 
  /// Parameters:
  /// - [page]: Page number (default: 1)
  /// - [limit]: Items per page (default: 10)
  /// - [minPh]: Filter by minimum pH
  /// - [maxPh]: Filter by maximum pH
  /// - [minMoisture]: Filter by minimum moisture
  /// - [maxMoisture]: Filter by maximum moisture
  /// - [sortBy]: Sort field (createdAt, ph, soilMoisture, temperature)
  /// - [order]: Sort order (ASC, DESC)
  Future<PaginatedSoilResponse> getMeasurements({
    int page = 1,
    int limit = 10,
    double? minPh,
    double? maxPh,
    double? minMoisture,
    double? maxMoisture,
    double? minTemperature,
    double? maxTemperature,
    String? sortBy,
    String? order,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (minPh != null) 'minPh': minPh,
        if (maxPh != null) 'maxPh': maxPh,
        if (minMoisture != null) 'minMoisture': minMoisture,
        if (maxMoisture != null) 'maxMoisture': maxMoisture,
        if (minTemperature != null) 'minTemperature': minTemperature,
        if (maxTemperature != null) 'maxTemperature': maxTemperature,
        if (sortBy != null) 'sortBy': sortBy,
        if (order != null) 'order': order,
      };

      final response = await _dio.get(
        '',
        queryParameters: queryParams,
      );

      return PaginatedSoilResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single soil measurement by ID
  Future<SoilMeasurement> getMeasurementById(String id) async {
    try {
      final response = await _dio.get('/$id');
      return SoilMeasurement.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new soil measurement
  Future<SoilMeasurement> createMeasurement(
    CreateSoilMeasurementDto dto,
  ) async {
    try {
      final response = await _dio.post(
        '',
        data: dto.toJson(),
      );
      return SoilMeasurement.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing soil measurement
  Future<SoilMeasurement> updateMeasurement(
    String id,
    UpdateSoilMeasurementDto dto,
  ) async {
    try {
      final response = await _dio.patch(
        '/$id',
        data: dto.toJson(),
      );
      return SoilMeasurement.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a soil measurement
  Future<void> deleteMeasurement(String id) async {
    try {
      await _dio.delete('/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== AI PREDICTION METHODS ====================

  /// Get AI prediction for a soil measurement
  /// 
  /// Calls the backend which forwards to the AI microservice
  Future<AiPrediction> getPrediction(String measurementId) async {
    try {
      final response = await _dio.get('/$measurementId/predict');
      return AiPrediction.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        throw SoilApiException(
          'AI service is currently unavailable. Please try again later.',
          type: SoilApiExceptionType.server,
        );
      }
      throw _handleError(e);
    }
  }

  /// Get batch predictions for multiple measurements
  Future<List<AiPrediction>> getBatchPredictions(
    List<String> measurementIds,
  ) async {
    try {
      final response = await _dio.post(
        '/predict/batch',
        data: {'measurementIds': measurementIds},
      );
      
      return (response.data as List)
          .map((json) => AiPrediction.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Check AI service health
  Future<Map<String, dynamic>> checkAiHealth() async {
    try {
      final response = await _dio.get('/ai/health');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors and convert to meaningful exceptions
  SoilApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return SoilApiException(
          'Connection timeout. Please check your internet connection.',
          type: SoilApiExceptionType.timeout,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 
                       error.response?.data?['error'] ?? 
                       'An error occurred';

        if (statusCode == 404) {
          return SoilApiException(
            'Measurement not found',
            type: SoilApiExceptionType.notFound,
            statusCode: statusCode,
          );
        } else if (statusCode == 400) {
          return SoilApiException(
            message is List ? message.join(', ') : message.toString(),
            type: SoilApiExceptionType.validation,
            statusCode: statusCode,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return SoilApiException(
            'Server error. Please try again later.',
            type: SoilApiExceptionType.server,
            statusCode: statusCode,
          );
        }

        return SoilApiException(
          message.toString(),
          type: SoilApiExceptionType.unknown,
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return SoilApiException(
          'Request was cancelled',
          type: SoilApiExceptionType.cancelled,
        );

      case DioExceptionType.connectionError:
        return SoilApiException(
          'Cannot connect to server. Please check if the backend is running.',
          type: SoilApiExceptionType.network,
        );

      default:
        return SoilApiException(
          error.message ?? 'Unknown error occurred',
          type: SoilApiExceptionType.unknown,
        );
    }
  }
}

/// DTO for creating a soil measurement
class CreateSoilMeasurementDto {
  final double ph;
  final double soilMoisture;
  final double sunlight;
  final Map<String, dynamic> nutrients;
  final double temperature;
  final double latitude;
  final double longitude;

  const CreateSoilMeasurementDto({
    required this.ph,
    required this.soilMoisture,
    required this.sunlight,
    required this.nutrients,
    required this.temperature,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'ph': ph,
      'soilMoisture': soilMoisture,
      'sunlight': sunlight,
      'nutrients': nutrients,
      'temperature': temperature,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// DTO for updating a soil measurement
class UpdateSoilMeasurementDto {
  final double? ph;
  final double? soilMoisture;
  final double? sunlight;
  final Map<String, dynamic>? nutrients;
  final double? temperature;
  final double? latitude;
  final double? longitude;

  const UpdateSoilMeasurementDto({
    this.ph,
    this.soilMoisture,
    this.sunlight,
    this.nutrients,
    this.temperature,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (ph != null) json['ph'] = ph;
    if (soilMoisture != null) json['soilMoisture'] = soilMoisture;
    if (sunlight != null) json['sunlight'] = sunlight;
    if (nutrients != null) json['nutrients'] = nutrients;
    if (temperature != null) json['temperature'] = temperature;
    if (latitude != null) json['latitude'] = latitude;
    if (longitude != null) json['longitude'] = longitude;
    return json;
  }
}

/// Paginated response wrapper
class PaginatedSoilResponse {
  final List<SoilMeasurement> data;
  final PaginationMeta meta;

  const PaginatedSoilResponse({
    required this.data,
    required this.meta,
  });

  factory PaginatedSoilResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedSoilResponse(
      data: (json['data'] as List)
          .map((item) => SoilMeasurement.fromJson(item))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta']),
    );
  }
}

/// Pagination metadata
class PaginationMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

/// Exception types for API errors
enum SoilApiExceptionType {
  network,
  timeout,
  notFound,
  validation,
  server,
  cancelled,
  unknown,
}

/// Custom exception for Soil API errors
class SoilApiException implements Exception {
  final String message;
  final SoilApiExceptionType type;
  final int? statusCode;

  const SoilApiException(
    this.message, {
    required this.type,
    this.statusCode,
  });

  @override
  String toString() => message;

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case SoilApiExceptionType.network:
        return 'Cannot connect to server. Please check your internet connection and ensure the backend is running at http://localhost:3000';
      case SoilApiExceptionType.timeout:
        return 'Request timed out. Please try again.';
      case SoilApiExceptionType.notFound:
        return 'Measurement not found.';
      case SoilApiExceptionType.validation:
        return message;
      case SoilApiExceptionType.server:
        return 'Server error. Please try again later.';
      case SoilApiExceptionType.cancelled:
        return 'Request was cancelled.';
      case SoilApiExceptionType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
