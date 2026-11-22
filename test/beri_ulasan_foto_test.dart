import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobilebatik/screens/beri_ulasan_screen.dart';

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
}
