import '../models/soil_measurement.dart';
import 'soil_api_service.dart';

/// Repository pattern for Soil Measurement data access
/// Provides a clean abstraction layer over the API service
class SoilRepository {
  final SoilApiService _apiService;

  SoilRepository({SoilApiService? apiService})
      : _apiService = apiService ?? SoilApiService();

  /// Get paginated list of soil measurements
  Future<PaginatedSoilResponse> getMeasurements({
    int page = 1,
    int limit = 10,
    double? minPh,
    double? maxPh,
    double? minMoisture,
    double? maxMoisture,
    double? minTemperature,
    double? maxTemperature,
    String? sortBy = 'createdAt',
    String? order = 'DESC',
  }) async {
    return await _apiService.getMeasurements(
      page: page,
      limit: limit,
      minPh: minPh,
      maxPh: maxPh,
      minMoisture: minMoisture,
      maxMoisture: maxMoisture,
      minTemperature: minTemperature,
      maxTemperature: maxTemperature,
      sortBy: sortBy,
      order: order,
    );
  }

  /// Get a single measurement by ID
  Future<SoilMeasurement> getMeasurementById(String id) async {
    return await _apiService.getMeasurementById(id);
  }

  /// Create a new soil measurement
  Future<SoilMeasurement> createMeasurement({
    required double ph,
    required double soilMoisture,
    required double sunlight,
    required Map<String, dynamic> nutrients,
    required double temperature,
    required double latitude,
    required double longitude,
    String? fieldId,
  }) async {
    final dto = CreateSoilMeasurementDto(
      ph: ph,
      soilMoisture: soilMoisture,
      sunlight: sunlight,
      nutrients: nutrients,
      temperature: temperature,
      latitude: latitude,
      longitude: longitude,
      fieldId: fieldId,
    );

    return await _apiService.createMeasurement(dto);
  }

  /// Update an existing measurement
  Future<SoilMeasurement> updateMeasurement({
    required String id,
    double? ph,
    double? soilMoisture,
    double? sunlight,
    Map<String, dynamic>? nutrients,
    double? temperature,
    double? latitude,
    double? longitude,
    String? fieldId,
  }) async {
    final dto = UpdateSoilMeasurementDto(
      ph: ph,
      soilMoisture: soilMoisture,
      sunlight: sunlight,
      nutrients: nutrients,
      temperature: temperature,
      latitude: latitude,
      longitude: longitude,
      fieldId: fieldId,
    );

    return await _apiService.updateMeasurement(id, dto);
  }

  /// Delete a measurement
  Future<void> deleteMeasurement(String id) async {
    return await _apiService.deleteMeasurement(id);
  }

  /// Get all healthy measurements
  Future<List<SoilMeasurement>> getHealthyMeasurements({
    int page = 1,
    int limit = 100,
  }) async {
    final response = await getMeasurements(
      page: page,
      limit: limit,
      minPh: 6.0,
      maxPh: 7.5,
      minMoisture: 30,
      maxMoisture: 80,
    );
    return response.data;
  }

  /// Get measurements with warnings (unhealthy)
  Future<List<SoilMeasurement>> getWarningMeasurements({
    int page = 1,
    int limit = 100,
  }) async {
    // This would require multiple API calls or backend support
    // For now, we'll fetch all and filter on client side
    final response = await getMeasurements(
      page: page,
      limit: limit,
    );
    return response.data.where((m) => !m.isHealthy).toList();
  }
}
