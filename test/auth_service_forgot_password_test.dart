import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:mobilebatik/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<http.Request> requests;

  MockClient record(http.Response Function(http.Request request) respond) {
    return MockClient((request) async {
      requests.add(request);
      return respond(request);
    });
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient.instance.setToken(null);
    requests = [];
    ApiClient.debugClientOverride = null;
  });

  tearDown(() {
    ApiClient.debugClientOverride = null;
  });

  group('AuthService forgot and reset password', () {
    test('forgotPassword sends POST /forgot-password with email', () async {
      ApiClient.debugClientOverride = record((req) {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/forgot-password');
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['email'], 'user@example.com');
        return http.Response(
          jsonEncode({'message': 'Tautan pemulihan kata sandi telah dikirim.'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final res = await AuthService.instance.forgotPassword('user@example.com');
      expect(res['message'], contains('Tautan pemulihan kata sandi'));
      expect(requests.length, 1);
    });

    test('resetPassword sends POST /reset-password with credentials and token', () async {
      ApiClient.debugClientOverride = record((req) {
        expect(req.method, 'POST');
        expect(req.url.path, '/api/reset-password');
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['email'], 'user@example.com');
        expect(body['token'], 'test-token-123');
        expect(body['password'], 'secret123');
        expect(body['password_confirmation'], 'secret123');
        return http.Response(
          jsonEncode({'message': 'Kata sandi berhasil diperbarui.'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final res = await AuthService.instance.resetPassword(
        email: 'user@example.com',
        token: 'test-token-123',
        password: 'secret123',
        passwordConfirmation: 'secret123',
      );
      expect(res['message'], contains('berhasil diperbarui'));
      expect(requests.length, 1);
    });
  });
}

