import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/models/meal_plan.dart';
import 'package:recipe_app/providers/meal_planner_provider.dart';
import 'package:recipe_app/services/meal_plan_service.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _entry(String id, DateTime localTime) => {
      'id': id,
      'recipeId': 'r1',
      'date': localTime.toUtc().toIso8601String(),
      'mealType': 'dinner',
    };

void main() {
  test('entriesForWeek covers Monday 00:00 to next Monday 00:00 regardless of the time in weekStart', () async {
    final planner = MealPlannerProvider(
      mealPlanService: MealPlanService(
        api: fakeApi({
          'GET /meal-plan': (_) => jsonResponse([
                _entry('prev-sunday-night', DateTime(2026, 9, 20, 20)),
                _entry('monday-morning', DateTime(2026, 9, 21, 7)),
                _entry('sunday-night', DateTime(2026, 9, 27, 23)),
                _entry('next-monday', DateTime(2026, 9, 28, 0, 30)),
              ]),
        }),
      ),
    );
    await planner.onAuthChanged(true);

    // weekStart มาจาก DateTime.now() ของหน้าจอจึงมีเวลาติดมา (จันทร์ 15:00)
    final ids = planner.entriesForWeek(DateTime(2026, 9, 21, 15)).map((e) => e.id);

    expect(ids, ['monday-morning', 'sunday-night']);
  });

  test('addEntry sends the date as UTC and files it under the local day', () async {
    final planner = MealPlannerProvider(
      mealPlanService: MealPlanService(
        api: fakeApi({
          'POST /meal-plan': (req) {
            final sent = jsonDecode(req.body)['date'] as String;
            expect(sent, endsWith('Z'));
            return jsonResponse({..._entry('m1', DateTime.parse(sent).toLocal()), 'mealType': 'breakfast'}, 201);
          },
        }),
      ),
    );

    final earlyMorning = DateTime(2026, 9, 26, 1);
    await planner.addEntry(recipeId: 'r1', date: earlyMorning, mealType: MealType.breakfast);

    expect(planner.entriesForDate(DateTime(2026, 9, 26)), hasLength(1));
    expect(planner.entriesForDate(DateTime(2026, 9, 25)), isEmpty);
  });
}
