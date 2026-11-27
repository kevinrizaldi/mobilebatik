import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobilebatik/data/profile_store.dart';
import 'package:mobilebatik/screens/beri_ulasan_screen.dart';
import 'package:mobilebatik/screens/detail_produk_screen.dart';
import 'package:mobilebatik/screens/profil_subscreens.dart';

Uint8List _validPng() => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    );

class _FakeImagePicker extends ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    return [
      XFile.fromData(_validPng()),
      XFile.fromData(_validPng()),
    ];
  }
}

int _memoryImages(WidgetTester tester) => tester
    .widgetList(find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage))
    .length;

void main() {
  testWidgets('preview foto muncul dan tombol X menghapus foto yang dipilih',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: BeriUlasanScreen(
        order: const {'productName': 'Batik Cap', 'orderNumber': 'ORD-TEST'},
        imagePicker: _FakeImagePicker(),
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('TAMBAH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2/3 Terunggah'), findsOneWidget);
    expect(_memoryImages(tester), 2);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1/3 Terunggah'), findsOneWidget);
    expect(_memoryImages(tester), 1);
  });

  testWidgets('Ulasan Saya merender foto ulasan dari URL', (tester) async {
    ProfileStore.instance.addReview(ProfileReview(
      product: 'Batik Cap',
      date: 'Hari ini',
      rating: 5,
      comment: 'Bagus sekali',
      imageUrl: '',
      photos: const ['https://example.com/foto-ulasan.jpg'],
    ));

    await tester.pumpWidget(const MaterialApp(home: UlasanSayaScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
      findsWidgets,
    );
  });

  testWidgets('detail produk merender foto ulasan dari URL', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DetailProdukScreen(product: {
        'name': 'Batik Cap',
        'price': 150000,
        'imageUrl': '',
        'reviews': [
          {
            'user_name': 'Budi',
            'rating': 5,
            'comment': 'Kainnya bagus',
            'photos': ['https://example.com/foto-ulasan.jpg'],
          },
        ],
      }),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
      findsWidgets,
    );
  });
}
