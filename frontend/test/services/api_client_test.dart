import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipe_app/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ApiClient requests', () {
    test('sends the bearer token only on authenticated calls', () async {
      final log = <http.Request>[];
      final api = fakeApi({
        'GET /auth/me': (_) => jsonResponse({'ok': true}),
        'GET /recipes': (_) => jsonResponse([]),
      }, log: log);

      await api.setToken('abc123');
      await api.get('/auth/me');
      await api.get('/recipes', auth: false);

      expect(log[0].headers['Authorization'], 'Bearer abc123');
      expect(log[1].headers.containsKey('Authorization'), isFalse);
    });

    test('encodes the body as JSON', () async {
      final log = <http.Request>[];
      final api = fakeApi({
        'POST /auth/login': (_) => jsonResponse({}),
      }, log: log);

      await api.post('/auth/login', body: {'email': 'a@b.com'}, auth: false);

      expect(
        log.single.headers['Content-Type'],
        startsWith('application/json'),
      );
      expect(jsonDecode(log.single.body), {'email': 'a@b.com'});
    });

    test('returns null for an empty success body', () async {
      final api = fakeApi({'DELETE /recipes/1': (_) => jsonResponse(null)});
      expect(await api.delete('/recipes/1'), isNull);
    });
  });

  group('ApiClient errors', () {
    Future<ApiException> errorFrom(http.Response response) async {
      final api = fakeApi({'GET /x': (_) => response});
      try {
        await api.get('/x');
      } on ApiException catch (e) {
        return e;
      }
      fail('expected ApiException');
    }

    test('uses the backend message when it is a string', () async {
      final e = await errorFrom(
        jsonResponse({'message': 'รหัสผ่านไม่ถูกต้อง'}, 401),
      );
      expect(e.message, 'รหัสผ่านไม่ถูกต้อง');
    });

    test('joins validation messages when the backend sends a list', () async {
      final e = await errorFrom(
        jsonResponse({
          'message': ['email must be an email', 'password too short'],
        }, 400),
      );
      expect(e.message, 'email must be an email, password too short');
    });

    test('falls back to the status code when there is no message', () async {
      final e = await errorFrom(jsonResponse({}, 500));
      expect(e.message, 'เกิดข้อผิดพลาด (500)');
    });

    test('keeps the HTTP status code on the exception', () async {
      final e = await errorFrom(jsonResponse({'message': 'ไม่พบ'}, 404));
      expect(e.statusCode, 404);
    });

    test(
      'turns a non-JSON error page (e.g. from a proxy) into an ApiException',
      () async {
        final e = await errorFrom(
          http.Response('<html>Bad Gateway</html>', 502),
        );
        expect(e.message, 'เกิดข้อผิดพลาด (502)');
        expect(e.statusCode, 502);
      },
    );

    test('reports a non-JSON success body as invalid server data', () async {
      final e = await errorFrom(http.Response('<html>login</html>', 200));
      expect(e.message, 'ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    });

    test('turns network failures into a friendly connection error', () async {
      final api = ApiClient.forTesting(
        MockClient((_) => throw http.ClientException('offline')),
      );
      await expectLater(
        api.get('/recipes'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'),
          ),
        ),
      );
    });
  });

  group('ApiClient expired session', () {
    test(
      'clears the token and notifies when an authenticated call gets 401',
      () async {
        final api = fakeApi({
          'GET /auth/me': (_) => jsonResponse({'message': 'Unauthorized'}, 401),
        });
        await api.setToken('stale');
        var notified = 0;
        api.onUnauthorized = () => notified++;

        await expectLater(api.get('/auth/me'), throwsA(isA<ApiException>()));

        expect(notified, 1);
        expect(api.hasToken, isFalse);
        expect(
          (await SharedPreferences.getInstance()).getString('auth_token'),
          isNull,
        );
      },
    );

    test(
      'does not treat a wrong login password (no token sent) as an expired session',
      () async {
        final api = fakeApi({
          'POST /auth/login': (_) =>
              jsonResponse({'message': 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'}, 401),
        });
        var notified = 0;
        api.onUnauthorized = () => notified++;

        await expectLater(
          api.post('/auth/login', auth: false, body: {}),
          throwsA(isA<ApiException>()),
        );

        expect(notified, 0);
      },
    );

    test(
      'ignores other error statuses such as a bad current password (400)',
      () async {
        final api = fakeApi({
          'POST /auth/change-password': (_) =>
              jsonResponse({'message': 'รหัสผ่านปัจจุบันไม่ถูกต้อง'}, 400),
        });
        await api.setToken('valid');
        var notified = 0;
        api.onUnauthorized = () => notified++;

        await expectLater(
          api.post('/auth/change-password', body: {}),
          throwsA(isA<ApiException>()),
        );

        expect(notified, 0);
        expect(api.hasToken, isTrue);
      },
    );
  });

  group('ApiClient base URL', () {
    test('uses the platform default when API_BASE_URL is not set', () {
      final api = ApiClient.forTesting(
        MockClient((_) async => jsonResponse(null)),
      );
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(api.baseUrl, 'http://localhost:3000');

      // The Android emulator reaches the host machine through 10.0.2.2.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(api.baseUrl, 'http://10.0.2.2:3000');
    });

    test(
      'uses the configured base URL for requests and relative upload paths, without a trailing slash',
      () async {
        final log = <http.Request>[];
        final api = ApiClient.forTesting(
          MockClient((request) async {
            log.add(request);
            return jsonResponse([]);
          }),
          baseUrl: 'https://api.example.com/',
        );

        await api.get('/recipes', auth: false);

        expect(api.baseUrl, 'https://api.example.com');
        expect(log.single.url.toString(), 'https://api.example.com/recipes');
        expect(
          api.resolveUrl('/uploads/recipes/x.jpg'),
          'https://api.example.com/uploads/recipes/x.jpg',
        );
        expect(
          api.resolveUrl('https://upload.wikimedia.org/x.jpg'),
          'https://upload.wikimedia.org/x.jpg',
        );
      },
    );
  });

  group('ApiClient token storage', () {
    test(
      'persists the token by default and restores it with loadToken',
      () async {
        await fakeApi({}).setToken('saved');

        final fresh = fakeApi({});
        expect(await fresh.loadToken(), isTrue);
        expect(fresh.hasToken, isTrue);
      },
    );

    test('does not persist the token when persist is false', () async {
      await fakeApi({}).setToken('session-only', persist: false);
      expect(await fakeApi({}).loadToken(), isFalse);
    });

    test(
      'persist false also forgets a token remembered by an earlier login',
      () async {
        await fakeApi({}).setToken('remembered');
        await fakeApi({}).setToken('session-only', persist: false);

        expect(
          await fakeApi({}).loadToken(),
          isFalse,
          reason: 'reopening the app must not sign back in as the old account',
        );
      },
    );

    test('clearToken removes the stored token', () async {
      final api = fakeApi({});
      await api.setToken('saved');
      await api.clearToken();

      expect(api.hasToken, isFalse);
      expect(await fakeApi({}).loadToken(), isFalse);
    });
  });
}
