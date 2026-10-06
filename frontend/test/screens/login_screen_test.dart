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
import '../helpers/fake_google_sign_in.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late AuthProvider auth;
  late FakeGoogleSignIn google;

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
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
    google = FakeGoogleSignIn();
    auth = AuthProvider(
      googleSignIn: google,
      authService: AuthService(
        api: fakeApi({
          'POST /auth/login': (_) =>
              jsonResponse({'message': 'รหัสผ่านไม่ถูกต้อง'}, 401),
          'POST /auth/google': (request) => request.body.contains('good-token')
              ? jsonResponse({
                  'accessToken': 'app-jwt',
                  'user': {
                    'id': 'u1',
                    'email': 'somchai@example.com',
                    'name': 'สมชาย',
                    'profileImageUrl': null,
                  },
                })
              : jsonResponse({
                  'message': 'ยืนยันตัวตนกับ Google ไม่สำเร็จ',
                }, 401),
        }),
      ),
    );
  });

  testWidgets('asks for email and password when the form is empty', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tapLogin(tester);

    expect(find.text('กรุณากรอกอีเมลและรหัสผ่าน'), findsOneWidget);
    expect(auth.isLoggedIn, isFalse);
  });

  testWidgets(
    'shows the backend error for wrong credentials and stays on the login screen',
    (tester) async {
      await pumpLogin(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'somchai@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong-pass');
      await tapLogin(tester);

      expect(find.text('รหัสผ่านไม่ถูกต้อง'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(auth.isLoggedIn, isFalse);
    },
  );

  group('Google sign-in', () {
    final googleButton = find.text('ดำเนินการต่อด้วย Google');

    testWidgets('offers Google but no GitHub', (tester) async {
      await pumpLogin(tester);

      expect(googleButton, findsOneWidget);
      expect(find.textContaining('GitHub'), findsNothing);
    });

    testWidgets('hides the button when the app has no Google client ID', (
      tester,
    ) async {
      google = FakeGoogleSignIn(isConfigured: false);
      auth = AuthProvider(googleSignIn: google);
      await pumpLogin(tester);

      expect(googleButton, findsNothing);
      expect(find.text('หรือ'), findsNothing);
      expect(find.text('ดูสูตรอาหารโดยไม่เข้าสู่ระบบ'), findsOneWidget);
    });

    testWidgets('logs in with the ID token Google returned', (tester) async {
      google.tokenToReturn = 'good-token';
      await pumpLogin(tester);

      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(google.signInCalls, 1);
      expect(auth.status, AuthStatus.loggedIn);
      expect(auth.currentUser?.email, 'somchai@example.com');
    });

    testWidgets('does nothing when the user cancels the account chooser', (
      tester,
    ) async {
      google.tokenToReturn = null;
      await pumpLogin(tester);

      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(google.signInCalls, 1);
      expect(auth.status, AuthStatus.unknown);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows why Google sign-in failed', (tester) async {
      google.failureToThrow =
          'เข้าสู่ระบบด้วย Google ไม่สำเร็จ กรุณาลองอีกครั้ง';
      await pumpLogin(tester);

      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(
        find.text('เข้าสู่ระบบด้วย Google ไม่สำเร็จ กรุณาลองอีกครั้ง'),
        findsOneWidget,
      );
      expect(auth.status, AuthStatus.unknown);
    });

    testWidgets('shows the backend error when it refuses the token', (
      tester,
    ) async {
      google.tokenToReturn = 'forged-token';
      await pumpLogin(tester);

      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(find.text('ยืนยันตัวตนกับ Google ไม่สำเร็จ'), findsOneWidget);
      expect(auth.status, AuthStatus.unknown);
    });

    testWidgets(
      'on the web, uses the Google button and logs in with its token',
      (tester) async {
        google = FakeGoogleSignIn(usesGoogleButton: true);
        auth = AuthProvider(
          googleSignIn: google,
          authService: AuthService(
            api: fakeApi({
              'POST /auth/google': (_) => jsonResponse({
                'accessToken': 'app-jwt',
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
        await pumpLogin(tester);

        expect(find.byKey(const Key('google-web-button')), findsOneWidget);
        expect(
          googleButton,
          findsNothing,
          reason: 'Google draws its own button',
        );

        google.emitWebToken('good-token');
        await tester.pumpAndSettle();

        expect(auth.status, AuthStatus.loggedIn);
      },
    );
  });

  test(
    'logging out also signs out of Google, so the next sign-in can pick another account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final google = FakeGoogleSignIn();
      final auth = AuthProvider(
        googleSignIn: google,
        authService: AuthService(api: fakeApi({})),
      );

      await auth.logout();

      expect(google.signOutCalls, 1);
    },
  );
}
