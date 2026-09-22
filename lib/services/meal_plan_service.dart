import '../models/meal_plan.dart';
import 'api_client.dart';

/// เรียก backend API สำหรับแผนมื้ออาหาร — auth เสมอ
class MealPlanService {
  final ApiClient _api = ApiClient();

  Future<List<MealPlanEntry>> fetchAll() async {
    final data = await _api.get('/meal-plan') as List;
    return data.map((e) => MealPlanEntry.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<MealPlanEntry> create({
    required String recipeId,
    required DateTime date,
    required MealType mealType,
    int servings = 1,
  }) async {
    final data = await _api.post(
      '/meal-plan',
      body: {
        'recipeId': recipeId,
        'date': date.toIso8601String(),
        'mealType': mealType.name,
        'servings': servings,
      },
    ) as Map<String, dynamic>;
    return MealPlanEntry.fromApi(data);
  }

  Future<void> delete(String id) => _api.delete('/meal-plan/$id');
}
