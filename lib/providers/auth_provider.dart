import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // ── Initialize — check stored tokens on app launch ─────────

  Future<void> initialize() async {
    final rememberMe = await ApiService.getRememberMe();
    final token = await ApiService.getAccessToken();

    if (token != null && rememberMe) {
      try {
        await fetchProfile();
      } catch (_) {
        await ApiService.clearTokens();
        _isAuthenticated = false;
        _user = null;
      }
    } else if (token != null && !rememberMe) {
      // Not remembered — clear tokens so user must log in again
      await ApiService.clearTokens();
      _isAuthenticated = false;
      _user = null;
    }
    notifyListeners();
  }

  // ── Sign Up ────────────────────────────────────────────────

  Future<bool> signUp({
    required String name,
    required String farmName,
    required String password,
    String? email,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final body = <String, dynamic>{
        'name': name,
        'farmName': farmName,
        'password': password,
      };
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;

      final data = await ApiService.post('/auth/signup', body);

      await ApiService.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );

      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // Save user data for stateless services
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(data['user']));

      // Register token with backend so AI engine auto-detects this user
      await _registerAiToken();

      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Connection failed. Please check your internet.');
      _setLoading(false);
      return false;
    }
  }

  // ── Sign In ────────────────────────────────────────────────

  Future<bool> signIn({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await ApiService.post('/auth/signin', {
        'identifier': identifier,
        'password': password,
      });

      await ApiService.saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      await ApiService.setRememberMe(rememberMe);

      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      // Save user data for stateless services
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(data['user']));

      // Register token with backend so AI engine auto-detects this user
      await _registerAiToken();

      _isAuthenticated = true;
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Connection failed. Please check your internet.');
      _setLoading(false);
      return false;
    }
  }

  // ── Fetch Profile ──────────────────────────────────────────

  Future<void> fetchProfile() async {
    final data = await ApiService.get('/user/profile', withAuth: true);
    _user = UserModel.fromJson(data);

    // Update saved user data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(data));

    _isAuthenticated = true;
    notifyListeners();
  }

  // ── Update Profile ─────────────────────────────────────────

  Future<bool> updateProfile({
    String? name,
    String? farmName,
    String? email,
    String? phone,
    String? password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (farmName != null && farmName.isNotEmpty) body['farmName'] = farmName;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (password != null && password.isNotEmpty) body['password'] = password;

      final data = await ApiService.patch(
        '/user/profile',
        body,
        withAuth: true,
      );
      _user = UserModel.fromJson(data);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Update failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ── Upload Profile Picture ─────────────────────────────────

  Future<bool> uploadProfilePicture(String filePath) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await ApiService.uploadFile(
        '/user/profile/picture',
        filePath,
      );
      _user = UserModel.fromJson(data);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Upload failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ── Delete Account ─────────────────────────────────────────

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await ApiService.delete('/user/profile', withAuth: true);
      await _logout();
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Delete failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ── Sign Out ───────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await ApiService.post('/auth/signout', {}, withAuth: true);
    } catch (_) {
      // Even if server call fails, clear local state
    }
    await _logout();
  }

  // ── Private Helpers ────────────────────────────────────────

  /// Push the current JWT to the backend so the AI engine auto-detects
  /// which user is logged in — no manual .env editing needed.
  /// Also registers the FCM device token for push notifications.
  Future<void> _registerAiToken() async {
    try {
      await ApiService.post('/security/register-ai', {}, withAuth: true);
      print('[AuthProvider] ✓ AI engine registered for current user');
    } catch (e) {
      print('[AuthProvider] ⚠ Could not register AI token: $e');
    }

    // Register FCM device token for push notifications
    try {
      final messaging = FirebaseMessaging.instance;
      // Request permission (iOS requires explicit ask)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS: APNS token must be ready before FCM token can be fetched.
      // We retry up to 5 times with a short delay to handle the race condition.
      String? fcmToken;
      for (int attempt = 1; attempt <= 5; attempt++) {
        try {
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            // Wait for APNS token to be set by the OS
            final apnsToken = await messaging.getAPNSToken();
            if (apnsToken == null) {
              print('[AuthProvider] APNS not ready (attempt $attempt/5), retrying...');
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
          }
          fcmToken = await messaging.getToken();
          break; // success — exit retry loop
        } catch (_) {
          if (attempt == 5) rethrow;
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (fcmToken != null) {
        await ApiService.post(
          '/user/fcm-token',
          {'token': fcmToken},
          withAuth: true,
        );
        print('[AuthProvider] ✓ FCM token registered: ${fcmToken.substring(0, 20)}...');
      } else {
        print('[AuthProvider] ⚠ FCM token unavailable after retries (non-critical)');
      }
    } catch (e) {
      print('[AuthProvider] ⚠ Could not register FCM token: $e');
    }
  }

  Future<void> _logout() async {
    await ApiService.clearTokens();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
