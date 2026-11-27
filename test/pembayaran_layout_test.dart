import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/router/app_router.dart';
import 'package:mobilebatik/screens/pembayaran_screen.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:mobilebatik/services/api_config.dart';
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

  testWidgets(
      'Halaman pembayaran pending merender penuh tanpa error layout fatal',
      (tester) async {
    await ApiClient.instance.setToken('tok');
    ApiClient.debugClientOverride = MockClient((request) async {
      if (request.url.path.contains('/payment')) {
        return http.Response(
          jsonEncode({
            'data': {
              'payment_status': 'pending',
              'snap_token': 'abc-token',
              'snap_redirect_url':
                  'https://app.sandbox.midtrans.com/snap/v4/redirection/abc',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 200,
          headers: {'content-type': 'application/json'});
    });

    tester.view.physicalSize = const Size(1220, 2712);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (details.exception is NetworkImageLoadException) return;
      if (text.contains('overflowed')) return;
      errors.add(details);
    };

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: AppRouter.router,
        theme: AppTheme.lightTheme,
      ),
    );
    await tester.pump();

    AppRouter.router.go('/pembayaran', extra: {
      'orderId': 24,
      'orderNumber': 'ORD-20261118-VHXX4D',
      'totalPayment': 150000,
      'items': [
        {'name': 'Batik Tulis Premium', 'quantity': 2, 'price': 75000},
      ],
      'snapRedirectUrl':
          'https://app.sandbox.midtrans.com/snap/v4/redirection/abc',
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    FlutterError.onError = previous;

    expect(find.byType(PembayaranScreen), findsOneWidget);
    expect(errors, isEmpty,
        reason: 'error layout: ${errors.map((e) => e.exceptionAsString()).join('\n')}');
    expect(find.text('Bayar Sekarang'), findsOneWidget);
  });
}
