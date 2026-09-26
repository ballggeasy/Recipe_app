import 'package:flutter/foundation.dart';

import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../models/nutrition.dart';
import '../services/api_client.dart';
import '../services/meal_plan_service.dart';

/// วางแผนมื้ออาหาร รายวัน/สัปดาห์/เดือน + คำนวณแคลอรี/สารอาหาร — ข้อมูลอยู่บน backend ต่อผู้ใช้
class MealPlannerProvider extends ChangeNotifier {
  final MealPlanService _mealPlanService;

  MealPlannerProvider({MealPlanService? mealPlanService}) : _mealPlanService = mealPlanService ?? MealPlanService();

  List<MealPlanEntry> _entries = [];
  bool _isLoading = false;

  List<MealPlanEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;

  List<MealPlanEntry> entriesForDate(DateTime date) {
    return _entries.where((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day).toList();
  }

  List<MealPlanEntry> entriesForWeek(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 7));
    return _entries.where((e) =>
        e.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        e.date.isBefore(end)).toList();
  }

  List<MealPlanEntry> entriesForMonth(int year, int month) {
    return _entries.where((e) =>
        e.date.year == year && e.date.month == month).toList();
  }

  /// เรียกทุกครั้งที่สถานะล็อกอินเปลี่ยน
  Future<void> onAuthChanged(bool isLoggedIn) async {
    if (!isLoggedIn) {
      _entries = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      _entries = await _mealPlanService.fetchAll();
    } on ApiException {
      _entries = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry({
    required String recipeId,
    required DateTime date,
    required MealType mealType,
    int servings = 1,
  }) async {
    try {
      final entry = await _mealPlanService.create(
        recipeId: recipeId,
        date: date,
        mealType: mealType,
        servings: servings,
      );
      _entries.add(entry);
      notifyListeners();
    } on ApiException {
      // เพิ่มไม่สำเร็จ
    }
  }

  Future<void> removeEntry(String id) async {
    try {
      await _mealPlanService.delete(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
    } on ApiException {
      // ลบไม่สำเร็จ
    }
  }

  /// คำนวณแคลอรีรวมของวัน
  int totalCaloriesForDate(DateTime date, List<Recipe> recipes) {
    return _calcNutritionForDate(date, recipes).calories;
  }

  /// คำนวณสารอาหารรวมของวัน
  NutritionInfo nutritionForDate(DateTime date, List<Recipe> recipes) {
    return _calcNutritionForDate(date, recipes);
  }

  NutritionInfo _calcNutritionForDate(DateTime date, List<Recipe> recipes) {
    final dayEntries = entriesForDate(date);
    var total = const NutritionInfo();
    for (final entry in dayEntries) {
      final recipe = recipes.cast<Recipe?>().firstWhere(
            (r) => r?.id == entry.recipeId,
            orElse: () => null,
          );
      if (recipe?.nutrition != null) {
        final n = recipe!.nutrition!.forServings(entry.servings);
        total = NutritionInfo(
          calories: total.calories + n.calories,
          protein: total.protein + n.protein,
          fat: total.fat + n.fat,
          carbs: total.carbs + n.carbs,
          sugar: total.sugar + n.sugar,
          sodium: total.sodium + n.sodium,
        );
      }
    }
    return total;
  }

  NutritionInfo nutritionForWeek(DateTime weekStart, List<Recipe> recipes) {
    final weekEntries = entriesForWeek(weekStart);
    var total = const NutritionInfo();
    for (final entry in weekEntries) {
      final recipe = recipes.cast<Recipe?>().firstWhere(
            (r) => r?.id == entry.recipeId,
            orElse: () => null,
          );
      if (recipe?.nutrition != null) {
        final n = recipe!.nutrition!.forServings(entry.servings);
        total = NutritionInfo(
          calories: total.calories + n.calories,
          protein: total.protein + n.protein,
          fat: total.fat + n.fat,
          carbs: total.carbs + n.carbs,
          sugar: total.sugar + n.sugar,
          sodium: total.sodium + n.sodium,
        );
      }
    }
    return total;
  }
}
