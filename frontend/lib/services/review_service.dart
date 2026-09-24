import '../models/review.dart';
import 'api_client.dart';

/// เรียก backend API สำหรับรีวิว — อ่านสาธารณะ, เขียน/like/report/reply ต้อง auth
class ReviewService {
  final ApiClient _api = ApiClient();

  Future<List<Review>> fetchForRecipe(String recipeId) async {
    final data = await _api.get('/recipes/$recipeId/reviews', auth: false) as List;
    return data.map((e) => Review.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<Review> create(
    String recipeId, {
    required double rating,
    required String content,
    List<String> imageUrls = const [],
  }) async {
    final data = await _api.post(
      '/recipes/$recipeId/reviews',
      body: {'rating': rating, 'content': content, 'imageUrls': imageUrls},
    ) as Map<String, dynamic>;
    return Review.fromApi(data);
  }

  Future<Review> toggleLike(String reviewId) async {
    final data = await _api.post('/reviews/$reviewId/like') as Map<String, dynamic>;
    return Review.fromApi(data);
  }

  Future<Review> report(String reviewId) async {
    final data = await _api.post('/reviews/$reviewId/report') as Map<String, dynamic>;
    return Review.fromApi(data);
  }

  Future<Review> addReply(String reviewId, String content) async {
    final data = await _api.post('/reviews/$reviewId/replies', body: {'content': content}) as Map<String, dynamic>;
    return Review.fromApi(data);
  }
}
