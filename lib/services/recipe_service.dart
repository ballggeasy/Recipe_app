import '../models/ingredient.dart';
import '../models/nutrition.dart';
import '../models/recipe.dart';
import 'api_client.dart';

/// เรียก backend API สำหรับสูตรอาหาร — รายการสาธารณะ, เพิ่ม/แก้/ลบของผู้ใช้ที่ล็อกอิน
class RecipeService {
  final ApiClient _api = ApiClient();

  Future<List<Recipe>> fetchAll() async {
    final data = await _api.get('/recipes', auth: false) as List;
    return data.map((e) => Recipe.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<Recipe> create({
    required String name,
    required String emoji,
    required String category,
    required String country,
    required int cookTimeMinutes,
    required int prepTimeMinutes,
    required String difficulty,
    required int servings,
    required List<String> ingredients,
    required List<IngredientItem> ingredientItems,
    required List<String> steps,
    String? tips,
    String? platingTips,
    List<String> dietTags = const [],
    NutritionInfo? nutrition,
  }) async {
    final data = await _api.post(
      '/recipes',
      body: {
        'name': name,
        'emoji': emoji,
        'category': category,
        'country': country,
        'cookTimeMinutes': cookTimeMinutes,
        'prepTimeMinutes': prepTimeMinutes,
        'difficulty': difficulty,
        'servings': servings,
        'ingredients': ingredients,
        'ingredientItems': ingredientItems.map((i) => i.toJson()).toList(),
        'steps': steps,
        if (tips != null) 'tips': tips,
        if (platingTips != null) 'platingTips': platingTips,
        'dietTags': dietTags,
        if (nutrition != null) 'nutrition': nutrition.toJson(),
      },
    ) as Map<String, dynamic>;
    return Recipe.fromApi(data);
  }

  Future<Recipe> update(String id, Map<String, dynamic> patch) async {
    final data = await _api.patch('/recipes/$id', body: patch) as Map<String, dynamic>;
    return Recipe.fromApi(data);
  }

  Future<void> delete(String id) => _api.delete('/recipes/$id');
}
