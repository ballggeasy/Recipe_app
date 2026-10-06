import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/screens/recipe/my_recipes_screen.dart';
import 'package:recipe_app/screens/recipe/recipe_form_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/widgets/common/app_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

const _me = {
  'id': 'u1',
  'email': 'somchai@example.com',
  'name': 'สมชาย',
  'profileImageUrl': null,
};

/// สูตรของ u1 ที่มีข้อมูลครบทุกช่อง — หมวด "ขนมไทย" ไม่อยู่ในรายการหมวดของแคตตาล็อกโดยตั้งใจ
Map<String, dynamic> _myRecipeJson() => {
  ...recipeJson(id: 'mine', name: 'ข้าวเหนียวมะม่วง', isOfficial: false),
  'category': 'ขนมไทย',
  'uploaderId': 'u1',
  'uploaderName': 'สมชาย',
  'servings': 3,
  'steps': ['นึ่งข้าวเหนียว', 'ราดกะทิ'],
  'ingredients': ['ข้าวเหนียว 200 กรัม', 'มะม่วง 1 ลูก'],
  // แบบแยกช่องจากเวอร์ชันก่อน — บันทึกครั้งถัดไปต้องล้างทิ้ง
  'ingredientItems': [
    {'name': 'ข้าวเหนียว', 'amount': '200', 'unit': 'กรัม'},
    {'name': 'มะม่วง', 'amount': '1', 'unit': 'ลูก'},
  ],
  'tips': 'ใช้มะม่วงน้ำดอกไม้',
  'platingTips': 'โรยงาคั่ว',
  'dietTags': ['มังสวิรัติ'],
  'videoUrl': 'https://example.com/v',
};

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late List<http.Request> log;
  late RecipeProvider recipes;
  late AuthProvider auth;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> setUpProviders({bool loggedIn = true}) async {
    log = [];
    final api = fakeApi({
      'GET /recipes': (_) => jsonResponse([recipeJson(), _myRecipeJson()]),
      'POST /auth/login': (_) =>
          jsonResponse({'accessToken': 'tok', 'user': _me}),
      // backend ตอบสูตรที่บันทึกแล้วกลับมา — สะท้อน body ที่ส่งไปเพื่อเช็คได้ว่าแอปอัปเดตตาม
      'POST /recipes': (req) => jsonResponse({
        ...recipeJson(id: 'new', isOfficial: false),
        'uploaderId': 'u1',
      }, 201),
      'PATCH /recipes/mine': (req) => jsonResponse({
        ..._myRecipeJson(),
        ...jsonDecode(req.body) as Map<String, dynamic>,
      }),
    }, log: log);
    recipes = RecipeProvider(
      recipeService: RecipeService(api: api),
      favoriteService: FavoriteService(api: api),
    );
    await recipes.init();
    auth = AuthProvider(authService: AuthService(api: api));
    if (loggedIn) {
      await auth.login(email: 'somchai@example.com', password: 'secret123');
    }
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    // ListView สร้าง widget เฉพาะที่อยู่ในจอ — ใช้จอสูงพอให้ฟอร์มทั้งหมดถูกสร้าง
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: recipes),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Recipe mine() => recipes.getById('mine')!;

  // AppTextField วาด label ไว้นอก TextFormField จึงหาจาก AppTextField ที่มี label นั้น
  Finder fieldLabelled(String label) => find.descendant(
    of: find.widgetWithText(AppTextField, label),
    matching: find.byType(TextFormField),
  );

  testWidgets('edit mode fills in every field of the recipe', (tester) async {
    await setUpProviders();
    await pump(tester, RecipeFormScreen(recipe: mine()));

    expect(find.text('แก้ไขสูตรอาหาร'), findsOneWidget);
    expect(find.text('ข้าวเหนียวมะม่วง'), findsOneWidget);
    expect(
      find.text('ขนมไทย'),
      findsOneWidget,
      reason: 'a category outside the list must not assert',
    );
    expect(find.text('นึ่งข้าวเหนียว\nราดกะทิ'), findsOneWidget);
    expect(find.text('ข้าวเหนียว 200 กรัม\nมะม่วง 1 ลูก'), findsOneWidget);
    expect(find.text('ใช้มะม่วงน้ำดอกไม้'), findsOneWidget);
    expect(find.text('โรยงาคั่ว'), findsOneWidget);
    expect(find.text('https://example.com/v'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // servings
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'มังสวิรัติ'))
          .selected,
      isTrue,
    );
  });

  testWidgets(
    'saving sends every field, clears emptied tips and keeps the recipe owned by its uploader',
    (tester) async {
      await setUpProviders();
      await pump(
        tester,
        // ต้องมี Scaffold ใต้หน้าที่ pop กลับมา ไม่งั้น SnackBar "แก้ไขสูตรเรียบร้อย" ไม่มีที่แสดง
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecipeFormScreen(recipe: mine()),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'ข้าวเหนียวมะม่วง'),
        'ข้าวเหนียวมะม่วงสูตรใหม่',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ใช้มะม่วงน้ำดอกไม้'),
        '',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ข้าวเหนียว 200 กรัม\nมะม่วง 1 ลูก'),
        'ข้าวเหนียว 300 กรัม\n\n  มะม่วง 2 ลูก  ',
      );
      final save = find.text('บันทึกการแก้ไข');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final patch = log.singleWhere((r) => r.method == 'PATCH');
      final body = jsonDecode(patch.body) as Map<String, dynamic>;
      expect(body['name'], 'ข้าวเหนียวมะม่วงสูตรใหม่');
      expect(body['tips'], isNull);
      expect(body['platingTips'], 'โรยงาคั่ว');
      expect(body['steps'], ['นึ่งข้าวเหนียว', 'ราดกะทิ']);
      expect(body['ingredients'], ['ข้าวเหนียว 300 กรัม', 'มะม่วง 2 ลูก']);
      expect(
        body['ingredientItems'],
        isEmpty,
        reason:
            'the detail screen shows structured items first, so old ones must go',
      );
      expect(body['category'], 'ขนมไทย');
      expect(body['servings'], 3);

      expect(find.text('แก้ไขสูตรเรียบร้อย'), findsOneWidget);
      expect(mine().name, 'ข้าวเหนียวมะม่วงสูตรใหม่');
      expect(
        mine().uploaderId,
        'u1',
        reason: 'copyWith used to drop the owner, hiding the edit button',
      );
    },
  );

  testWidgets(
    'an older recipe with only structured ingredients is shown as text, one per line',
    (tester) async {
      await setUpProviders();
      final old = Recipe.fromApi({..._myRecipeJson(), 'ingredients': []});
      await pump(tester, RecipeFormScreen(recipe: old));

      expect(find.text('200 กรัม ข้าวเหนียว\n1 ลูก มะม่วง'), findsOneWidget);
    },
  );

  testWidgets('a new recipe sends its ingredients as plain text lines', (
    tester,
  ) async {
    await setUpProviders();
    await pump(tester, const RecipeFormScreen());

    await tester.enterText(fieldLabelled('ชื่อเมนู *'), 'ไก่ทอดหาดใหญ่');
    await tester.enterText(
      fieldLabelled('ส่วนผสม (แยกบรรทัด) *'),
      'ไก่ 1 กิโลกรัม\nกระเทียมเจียว',
    );
    await tester.enterText(
      fieldLabelled('ขั้นตอน (แยกบรรทัด) *'),
      'หมักไก่\nทอด',
    );
    final save = find.text('บันทึกสูตร');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final post = log.singleWhere(
      (r) => r.method == 'POST' && r.url.path == '/recipes',
    );
    final body = jsonDecode(post.body) as Map<String, dynamic>;
    expect(body['ingredients'], ['ไก่ 1 กิโลกรัม', 'กระเทียมเจียว']);
    expect(body['ingredientItems'], isEmpty);
  });

  testWidgets("someone else's recipe can't be edited", (tester) async {
    await setUpProviders();
    final official = recipes.getById('r1')!; // uploaderId is null
    await pump(tester, RecipeFormScreen(recipe: official));

    expect(find.text('แก้ไขได้เฉพาะสูตรที่คุณเพิ่มเอง'), findsOneWidget);
    expect(find.text('บันทึกการแก้ไข'), findsNothing);
  });

  testWidgets('a guest is asked to log in instead of filling in the form', (
    tester,
  ) async {
    await setUpProviders(loggedIn: false);
    await pump(tester, const RecipeFormScreen());

    expect(find.text('เข้าสู่ระบบก่อนเพิ่มสูตรอาหาร'), findsOneWidget);
    expect(find.text('บันทึกสูตร'), findsNothing);
  });

  testWidgets(
    'My recipes lists only your own recipes and opens the edit form',
    (tester) async {
      await setUpProviders();
      await pump(tester, const MyRecipesScreen());

      expect(find.text('ข้าวเหนียวมะม่วง'), findsOneWidget);
      expect(
        find.text('ผัดกะเพรา'),
        findsNothing,
        reason: 'official recipes are not yours',
      );

      await tester.tap(find.byTooltip('แก้ไข ข้าวเหนียวมะม่วง'));
      await tester.pumpAndSettle();

      expect(find.byType(RecipeFormScreen), findsOneWidget);
      expect(find.text('แก้ไขสูตรอาหาร'), findsOneWidget);
    },
  );
}
