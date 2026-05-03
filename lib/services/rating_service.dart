import '../models/app_rating.dart';
import 'api_service.dart';

class RatingService {
  /// Submit a new rating. Requires auth.
  Future<AppRating> submitRating({
    required int stars,
    String? message,
  }) async {
    final response = await ApiService.post(
      '/ratings',
      {
        'stars': stars,
        if (message != null && message.isNotEmpty) 'message': message,
      },
      withAuth: true,
    );
    return AppRating.fromJson(response as Map<String, dynamic>);
  }

  /// Fetch the latest [limit] ratings. Public — no auth needed.
  Future<List<AppRating>> fetchRatings({int limit = 50}) async {
    final response = await ApiService.get('/ratings?limit=$limit');
    final list = response as List<dynamic>;
    return list
        .map((e) => AppRating.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
