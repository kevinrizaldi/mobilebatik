import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/router/app_router.dart';
import 'package:mobilebatik/screens/checkout_screen.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:mobilebatik/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  void ignoreNetworkImageErrors() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is NetworkImageLoadException) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);
  }

  Future<void> pumpCheckout(
    WidgetTester tester, {
    Object? shippingResponse,
  }) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: AppRouter.router,
        theme: AppTheme.lightTheme,
      ),
    );
    AppRouter.router.go(
      '/checkout',
      extra: {
        'directItem': {
          'id': 'direct_tes',
          'productId': 1,
          'name': 'Kemeja Batik Tes',
          'variant': 'Ukuran M',
          'imageUrl': '',
          'unitPrice': 250000,
          'quantity': 1,
        },
      },
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('checkout menampilkan biaya kurir live dari API RajaOngkir', (
    tester,
  ) async {
    ignoreNetworkImageErrors();
    SharedPreferences.setMockInitialValues({});
    await ApiClient.instance.setToken('token-tes');

    Map<String, dynamic>? shippingRequest;
    ApiClient.debugClientOverride = MockClient((request) async {
      final url = request.url.toString();
      if (url.endsWith('/addresses')) {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 7,
                'label': 'Rumah',
                'recipient_name': 'Budi Santoso',
                'phone': '081234567890',
                'full_address': 'Jl. Merdeka 1, Jakarta Barat',
                'is_primary': true,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (url.contains('/shipping/costs')) {
        shippingRequest = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'is_live': true,
            'services': [
              {
                'code': 'JNE',
                'name': 'Jalur Nugraha Ekakurir (JNE)',
                'service': 'REG',
                'description': 'Layanan Reguler',
                'cost': 15000,
                'etd': '1-2 hari',
              },
              {
                'code': 'SICEPAT',
                'name': 'SiCepat Ekspres',
                'service': 'BEST',
                'description': 'Besok Sampai Tujuan',
                'cost': 20000,
                'etd': '1 hari',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        '{"data": []}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await pumpCheckout(tester);

    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(find.textContaining('JNE REG'), findsOneWidget);
    expect(find.textContaining('SICEPAT BEST'), findsOneWidget);
    expect(find.textContaining('15.000'), findsWidgets);
    expect(
      shippingRequest,
      isNotNull,
      reason: 'checkout harus memanggil API biaya kirim',
    );
    expect(shippingRequest!['address_id'], 7);
    expect(shippingRequest!['weight'], 1000);

    ApiClient.debugClientOverride = null;
  });

  testWidgets(
    'bila API biaya gagal, tampilkan status gagal + Coba Lagi tanpa kurir dummy',
    (tester) async {
      ignoreNetworkImageErrors();
      SharedPreferences.setMockInitialValues({});
      await ApiClient.instance.setToken('token-tes');

      var failShipping = true;
      ApiClient.debugClientOverride = MockClient((request) async {
        final url = request.url.toString();
        if (url.endsWith('/addresses')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 7,
                  'label': 'Rumah',
                  'recipient_name': 'Budi Santoso',
                  'phone': '081234567890',
                  'full_address': 'Jl. Merdeka 1, Jakarta Barat',
                  'is_primary': true,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (url.contains('/shipping/costs')) {
          if (failShipping) {
            return http.Response(
              '{"message":"server error"}',
              500,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'is_live': true,
              'services': [
                {
                  'code': 'JNE',
                  'name': 'Jalur Nugraha Ekakurir (JNE)',
                  'service': 'REG',
                  'description': 'Layanan Reguler',
                  'cost': 15000,
                  'etd': '1-2 hari',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"data": []}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await pumpCheckout(tester);

      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.textContaining('GoSend / GrabExpress'), findsNothing);
      expect(find.textContaining('JNE Reguler'), findsNothing);
      expect(find.text('Biaya ongkir tidak tersedia'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      failShipping = false;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('JNE REG'), findsOneWidget);
      expect(find.textContaining('GoSend / GrabExpress'), findsNothing);
      expect(find.text('Biaya ongkir tidak tersedia'), findsNothing);

      ApiClient.debugClientOverride = null;
    },
  );
}
