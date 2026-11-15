import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/router/app_router.dart';
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
    bool cancelRequested = false,
  }) {
    return {
      'id': id,
      'code': code,
      'status': status,
      'status_index': statusIndex,
      'cancel_requested': cancelRequested,
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

  void setupMocks({bool requested = false}) {
    SharedPreferences.setMockInitialValues({});
    var cancelRequested = requested;
    ApiClient.debugClientOverride = MockClient((request) async {
      final url = request.url.toString();
      if (request.method == 'POST' && url.endsWith('/orders/1/cancel')) {
        cancelRequested = true;
        return http.Response(
          jsonEncode({
            'message':
                'Permintaan pembatalan berhasil diajukan. Menunggu persetujuan admin.',
            'data': rawOrder(
              id: 1,
              code: 'ORD-1',
              status: 'Diproses',
              statusIndex: 2,
              cancelRequested: true,
            ),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (url.endsWith('/orders')) {
        return http.Response(
          jsonEncode({
            'data': [
              rawOrder(
                id: 1,
                code: 'ORD-1',
                status: 'Diproses',
                statusIndex: 2,
                cancelRequested: cancelRequested,
              ),
              rawOrder(
                id: 2,
                code: 'ORD-2',
                status: 'Menunggu Pembayaran',
                statusIndex: 1,
              ),
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
  }

  testWidgets(
    'kartu Diproses: primer Lihat Detail + sekunder Batalkan (bukan dua Lihat Detail)',
    (tester) async {
      ignoreNetworkImageErrors();
      setupMocks();
      await ApiClient.instance.setToken('token-tes');

      await pumpPesanan(tester);
      await tester.tap(find.text('Diproses (1)'));
      await tester.pump();

      expect(find.text('Lihat Detail'), findsOneWidget);
      expect(find.text('Batalkan'), findsOneWidget);

      final batalkan = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Batalkan'),
      );
      expect(
        batalkan.style?.backgroundColor?.resolve(const <WidgetState>{}),
        AppTheme.errorRed,
        reason: 'tombol Batalkan wajib berwarna merah',
      );

      ApiClient.debugClientOverride = null;
    },
  );

  testWidgets(
    'setelah ajukan pembatalan, tombol berubah jadi Menunggu Persetujuan',
    (tester) async {
      ignoreNetworkImageErrors();
      setupMocks();
      await ApiClient.instance.setToken('token-tes');

      await pumpPesanan(tester);
      await tester.tap(find.text('Diproses (1)'));
      await tester.pump();

      expect(find.text('Menunggu Persetujuan'), findsNothing);

      await tester.tap(find.text('Batalkan'));
      await tester.pump();

      expect(find.text('Ajukan Pembatalan?'), findsOneWidget);
      expect(
        find.textContaining('stok'),
        findsNothing,
        reason: 'customer tidak perlu tahu soal pengembalian stok',
      );

      await tester.tap(find.text('Ya, Ajukan'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }

      expect(
        find.textContaining('Menunggu persetujuan admin'),
        findsWidgets,
        reason: 'snackbar harus menampilkan pesan backend',
      );
      expect(find.text('Menunggu Persetujuan'), findsOneWidget);
      expect(find.text('Batalkan'), findsNothing);

      ApiClient.debugClientOverride = null;
    },
  );

  testWidgets(
    'kartu yang sudah diajukan: tombol sekunder nonaktif Menunggu Persetujuan',
    (tester) async {
      ignoreNetworkImageErrors();
      setupMocks(requested: true);
      await ApiClient.instance.setToken('token-tes');

      await pumpPesanan(tester);
      await tester.tap(find.text('Diproses (1)'));
      await tester.pump();

      expect(find.text('Menunggu Persetujuan'), findsOneWidget);
      expect(find.text('Batalkan'), findsNothing);
      expect(find.text('Lihat Detail'), findsOneWidget);

      ApiClient.debugClientOverride = null;
    },
  );

  testWidgets('dialog batal pesanan belum bayar juga tidak menyebut stok', (
    tester,
  ) async {
    ignoreNetworkImageErrors();
    setupMocks();
    await ApiClient.instance.setToken('token-tes');

    await pumpPesanan(tester);
    await tester.tap(find.text('Menunggu Pembayaran (1)'));
    await tester.pump();

    await tester.tap(find.text('Batalkan'));
    await tester.pump();

    expect(find.text('Batalkan Pesanan?'), findsOneWidget);
    expect(
      find.textContaining('stok'),
      findsNothing,
      reason: 'customer tidak perlu tahu soal pengembalian stok',
    );

    ApiClient.debugClientOverride = null;
  });
}
