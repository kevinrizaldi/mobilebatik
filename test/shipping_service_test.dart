import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:mobilebatik/services/api_config.dart';
import 'package:mobilebatik/services/shipping_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient.instance.setToken('tok');
    ApiClient.debugClientOverride = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'is_live': true,
          'origin': {'city_id': 444, 'city_name': 'Kota Surakarta (Solo)'},
          'destination_city_id': 135,
          'weight': 1000,
          'services': [
            {
              'code': 'JNE',
              'name': 'Jalur Nugraha Ekakurir (JNE)',
              'service': 'REG',
              'description': 'Layanan Reguler',
              'cost': 15000,
              'etd': '1-2 hari',
            },
            {
              'code': 'SIKEPAT',
              'name': 'SiCepat Ekspres',
              'service': 'BEST',
              'description': 'Besok Sampai Tujuan',
              'cost': 20000,
              'etd': '1 hari',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  });

  tearDown(() {
    ApiClient.debugClientOverride = null;
  });

  test(
    'fetchCosts POST /shipping/costs dan memetakan layanan siap tampil',
    () async {
      Object? capturedBody;
      Uri? capturedUrl;
      ApiClient.debugClientOverride = MockClient((request) async {
        capturedUrl = request.url;
        capturedBody = jsonDecode(request.body);
        return http.Response(
          jsonEncode({
            'success': true,
            'services': [
              {
                'code': 'JNE',
                'name': 'Jalur Nugraha Ekakurir (JNE)',
                'service': 'REG',
                'description': 'Layanan Reguler',
                'cost': 15000,
                'etd': '1-2 hari',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final costs = await ShippingService.instance.fetchCosts(
        addressId: 7,
        weightGrams: 600,
      );

      expect(capturedUrl.toString(), '${ApiConfig.baseUrl}/shipping/costs');
      expect(capturedBody, {
        'address_id': 7,
        'weight': 600,
        'couriers': 'jne,sicepat,jnt,pos,tiki',
      });

      expect(costs, hasLength(1));
      expect(costs.first['name'], 'JNE REG');
      expect(costs.first['fee'], 15000);
      expect(costs.first['estimate'], '1-2 hari');
    },
  );

  test(
    'fetchCosts mengembalikan daftar kosong bila layanan tidak tersedia',
    () async {
      ApiClient.debugClientOverride = MockClient(
        (_) async => http.Response(
          '{"success":true,"services":[]}',
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final costs = await ShippingService.instance.fetchCosts(
        addressId: 7,
        weightGrams: 1000,
      );

      expect(costs, isEmpty);
    },
  );
}
