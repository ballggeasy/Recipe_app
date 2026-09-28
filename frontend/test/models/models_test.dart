import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/comment.dart';
import 'package:recipe_app/models/favorite_folder.dart';
import 'package:recipe_app/models/ingredient.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/models/nutrition.dart';
import 'package:recipe_app/models/review.dart';
import 'package:recipe_app/models/user.dart';
import 'package:recipe_app/services/api_client.dart';

void main() {
  group('NutritionInfo', () {
    test('accepts fractional calories from the API instead of throwing', () {
      expect(NutritionInfo.fromJson({'calories': 350.6}).calories, 351);
    });

    test('fromJson defaults missing values to zero and accepts ints for doubles', () {
      final n = NutritionInfo.fromJson({'calories': 300, 'protein': 20});
      expect(n.calories, 300);
      expect(n.protein, 20.0);
      expect(n.fat, 0);
      expect(n.sodium, 0);
    });

    test('forServings scales every value and leaves 1 serving unchanged', () {
      const n = NutritionInfo(calories: 101, protein: 10, fat: 5, carbs: 30, sugar: 2, sodium: 400);
      expect(identical(n.forServings(1), n), isTrue);

      final doubled = n.forServings(2);
      expect(doubled.calories, 202);
      expect(doubled.protein, 20);
      expect(doubled.sodium, 800);
    });

    test('toJson round-trips through fromJson', () {
      const n = NutritionInfo(calories: 1, protein: 2, fat: 3, carbs: 4, sugar: 5, sodium: 6);
      final back = NutritionInfo.fromJson(n.toJson());
      expect(back.toJson(), n.toJson());
    });
  });

  group('IngredientItem', () {
    test('display skips empty amount and unit', () {
      expect(const IngredientItem(name: 'เกลือ', amount: '', unit: '').display, 'เกลือ');
      expect(const IngredientItem(name: 'ไข่', amount: '2', unit: '').display, '2 ไข่');
      expect(const IngredientItem(name: 'น้ำ', amount: '1', unit: 'ถ้วย').display, '1 ถ้วย น้ำ');
    });

    test('fromJson defaults amount and unit to empty strings', () {
      final item = IngredientItem.fromJson({'name': 'เกลือ'});
      expect(item.amount, '');
      expect(item.unit, '');
    });
  });

  group('Review.fromApi', () {
    test('parses replies and likes', () {
      final review = Review.fromApi({
        'id': 'rv1',
        'recipeId': 'r1',
        'userId': 'u1',
        'userName': 'สมชาย',
        'rating': 5,
        'content': 'อร่อยมาก',
        'createdAt': '2026-03-01T00:00:00.000Z',
        'likedByUserIds': ['u2', 'u3'],
        'replies': [
          {'id': 'rp1', 'userId': 'u2', 'userName': 'สมศรี', 'content': 'จริง', 'createdAt': '2026-03-02T00:00:00.000Z'},
        ],
      });

      expect(review.rating, 5.0);
      expect(review.likeCount, 2);
      expect(review.likedBy('u2'), isTrue);
      expect(review.likedBy('u1'), isFalse);
      expect(review.likedBy(null), isFalse);
      expect(review.replies.single.userName, 'สมศรี');
      expect(review.imageUrls, isEmpty);
      expect(review.isReported, isFalse);
    });
  });

  test('Review and Comment timestamps are shown in local time', () {
    const stamp = '2026-09-25T23:30:00.000Z';
    final review = Review.fromApi({
      'id': 'r1', 'recipeId': 'x', 'userId': 'u', 'userName': 'ก', 'rating': 5, 'content': '',
      'createdAt': stamp,
      'replies': [{'id': 'p1', 'userId': 'u', 'userName': 'ข', 'content': '', 'createdAt': stamp}],
    });
    final comment = Comment.fromApi({
      'id': 'c1', 'recipeId': 'x', 'userId': 'u', 'userName': 'ก', 'content': '', 'createdAt': stamp,
    });

    final local = DateTime.parse(stamp).toLocal();
    for (final d in [review.createdAt, review.replies.single.createdAt, comment.createdAt]) {
      expect(d.isUtc, isFalse);
      expect([d.year, d.month, d.day, d.hour], [local.year, local.month, local.day, local.hour]);
    }
  });

  group('Comment.fromApi', () {
    test('parses nested replies recursively', () {
      final comment = Comment.fromApi({
        'id': 'c1',
        'recipeId': 'r1',
        'userId': 'u1',
        'userName': 'A',
        'content': 'สวัสดี @B',
        'createdAt': '2026-03-01T00:00:00.000Z',
        'mentions': ['B'],
        'replies': [
          {'id': 'c2', 'recipeId': 'r1', 'userId': 'u2', 'userName': 'B', 'content': 'หวัดดี', 'createdAt': '2026-03-01T01:00:00.000Z'},
        ],
      });

      expect(comment.mentions, ['B']);
      expect(comment.replies.single.id, 'c2');
      expect(comment.replies.single.replies, isEmpty);
      expect(comment.imageUrl, isNull);
    });
  });

  group('MealPlanEntry.fromApi', () {
    test('maps mealType by enum name and defaults servings to 1', () {
      final entry = MealPlanEntry.fromApi({
        'id': 'm1',
        'recipeId': 'r1',
        'date': '2026-09-26',
        'mealType': 'dinner',
      });

      expect(entry.mealType, MealType.dinner);
      expect(entry.servings, 1);
      expect(entry.date, DateTime(2026, 9, 26));
    });

    test('converts a UTC timestamp to the local calendar day', () {
      final local = DateTime(2026, 9, 26, 1, 30);
      final entry = MealPlanEntry.fromApi({
        'id': 'm1',
        'recipeId': 'r1',
        'date': local.toUtc().toIso8601String(),
        'mealType': 'breakfast',
      });

      expect(entry.date.isUtc, isFalse);
      expect([entry.date.year, entry.date.month, entry.date.day], [2026, 9, 26]);
    });
  });

  group('FavoriteFolder.fromApi', () {
    test('defaults the emoji and recipe list', () {
      final folder = FavoriteFolder.fromApi({'id': 'f1', 'name': 'ของหวาน', 'createdAt': '2026-01-01T00:00:00.000Z'});
      expect(folder.emoji, '📁');
      expect(folder.recipeIds, isEmpty);
    });
  });

  group('AppUser.fromApi', () {
    test('prefixes a relative avatar path with the API base URL', () {
      final user = AppUser.fromApi({
        'id': 'u1',
        'email': 'a@example.com',
        'name': 'A',
        'profileImageUrl': '/uploads/avatars/u1.jpg',
      });
      expect(user.profileImagePath, '${ApiClient().baseUrl}/uploads/avatars/u1.jpg');
    });

    test('keeps absolute URLs and null as they are', () {
      final withUrl = AppUser.fromApi({'id': 'u1', 'email': 'a@x.com', 'name': 'A', 'profileImageUrl': 'https://cdn/x.jpg'});
      final withoutUrl = AppUser.fromApi({'id': 'u1', 'email': 'a@x.com', 'name': 'A', 'profileImageUrl': null});
      expect(withUrl.profileImagePath, 'https://cdn/x.jpg');
      expect(withoutUrl.profileImagePath, isNull);
    });
  });
}
