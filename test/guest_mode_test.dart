import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/data/cart_store.dart';
import 'package:mobilebatik/router/app_router.dart';
import 'package:mobilebatik/screens/home_screen.dart';
import 'package:mobilebatik/screens/katalog_screen.dart';
import 'package:mobilebatik/screens/keranjang_screen.dart';
import 'package:mobilebatik/screens/login_screen.dart';
import 'package:mobilebatik/screens/pesanan_screen.dart';
import 'package:mobilebatik/screens/profil_screen.dart';
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

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

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

  testWidgets('dari /login, tombol kembali membawa ke /home (mode tamu)', (
    tester,
  ) async {
    ignoreNetworkImageErrors();
    await pumpApp(tester);

    await goTo(tester, '/login');
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(currentPath(), '/home');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('back sistem di /login: pindah ke /home, bukan keluar aplikasi', (
    tester,
  ) async {
    ignoreNetworkImageErrors();
    await pumpApp(tester);

    await goTo(tester, '/login');
    expect(find.byType(LoginScreen), findsOneWidget);

    await systemBack(tester);

    expect(currentPath(), '/home');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'back sistem di /katalog: pindah ke /home, bukan keluar aplikasi',
    (tester) async {
      ignoreNetworkImageErrors();
      await pumpApp(tester);

      await goTo(tester, '/katalog');
      expect(find.byType(KatalogScreen), findsOneWidget);

      await systemBack(tester);

      expect(currentPath(), '/home');
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'back sistem di /keranjang: pindah ke /home, bukan keluar aplikasi',
    (tester) async {
      ignoreNetworkImageErrors();
      await pumpApp(tester);

      await goTo(tester, '/keranjang');
      expect(find.byType(KeranjangScreen), findsOneWidget);

      await systemBack(tester);

      expect(currentPath(), '/home');
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'back sistem di /pesanan: pindah ke /home, bukan keluar aplikasi',
    (tester) async {
      ignoreNetworkImageErrors();
      await pumpApp(tester);

      await ApiClient.instance.setToken('token-tes');
      await goTo(tester, '/pesanan');
      expect(find.byType(PesananScreen), findsOneWidget);

      await systemBack(tester);

      expect(currentPath(), '/home');
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'back sistem di /profil: pindah ke /home, bukan keluar aplikasi',
    (tester) async {
      ignoreNetworkImageErrors();
      await pumpApp(tester);

      await ApiClient.instance.setToken('token-tes');
      await goTo(tester, '/profil');
      expect(find.byType(ProfilScreen), findsOneWidget);

      await systemBack(tester);

      expect(currentPath(), '/home');
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'back sistem pertama di /home tampil hint, kedua baru keluar aplikasi',
    (tester) async {
      ignoreNetworkImageErrors();
      await pumpApp(tester);

      MethodCall? systemPop;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') systemPop = call;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await systemBack(tester);
      expect(
        find.text('Tekan kembali sekali lagi untuk keluar'),
        findsOneWidget,
        reason:
            'tekanan pertama hanya menampilkan hint, aplikasi tetap terbuka',
      );
      expect(currentPath(), '/home');
      expect(systemPop, isNull);

      await systemBack(tester);
      expect(
        systemPop,
        isNotNull,
        reason: 'tekanan kedua mengeluarkan aplikasi',
      );
    },
  );
}
