import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/screens/home/home_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/widgets/common/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  late bool backendUp;

  Future<RecipeProvider> pumpHome(WidgetTester tester) async {
    final api = fakeApi({
      'GET /recipes': (_) => backendUp
          ? jsonResponse([recipeJson(id: 'krapao', name: 'ผัดกะเพรา')])
          : jsonResponse({'message': 'เซิร์ฟเวอร์ไม่ตอบสนอง'}, 503),
    });
    final recipes = RecipeProvider(
      recipeService: RecipeService(api: api),
      favoriteService: FavoriteService(api: api),
    );
    await recipes.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: recipes),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService: AuthService(api: api)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return recipes;
  }

  testWidgets(
    'shows the error with a retry button instead of "no results" when loading fails',
    (tester) async {
      backendUp = false;
      await pumpHome(tester);

      expect(find.text('โหลดเมนูไม่สำเร็จ'), findsOneWidget);
      expect(find.text('เซิร์ฟเวอร์ไม่ตอบสนอง'), findsOneWidget);
      expect(find.text('ไม่พบเมนูที่ตรงกับการค้นหา'), findsNothing);
    },
  );

  testWidgets('retry reloads the recipes and replaces the error state', (
    tester,
  ) async {
    backendUp = false;
    await pumpHome(tester);

    backendUp = true;
    final retry = find.widgetWithText(AppButton, 'ลองอีกครั้ง');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(find.text('โหลดเมนูไม่สำเร็จ'), findsNothing);
    expect(find.text('ผัดกะเพรา'), findsWidgets);
  });
}
