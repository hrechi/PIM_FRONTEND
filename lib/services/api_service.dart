import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  // Uses the centralized server config from AppConfig.
  // Physical devices → uses AppConfig.serverHost (your PC's WiFi IP)
  // Android emulator → 10.0.2.2 (maps to host localhost)
  // Web / iOS simulator → localhost
  static String get baseUrl {
    final host = AppConfig.serverHost;
    final port = AppConfig.serverPort;

    if (kIsWeb) {
      return 'http://localhost:$port/api';
    }
    if (Platform.isAndroid) {
      // Emulator uses 10.0.2.2; real device uses the WiFi IP
      final isEmulator = host == 'localhost' || host == '127.0.0.1';
      return isEmulator
          ? 'http://10.0.2.2:$port/api'
          : 'http://$host:$port/api';
    }
    // iOS simulator can use localhost; real iPhone uses WiFi IP
    if (host == 'localhost' || host == '127.0.0.1') {
      return 'http://localhost:$port/api';
    }
    return 'http://$host:$port/api';
  }

  // ── Token Management ───────────────────────────────────────

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);

    // Also save access token to shared file for AI engine
    await _saveTokenToFile(accessToken);
  }

  // Save JWT token to shared file (~/.pim_jwt_token) for AI engine
  static Future<void> _saveTokenToFile(String token) async {
    try {
      // Try to save token to home directory (works on macOS when debugging)
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        final tokenFile = File('$homeDir/.pim_jwt_token');
        await tokenFile.writeAsString(token);
        print('[ApiService] ✓ Token saved to: ${tokenFile.path}');
      } else {
        print('[ApiService] HOME environment variable not found');
      }
    } catch (e) {
      print('[ApiService] ⚠️ Could not save token to file: $e');
      print(
        '[ApiService] This is only needed if AI engine runs on same machine',
      );
      // Not critical - continue anyway
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refreshToken');
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('rememberMe');
  }

  static Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rememberMe') ?? false;
  }

  // ── Public Header Methods ──────────────────────────────────

  static Future<Map<String, String>> getAuthHeaders() async {
    return _headers(withAuth: true);
  }

  static Future<void> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
      }
    } catch (e) {
      // Silent fail for token refresh
    }
  }

  // ── HTTP Methods ───────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _handleResponse(response, endpoint, body, withAuth);
  }

  static Future<dynamic> get(String endpoint, {bool withAuth = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(withAuth: withAuth),
    );
    return _handleResponse(response, endpoint, null, withAuth);
  }

  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _handleResponse(response, endpoint, body, withAuth);
  }

  static Future<dynamic> delete(
    String endpoint, {
    bool withAuth = false,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers(withAuth: withAuth),
    );
    return _handleResponse(response, endpoint, null, withAuth);
  }

  // ── Multipart Upload ──────────────────────────────────────

  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath, {
    String fieldName = 'file',
  }) async {
    final token = await getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$endpoint'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleUploadResponse(response);
  }

  /// Upload a staff member with name + image to the whitelist endpoint.
  static Future<Map<String, dynamic>> uploadStaff(
    String name,
    String imagePath,
  ) async {
    final token = await getAccessToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/staff'));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleUploadResponse(response);
  }

  // ── Response Handling ──────────────────────────────────────

  static Future<dynamic> _handleResponse(
    http.Response response,
    String endpoint,
    Map<String, dynamic>? body,
    bool withAuth,
  ) async {
    final data = jsonDecode(response.body);

    if (response.statusCode == 401 && withAuth) {
      // Try to refresh the token
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry the original request
        final retryHeaders = await _headers(withAuth: true);
        http.Response retryResponse;

        if (body != null) {
          retryResponse = await http.post(
            Uri.parse('$baseUrl$endpoint'),
            headers: retryHeaders,
            body: jsonEncode(body),
          );
        } else {
          retryResponse = await http.get(
            Uri.parse('$baseUrl$endpoint'),
            headers: retryHeaders,
          );
        }

        final retryData = jsonDecode(retryResponse.body);
        if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
          return retryData;
        }

        // Handle error from retry
        if (retryData is Map<String, dynamic>) {
          throw ApiException(
            retryData['message']?.toString() ?? 'Request failed',
            retryResponse.statusCode,
          );
        }
        throw ApiException('Request failed', retryResponse.statusCode);
      }

      throw ApiException('Session expired. Please sign in again.', 401);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // Handle error response
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      final errorMsg = message is List
          ? message.first.toString()
          : message?.toString() ?? 'Something went wrong';
      throw ApiException(errorMsg, response.statusCode);
    }

    throw ApiException('Something went wrong', response.statusCode);
  }

  static Map<String, dynamic> _handleUploadResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw ApiException(
      data['message']?.toString() ?? 'Upload failed',
      response.statusCode,
    );
  }

  static Future<bool> _tryRefreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        return true;
      }
    } catch (_) {
      // Refresh failed
    }

    await clearTokens();
    return false;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
