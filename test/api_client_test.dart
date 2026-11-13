import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:mobilebatik/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<http.Request> requests;

  MockClient record(http.Response Function(http.Request request) respond) {
    return MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
  }

  MockClient ok([String body = '{}']) {
    return record(
      (_) => http.Response(
        body,
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient.instance.setToken(null);
    requests = [];
    ApiClient.debugClientOverride = null;
    ApiConfig.debugBaseUrlOverride = null;
  });

  tearDown(() {
    ApiClient.debugClientOverride = null;
    ApiConfig.debugBaseUrlOverride = null;
  });

  group('ApiClient base URL', () {
    test('builds request URLs from ApiConfig.baseUrl (default)', () async {
      ApiClient.debugClientOverride = ok('{"data": []}');

      final res = await ApiClient.instance.get(
        '/products',
        query: {'sort': 'latest'},
      );

      expect(res, {'data': []});
      expect(requests, hasLength(1));
      expect(
        requests.single.url.toString(),
        '${ApiConfig.baseUrl}/products?sort=latest',
      );
    });

    test('honors base URL override', () async {
      ApiConfig.debugBaseUrlOverride = 'http://override.example/api';
      ApiClient.debugClientOverride = ok();

      await ApiClient.instance.get('/ping');

      expect(
        requests.single.url.toString(),
        'http://override.example/api/ping',
      );
    });
  });

  group('ApiClient auth headers', () {
    test('GET attaches Authorization Bearer when token is present', () async {
      await ApiClient.instance.setToken('token-abc');
      ApiClient.debugClientOverride = ok();

      await ApiClient.instance.get('/me');

      expect(requests.single.headers['Authorization'], 'Bearer token-abc');
      expect(requests.single.headers['Accept'], 'application/json');
    });

    test('POST attaches Authorization Bearer when token is present', () async {
      await ApiClient.instance.setToken('token-abc');
      ApiClient.debugClientOverride = ok();

      await ApiClient.instance.post('/cart', body: {'product_id': 1});

      expect(requests.single.headers['Authorization'], 'Bearer token-abc');
      expect(requests.single.method, 'POST');
    });

    test('omits Authorization header when token is absent', () async {
      ApiClient.debugClientOverride = ok();

      await ApiClient.instance.get('/products');

      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('ApiClient error handling', () {
    test('non-2xx throws ApiException with errors field message', () async {
      ApiClient.debugClientOverride = record(
        (_) => http.Response(
          '{"message":"Validasi gagal",'
          '"errors":{"email":["Format email tidak valid"]}}',
          422,
          headers: {'content-type': 'application/json'},
        ),
      );

      final future = ApiClient.instance.post('/register', body: {'email': 'x'});

      await expectLater(
        future,
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'Format email tidak valid'),
        ),
      );
    });

    test('non-2xx falls back to backend message field', () async {
      ApiClient.debugClientOverride = record(
        (_) => http.Response(
          '{"message":"Stok tidak cukup."}',
          422,
          headers: {'content-type': 'application/json'},
        ),
      );

      await expectLater(
        ApiClient.instance.post('/cart', body: {'product_id': 1}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', 'Stok tidak cukup.'),
        ),
      );
    });

    test('401 clears the stored token', () async {
      await ApiClient.instance.setToken('expired-token');
      ApiClient.debugClientOverride = record(
        (_) => http.Response(
          '{"message":"Unauthenticated."}',
          401,
          headers: {'content-type': 'application/json'},
        ),
      );

      await expectLater(
        ApiClient.instance.get('/me'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );

      expect(await ApiClient.instance.getToken(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sanctum_api_token'), isNull);
      expect(ApiClient.instance.isLoggedIn, isFalse);
    });
  });
}
