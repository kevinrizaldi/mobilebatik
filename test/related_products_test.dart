import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobilebatik/screens/detail_produk_screen.dart';
import 'package:mobilebatik/theme/app_theme.dart';

void main() {
  testWidgets('DetailProdukScreen displays dynamic related products and triggers navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;

    bool navigatedToRelated = false;
    Map<String, dynamic>? navigatedExtra;

    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/detail',
          builder: (context, state) => DetailProdukScreen(
            product: {
              'name': 'Batik Utama',
              'price': 'Rp 200.000',
              'relatedProducts': [
                {
                  'id': 2,
                  'name': 'Batik Terkait Dinamis 1',
                  'price': 'Rp 150.000',
                  'imageUrl': 'https://example.com/b1.jpg',
                },
                {
                  'id': 3,
                  'name': 'Batik Terkait Dinamis 2',
                  'price': 'Rp 175.000',
                  'imageUrl': 'https://example.com/b2.jpg',
                },
              ],
            },
          ),
        ),
        GoRoute(
          path: '/detail-produk',
          builder: (context, state) {
            navigatedToRelated = true;
            navigatedExtra = state.extra as Map<String, dynamic>?;
            return const Scaffold(body: Text('Detail Terkait Page'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pump();

    // Scroll down until related product is visible
    final targetItem = find.text('Batik Terkait Dinamis 1');
    await tester.scrollUntilVisible(
      targetItem,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify dynamic related products appear
    expect(find.text('Produk Terkait'), findsOneWidget);
    expect(targetItem, findsOneWidget);
    expect(find.text('Rp 150.000'), findsOneWidget);

    // Tap on the first related product
    await tester.tap(targetItem);
    await tester.pumpAndSettle();

    expect(navigatedToRelated, isTrue);
    expect(navigatedExtra?['name'], 'Batik Terkait Dinamis 1');
    expect(navigatedExtra?['id'], 2);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
