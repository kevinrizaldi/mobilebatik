import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobilebatik/screens/beri_ulasan_screen.dart';

/// PNG 1x1 valid agar `Image.memory` di grid foto bisa men-decode-nya.
Uint8List _validPng() => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    );

/// Fake ImagePicker: hanya jalur galeri yang dipakai (pickMultiImage).
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.multiResult});

  final List<XFile>? multiResult;
  bool lastMultiCall = false;

  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    lastMultiCall = true;
    return multiResult ?? const [];
  }
}

Future<void> pumpUlasan(WidgetTester tester, {ImagePicker? picker}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: BeriUlasanScreen(
      order: const {'productName': 'Batik Cap', 'orderNumber': 'ORD-TEST'},
      imagePicker: picker,
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('ketuk TAMBAH langsung membuka pemilih file (tanpa opsi kamera)',
      (tester) async {
    final fake = _FakeImagePicker();
    await pumpUlasan(tester, picker: fake);
    await tester.tap(find.text('TAMBAH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fake.lastMultiCall, isTrue);
    expect(find.text('Ambil Foto'), findsNothing);
    expect(find.text('Pilih dari Galeri'), findsNothing);
  });

  testWidgets('foto dari galeri ditambahkan sampai batas 3', (tester) async {
    final fake = _FakeImagePicker(multiResult: [
      XFile.fromData(_validPng()),
      XFile.fromData(_validPng()),
      XFile.fromData(_validPng()),
    ]);
    await pumpUlasan(tester, picker: fake);
    await tester.tap(find.text('TAMBAH'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fake.lastMultiCall, isTrue);
    expect(find.text('3/3 Terunggah'), findsOneWidget);
    expect(find.text('TAMBAH'), findsNothing);
  });
}
