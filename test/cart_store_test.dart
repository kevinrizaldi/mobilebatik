import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobilebatik/data/cart_store.dart';
import 'package:mobilebatik/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final store = CartStore.instance;

  const serverItemJson =
      '{"data":[{'
      '"id":42,"product_id":7,"name":"Kemeja Batik",'
      '"size":"L","variant":"Batik Tulis","image_url":"k.jpg",'
      '"unit_price":285000,"quantity":2,"selected":true}]}';

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    await ApiClient.instance.setToken(null);
    store.items.clear();
    store.isSyncing = false;
    store.onError = null;
    ApiClient.debugClientOverride = null;
  });

  tearDown(() {
    ApiClient.debugClientOverride = null;
    store.onError = null;
  });

  group('local cart logic (no token, API+local fallback)', () {
    test(
      'addProduct keeps item locally and raises itemCount (regression)',
      () async {
        var notified = 0;
        store.addListener(() => notified++);

        await store.addProduct(
          productId: 7,
          name: 'Kemeja Batik',
          size: 'L',
          imageUrl: 'k.jpg',
          unitPrice: 285000,
          quantity: 2,
        );

        // Regresi bug detail_produk: add pada store harus menaikkan itemCount.
        expect(store.items, hasLength(1));
        expect(store.itemCount, 2);
        expect(store.items.single.quantity, 2);
        expect(store.items.single.variant, 'Ukuran L');
        expect(store.items.single.isSelected, isTrue);
        expect(notified, greaterThan(0));
      },
    );

    test('addProduct same product+size increments and clamps at 99', () async {
      await store.addProduct(
        productId: 7,
        name: 'Kemeja Batik',
        size: 'L',
        imageUrl: '',
        unitPrice: 1000,
        quantity: 98,
      );
      await store.addProduct(
        productId: 7,
        name: 'Kemeja Batik',
        size: 'L',
        imageUrl: '',
        unitPrice: 1000,
        quantity: 5,
      );

      expect(store.items, hasLength(1));
      expect(store.items.single.quantity, 99);
      expect(store.itemCount, 99);
    });

    test('addProduct different sizes are separate line items', () async {
      await store.addProduct(
        productId: 7,
        name: 'Kemeja',
        size: 'L',
        imageUrl: '',
        unitPrice: 1000,
      );
      await store.addProduct(
        productId: 7,
        name: 'Kemeja',
        size: 'M',
        imageUrl: '',
        unitPrice: 1000,
      );

      expect(store.items, hasLength(2));
      expect(store.itemCount, 2);
    });

    test('changeQuantity clamps between 1 and 99 and notifies', () async {
      await store.addProduct(
        productId: null,
        name: 'Tanpa Produk',
        size: 'M',
        imageUrl: '',
        unitPrice: 5000,
        quantity: 2,
      );
      var notified = 0;
      store.addListener(() => notified++);

      store.changeQuantity(store.items.single.id, -10);
      expect(store.items.single.quantity, 1);

      store.changeQuantity(store.items.single.id, 1);
      expect(store.items.single.quantity, 2);
      expect(notified, 2);
    });

    test('removeItem drops the item and lowers itemCount', () async {
      await store.addProduct(
        productId: null,
        name: 'A',
        size: 'S',
        imageUrl: '',
        unitPrice: 1000,
        quantity: 3,
      );
      await store.addProduct(
        productId: null,
        name: 'B',
        size: 'S',
        imageUrl: '',
        unitPrice: 1000,
      );

      // Item baru disisipkan di depan, jadi first = B, last = A.
      store.removeItem(store.items.first.id);

      expect(store.items, hasLength(1));
      expect(store.items.single.name, 'A');
      expect(store.itemCount, 3);
    });

    test(
      'selection flags drive selectedItemCount/subtotal/allSelected',
      () async {
        store.items.addAll([
          CartItem(
            id: 'a',
            productId: 1,
            name: 'A',
            variant: 'Ukuran M',
            imageUrl: '',
            unitPrice: 10000,
            quantity: 2,
            isSelected: false,
          ),
          CartItem(
            id: 'b',
            productId: 2,
            name: 'B',
            variant: 'Ukuran M',
            imageUrl: '',
            unitPrice: 5000,
            quantity: 1,
            isSelected: true,
          ),
        ]);

        expect(store.selectedItemCount, 1);
        expect(store.selectedSubtotal, 5000);
        expect(store.allSelected, isFalse);

        store.toggleItem('a');
        expect(store.selectedItemCount, 3);
        expect(store.selectedSubtotal, 25000);
        expect(store.allSelected, isTrue);

        store.toggleAll(false);
        expect(store.selectedItemCount, 0);
        expect(store.selectedSubtotal, 0);
        expect(store.allSelected, isFalse);
      },
    );
  });

  group('server-backed cart (plan Task 11: MockClient)', () {
    test('syncFromServer maps API payload into items', () async {
      await ApiClient.instance.setToken('tok');
      ApiClient.debugClientOverride = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/cart'));
        return http.Response(
          serverItemJson,
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await store.syncFromServer();

      final item = store.items.single;
      expect(item.cartItemId, 42);
      expect(item.productId, 7);
      expect(item.name, 'Kemeja Batik');
      expect(item.variant, 'Ukuran L · Batik Tulis');
      expect(item.imageUrl, 'k.jpg');
      expect(item.unitPrice, 285000);
      expect(item.quantity, 2);
      expect(item.isSelected, isTrue);
      expect(store.itemCount, 2);
      expect(store.selectedSubtotal, 570000);
    });

    test('changeQuantity on server item PATCHes /cart/{id}', () async {
      await ApiClient.instance.setToken('tok');
      final requests = <http.Request>[];
      ApiClient.debugClientOverride = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            serverItemJson,
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"data":{"id":42,"quantity":3}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      await store.syncFromServer();

      store.changeQuantity('42', 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final patch = requests.where((r) => r.method == 'PATCH').single;
      expect(patch.url.path, endsWith('/cart/42'));
      expect(jsonDecode(patch.body), {'quantity': 3});
      expect(store.items.single.quantity, 3);
    });

    test('removeItem on server item sends DELETE /cart/{id}', () async {
      await ApiClient.instance.setToken('tok');
      final requests = <http.Request>[];
      ApiClient.debugClientOverride = MockClient((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            serverItemJson,
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('', 204);
      });
      await store.syncFromServer();

      store.removeItem('42');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final delete = requests.where((r) => r.method == 'DELETE').single;
      expect(delete.url.path, endsWith('/cart/42'));
      expect(store.items, isEmpty);
    });

    test('API failure fires onError with server message', () async {
      await ApiClient.instance.setToken('tok');
      ApiClient.debugClientOverride = MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            serverItemJson,
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"message":"Stok tidak cukup."}',
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      await store.syncFromServer();

      String? error;
      store.onError = (message) => error = message;

      store.changeQuantity('42', 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(error, 'Stok tidak cukup.');
    });
  });
}
