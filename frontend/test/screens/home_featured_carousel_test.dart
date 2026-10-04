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
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHome(
    WidgetTester tester,
    List<Map<String, dynamic>> data,
  ) async {
    final api = fakeApi({'GET /recipes': (_) => jsonResponse(data)});
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
  }

  // index of the card in the middle of the carousel, counted in recipes (not raw pages)
  int shownIndex(WidgetTester tester, int count) {
    final view = tester.widget<PageView>(
      find.byKey(const Key('featured-carousel')),
    );
    return view.controller!.page!.round() % count;
  }

  final three = [
    recipeJson(id: 'a', name: 'เมนูเอ', rating: 5),
    recipeJson(id: 'b', name: 'เมนูบี', rating: 4),
    recipeJson(id: 'c', name: 'เมนูซี', rating: 3),
  ];

  testWidgets(
    'starts on the best rated recipe and swipes on to the next ones',
    (tester) async {
      await pumpHome(tester, three);
      final carousel = find.byKey(const Key('featured-carousel'));

      expect(find.text('เมนูแนะนำวันนี้'), findsWidgets);
      expect(shownIndex(tester, 3), 0);

      await tester.fling(carousel, const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(shownIndex(tester, 3), 1);

      await tester.fling(carousel, const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(shownIndex(tester, 3), 2);
    },
  );

  testWidgets('keeps going after the last recipe, in both directions', (
    tester,
  ) async {
    await pumpHome(tester, three);
    final carousel = find.byKey(const Key('featured-carousel'));

    for (var i = 0; i < 3; i++) {
      await tester.fling(carousel, const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
    }
    expect(
      shownIndex(tester, 3),
      0,
      reason: 'wrapped around past the last one',
    );

    await tester.fling(carousel, const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(
      shownIndex(tester, 3),
      2,
      reason: 'and backwards from the first one',
    );
  });

  testWidgets('a single recipe stays put instead of looping', (tester) async {
    await pumpHome(tester, [recipeJson(id: 'a', name: 'เมนูเอ')]);
    final carousel = find.byKey(const Key('featured-carousel'));

    await tester.fling(carousel, const Offset(-300, 0), 1500);
    await tester.pumpAndSettle();
    expect(shownIndex(tester, 1), 0);
  });

  group('auto play', () {
    testWidgets('moves to the next recipe by itself', (tester) async {
      await pumpHome(tester, three);
      expect(shownIndex(tester, 3), 0);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(shownIndex(tester, 3), 1);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(shownIndex(tester, 3), 2);
    });

    testWidgets(
      'waits while the user is touching it, then starts counting again',
      (tester) async {
        await pumpHome(tester, three);
        final carousel = find.byKey(const Key('featured-carousel'));

        final finger = await tester.startGesture(tester.getCenter(carousel));
        await finger.moveBy(
          const Offset(-40, 0),
        ); // a drag, not a tap on the card
        await tester.pump(const Duration(seconds: 12));
        expect(shownIndex(tester, 3), 0, reason: 'held down: no auto scroll');

        await finger.up();
        await tester.pump(const Duration(seconds: 4));
        expect(
          shownIndex(tester, 3),
          0,
          reason: 'countdown restarted on release',
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(shownIndex(tester, 3), 1);
      },
    );

    testWidgets('stays still when the system asks to reduce animations', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpHome(tester, three);

      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(shownIndex(tester, 3), 0);
    });

    testWidgets('does not auto scroll a single recipe', (tester) async {
      await pumpHome(tester, [recipeJson(id: 'a', name: 'เมนูเอ')]);

      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(shownIndex(tester, 1), 0);
    });
  });
}
