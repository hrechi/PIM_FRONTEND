import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/short_video.dart';
import 'api_service.dart';

class ShortsService {
  static const String _endpoint = 'shorts';

  /// Fetch agriculture shorts feed, optionally filtered by category
  Future<ShortsResponse> fetchShorts({
    String? pageToken,
    String category = 'all',
  }) async {
    try {
      final queryParams = <String, String>{
        'category': category,
      };
      if (pageToken != null && pageToken.isNotEmpty) {
        queryParams['pageToken'] = pageToken;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/$_endpoint')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: await ApiService.getAuthHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return ShortsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return fetchShorts(pageToken: pageToken, category: category);
      } else if (response.statusCode == 429) {
        throw Exception('API quota exceeded. Please try again later.');
      } else {
        throw Exception('Failed to load shorts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shorts: $e');
    }
  }

  /// Get available agriculture categories
  Future<List<String>> fetchCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/$_endpoint/categories'),
            headers: await ApiService.getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(jsonData['categories'] ?? []);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return fetchCategories();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Fetch comments for a specific video
  Future<CommentsResponse> fetchComments({
    required String videoId,
    String? pageToken,
  }) async {
    try {
      final queryParams = <String, String>{
        'videoId': videoId,
      };
      if (pageToken != null && pageToken.isNotEmpty) {
        queryParams['pageToken'] = pageToken;
      }

      final uri = Uri.parse('${ApiService.baseUrl}/$_endpoint/comments')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: await ApiService.getAuthHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CommentsResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        await ApiService.refreshToken();
        return fetchComments(videoId: videoId, pageToken: pageToken);
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }
}
