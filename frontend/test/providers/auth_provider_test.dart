import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/providers/auth_provider.dart';
import 'package:recipe_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

const _user = {'id': 'u1', 'email': 'somchai@example.com', 'name': 'สมชาย', 'profileImageUrl': null};

void main() {
  AuthProvider buildProvider(Map<String, RouteHandler> routes) =>
      AuthProvider(authService: AuthService(api: fakeApi(routes)));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('init', () {
    test('is logged out when no token is stored', () async {
      final auth = buildProvider({});
      await auth.init();

      expect(auth.status, AuthStatus.loggedOut);
      expect(auth.isLoading, isFalse);
    });

    test('restores the session when the stored token is still valid', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'valid'});
      final auth = buildProvider({'GET /auth/me': (_) => jsonResponse(_user)});

      await auth.init();

      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser!.name, 'สมชาย');
    });

    test('drops an expired token and logs out', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'expired'});
      final auth = buildProvider({'GET /auth/me': (_) => jsonResponse({'message': 'Unauthorized'}, 401)});

      await auth.init();

      expect(auth.status, AuthStatus.loggedOut);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });
  });

  group('login', () {
    test('logs in, stores the user and remembers the token', () async {
      final auth = buildProvider({
        'POST /auth/login': (req) {
          expect(jsonDecode(req.body)['email'], 'somchai@example.com',
              reason: 'email should be trimmed and lower-cased before sending');
          return jsonResponse({'accessToken': 'tok', 'user': _user});
        },
      });

      final error = await auth.login(email: '  Somchai@Example.com ', password: 'secret123');

      expect(error, isNull);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser!.email, 'somchai@example.com');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'tok');
    });

    test('does not persist the token when remember is off', () async {
      final auth = buildProvider({'POST /auth/login': (_) => jsonResponse({'accessToken': 'tok', 'user': _user})});

      await auth.login(email: 'somchai@example.com', password: 'secret123', remember: false);

      expect(auth.isLoggedIn, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });

    test('returns the backend error and stays logged out on failure', () async {
      final auth = buildProvider({
        'POST /auth/login': (_) => jsonResponse({'message': 'รหัสผ่านไม่ถูกต้อง'}, 401),
      });
      await auth.init();

      final error = await auth.login(email: 'somchai@example.com', password: 'wrong');

      expect(error, 'รหัสผ่านไม่ถูกต้อง');
      expect(auth.status, AuthStatus.loggedOut);
      expect(auth.currentUser, isNull);
      expect(auth.isLoading, isFalse);
    });
  });

  test('register logs the new user in', () async {
    final auth = buildProvider({'POST /auth/register': (_) => jsonResponse({'accessToken': 'tok', 'user': _user}, 201)});

    final error = await auth.register(name: 'สมชาย', email: 'somchai@example.com', password: 'secret123');

    expect(error, isNull);
    expect(auth.isLoggedIn, isTrue);
  });

  test('continueAsGuest switches to guest with no user', () {
    final auth = buildProvider({});
    auth.continueAsGuest();

    expect(auth.isGuest, isTrue);
    expect(auth.currentUser, isNull);
  });

  test('logout clears the user and the stored token', () async {
    final auth = buildProvider({'POST /auth/login': (_) => jsonResponse({'accessToken': 'tok', 'user': _user})});
    await auth.login(email: 'somchai@example.com', password: 'secret123');

    await auth.logout();

    expect(auth.status, AuthStatus.loggedOut);
    expect(auth.currentUser, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
  });

  test('changePassword refuses when nobody is logged in', () async {
    final auth = buildProvider({});
    expect(
      await auth.changePassword(currentPassword: 'a', newPassword: 'b'),
      'ไม่พบผู้ใช้ที่ล็อกอินอยู่',
    );
  });
}
