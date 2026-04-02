import 'package:flutter/material.dart';
import '../models/short_video.dart';
import '../services/shorts_service.dart';

class ShortsProvider extends ChangeNotifier {
  final ShortsService _service = ShortsService();

  List<ShortVideo> _videos = [];
  List<String> _categories = ['all', 'crops', 'livestock', 'agritech', 'organic', 'harvesting'];
  String _activeCategory = 'all';
  String? _nextPageToken;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────
  List<ShortVideo> get videos => _videos;
  List<String> get categories => _categories;
  String get activeCategory => _activeCategory;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  bool get hasMore => _nextPageToken != null;

  /// Load the initial page of shorts
  Future<void> loadShorts() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchShorts(
        category: _activeCategory,
      );
      _videos = response.videos;
      _nextPageToken = response.nextPageToken;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page of shorts (infinite scroll)
  Future<void> loadMore() async {
    if (_isLoadingMore || _nextPageToken == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _service.fetchShorts(
        category: _activeCategory,
        pageToken: _nextPageToken,
      );
      _videos.addAll(response.videos);
      _nextPageToken = response.nextPageToken;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Switch category and reload
  Future<void> changeCategory(String category) async {
    if (_activeCategory == category) return;
    _activeCategory = category;
    _videos = [];
    _nextPageToken = null;
    notifyListeners();
    await loadShorts();
  }

  /// Fetch categories from backend (fallback to default list)
  Future<void> loadCategories() async {
    try {
      final cats = await _service.fetchCategories();
      if (cats.isNotEmpty) {
        _categories = cats;
        notifyListeners();
      }
    } catch (_) {
      // Keep default categories on error
    }
  }

  /// Refresh shorts: reload from API and shuffle order (pull-to-refresh)
  Future<void> refreshShorts() async {
    if (_isRefreshing || _isLoading) return;

    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchShorts(
        category: _activeCategory,
      );
      _videos = response.videos;
      _videos.shuffle(); // Randomize order
      _nextPageToken = response.nextPageToken;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
}
