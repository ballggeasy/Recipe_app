import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/screens/forgot_password_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:recipe_app/widgets/common/app_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

const _disabledMessage = 'ระบบรีเซ็ตรหัสผ่านยังไม่เปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScreen(WidgetTester tester, Map<String, RouteHandler> routes) async {
    final auth = AuthProvider(authService: AuthService(api: fakeApi(routes)));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const ForgotPasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> checkEmail(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'somchai@example.com');
    await tester.tap(find.widgetWithText(AppButton, 'ตรวจสอบอีเมล'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the server message and never asks for a new password when reset is disabled', (tester) async {
    await pumpScreen(tester, {
      'GET /auth/exists/somchai%40example.com': (_) => jsonResponse({'message': _disabledMessage}, 403),
    });

    await checkEmail(tester);

    expect(find.text(_disabledMessage), findsOneWidget);
    expect(find.text('รหัสผ่านใหม่'), findsNothing);
    expect(find.widgetWithText(AppButton, 'ตรวจสอบอีเมล'), findsOneWidget);
  });

  testWidgets('asks for a new password once the email is confirmed to exist', (tester) async {
    await pumpScreen(tester, {
      'GET /auth/exists/somchai%40example.com': (_) => jsonResponse({'exists': true}),
    });

    await checkEmail(tester);

    expect(find.text('รหัสผ่านใหม่'), findsOneWidget);
  });
}
