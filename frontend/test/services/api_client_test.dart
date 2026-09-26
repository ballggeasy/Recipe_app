import 'dart:convert';

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
      final api = fakeApi({'POST /auth/login': (_) => jsonResponse({})}, log: log);

      await api.post('/auth/login', body: {'email': 'a@b.com'}, auth: false);

      expect(log.single.headers['Content-Type'], startsWith('application/json'));
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
      final e = await errorFrom(jsonResponse({'message': 'รหัสผ่านไม่ถูกต้อง'}, 401));
      expect(e.message, 'รหัสผ่านไม่ถูกต้อง');
    });

    test('joins validation messages when the backend sends a list', () async {
      final e = await errorFrom(jsonResponse({'message': ['email must be an email', 'password too short']}, 400));
      expect(e.message, 'email must be an email, password too short');
    });

    test('falls back to the status code when there is no message', () async {
      final e = await errorFrom(jsonResponse({}, 500));
      expect(e.message, 'เกิดข้อผิดพลาด (500)');
    });

    test('turns network failures into a friendly connection error', () async {
      final api = ApiClient.forTesting(MockClient((_) => throw http.ClientException('offline')));
      await expectLater(
        api.get('/recipes'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้'))),
      );
    });
  });

  group('ApiClient token storage', () {
    test('persists the token by default and restores it with loadToken', () async {
      await fakeApi({}).setToken('saved');

      final fresh = fakeApi({});
      expect(await fresh.loadToken(), isTrue);
      expect(fresh.hasToken, isTrue);
    });

    test('does not persist the token when persist is false', () async {
      await fakeApi({}).setToken('session-only', persist: false);
      expect(await fakeApi({}).loadToken(), isFalse);
    });

    test('clearToken removes the stored token', () async {
      final api = fakeApi({});
      await api.setToken('saved');
      await api.clearToken();

      expect(api.hasToken, isFalse);
      expect(await fakeApi({}).loadToken(), isFalse);
    });
  });
}
