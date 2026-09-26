import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/ingredient.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/services/api_client.dart';

void main() {
  group('Recipe.fromApi', () {
    test('maps every field the backend sends', () {
      final recipe = Recipe.fromApi({
        'id': 'r1',
        'name': 'ผัดกะเพรา',
        'emoji': '🌶️',
        'imageUrl': 'https://example.com/a.jpg',
        'imageUrls': ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
        'category': 'อาหารจานเดียว',
        'country': 'ไทย',
        'cookTimeMinutes': 15,
        'prepTimeMinutes': 5,
        'difficulty': 'ง่าย',
        'servings': 1,
        'ingredients': ['หมูสับ 200 กรัม'],
        'ingredientItems': [
          {'name': 'หมูสับ', 'amount': '200', 'unit': 'กรัม'},
        ],
        'steps': ['ผัดหมู', 'ใส่กะเพรา'],
        'tips': 'ใช้ไฟแรง',
        'platingTips': null,
        'nutrition': {'calories': 550, 'protein': 30, 'fat': 20.5, 'carbs': 60, 'sugar': 5, 'sodium': 900},
        'dietTags': ['โปรตีนสูง'],
        'season': 'ฤดูร้อน',
        'videoUrl': null,
        'isOfficial': false,
        'uploaderId': 'u1',
        'uploaderName': 'สมชาย',
        'rating': 4,
        'reviewCount': 3,
        'viewCount': 99,
        'isRecommended': true,
        'createdAt': '2026-05-01T10:00:00.000Z',
      });

      expect(recipe.id, 'r1');
      expect(recipe.imageUrls, hasLength(2));
      expect(recipe.prepTimeMinutes, 5);
      expect(recipe.servings, 1);
      expect(recipe.ingredientItems.single.display, '200 กรัม หมูสับ');
      expect(recipe.nutrition!.calories, 550);
      expect(recipe.nutrition!.fat, 20.5);
      expect(recipe.isOfficial, isFalse);
      expect(recipe.uploaderName, 'สมชาย');
      expect(recipe.rating, 4.0, reason: 'int rating from JSON must become a double');
      expect(recipe.isRecommended, isTrue);
      expect(recipe.createdAt, DateTime.utc(2026, 5, 1, 10));
    });

    test('prefixes uploaded (relative) image paths with the API base URL, leaves full URLs alone', () {
      final recipe = Recipe.fromApi({
        'id': 'r3',
        'name': 'ข้าวผัด',
        'emoji': '🍚',
        'category': 'อาหารจานเดียว',
        'country': 'ไทย',
        'cookTimeMinutes': 10,
        'difficulty': 'ง่าย',
        'imageUrl': '/uploads/recipes/r3-1.jpg',
        'imageUrls': ['/uploads/recipes/r3-1.jpg', 'https://example.com/b.jpg'],
      });

      final base = ApiClient().baseUrl;
      expect(recipe.imageUrl, '$base/uploads/recipes/r3-1.jpg');
      expect(recipe.imageUrls, ['$base/uploads/recipes/r3-1.jpg', 'https://example.com/b.jpg']);
    });

    test('falls back to defaults when optional fields are missing', () {
      final recipe = Recipe.fromApi({
        'id': 'r2',
        'name': 'ต้มยำ',
        'emoji': '🍲',
        'category': 'ต้ม',
        'country': 'ไทย',
        'cookTimeMinutes': 20,
        'difficulty': 'ปานกลาง',
      });

      expect(recipe.imageUrl, '');
      expect(recipe.imageUrls, isEmpty);
      expect(recipe.prepTimeMinutes, 10);
      expect(recipe.servings, 2);
      expect(recipe.ingredients, isEmpty);
      expect(recipe.ingredientItems, isEmpty);
      expect(recipe.steps, isEmpty);
      expect(recipe.nutrition, isNull);
      expect(recipe.isOfficial, isTrue);
      expect(recipe.rating, 0);
      expect(recipe.season, 'ตลอดปี');
      expect(recipe.isRecommended, isFalse);
    });
  });

  group('Recipe helpers', () {
    Recipe build({String imageUrl = '', List<String>? imageUrls, bool isOfficial = true, String? uploaderName}) =>
        Recipe(
          id: 'r',
          name: 'Pad Thai',
          imageUrl: imageUrl,
          imageUrls: imageUrls,
          category: 'เส้น',
          cookTimeMinutes: 20,
          prepTimeMinutes: 15,
          difficulty: 'ง่าย',
          ingredients: const ['เส้นจันท์'],
          ingredientItems: const [IngredientItem(name: 'กุ้งสด', amount: '5', unit: 'ตัว')],
          steps: const [],
          country: 'ไทย',
          isOfficial: isOfficial,
          uploaderName: uploaderName,
        );

    test('totalTimeMinutes adds prep and cook time', () {
      expect(build().totalTimeMinutes, 35);
    });

    test('allImages prefers imageUrls, then imageUrl, then nothing', () {
      expect(build(imageUrl: 'a', imageUrls: ['x', 'y']).allImages, ['x', 'y']);
      expect(build(imageUrl: 'a').allImages, ['a']);
      expect(build().allImages, isEmpty);
    });

    test('sourceLabel shows official or the uploader name', () {
      expect(build().sourceLabel, 'สูตรทางการ');
      expect(build(isOfficial: false, uploaderName: 'สมศรี').sourceLabel, 'โดย สมศรี');
      expect(build(isOfficial: false).sourceLabel, 'โดย ผู้ใช้');
    });

    test('matchesQuery checks the name and both ingredient lists, case-insensitively', () {
      final recipe = build();
      expect(recipe.matchesQuery(''), isTrue);
      expect(recipe.matchesQuery('pad'), isTrue);
      expect(recipe.matchesQuery('เส้นจันท์'), isTrue);
      expect(recipe.matchesQuery('กุ้ง'), isTrue);
      expect(recipe.matchesQuery('ปลาร้า'), isFalse);
    });
  });
}
