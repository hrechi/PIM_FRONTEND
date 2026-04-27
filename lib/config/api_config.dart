/// API Configuration
/// Centralized configuration for API endpoints and settings
import '../utils/constants.dart';

class ApiConfig {
  // Base URLs
  // Use the WiFi IP for device, emulator, and simulator testing.
  static String get _localBaseUrl => 'http://${AppConfig.serverHost}:${AppConfig.serverPort}/api';
  static const String _productionBaseUrl =
      'https://your-production-api.com/api';

  // Environment flag
  static const bool isProduction = false; // Set to true for production

  /// Get the current base URL based on environment
  static String get baseUrl =>
      isProduction ? _productionBaseUrl : _localBaseUrl;

  // API Endpoints
  static String get soilEndpoint => '$baseUrl/soil';
  static String get userEndpoint => '$baseUrl/user';
  static String get authEndpoint => '$baseUrl/auth';

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get headers with authentication token
  static Map<String, String> getAuthHeaders(String token) {
    return {...defaultHeaders, 'Authorization': 'Bearer $token'};
  }
}
