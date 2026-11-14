import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:mobilebatik/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final service = ProductService.instance;
  http.Request? lastRequest;

  MockClient jsonResponse(String body) {
    return MockClient((request) async {
      lastRequest = request;
      return http.Response(
        body,
        200,
        headers: {'content-type': 'application/json'},
      );
    });
  }

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    await ApiClient.instance.setToken(null);
    lastRequest = null;
    ApiClient.debugClientOverride = null;
  });

  tearDown(() {
    ApiClient.debugClientOverride = null;
  });

  group('toUiProduct mapping (plan: product repository parse)', () {
    test('canonical category object becomes a name string', () {
      final ui = service.toUiProduct({
        'id': 1,
        'name': 'Kemeja Parang',
        'price': 285000,
        'category': {'id': 3, 'name': 'Kemeja'},
      });

      expect(ui['category'], 'Kemeja');
      expect(ui['name'], 'Kemeja Parang');
      expect(ui['price'], 'Rp 285.000');
      expect(ui['rawPrice'], 285000);
    });

    test('legacy category string and category_name fallbacks', () {
      expect(service.toUiProduct({'category': 'Sarung'})['category'], 'Sarung');
      expect(
        service.toUiProduct({'category_name': 'Legacy Kategori'})['category'],
        'Legacy Kategori',
      );
      // Objek kategori tanpa nama jatuh ke category_name, lalu default.
      expect(
        service.toUiProduct({
          'category': {'name': ''},
          'category_name': 'Dari Legacy',
        })['category'],
        'Dari Legacy',
      );
      expect(service.toUiProduct({})['category'], 'Batik');
    });

    test('image, review count and size stock aliases are mapped', () {
      final ui = service.toUiProduct({
        'id': 2,
        'image_url': 'https://cdn.test/kemeja.jpg',
        'reviews_count': 12,
        'size_stock': {'L': 3, 'M': 5},
        'other_images': ['a.jpg'],
        'reviews': [
          {'rating': 5},
        ],
      });

      expect(ui['imageUrl'], 'https://cdn.test/kemeja.jpg');
      expect(ui['sold'], '12');
      expect(ui['sizeStock'], {'L': 3, 'M': 5});
      expect(ui['otherImages'], ['a.jpg']);
      expect(ui['reviews'], [
        {'rating': 5},
      ]);
    });

    test('null/missing fields get safe defaults', () {
      final ui = service.toUiProduct({'id': 9});

      expect(ui['name'], 'Produk Batik');
      expect(ui['category'], 'Batik');
      expect(ui['price'], 'Rp 0');
      expect(ui['rawPrice'], 0);
      expect(ui['stock'], 0);
      expect(ui['status'], 'Tersedia');
      expect(ui['description'], '');
      expect(ui['rating'], '5.0');
      expect(ui['sold'], '0');
      expect(ui['imageUrl'], '');
      expect(ui['sizeStock'], {});
      expect(ui['reviews'], []);
      expect(ui['otherImages'], []);
    });

    test('string price and rating are parsed; zero rating falls back', () {
      expect(
        service.toUiProduct({'price': '150000', 'rating': '4.5'}),
        containsPair('price', 'Rp 150.000'),
      );
      expect(service.toUiProduct({'price': 'bukan-angka'})['rawPrice'], 0);
      expect(service.toUiProduct({'rating': 0})['rating'], '5.0');
      expect(service.toUiProduct({'rating': 4.2})['rating'], '4.2');
    });
  });

  group('fetch mapping through ApiClient (plan: repository parse JSON)', () {
    test('fetchProducts maps API payload and sends filter query', () async {
      ApiClient.debugClientOverride = jsonResponse(
        '{"data":['
        '{"id":1,"name":"Kemeja Batik","price":"285000","stock":4,'
        '"image_url":"k.jpg","reviews_count":12,"rating":4.2,'
        '"category":{"id":1,"name":"Kemeja"},'
        '"size_stock":{"L":2}},'
        '{"id":2,"name":"Sarung","price":150000,"category_name":"Sarung"}'
        ']}',
      );

      final products = await service.fetchProducts(
        search: ' batik ',
        category: 'Kemeja',
      );

      expect(products, hasLength(2));
      expect(products[0]['name'], 'Kemeja Batik');
      expect(products[0]['category'], 'Kemeja');
      expect(products[0]['price'], 'Rp 285.000');
      expect(products[0]['imageUrl'], 'k.jpg');
      expect(products[0]['sold'], '12');
      expect(products[0]['rating'], '4.2');
      expect(products[1]['category'], 'Sarung');

      expect(lastRequest, isNotNull);
      expect(lastRequest!.method, 'GET');
      expect(lastRequest!.url.path, endsWith('/products'));
      expect(lastRequest!.url.queryParameters['sort'], 'latest');
      expect(lastRequest!.url.queryParameters['search'], 'batik');
      expect(lastRequest!.url.queryParameters['category'], 'Kemeja');
    });

    test('fetchProducts omits empty search and Semua category', () async {
      ApiClient.debugClientOverride = jsonResponse('{"data":[]}');

      await service.fetchProducts(category: 'Semua');

      expect(lastRequest!.url.queryParameters.containsKey('search'), isFalse);
      expect(lastRequest!.url.queryParameters.containsKey('category'), isFalse);
      expect(lastRequest!.url.queryParameters['sort'], 'latest');
    });

    test('fetchProducts returns [] when data is not a list', () async {
      ApiClient.debugClientOverride = jsonResponse('{"data":{"oops":true}}');

      expect(await service.fetchProducts(), isEmpty);
    });

    test(
      'fetchProductDetail maps object and defaults on missing data',
      () async {
        ApiClient.debugClientOverride = jsonResponse(
          '{"data":{"id":5,"name":"Detail Produk","price":100000,'
          '"category":{"name":"Aksesoris"}}}',
        );

        final detail = await service.fetchProductDetail(5);
        expect(detail['id'], 5);
        expect(detail['category'], 'Aksesoris');
        expect(lastRequest!.url.path, endsWith('/products/5'));

        ApiClient.debugClientOverride = jsonResponse('{"data":null}');
        expect(await service.fetchProductDetail(6), isEmpty);
      },
    );

    test('fetchCategories returns names with Semua first', () async {
      ApiClient.debugClientOverride = jsonResponse(
        '{"data":[{"name":"Kemeja"},{"name":""},{"id":3}]}',
      );

      expect(await service.fetchCategories(), ['Semua', 'Kemeja']);
    });
  });
}
