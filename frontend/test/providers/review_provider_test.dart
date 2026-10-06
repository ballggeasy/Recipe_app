import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:recipe_app/providers/review_provider.dart';
import 'package:recipe_app/services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _review({
  required double rating,
  required String content,
}) => {
  'id': 'rv1',
  'recipeId': 'r1',
  'userId': 'u1',
  'userName': 'สมชาย',
  'rating': rating,
  'content': content,
  'createdAt': '2026-10-01T00:00:00.000Z',
  'likedByUserIds': ['u2'],
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'reviewing a recipe again replaces the earlier review instead of listing it twice',
    () async {
      // The backend keeps one review per user per recipe and answers a second post with the same review id.
      final log = <http.Request>[];
      var call = 0;
      final provider = ReviewProvider(
        reviewService: ReviewService(
          api: fakeApi({
            'GET /recipes/r1/reviews': (_) => jsonResponse([]),
            'POST /recipes/r1/reviews': (_) => jsonResponse(
              ++call == 1
                  ? _review(rating: 2, content: 'so-so')
                  : _review(rating: 5, content: 'great now'),
              201,
            ),
          }, log: log),
        ),
      );
      await provider.loadForRecipe('r1');

      await provider.addReview(recipeId: 'r1', rating: 2, content: 'so-so');
      await provider.addReview(recipeId: 'r1', rating: 5, content: 'great now');

      final reviews = provider.getReviewsForRecipe('r1');
      expect(reviews, hasLength(1));
      expect(reviews.single.content, 'great now');
      expect(reviews.single.rating, 5);
    },
  );

  test(
    'does not send an empty imageUrls list, so photos already attached are kept',
    () async {
      final log = <http.Request>[];
      final provider = ReviewProvider(
        reviewService: ReviewService(
          api: fakeApi({
            'POST /recipes/r1/reviews': (_) =>
                jsonResponse(_review(rating: 4, content: 'ok'), 201),
          }, log: log),
        ),
      );

      await provider.addReview(recipeId: 'r1', rating: 4, content: 'ok');

      final body = jsonDecode(log.single.body) as Map<String, dynamic>;
      expect(body.containsKey('imageUrls'), isFalse);
      expect(body, containsPair('rating', 4));
    },
  );
}
