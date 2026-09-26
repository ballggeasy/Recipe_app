// ปุ่ม "เพิ่มสูตร" หน้าแรก: เปิดฟอร์มได้เฉพาะบัญชีที่ล็อกอิน ผู้เยี่ยมชมได้ข้อความพร้อมปุ่มไปเข้าสู่ระบบ
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/providers/recipe_provider.dart';
import 'package:recipe_app/screens/home/home_screen.dart';
import 'package:recipe_app/screens/login_screen.dart';
import 'package:recipe_app/screens/recipe/recipe_form_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/services/favorite_service.dart';
import 'package:recipe_app/services/recipe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

const _user = {'id': 'u1', 'email': 'cook@example.com', 'name': 'แม่ครัว', 'profileImageUrl': null};

Future<void> _pumpHome(WidgetTester tester, {required bool loggedIn}) async {
  final api = fakeApi({
    'GET /recipes': (_) => jsonResponse([recipeJson()]),
    'POST /auth/login': (_) => jsonResponse({'accessToken': 'tok', 'user': _user}),
  });
  final recipes = RecipeProvider(recipeService: RecipeService(api: api), favoriteService: FavoriteService(api: api));
  await recipes.init();
  final auth = AuthProvider(authService: AuthService(api: api));
  if (loggedIn) {
    await auth.login(email: 'cook@example.com', password: 'secret123');
  } else {
    auth.continueAsGuest();
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: recipes),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guests get a login prompt instead of the add-recipe form', (tester) async {
    await _pumpHome(tester, loggedIn: false);

    await tester.tap(find.text('เพิ่มสูตร'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeFormScreen), findsNothing);
    expect(find.text('กรุณาเข้าสู่ระบบเพื่อเพิ่มสูตรอาหาร'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('logged-in users open the add-recipe form', (tester) async {
    await _pumpHome(tester, loggedIn: true);

    await tester.tap(find.text('เพิ่มสูตร'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeFormScreen), findsOneWidget);
    expect(find.text('แตะเพื่อเลือกรูปเมนู'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบก่อนเพิ่มสูตรอาหาร'), findsNothing);
  });
}
