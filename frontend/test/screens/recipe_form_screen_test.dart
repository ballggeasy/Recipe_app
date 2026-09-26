// ฟอร์มสูตร (เพิ่ม/แก้ไข): เลือกรูปแล้วอัปโหลดหลังบันทึกสูตร, แก้ได้ทุกช่องเฉพาะเจ้าของ, ผู้เยี่ยมชมเห็นหน้าให้เข้าสู่ระบบ
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/screens/recipe/recipe_form_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

// PNG 1x1 จริง ให้ Image.memory ถอดรหัสได้
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

/// แทนคลังรูปของเครื่อง — ส่งไฟล์ใน [next] กลับไปเมื่อผู้ใช้แตะเลือกรูป (null = ผู้ใช้ยกเลิก)
class _FakePicker {
  XFile? next;
  Future<XFile?> pick() async => next;
}

const _user = {'id': 'u1', 'email': 'cook@example.com', 'name': 'แม่ครัว', 'profileImageUrl': null};

/// เปิด RecipeFormScreen จากหน้าว่าง ๆ (ให้มีหน้าให้ย้อนกลับหลังบันทึก) พร้อม provider ที่หน้านี้ใช้
Future<void> _open(
  WidgetTester tester,
  RecipeProvider recipes,
  AuthProvider auth,
  _FakePicker picker, {
  Recipe? editing,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: recipes),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RecipeFormScreen(recipe: editing, pickImage: picker.pick)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// ListView ของฟอร์มสร้างเฉพาะส่วนที่อยู่บนจอ — เลื่อนให้เห็นก่อนแล้วค่อยพิมพ์
Future<void> _enter(WidgetTester tester, Finder field, String text) async {
  await tester.scrollUntilVisible(field, 200, scrollable: find.byType(Scrollable).first);
  await tester.enterText(field, text);
}

Future<void> _tapSave(WidgetTester tester, String label) async {
  final save = find.text(label);
  await tester.scrollUntilVisible(save, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('creates the recipe, then uploads the picked image to it', (tester) async {
    final log = <http.Request>[];
    Map<String, dynamic>? createdBody;
    final api = fakeApi({
      'GET /recipes': (_) => jsonResponse([recipeJson()]),
      'POST /auth/login': (_) => jsonResponse({'accessToken': 'tok', 'user': _user}),
      'POST /recipes': (req) {
        createdBody = jsonDecode(req.body) as Map<String, dynamic>;
        return jsonResponse({...recipeJson(id: 'new', isOfficial: false), 'uploaderId': 'u1'}, 201);
      },
      'POST /recipes/new/image': (_) => jsonResponse(
            {...recipeJson(id: 'new', isOfficial: false), 'uploaderId': 'u1', 'imageUrl': '/uploads/recipes/new-1.png'},
            201,
          ),
    }, log: log);
    final recipes = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
    await recipes.init();
    final auth = AuthProvider(authService: AuthService(api: api));
    await auth.login(email: 'cook@example.com', password: 'secret123');
    final picker = _FakePicker();
    await _open(tester, recipes, auth, picker);

    // ยกเลิกการเลือก (picker คืน null) ต้องไม่มีอะไรเปลี่ยน
    await tester.tap(find.text('แตะเพื่อเลือกรูปเมนู'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('ยกเลิกรูปที่เลือก'), findsNothing);

    picker.next = XFile.fromData(_png, path: 'dish.png');
    await tester.tap(find.text('แตะเพื่อเลือกรูปเมนู'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('ยกเลิกรูปที่เลือก'), findsOneWidget, reason: 'แสดงพรีวิวรูปที่เลือก');

    await _enter(tester, find.widgetWithText(TextField, 'เช่น ต้มยำกุ้งน้ำข้น'), 'ข้าวผัด');
    await _enter(tester, find.widgetWithText(TextField, 'พิมพ์ 1 บรรทัดต่อ 1 ขั้นตอน'), 'ผัดข้าว');
    await _tapSave(tester, 'บันทึกสูตร');

    final paths = log.where((r) => r.method == 'POST' && r.url.path.startsWith('/recipes')).map((r) => r.url.path).toList();
    expect(paths, ['/recipes', '/recipes/new/image']);
    expect(createdBody!.containsKey('imageUrl'), isFalse, reason: 'รูปอัปโหลดแยกหลังสร้างสูตร');
    expect(recipes.allRecipes.first.imageUrl, endsWith('/uploads/recipes/new-1.png'));
    expect(find.byType(RecipeFormScreen), findsNothing, reason: 'กลับหน้าก่อนหน้าหลังบันทึกสำเร็จ');
  });

  testWidgets('a guest who reaches the screen sees a login prompt instead of the form', (tester) async {
    final api = fakeApi({'GET /recipes': (_) => jsonResponse([recipeJson()])});
    final recipes = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
    await recipes.init();
    final auth = AuthProvider(authService: AuthService(api: api))..continueAsGuest();

    await _open(tester, recipes, auth, _FakePicker());

    expect(find.text('เข้าสู่ระบบก่อนเพิ่มสูตรอาหาร'), findsOneWidget);
    expect(find.text('บันทึกสูตร'), findsNothing);
    expect(find.text('แตะเพื่อเลือกรูปเมนู'), findsNothing);
  });

  group('editing', () {
    final mine = {
      ...recipeJson(id: 'mine', name: 'ข้าวผัดปู', isOfficial: false),
      'uploaderId': 'u1',
      'imageUrl': '/uploads/recipes/mine-1.png',
      'steps': ['ผัดข้าว', 'ใส่ปู'],
      'ingredientItems': [
        {'name': 'ปู', 'amount': '100', 'unit': 'กรัม'},
      ],
      'tips': 'ใช้ข้าวค้างคืน',
    };

    Future<(RecipeProvider, List<http.Request>, _FakePicker)> openEditor(WidgetTester tester, {required String asUser}) async {
      final log = <http.Request>[];
      final api = fakeApi({
        'GET /recipes': (_) => jsonResponse([mine, recipeJson()]),
        'POST /auth/login': (_) => jsonResponse({
              'accessToken': 'tok',
              'user': {..._user, 'id': asUser},
            }),
        'PATCH /recipes/mine': (req) => jsonResponse({...mine, ...jsonDecode(req.body) as Map<String, dynamic>}),
        'POST /recipes/mine/image': (_) => jsonResponse({...mine, 'imageUrl': '/uploads/recipes/mine-2.png'}, 201),
      }, log: log);
      final recipes = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
      await recipes.init();
      final auth = AuthProvider(authService: AuthService(api: api));
      await auth.login(email: 'cook@example.com', password: 'secret123');
      final picker = _FakePicker();
      await _open(tester, recipes, auth, picker, editing: recipes.getById('mine'));
      return (recipes, log, picker);
    }

    List<Map<String, dynamic>> patchBodies(List<http.Request> log) => log
        .where((r) => r.method == 'PATCH')
        .map((r) => jsonDecode(r.body) as Map<String, dynamic>)
        .toList();

    testWidgets("prefills every field and saves the owner's changes", (tester) async {
      final (recipes, log, _) = await openEditor(tester, asUser: 'u1');

      expect(find.text('แก้ไขสูตรอาหาร'), findsOneWidget);
      // แสดงรูปเดิม (ใน test โหลดรูปจากเน็ตไม่ได้ จึงเช็คที่ปุ่มเปลี่ยนรูปแทนตัวรูป)
      expect(find.byTooltip('เปลี่ยนรูปเมนู'), findsOneWidget);

      await _enter(tester, find.widgetWithText(TextField, 'ข้าวผัดปู'), 'ข้าวผัดปูก้อน');
      await _enter(tester, find.widgetWithText(TextField, 'ผัดข้าว\nใส่ปู'), 'ผัดข้าว\nใส่ปู\nโรยต้นหอม');
      await _tapSave(tester, 'บันทึกการแก้ไข');

      final body = patchBodies(log).single;
      expect(body['name'], 'ข้าวผัดปูก้อน');
      expect(body['steps'], ['ผัดข้าว', 'ใส่ปู', 'โรยต้นหอม']);
      expect(body['ingredientItems'], [
        {'name': 'ปู', 'amount': '100', 'unit': 'กรัม'},
      ]);
      expect(body['tips'], 'ใช้ข้าวค้างคืน');
      expect(body.containsKey('imageUrl'), isFalse, reason: 'ไม่ได้เปลี่ยนรูป');
      expect(log.where((r) => r.url.path.endsWith('/image')), isEmpty);
      expect(recipes.getById('mine')!.name, 'ข้าวผัดปูก้อน');
      expect(find.byType(RecipeFormScreen), findsNothing);
    });

    testWidgets('a newly picked image is uploaded after the fields are saved', (tester) async {
      final (recipes, log, picker) = await openEditor(tester, asUser: 'u1');

      picker.next = XFile.fromData(_png, path: 'new.png');
      await tester.tap(find.byTooltip('เปลี่ยนรูปเมนู'));
      await tester.pumpAndSettle();
      await _tapSave(tester, 'บันทึกการแก้ไข');

      final order = log.where((r) => r.method != 'GET' && r.url.path.startsWith('/recipes')).map((r) => '${r.method} ${r.url.path}');
      expect(order, ['PATCH /recipes/mine', 'POST /recipes/mine/image']);
      expect(recipes.getById('mine')!.imageUrl, endsWith('/uploads/recipes/mine-2.png'));
    });

    testWidgets("someone else's recipe cannot be edited", (tester) async {
      final (_, log, _) = await openEditor(tester, asUser: 'someone-else');

      expect(find.text('แก้ไขได้เฉพาะสูตรที่คุณเพิ่มเอง'), findsOneWidget);
      expect(find.text('บันทึกการแก้ไข'), findsNothing);
      expect(patchBodies(log), isEmpty);
    });
  });
}
