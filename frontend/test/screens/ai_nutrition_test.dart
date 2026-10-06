import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/comment_provider.dart';
import 'package:recipe_app/providers/meal_planner_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/providers/review_provider.dart';
import 'package:recipe_app/screens/meal_planner/meal_planner_screen.dart';
import 'package:recipe_app/screens/recipe/detail_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/comment_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/meal_plan_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/services/review_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/utils/feature_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

const _me = {
  'id': 'u1',
  'email': 'somchai@example.com',
  'name': 'สมชาย',
  'profileImageUrl': null,
};

const _aiNutrition = {
  'calories': 570,
  'protein': 18,
  'fat': 27,
  'carbs': 62,
  'sugar': 2,
  'sodium': 1800,
  'source': 'ai',
};

Map<String, dynamic> _mine({Map<String, dynamic>? nutrition}) => {
  ...recipeJson(id: 'mine', name: 'ไก่ทอดหาดใหญ่', isOfficial: false),
  'uploaderId': 'u1',
  'uploaderName': 'สมชาย',
  'nutrition': nutrition,
};

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late List<http.Request> log;
  late RecipeProvider recipes;

  Future<void> pumpWith(
    WidgetTester tester,
    Widget home, {
    required Map<String, RouteHandler> routes,
  }) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    log = [];
    final api = fakeApi({
      'POST /auth/login': (_) =>
          jsonResponse({'accessToken': 'tok', 'user': _me}),
      'GET /recipes/mine/reviews': (_) => jsonResponse([]),
      'GET /recipes/mine/comments': (_) => jsonResponse([]),
      ...routes,
    }, log: log);
    recipes = RecipeProvider(
      recipeService: RecipeService(api: api),
      favoriteService: FavoriteService(api: api),
    );
    await recipes.init();
    final auth = AuthProvider(authService: AuthService(api: api));
    await auth.login(email: 'somchai@example.com', password: 'secret123');
    final planner = MealPlannerProvider(
      mealPlanService: MealPlanService(api: api),
    );
    await planner.onAuthChanged(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: recipes),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: planner),
          ChangeNotifierProvider(
            create: (_) =>
                ReviewProvider(reviewService: ReviewService(api: api)),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                CommentProvider(commentService: CommentService(api: api)),
          ),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'while AI estimates are switched off, the owner sees no AI button and nothing reloads',
    (tester) async {
      expect(aiNutritionEnabled, isFalse, reason: 'off by default for now');
      var listCalls = 0;
      await pumpWith(
        tester,
        Builder(
          builder: (context) => DetailScreen(
            recipe: context.read<RecipeProvider>().getById('mine')!,
          ),
        ),
        routes: {
          'GET /recipes': (_) {
            listCalls++;
            return jsonResponse([_mine()]);
          },
        },
      );

      expect(find.text('ข้อมูลโภชนาการ (ต่อ 1 เสิร์ฟ)'), findsNothing);
      expect(find.text('ประเมินด้วย AI'), findsNothing);
      expect(listCalls, 1);
    },
  );

  group('recipe detail with AI estimates switched on', () {
    setUp(() => aiNutritionEnabled = true);
    tearDown(() => aiNutritionEnabled = false);

    testWidgets(
      'the owner can ask the AI for nutrition and sees it marked as an estimate',
      (tester) async {
        var listCalls = 0;
        await pumpWith(
          tester,
          Builder(
            builder: (context) => DetailScreen(
              recipe: context.read<RecipeProvider>().getById('mine')!,
            ),
          ),
          routes: {
            'GET /recipes': (_) {
              listCalls++;
              return jsonResponse([_mine()]);
            },
            'POST /recipes/mine/nutrition/estimate': (_) =>
                jsonResponse(_mine(nutrition: _aiNutrition), 201),
          },
        );

        expect(
          listCalls,
          2,
          reason:
              'an own recipe without nutrition reloads once in case the background estimate finished',
        );
        expect(find.textContaining('ยังไม่มีข้อมูลโภชนาการ'), findsOneWidget);

        await tester.tap(find.text('ประเมินด้วย AI'));
        await tester.pumpAndSettle();

        expect(
          log.where((r) => r.url.path == '/recipes/mine/nutrition/estimate'),
          hasLength(1),
        );
        expect(find.text('570'), findsOneWidget);
        expect(find.textContaining('ค่าประมาณจาก AI'), findsOneWidget);
        expect(find.text('ประเมินใหม่'), findsOneWidget);
        expect(recipes.getById('mine')!.nutrition!.isAiEstimate, isTrue);
      },
    );

    testWidgets("shows the AI's error and keeps the button", (tester) async {
      await pumpWith(
        tester,
        Builder(
          builder: (context) => DetailScreen(
            recipe: context.read<RecipeProvider>().getById('mine')!,
          ),
        ),
        routes: {
          'GET /recipes': (_) => jsonResponse([_mine()]),
          'POST /recipes/mine/nutrition/estimate': (_) => jsonResponse({
            'message': 'AI ประเมินโภชนาการไม่สำเร็จ กรุณาลองใหม่ภายหลัง',
          }, 503),
        },
      );

      await tester.tap(find.text('ประเมินด้วย AI'));
      await tester.pumpAndSettle();

      expect(
        find.text('AI ประเมินโภชนาการไม่สำเร็จ กรุณาลองใหม่ภายหลัง'),
        findsOneWidget,
      );
      expect(find.text('ประเมินด้วย AI'), findsOneWidget);
    });

    testWidgets("other people's recipes without nutrition show no AI button", (
      tester,
    ) async {
      await pumpWith(
        tester,
        Builder(
          builder: (context) => DetailScreen(
            recipe: context.read<RecipeProvider>().getById('r1')!,
          ),
        ),
        routes: {
          'GET /recipes': (_) => jsonResponse([recipeJson()]),
          'GET /recipes/r1/reviews': (_) => jsonResponse([]),
          'GET /recipes/r1/comments': (_) => jsonResponse([]),
        },
      );

      expect(find.text('ข้อมูลโภชนาการ (ต่อ 1 เสิร์ฟ)'), findsNothing);
      expect(find.text('ประเมินด้วย AI'), findsNothing);
    });
  });

  group('meal planner', () {
    final today = DateTime.now();
    final mealDate = DateTime(
      today.year,
      today.month,
      today.day,
      12,
    ).toUtc().toIso8601String();

    testWidgets(
      'adds up AI nutrition per serving, notes it, and counts meals without data',
      (tester) async {
        await pumpWith(
          tester,
          const MealPlannerScreen(),
          routes: {
            'GET /recipes': (_) => jsonResponse([
              _mine(nutrition: _aiNutrition),
              recipeJson(id: 'r1'),
            ]),
            'GET /meal-plan': (_) => jsonResponse([
              {
                'id': 'm1',
                'recipeId': 'mine',
                'date': mealDate,
                'mealType': 'lunch',
                'servings': 2,
              },
              {
                'id': 'm2',
                'recipeId': 'r1',
                'date': mealDate,
                'mealType': 'dinner',
                'servings': 1,
              },
            ]),
          },
        );

        expect(find.text('1140'), findsOneWidget); // 570 kcal x 2 servings
        expect(
          find.text('1 มื้อยังไม่มีข้อมูลโภชนาการ จึงยังไม่ได้นับรวม'),
          findsOneWidget,
        );
        expect(find.text('บางเมนูเป็นค่าประมาณจาก AI'), findsOneWidget);
      },
    );
  });
}
