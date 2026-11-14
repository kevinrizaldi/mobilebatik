import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/screens/login_screen.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.debugClientOverride = null;
  });

  tearDown(() {
    ApiClient.debugClientOverride = null;
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();
  }

  testWidgets('form login tidak lagi terisi kredensial demo', (tester) async {
    await pumpLogin(tester);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(2));
    expect(fields[0].controller!.text, isEmpty);
    expect(fields[1].controller!.text, isEmpty);

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets(
    'tap Masuk dengan form kosong: validasi jalan, tidak ada request',
    (tester) async {
      final requests = <http.Request>[];
      ApiClient.debugClientOverride = MockClient((request) async {
        requests.add(request);
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await pumpLogin(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
      expect(find.text('Password tidak boleh kosong'), findsOneWidget);
      expect(requests, isEmpty);
    },
  );
}
