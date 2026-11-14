import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/data/cart_store.dart';
import 'package:mobilebatik/router/app_router.dart';
import 'package:mobilebatik/screens/home_screen.dart';
import 'package:mobilebatik/screens/login_screen.dart';
import 'package:mobilebatik/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobilebatik/services/api_client.dart';

void main() {
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

  tearDown(() {
    ApiClient.debugClientOverride = null;
  });

  // Banner HomeScreen memakai NetworkImage hardcoded; di test Flutter semua
  // request HttpClient di-mock 400 → NetworkImageLoadException. Abaikan hanya
  // error gambar itu; error lain tetap gagal.
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

  Future<void> goTo(
    WidgetTester tester,
    String location, {
    Object? extra,
  }) async {
    AppRouter.router.go(location, extra: extra);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  String currentPath() =>
      AppRouter.router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('tanpa sesi, aplikasi terbuka langsung di /home (mode tamu)', (
    tester,
  ) async {
    ignoreNetworkImageErrors();
    await pumpApp(tester);
    expect(currentPath(), '/home');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'tamu tap + Keranjang: diajak login, keranjang tetap kosong, aksi Login membuka /login',
    (tester) async {
      ignoreNetworkImageErrors();
      await pumpApp(tester);

      await goTo(
        tester,
        '/detail-produk',
        extra: <String, dynamic>{
          'name': 'Kemeja Batik Tes',
          'category': 'Baju Batik',
          'price': 'Rp 100.000',
          'rawPrice': 100000,
          'rating': '4.8',
          'sold': '12',
          'imageUrl': '',
          // tanpa 'id' → _loadDetailIfNeeded() return awal, tanpa network detail
        },
      );
      // Selesaikan transisi rute (~300ms): selama HomeScreen masih ter-mount,
      // dua Scaffold terdaftar di ScaffoldMessenger dan snackbar dirender 2×.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final addToCart = find
          .widgetWithText(OutlinedButton, '+ Keranjang')
          .first;
      await tester.ensureVisible(addToCart);
      await tester.tap(addToCart);
      await tester.pump();

      expect(
        find.text(
          'Silakan login terlebih dahulu untuk menambahkan produk ke keranjang.',
        ),
        findsOneWidget,
        reason:
            'tamu harus melihat ajakan login, bukan konfirmasi masuk keranjang',
      );
      expect(CartStore.instance.items, isEmpty);
      expect(CartStore.instance.itemCount, 0);

      await tester.pump(
        const Duration(milliseconds: 300),
      ); // animasi masuk selesai
      await tester.tap(find.byType(SnackBarAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(), '/login');
      expect(find.byType(LoginScreen), findsOneWidget);

      CartStore.instance.items.clear();
    },
  );

  testWidgets('logout dari profil: kembali ke /home sebagai tamu', (
    tester,
  ) async {
    ignoreNetworkImageErrors();
    await pumpApp(tester);

    await ApiClient.instance.setToken('token-tes');
    await goTo(tester, '/profil');
    expect(currentPath(), '/profil');

    await tester.ensureVisible(find.text('Keluar dari Akun'));
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(
      currentPath(),
      '/home',
      reason: 'setelah keluar, pengguna kembali ke /home dalam mode tamu',
    );
    expect(ApiClient.instance.isLoggedIn, isFalse);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
