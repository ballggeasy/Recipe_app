import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/widgets/recipe_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late RecipeProvider provider;
  late int taps;

  Future<void> pumpCard(WidgetTester tester, Recipe recipe) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 260,
                child: RecipeCard(recipe: recipe, onTap: () => taps++),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final api = fakeApi({});
    provider = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
    taps = 0;
  });

  final recipe = Recipe.fromApi(recipeJson(name: 'ผัดกะเพรา', cookTimeMinutes: 15, difficulty: 'ง่าย'));

  testWidgets('shows the name, cook time, difficulty and emoji fallback', (tester) async {
    await pumpCard(tester, recipe);

    expect(find.text('ผัดกะเพรา'), findsOneWidget);
    expect(find.text('15 นาที'), findsOneWidget);
    expect(find.text('ง่าย'), findsOneWidget);
    expect(find.text('🍛'), findsOneWidget, reason: 'recipe has no imageUrl, so the emoji is shown');
  });

  testWidgets('calls onTap when the card is tapped', (tester) async {
    await pumpCard(tester, recipe);

    await tester.tap(find.text('ผัดกะเพรา'));
    expect(taps, 1);
  });

  testWidgets('heart button toggles the favorite without opening the recipe', (tester) async {
    await pumpCard(tester, recipe);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(provider.isFavorite(recipe.id), isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(taps, 0);
  });
}
