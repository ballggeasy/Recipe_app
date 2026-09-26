import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/screens/login_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/widgets/common/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late AuthProvider auth;

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapLogin(WidgetTester tester) async {
    final button = find.widgetWithText(AppButton, 'เข้าสู่ระบบ');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = AuthProvider(
      authService: AuthService(
        api: fakeApi({
          'POST /auth/login': (_) => jsonResponse({'message': 'รหัสผ่านไม่ถูกต้อง'}, 401),
        }),
      ),
    );
  });

  testWidgets('asks for email and password when the form is empty', (tester) async {
    await pumpLogin(tester);

    await tapLogin(tester);

    expect(find.text('กรุณากรอกอีเมลและรหัสผ่าน'), findsOneWidget);
    expect(auth.isLoggedIn, isFalse);
  });

  testWidgets('shows the backend error for wrong credentials and stays on the login screen', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'somchai@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-pass');
    await tapLogin(tester);

    expect(find.text('รหัสผ่านไม่ถูกต้อง'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(auth.isLoggedIn, isFalse);
  });
}
