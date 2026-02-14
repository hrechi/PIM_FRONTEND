/// API Configuration
/// Centralized configuration for API endpoints and settings
class ApiConfig {
  // Base URLs
  // Use 10.0.2.2 for Android emulator (maps to host machine's localhost)
  // Use localhost for iOS simulator or web
  static const String _localBaseUrl = 'http://10.0.2.2:3000/api';
  static const String _productionBaseUrl = 'https://your-production-api.com/api';
  
  // Environment flag
  static const bool isProduction = false; // Set to true for production
  
  /// Get the current base URL based on environment
  static String get baseUrl => isProduction ? _productionBaseUrl : _localBaseUrl;
  
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
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }
}
