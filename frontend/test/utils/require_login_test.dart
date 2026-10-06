import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/utils/require_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late AuthProvider auth;
  late List<bool> results;

  /// หน้าแรก > หน้าที่ถูก push ทับ (เช่นหน้ารายละเอียดสูตร) ที่มีปุ่มซึ่งต้องล็อกอิน
  Future<void> pumpPushedPage(WidgetTester tester) async {
    results = [];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => results.add(
                          requireLogin(context, 'เข้าสู่ระบบเพื่อเขียนรีวิว'),
                        ),
                        child: const Text('เขียนรีวิว'),
                      ),
                    ),
                  ),
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
    await tester.tap(find.text('เขียนรีวิว'));
    await tester.pumpAndSettle(); // รอ SnackBar เลื่อนขึ้นมาจนกดปุ่มได้
  }

  testWidgets('lets a logged-in user carry on without any message', (
    tester,
  ) async {
    auth = AuthProvider(
      authService: AuthService(
        api: fakeApi({
          'POST /auth/login': (_) => jsonResponse({
            'accessToken': 'tok',
            'user': {
              'id': 'u1',
              'email': 'somchai@example.com',
              'name': 'สมชาย',
              'profileImageUrl': null,
            },
          }),
        }),
      ),
    );
    await auth.login(email: 'somchai@example.com', password: 'secret123');

    await pumpPushedPage(tester);

    expect(results, [isTrue]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'stops a guest, explains why and offers a way to the login screen',
    (tester) async {
      auth = AuthProvider(authService: AuthService(api: fakeApi({})))
        ..continueAsGuest();

      await pumpPushedPage(tester);

      expect(results, [isFalse]);
      expect(find.text('เข้าสู่ระบบเพื่อเขียนรีวิว'), findsOneWidget);

      await tester.tap(find.widgetWithText(SnackBarAction, 'เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      expect(auth.status, AuthStatus.loggedOut);
      expect(
        find.text('open'),
        findsOneWidget,
        reason: 'pushed pages close so the login screen is not hidden',
      );
    },
  );
}
