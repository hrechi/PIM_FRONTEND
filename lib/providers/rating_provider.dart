import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_rating.dart';
import '../services/rating_service.dart';

/// Manages app ratings fetched from the backend.
///
/// • Loads on first access.
/// • Polls every 30 s so newly submitted ratings from other users appear
///   without requiring a manual refresh.
/// • [submitRating] posts to the backend and prepends the result locally
///   for instant UI feedback.
class RatingProvider with ChangeNotifier {
  final RatingService _service = RatingService();

  List<AppRating> _ratings = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;

  List<AppRating> get ratings => List.unmodifiable(_ratings);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Initialise ────────────────────────────────────────────────────────────

  /// Call once (e.g. from main.dart or the home screen's initState).
  Future<void> init() async {
    await _load();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  // ── Internal fetch ────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final fresh = await _service.fetchRatings(limit: 60);
      _ratings = fresh;
      _error = null;
      notifyListeners();
    } catch (e) {
      // Keep stale data; surface error only on first load.
      if (_ratings.isEmpty) {
        _error = 'Could not load ratings.';
        notifyListeners();
      }
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Submit a new rating. Optimistically prepends it, then confirms from server.
  Future<void> submitRating({
    required int stars,
    String? message,
    required String userName,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final saved = await _service.submitRating(stars: stars, message: message);
      // Prepend the confirmed record (server version has real id + timestamp).
      _ratings = [saved, ..._ratings];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
