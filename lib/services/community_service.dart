import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/community_models.dart';
import 'api_service.dart';

class CommunityService {
  Future<List<CommunityPost>> fetchPosts({int limit = 20, int offset = 0}) async {
    final data = await ApiService.get(
      '/community/posts?limit=$limit&offset=$offset',
      withAuth: true,
    );

    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(CommunityPost.fromJson)
        .toList();
  }

  Future<CommunityPost> createPost({
    String? content,
    String? imagePath,
    String? pollQuestion,
    List<String>? pollOptions,
    DateTime? pollEndsAt,
  }) async {
    final token = await ApiService.getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/community/posts'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (content != null && content.trim().isNotEmpty) {
      request.fields['content'] = content.trim();
    }

    if (pollQuestion != null && pollQuestion.trim().isNotEmpty) {
      request.fields['pollQuestion'] = pollQuestion.trim();
    }

    final cleanedOptions = (pollOptions ?? [])
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();

    if (cleanedOptions.isNotEmpty) {
      request.fields['pollOptions'] = jsonEncode(cleanedOptions);
    }

    if (pollEndsAt != null) {
      request.fields['pollEndsAt'] = pollEndsAt.toUtc().toIso8601String();
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return CommunityPost.fromJson(body as Map<String, dynamic>);
    }

    final message =
        (body is Map<String, dynamic> ? body['message']?.toString() : null) ??
            'Failed to create post';
    throw ApiException(message, response.statusCode);
  }

  Future<Map<String, dynamic>> reactToPost(String postId, String type) async {
    final data = await ApiService.post(
      '/community/posts/$postId/react',
      {'type': type},
      withAuth: true,
    );

    return (data as Map).cast<String, dynamic>();
  }

  Future<List<CommunityComment>> fetchComments(String postId) async {
    final data = await ApiService.get(
      '/community/posts/$postId/comments',
      withAuth: true,
    );

    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(CommunityComment.fromJson)
        .toList();
  }

  Future<CommunityComment> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (parentCommentId != null) {
      body['parentCommentId'] = parentCommentId;
    }

    final data = await ApiService.post(
      '/community/posts/$postId/comments',
      body,
      withAuth: true,
    );

    return CommunityComment.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Map<String, dynamic>> reactToComment(String commentId, String type) async {
    final data = await ApiService.post(
      '/community/comments/$commentId/react',
      {'type': type},
      withAuth: true,
    );

    return (data as Map).cast<String, dynamic>();
  }

  Future<CommunityComment> updateComment({
    required String commentId,
    required String content,
  }) async {
    final data = await ApiService.patch(
      '/community/comments/$commentId',
      {'content': content},
      withAuth: true,
    );

    return CommunityComment.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> deleteComment(String commentId) async {
    await ApiService.delete(
      '/community/comments/$commentId',
      withAuth: true,
    );
  }

  Future<Map<String, dynamic>> vote(String postId, String optionId) async {
    final data = await ApiService.post(
      '/community/posts/$postId/vote',
      {'optionId': optionId},
      withAuth: true,
    );

    return (data as Map).cast<String, dynamic>();
  }

  Future<CommunityPost> updatePost({
    required String postId,
    required String content,
  }) async {
    final data = await ApiService.patch(
      '/community/posts/$postId',
      {'content': content},
      withAuth: true,
    );

    return CommunityPost.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> deletePost(String postId) async {
    await ApiService.delete(
      '/community/posts/$postId',
      withAuth: true,
    );
  }
}
