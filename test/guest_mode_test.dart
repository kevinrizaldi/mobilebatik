import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/router/app_router.dart';
import 'package:mobilebatik/screens/home_screen.dart';
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
}
