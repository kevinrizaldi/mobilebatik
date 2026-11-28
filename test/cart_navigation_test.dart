import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobilebatik/data/cart_store.dart';
import 'package:mobilebatik/screens/keranjang_screen.dart';
import 'package:mobilebatik/theme/app_theme.dart';

void main() {
  testWidgets('Clicking cart item name or image navigates to /detail-produk', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;

    final store = CartStore.instance;
    store.items.clear();
    store.items.add(
      CartItem(
        id: '1',
        productId: 17,
        name: 'Kemeja Cowo Parang',
        variant: 'Ukuran L',
        imageUrl: '',
        unitPrice: 285000,
        quantity: 1,
        isSelected: true,
      ),
    );

    bool navigated = false;
    Map<String, dynamic>? passedExtra;

    final router = GoRouter(
      initialLocation: '/keranjang',
      routes: [
        GoRoute(
          path: '/keranjang',
          builder: (context, state) => const KeranjangScreen(),
        ),
        GoRoute(
          path: '/detail-produk',
          builder: (context, state) {
            navigated = true;
            passedExtra = state.extra as Map<String, dynamic>?;
            return const Scaffold(body: Text('Product Detail Screen'));
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

    expect(find.text('Kemeja Cowo Parang'), findsOneWidget);

    // Tap product name in cart
    await tester.tap(find.text('Kemeja Cowo Parang'));
    await tester.pumpAndSettle();

    expect(navigated, isTrue);
    expect(passedExtra?['id'], 17);
    expect(passedExtra?['name'], 'Kemeja Cowo Parang');

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      store.items.clear();
    });
  });
}
