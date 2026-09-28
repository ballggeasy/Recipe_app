// หน้า detail: ปุ่มบน app bar ต้องกดได้จริง (ไม่ชน assertion ของ provider) และปุ่มแก้ไข/ลบโชว์เฉพาะเจ้าของสูตร
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/comment_provider.dart';
import 'package:recipe_app/providers/favorite_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/providers/review_provider.dart';
import 'package:recipe_app/screens/recipe/detail_screen.dart';
import 'package:recipe_app/services/api_client.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/comment_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

const _owner = {'id': 'u1', 'email': 'owner@example.com', 'name': 'เจ้าของ', 'profileImageUrl': null};

final _mine = {...recipeJson(id: 'mine', isOfficial: false), 'uploaderId': 'u1'};
final _official = recipeJson(id: 'official');

ApiClient _api() => fakeApi({
      'GET /recipes': (_) => jsonResponse([_mine, _official]),
      'GET /recipes/mine/reviews': (_) => jsonResponse([]),
      'GET /recipes/mine/comments': (_) => jsonResponse([]),
      'GET /recipes/official/reviews': (_) => jsonResponse([]),
      'GET /recipes/official/comments': (_) => jsonResponse([]),
      'POST /auth/login': (_) => jsonResponse({'accessToken': 'tok', 'user': _owner}),
      'DELETE /recipes/mine': (_) => jsonResponse({}),
    });

Future<RecipeProvider> _pump(WidgetTester tester, Map<String, dynamic> recipe, {bool loggedIn = false}) async {
  final api = _api();
  final auth = AuthProvider(authService: AuthService(api: api));
  if (loggedIn) await auth.login(email: 'owner@example.com', password: 'secret123');
  final recipes = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
  await recipes.init();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: recipes),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => FavoriteProvider(favoriteService: FavoriteService(api: api))),
        ChangeNotifierProvider(create: (_) => ReviewProvider(reviewService: ReviewService(api: api))),
        ChangeNotifierProvider(create: (_) => CommentProvider(commentService: CommentService(api: api))),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(recipe: Recipe.fromApi(recipe))),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return recipes;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('favorite button on the app bar toggles without a provider assertion', (tester) async {
    final recipes = await _pump(tester, _official);

    await tester.tap(find.byTooltip('บันทึกเป็นสูตรโปรด'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(recipes.isFavorite('official'), isTrue);
    expect(find.byTooltip('เอาออกจากสูตรโปรด'), findsOneWidget);
  });

  testWidgets('guests are told to log in instead of a review dialog that silently fails', (tester) async {
    await _pump(tester, _official);

    final writeReview = find.text('เขียนรีวิว');
    await Scrollable.ensureVisible(tester.element(writeReview), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(writeReview);
    await tester.pump();

    expect(find.text('กรุณาเข้าสู่ระบบเพื่อเขียนรีวิว'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    // กดซ้ำไม่ต่อคิวข้อความ และข้อความหายเองไม่ค้างบังปุ่มด้านล่าง
    await tester.tap(writeReview);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('hides edit and delete on a recipe the user does not own', (tester) async {
    await _pump(tester, _official, loggedIn: true);

    expect(find.byTooltip('แก้ไขสูตร'), findsNothing);
    await tester.tap(find.byTooltip('ตัวเลือกเพิ่มเติม'));
    await tester.pumpAndSettle();
    expect(find.text('ลบสูตร'), findsNothing);
  });

  testWidgets('owner deletes only after confirming, then leaves the screen', (tester) async {
    final recipes = await _pump(tester, _mine, loggedIn: true);
    expect(find.byTooltip('แก้ไขสูตร'), findsOneWidget);

    await tester.tap(find.byTooltip('ตัวเลือกเพิ่มเติม'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบสูตร'));
    await tester.pumpAndSettle();

    // dialog ยืนยัน — ยกเลิกแล้วสูตรต้องยังอยู่
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(recipes.getById('mine'), isNotNull);
    expect(find.byType(DetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip('ตัวเลือกเพิ่มเติม'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบสูตร'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'ลบสูตร'));
    await tester.pumpAndSettle();

    expect(recipes.getById('mine'), isNull);
    expect(find.byType(DetailScreen), findsNothing);
  });
}
