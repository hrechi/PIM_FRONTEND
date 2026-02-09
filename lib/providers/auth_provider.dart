import 'package:flutter/material.dart';
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

      final data = await ApiService.patch('/user/profile', body, withAuth: true);
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
