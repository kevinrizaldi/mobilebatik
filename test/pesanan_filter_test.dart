import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/router/app_router.dart';
import 'package:mobilebatik/screens/detail_produk_screen.dart';
import 'package:mobilebatik/screens/pesanan_screen.dart';
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

  Map<String, dynamic> rawOrder({
    required int id,
    required String code,
    required String status,
    required int statusIndex,
  }) {
    return {
      'id': id,
      'code': code,
      'status': status,
      'status_index': statusIndex,
      'total_price': 250000,
      'shipping_cost': 15000,
      'payment_method': 'Transfer Bank Manual',
      'courier': 'JNE',
      'created_at': '2026-11-15T10:00:00Z',
      'items': [
        {
          'product_id': id * 10,
          'name': 'Kemeja Batik $code',
          'price': 250000,
          'quantity': 1,
          'subtotal': 250000,
          'image_url': '',
        },
      ],
    };
  }

  Future<void> pumpPesanan(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: AppRouter.router,
        theme: AppTheme.lightTheme,
      ),
    );
    AppRouter.router.go('/pesanan');
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  void setupMocks() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.debugClientOverride = MockClient((request) async {
      final url = request.url.toString();
      if (url.endsWith('/orders')) {
        return http.Response(
          jsonEncode({
            'data': [
              rawOrder(
                id: 1,
                code: 'BAT-1',
                status: 'Dibatalkan',
                statusIndex: 1,
              ),
              rawOrder(
                id: 2,
                code: 'ORD-2',
                status: 'Menunggu Pembayaran',
                statusIndex: 1,
              ),
              rawOrder(id: 3, code: 'ORD-3', status: 'Dikirim', statusIndex: 3),
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (url.contains('/products')) {
        return http.Response(
          jsonEncode({
            'data': {
              'id': 10,
              'name': 'Kemeja Batik',
              'price': 'Rp250.000',
              'imageUrl': '',
            },
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
  }

  testWidgets(
    'pesanan dibatalkan punya tab sendiri dan tidak bocor ke Menunggu Pembayaran',
    (tester) async {
      ignoreNetworkImageErrors();
      setupMocks();
      await ApiClient.instance.setToken('token-tes');

      await pumpPesanan(tester);
      expect(find.byType(PesananScreen), findsOneWidget);

      expect(find.text('Semua (3)'), findsOneWidget);
      expect(find.text('Menunggu Pembayaran (1)'), findsOneWidget);
      expect(find.text('Dibatalkan (1)'), findsOneWidget);
      await tester.tap(find.text('Menunggu Pembayaran (1)'));
      await tester.pump();

      expect(
        find.textContaining('BAT-1'),
        findsNothing,
        reason: 'pesanan dibatalkan tidak boleh ada di tab Menunggu Pembayaran',
      );
      expect(find.textContaining('Kemeja Batik ORD-2'), findsOneWidget);
      expect(find.textContaining('ORD-3'), findsNothing);

      await tester.tap(find.text('Dibatalkan (1)'));
      await tester.pump();

      expect(find.textContaining('Kemeja Batik BAT-1'), findsOneWidget);
      expect(find.textContaining('Kemeja Batik ORD-2'), findsNothing);

      ApiClient.debugClientOverride = null;
    },
  );

  testWidgets(
    'kartu dibatalkan: satu Lihat Detail + satu Beli Lagi yang membuka detail produk',
    (tester) async {
      ignoreNetworkImageErrors();
      setupMocks();
      await ApiClient.instance.setToken('token-tes');

      await pumpPesanan(tester);
      await tester.tap(find.text('Dibatalkan (1)'));
      await tester.pump();

      expect(find.text('Lihat Detail'), findsOneWidget);
      expect(find.text('Beli Lagi'), findsOneWidget);

      await tester.tap(find.text('Beli Lagi'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }

      expect(find.byType(DetailProdukScreen), findsOneWidget);

      ApiClient.debugClientOverride = null;
    },
  );
}
