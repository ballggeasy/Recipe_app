// สูตรของฉัน: แสดงเฉพาะสูตรที่ผู้ใช้เพิ่มเอง และกดแก้ไขได้จากรายการ
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/screens/recipe/my_recipes_screen.dart';
import 'package:recipe_app/screens/recipe/recipe_form_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lists only my recipes and opens the editor from the list', (tester) async {
    final api = fakeApi({
      'GET /recipes': (_) => jsonResponse([
            {...recipeJson(id: 'a', name: 'สูตรของฉัน A', isOfficial: false), 'uploaderId': 'u1'},
            {...recipeJson(id: 'b', name: 'สูตรคนอื่น', isOfficial: false), 'uploaderId': 'u2'},
            recipeJson(id: 'c', name: 'สูตรทางการ'),
          ]),
      'POST /auth/login': (_) => jsonResponse({
            'accessToken': 'tok',
            'user': {'id': 'u1', 'email': 'me@example.com', 'name': 'ฉัน', 'profileImageUrl': null},
          }),
    });
    final recipes = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
    await recipes.init();
    final auth = AuthProvider(authService: AuthService(api: api));
    await auth.login(email: 'me@example.com', password: 'secret123');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: recipes),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: const MaterialApp(home: MyRecipesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('สูตรของฉัน A'), findsOneWidget);
    expect(find.text('สูตรคนอื่น'), findsNothing);
    expect(find.text('สูตรทางการ'), findsNothing);

    await tester.tap(find.byTooltip('แก้ไข สูตรของฉัน A'));
    await tester.pumpAndSettle();
    expect(find.byType(RecipeFormScreen), findsOneWidget);
    expect(find.text('แก้ไขสูตรอาหาร'), findsOneWidget);
  });
}
