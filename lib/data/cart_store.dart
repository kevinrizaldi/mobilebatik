import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';

class CartItem {
  final String id;
  final int? cartItemId;
  final int? productId;
  final String name;
  final String variant;
  final String imageUrl;
  final int unitPrice;
  int quantity;
  bool isSelected;

  CartItem({
    required this.id,
    this.cartItemId,
    this.productId,
    required this.name,
    required this.variant,
    required this.imageUrl,
    required this.unitPrice,
    this.quantity = 1,
    this.isSelected = false,
  });
}

class CartStore extends ChangeNotifier {
  CartStore._();

  static final CartStore instance = CartStore._();

  final List<CartItem> items = [];
  bool isSyncing = false;

  /// Callback untuk menampilkan error aksi keranjang ke user (SnackBar).
  /// Layar yang memuat keranjang (mis. `keranjang_screen`) menyetel ini;
  /// jika tidak diset, error tetap tidak crash tapi tidak ditampilkan.
  void Function(String message)? onError;

  void _reportError(Object error) {
    final handler = onError;
    if (handler == null) return;
    handler(
      error is ApiException
          ? error.message
          : 'Gagal memperbarui keranjang. Periksa koneksi Anda.',
    );
  }

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  int get selectedItemCount => items
      .where((item) => item.isSelected)
      .fold(0, (total, item) => total + item.quantity);

  int get selectedSubtotal => items
      .where((item) => item.isSelected)
      .fold(0, (total, item) => total + item.unitPrice * item.quantity);

  bool get allSelected =>
      items.isNotEmpty && items.every((item) => item.isSelected);

  Future<void> syncFromServer() async {
    final token = await ApiClient.instance.getToken();
    if (token == null || token.isEmpty) return;

    isSyncing = true;
    notifyListeners();

    try {
      final serverItems = await CartService.instance.fetchCart();
      items
        ..clear()
        ..addAll(
          serverItems.map((raw) {
            final size = raw['size']?.toString() ?? '';
            final variant = raw['variant']?.toString() ?? '';
            final labelParts = [
              if (size.isNotEmpty) 'Ukuran $size',
              if (variant.isNotEmpty) variant,
            ];
            final rawPrice = raw['unit_price'];
            final price = rawPrice is num
                ? rawPrice.round()
                : int.tryParse(rawPrice?.toString() ?? '0') ?? 0;

            return CartItem(
              id: raw['id'].toString(),
              cartItemId: raw['id'] is int
                  ? raw['id'] as int
                  : int.tryParse('${raw['id']}'),
              productId: raw['product_id'] is int
                  ? raw['product_id'] as int
                  : int.tryParse('${raw['product_id']}'),
              name: raw['name']?.toString() ?? 'Produk Batik',
              variant: labelParts.isEmpty ? 'Standar' : labelParts.join(' · '),
              imageUrl: raw['image_url']?.toString() ?? '',
              unitPrice: price,
              quantity: raw['quantity'] is int
                  ? raw['quantity'] as int
                  : int.tryParse('${raw['quantity']}') ?? 1,
              isSelected: raw['selected'] == true,
            );
          }),
        );
    } catch (_) {
      // Pertahankan state terakhir bila gagal sync.
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> addProduct({
    required int? productId,
    required String name,
    required String size,
    required String imageUrl,
    required int unitPrice,
    int quantity = 1,
  }) async {
    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty && productId != null) {
      await CartService.instance.addToCart(
        productId: productId,
        size: size,
        quantity: quantity,
      );
      await syncFromServer();
      return;
    }

    final localId = '${productId ?? name}_$size';
    final existingIndex = items.indexWhere((item) => item.id == localId);
    if (existingIndex >= 0) {
      items[existingIndex].quantity = (items[existingIndex].quantity + quantity)
          .clamp(1, 99);
    } else {
      items.insert(
        0,
        CartItem(
          id: localId,
          productId: productId,
          name: name,
          variant: 'Ukuran $size',
          imageUrl: imageUrl,
          unitPrice: unitPrice,
          quantity: quantity,
          isSelected: true,
        ),
      );
    }
    notifyListeners();
  }

  void toggleAll(bool selected) {
    for (final item in items) {
      item.isSelected = selected;
      if (item.cartItemId != null) {
        CartService.instance
            .updateItem(item.cartItemId!, selected: selected)
            .catchError((Object e) {
              _reportError(e);
              return <String, dynamic>{};
            });
      }
    }
    notifyListeners();
  }

  void toggleItem(String id) {
    final item = items.firstWhere((item) => item.id == id);
    item.isSelected = !item.isSelected;
    notifyListeners();
    if (item.cartItemId != null) {
      CartService.instance
          .updateItem(item.cartItemId!, selected: item.isSelected)
          .catchError((Object e) {
            _reportError(e);
            return <String, dynamic>{};
          });
    }
  }

  void changeQuantity(String id, int delta) {
    final item = items.firstWhere((item) => item.id == id);
    item.quantity = (item.quantity + delta).clamp(1, 99);
    notifyListeners();
    if (item.cartItemId != null) {
      CartService.instance
          .updateItem(item.cartItemId!, quantity: item.quantity)
          .catchError((Object e) {
            _reportError(e);
            return <String, dynamic>{};
          });
    }
  }

  void removeItem(String id) {
    final idx = items.indexWhere((item) => item.id == id);
    if (idx < 0) return;
    final removed = items.removeAt(idx);
    notifyListeners();
    if (removed.cartItemId != null) {
      CartService.instance.removeItem(removed.cartItemId!).catchError((
        Object e,
      ) {
        _reportError(e);
      });
    }
  }

  void removeSelected() {
    final toRemove = items.where((item) => item.isSelected).toList();
    items.removeWhere((item) => item.isSelected);
    notifyListeners();
    for (final item in toRemove) {
      if (item.cartItemId != null) {
        CartService.instance.removeItem(item.cartItemId!).catchError((
          Object e,
        ) {
          _reportError(e);
        });
      }
    }
  }
}
