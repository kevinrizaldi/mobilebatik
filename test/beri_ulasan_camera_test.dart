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

/// Fake ImagePicker: hasil pickImage/pickMultiImage bisa dikonfigurasi via
/// ctor, plus pencatatan argumen terakhir untuk asersi test.
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({this.singleResult, this.multiResult});

  final XFile? singleResult;
  final List<XFile>? multiResult;
  ImageSource? lastSource;
  bool lastMultiCall = false;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    return singleResult;
  }

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
  // Viewport tinggi agar bagian foto (tombol TAMBAH) selalu terlihat tanpa scroll.
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

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text('TAMBAH'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('ketuk TAMBAH membuka pilihan Ambil Foto & Pilih dari Galeri', (tester) async {
    await pumpUlasan(tester, picker: _FakeImagePicker());
    await openSheet(tester);
    expect(find.text('Ambil Foto'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);
  });

  testWidgets('pilih dari galeri menambah foto sampai batas 3 (jalur lama utuh)', (tester) async {
    final fake = _FakeImagePicker(multiResult: [
      XFile.fromData(_validPng()),
      XFile.fromData(_validPng()),
      XFile.fromData(_validPng()),
    ]);
    await pumpUlasan(tester, picker: fake);
    await openSheet(tester);
    await tester.tap(find.text('Pilih dari Galeri'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(fake.lastMultiCall, isTrue);
    expect(find.text('3/3 Terunggah'), findsOneWidget);
    expect(find.text('TAMBAH'), findsNothing);
  });

  testWidgets('ambil foto kamera menambah 1 foto dengan ImageSource.camera', (tester) async {
    final fake = _FakeImagePicker(singleResult: XFile.fromData(_validPng()));
    await pumpUlasan(tester, picker: fake);
    await openSheet(tester);
    await tester.tap(find.text('Ambil Foto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(fake.lastSource, ImageSource.camera);
    expect(find.text('1/3 Terunggah'), findsOneWidget);
    expect(find.text('TAMBAH'), findsOneWidget);
  });

  testWidgets('kamera dibatalkan/ditolak (null) tidak menambah foto', (tester) async {
    await pumpUlasan(tester, picker: _FakeImagePicker(singleResult: null));
    await openSheet(tester);
    await tester.tap(find.text('Ambil Foto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('0/3 Terunggah'), findsOneWidget);
  });
}
