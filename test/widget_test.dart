import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobilebatik/screens/detail_produk_screen.dart';
import 'package:mobilebatik/theme/app_theme.dart';



void main() {
  setUpAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('DetailProdukScreen renders properly on phone screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DetailProdukScreen(),
      ),
    );
    await tester.pump();

    // Verify key titles and sections are present
    expect(find.text('Detail Produk'), findsOneWidget);
    expect(find.text('Kemeja Batik Parang Classic'), findsOneWidget);
    expect(find.text('Pilih Ukuran'), findsOneWidget);
    expect(find.text('Pilihan Corak Motif'), findsOneWidget);
    expect(find.text('Jumlah Pembelian'), findsOneWidget);
    expect(find.text('Hamzah Official Store'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('DetailProdukScreen renders properly on wide/landscape screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024 * 2, 768 * 2);
    tester.view.devicePixelRatio = 2.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DetailProdukScreen(),
      ),
    );
    await tester.pump();

    // Verify wide screen elements exist
    expect(find.text('Detail Produk'), findsOneWidget);
    expect(find.text('Batik Tulis Premium'), findsOneWidget);
    expect(find.text('Ulasan Pembeli (48)'), findsOneWidget);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pump(const Duration(seconds: 1));
  });
}
