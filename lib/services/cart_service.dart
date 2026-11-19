import 'api_client.dart';

class CartService {
  CartService._();

  static final CartService instance = CartService._();

  Future<List<Map<String, dynamic>>> fetchCart() async {
    final res = await ApiClient.instance.get('/cart');
    final data = res['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> addToCart({
    required int productId,
    String? size,
    String? variant,
    int quantity = 1,
  }) async {
    return ApiClient.instance.post(
      '/cart',
      body: {
        'product_id': productId,
        if (size != null && size.isNotEmpty) 'size': size,
        if (variant != null && variant.isNotEmpty) 'variant': variant,
        'quantity': quantity,
      },
    );
  }

  Future<Map<String, dynamic>> updateItem(
    int cartItemId, {
    int? quantity,
    bool? selected,
  }) async {
    return ApiClient.instance.patch(
      '/cart/$cartItemId',
      body: {'quantity': ?quantity, 'selected': ?selected},
    );
  }

  Future<void> removeItem(int cartItemId) async {
    await ApiClient.instance.delete('/cart/$cartItemId');
  }
}
