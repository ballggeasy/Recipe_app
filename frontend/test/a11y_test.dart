// ตรวจ accessibility guideline ของ Flutter บนหน้าหลัก ๆ ทั้ง light และ dark mode:
// พื้นที่กดขั้นต่ำ 48x48 และทุกอย่างที่กดได้ต้องมี label ให้ screen reader
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/comment_provider.dart';
import 'package:recipe_app/providers/favorite_provider.dart';
import 'package:recipe_app/providers/meal_planner_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/providers/review_provider.dart';
import 'package:recipe_app/providers/theme_provider.dart';
import 'package:recipe_app/screens/login_screen.dart';
import 'package:recipe_app/screens/main/main_screen.dart';
import 'package:recipe_app/screens/recipe/detail_screen.dart';
import 'package:recipe_app/services/api_client.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/comment_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/meal_plan_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/services/review_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_api.dart';

final _catalog = [
  recipeJson(id: 'krapao', name: 'ผัดกะเพรา'),
  recipeJson(id: 'tomyum', name: 'ต้มยำกุ้ง', category: 'ต้ม', rating: 4.8),
  recipeJson(id: 'carbonara', name: 'Carbonara', category: 'เส้น', country: 'อิตาลี', isOfficial: false),
];

ApiClient _api() => fakeApi({
      'GET /recipes': (_) => jsonResponse(_catalog),
      'GET /recipes/krapao/reviews': (_) => jsonResponse([]),
      'GET /recipes/krapao/comments': (_) => jsonResponse([]),
    });

/// ครอบ [home] ด้วย provider ชุดเดียวกับ main.dart แต่ทุก service คุยกับ fake API
Future<AuthProvider> _pump(WidgetTester tester, Widget home, {ThemeMode themeMode = ThemeMode.light}) async {
  final api = _api();
  final auth = AuthProvider(authService: AuthService(api: api));
  final recipes = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
  await recipes.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: recipes),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider(favoriteService: FavoriteService(api: api))),
        ChangeNotifierProvider(create: (_) => ReviewProvider(reviewService: ReviewService(api: api))),
        ChangeNotifierProvider(create: (_) => CommentProvider(commentService: CommentService(api: api))),
        ChangeNotifierProvider(create: (_) => MealPlannerProvider(mealPlanService: MealPlanService(api: api))),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

/// textContrastGuideline ต้องจับภาพหน้าจอผ่าน runAsync ซึ่งทำให้ google_fonts พยายามโหลดฟอนต์จริงแล้ว throw ใน test
/// จึงตรวจ contrast ที่ระดับ color token แทน (ดู theme/contrast_test.dart)
Future<void> _expectMeetsGuidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    group('${mode.name} mode', () {
      testWidgets('login screen meets accessibility guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, const LoginScreen(), themeMode: mode);

        await _expectMeetsGuidelines(tester);
        handle.dispose();
      });

      testWidgets('home screen (guest) meets accessibility guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        final auth = await _pump(tester, const MainScreen(), themeMode: mode);
        auth.continueAsGuest();
        await tester.pumpAndSettle();

        await _expectMeetsGuidelines(tester);
        handle.dispose();
      });

      testWidgets('recipe detail screen meets accessibility guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, DetailScreen(recipe: Recipe.fromApi(_catalog.first)), themeMode: mode);

        await _expectMeetsGuidelines(tester);
        handle.dispose();
      });
    });
  }
}
