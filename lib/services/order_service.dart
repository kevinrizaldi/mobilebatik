import 'dart:typed_data';

import 'api_client.dart';

class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final res = await ApiClient.instance.get('/orders');
    final data = res['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> checkout({
    required String customerName,
    required String phone,
    required String address,
    required String shippingOption,
    required double shippingCost,
    required String paymentMethod,
    String? voucher,
    String? notes,
    List<int>? cartItemIds,
    List<Map<String, dynamic>>? directItems,
  }) async {
    return ApiClient.instance.post(
      '/checkout',
      body: {
        'customer_name': customerName.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'shipping_option': shippingOption,
        'shipping_cost': shippingCost,
        'payment_method': paymentMethod,
        if (voucher != null && voucher.trim().isNotEmpty)
          'voucher': voucher.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (cartItemIds != null && cartItemIds.isNotEmpty)
          'cart_item_ids': cartItemIds,
        if (directItems != null && directItems.isNotEmpty) 'items': directItems,
      },
    );
  }

  Future<Map<String, dynamic>> submitReview({
    required int orderId,
    int? productId,
    required int rating,
    required String comment,
    List<Uint8List> photos = const [],
  }) async {
    final fields = <String, String>{
      'rating': '$rating',
      'comment': comment.trim(),
      if (productId != null) 'product_id': '$productId',
    };
    if (photos.isEmpty) {
      return ApiClient.instance.post(
        '/orders/$orderId/reviews',
        body: Map<String, dynamic>.from(fields),
      );
    }
    return ApiClient.instance.postMultipart(
      '/orders/$orderId/reviews',
      fields: fields,
      files: [
        for (var i = 0; i < photos.length; i++)
          (filename: 'photo_$i.jpg', bytes: photos[i]),
      ],
    );
  }

  Future<Map<String, dynamic>> confirmReceived(int orderId) {
    return ApiClient.instance.post('/orders/$orderId/confirm');
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) {
    return ApiClient.instance.post('/orders/$orderId/cancel');
  }
}
