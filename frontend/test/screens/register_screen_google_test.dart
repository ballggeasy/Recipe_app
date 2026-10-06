import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/screens/register_screen.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:recipe_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/fake_google_sign_in.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AuthProvider> pumpRegister(
    WidgetTester tester,
    FakeGoogleSignIn google,
  ) async {
    // Phone-sized: the test font is wider than the real one and the wide layout's form is narrower.
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = AuthProvider(
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
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RegisterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('signing up with Google logs the user in', (tester) async {
    final google = FakeGoogleSignIn();
    final auth = await pumpRegister(tester, google);

    final button = find.text('ดำเนินการต่อด้วย Google');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(google.signInCalls, 1);
    expect(auth.status, AuthStatus.loggedIn);
  });

  testWidgets('offers Google but no GitHub', (tester) async {
    await pumpRegister(tester, FakeGoogleSignIn());

    expect(find.text('ดำเนินการต่อด้วย Google'), findsOneWidget);
    expect(find.textContaining('GitHub'), findsNothing);
  });

  testWidgets('has no Google button without a client ID', (tester) async {
    await pumpRegister(tester, FakeGoogleSignIn(isConfigured: false));

    expect(find.text('ดำเนินการต่อด้วย Google'), findsNothing);
  });
}
