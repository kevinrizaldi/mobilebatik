import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/router/app_router.dart';
import 'package:mobilebatik/screens/checkout_screen.dart';
import 'package:mobilebatik/screens/home_screen.dart';
import 'package:mobilebatik/screens/login_screen.dart';
import 'package:mobilebatik/screens/pesanan_screen.dart';
import 'package:mobilebatik/screens/profil_screen.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:mobilebatik/services/api_config.dart';
import 'package:mobilebatik/services/order_service.dart';
import 'package:mobilebatik/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ApiClient.debugClientOverride = null;
    ApiConfig.debugBaseUrlOverride = null;
  });

  group('OrderService.checkout (plan Task 12: POST body via MockClient)', () {
    test('posts expected payload to /checkout with bearer token', () async {
      await ApiClient.instance.setToken('tok');
      http.Request? captured;
      ApiClient.debugClientOverride = MockClient((request) async {
        captured = request;
        return http.Response(
          '{"data":{"order":{"id":1}}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await OrderService.instance.checkout(
        customerName: ' Budi Santoso ',
        phone: '081234567890',
        address: 'Jl. Merdeka 1',
        shippingOption: 'Reguler',
        shippingCost: 15000,
        paymentMethod: 'snap',
        notes: 'Titip depan',
      );

      expect(captured, isNotNull);
      expect(captured!.method, 'POST');
      expect(captured!.url.toString(), '${ApiConfig.baseUrl}/checkout');
      expect(captured!.headers['Authorization'], 'Bearer tok');

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['customer_name'], 'Budi Santoso');
      expect(body['phone'], '081234567890');
      expect(body['address'], 'Jl. Merdeka 1');
      expect(body['shipping_option'], 'Reguler');
      expect(body['shipping_cost'], 15000);
      expect(body['payment_method'], 'snap');
      expect(body['notes'], 'Titip depan');
      expect(body.containsKey('voucher'), isFalse);
      expect(body.containsKey('cart_item_ids'), isFalse);
      expect(body.containsKey('items'), isFalse);

      await ApiClient.instance.setToken(null);
    });
  });

  group('app_router auth guard (plan Task 12)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ApiClient.instance.setToken(null);
      ApiClient.debugClientOverride = MockClient(
        (_) async => http.Response(
          '{"data": []}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
    });

    // Banner HomeScreen memakai NetworkImage hardcoded; di test Flutter semua
    // request HttpClient di-mock 400 → NetworkImageLoadException. Abaikan hanya
    // error gambar itu (dipasang di dalam body test karena binding.runTest
    // menimpa FlutterError.onError setelah setUp); error lain tetap gagal.
    void ignoreNetworkImageErrors() {
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exception is NetworkImageLoadException) return;
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);
    }

    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: AppRouter.router,
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    Future<void> goTo(WidgetTester tester, String location) async {
      AppRouter.router.go(location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    }

    String currentPath() =>
        AppRouter.router.routerDelegate.currentConfiguration.uri.path;

    testWidgets('logged-out user hitting /checkout, /pesanan, /profil '
        'is redirected to /login', (tester) async {
      ignoreNetworkImageErrors();
      await pumpApp(tester);

      for (final location in ['/checkout', '/pesanan', '/profil']) {
        await goTo(tester, location);
        expect(
          currentPath(),
          '/login',
          reason: '$location harus redirect ke /login saat belum login',
        );
        expect(find.byType(LoginScreen), findsOneWidget);
      }
    });

    testWidgets('logged-in user is allowed into protected routes', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      await ApiClient.instance.setToken('token-tes');
      await pumpApp(tester);

      await goTo(tester, '/checkout');
      expect(currentPath(), '/checkout');
      expect(find.byType(CheckoutScreen), findsOneWidget);

      await goTo(tester, '/pesanan');
      expect(currentPath(), '/pesanan');
      expect(find.byType(PesananScreen), findsOneWidget);

      await goTo(tester, '/profil');
      expect(currentPath(), '/profil');
      expect(find.byType(ProfilScreen), findsOneWidget);
    });

    testWidgets('logged-in user visiting /login is bounced to /home', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      await ApiClient.instance.setToken('token-tes');
      await pumpApp(tester);

      await goTo(tester, '/login');

      expect(currentPath(), '/home');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('dengan sesi tersimpan, aplikasi terbuka langsung di /home', (
      tester,
    ) async {
      ignoreNetworkImageErrors();
      await ApiClient.instance.setToken('token-tes');
      await pumpApp(tester);

      expect(currentPath(), '/home');
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
