import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/data/profile_store.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:mobilebatik/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<http.Request> requests;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient.instance.setToken(null);
    requests = [];
    ApiClient.debugClientOverride = null;
    ProfileStore.instance
      ..name = 'Awal'
      ..email = 'awal@example.com';
  });

  tearDown(() {
    ApiClient.debugClientOverride = null;
  });

  group('AuthService.restoreSession (design doc 2026-11-13)', () {
    test('token absent: tidak ada request, tetap tidak login', () async {
      ApiClient.debugClientOverride = MockClient((request) async {
        requests.add(request);
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await AuthService.instance.restoreSession();

      expect(requests, isEmpty);
      expect(ApiClient.instance.isLoggedIn, isFalse);
    });

    test(
      'token valid (/me 200): tetap login, profil terisi user asli',
      () async {
        await ApiClient.instance.setToken('token-hidup');
        ApiClient.debugClientOverride = MockClient((request) async {
          requests.add(request);
          return http.Response(
            '{"data":{"user":{"id":1,"name":"Siti Aminah",'
            '"email":"siti@hamzahstyle.id","phone":"+628123456789"}},'
            '"user":{"id":1}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        await AuthService.instance.restoreSession();

        expect(requests.single.method, 'GET');
        expect(requests.single.url.path, endsWith('/me'));
        expect(requests.single.headers['Authorization'], 'Bearer token-hidup');
        expect(ApiClient.instance.isLoggedIn, isTrue);
        expect(ProfileStore.instance.name, 'Siti Aminah');
        expect(ProfileStore.instance.email, 'siti@hamzahstyle.id');
      },
    );

    test('token dicabut server (/me 401): token dibersihkan', () async {
      await ApiClient.instance.setToken('token-mati');
      ApiClient.debugClientOverride = MockClient(
        (_) async => http.Response(
          '{"message":"Unauthenticated."}',
          401,
          headers: {'content-type': 'application/json'},
        ),
      );

      await AuthService.instance.restoreSession();

      expect(ApiClient.instance.isLoggedIn, isFalse);
    });

    test(
      'server tidak bisa dihubungi (timeout/koneksi): token dipertahankan',
      () async {
        await ApiClient.instance.setToken('token-lama');
        ApiClient.debugClientOverride = MockClient(
          (_) async => throw TimeoutException('timeout'),
        );

        await AuthService.instance.restoreSession();

        expect(ApiClient.instance.isLoggedIn, isTrue);
        expect(await ApiClient.instance.getToken(), 'token-lama');
      },
    );

    test(
      '/me 200 dengan payload tak terduga: token tetap, tidak crash',
      () async {
        await ApiClient.instance.setToken('token-tes');
        ApiClient.debugClientOverride = MockClient((request) async {
          requests.add(request);
          return http.Response(
            '{"data":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        await AuthService.instance.restoreSession();

        expect(ApiClient.instance.isLoggedIn, isTrue);
      },
    );
  });
}
