import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/screens/home/home_screen.dart';
import 'package:recipe_app/screens/recipe/recipe_form_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AuthProvider> pumpHome(WidgetTester tester) async {
    final api = fakeApi({
      'GET /recipes': (_) => jsonResponse([recipeJson()]),
      'POST /auth/login': (_) => jsonResponse({
        'accessToken': 'tok',
        'user': {
          'id': 'u1',
          'email': 'somchai@example.com',
          'name': 'สมชาย',
          'profileImageUrl': null,
        },
      }),
    });
    final recipes = RecipeProvider(
      recipeService: RecipeService(api: api),
      favoriteService: FavoriteService(api: api),
    );
    await recipes.init();
    final auth = AuthProvider(authService: AuthService(api: api));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: recipes),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('a guest who taps "เพิ่มสูตร" is sent to the login screen', (
    tester,
  ) async {
    final auth = await pumpHome(tester);
    auth.continueAsGuest();
    await tester.pumpAndSettle();
    expect(auth.status, AuthStatus.guest);

    await tester.tap(find.text('เพิ่มสูตร'));
    await tester.pumpAndSettle();

    expect(
      auth.status,
      AuthStatus.loggedOut,
      reason: 'the app shows the login screen',
    );
    expect(find.byType(RecipeFormScreen), findsNothing);
    expect(find.text('กรุณา Log in เพื่อแชร์ความอร่อย'), findsOneWidget);
  });

  testWidgets('a logged-out user is sent to the login screen too', (
    tester,
  ) async {
    final auth = await pumpHome(tester);
    expect(auth.status, AuthStatus.unknown);

    await tester.tap(find.text('เพิ่มสูตร'));
    await tester.pumpAndSettle();

    expect(auth.status, AuthStatus.loggedOut);
    expect(find.byType(RecipeFormScreen), findsNothing);
    expect(find.text('กรุณา Log in เพื่อแชร์ความอร่อย'), findsOneWidget);
  });

  testWidgets('a logged-in user gets the add recipe form', (tester) async {
    final auth = await pumpHome(tester);
    expect(
      await auth.login(email: 'somchai@example.com', password: 'Passw0rd!'),
      isNull,
    );
    await tester.pumpAndSettle();
    expect(auth.status, AuthStatus.loggedIn);

    await tester.tap(find.text('เพิ่มสูตร'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeFormScreen), findsOneWidget);
    expect(auth.status, AuthStatus.loggedIn);
    expect(find.text('กรุณา Log in เพื่อแชร์ความอร่อย'), findsNothing);
  });
}
