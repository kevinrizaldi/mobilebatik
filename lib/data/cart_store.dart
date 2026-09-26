import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final String variant;
  final String imageUrl;
  final int unitPrice;
  int quantity;
  bool isSelected;

  CartItem({
    required this.id,
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

  final List<CartItem> items = [
    CartItem(
      id: 'parang',
      name: 'Kemeja Batik Parang',
      variant: 'Ukuran L · Lengan Panjang',
      imageUrl:
          'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=300&q=80',
      unitPrice: 385000,
    ),
    CartItem(
      id: 'kawung',
      name: 'Kemeja Batik Kawung',
      variant: 'Ukuran L · Lengan Panjang',
      imageUrl:
          'https://images.unsplash.com/photo-1605806616949-1e87b487cb2a?w=300&q=80',
      unitPrice: 285000,
    ),
    CartItem(
      id: 'sogan',
      name: 'Kemeja Batik Sogan',
      variant: 'Ukuran M · Lengan Panjang',
      imageUrl:
          'https://images.unsplash.com/photo-1610448154563-39f80cc0faeb?w=300&q=80',
      unitPrice: 180000,
    ),
  ];

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  int get selectedItemCount => items
      .where((item) => item.isSelected)
      .fold(0, (total, item) => total + item.quantity);

  int get selectedSubtotal => items
      .where((item) => item.isSelected)
      .fold(0, (total, item) => total + item.unitPrice * item.quantity);

  bool get allSelected =>
      items.isNotEmpty && items.every((item) => item.isSelected);

  void toggleAll(bool selected) {
    for (final item in items) {
      item.isSelected = selected;
    }
    notifyListeners();
  }

  void toggleItem(String id) {
    final item = items.firstWhere((item) => item.id == id);
    item.isSelected = !item.isSelected;
    notifyListeners();
  }

  void changeQuantity(String id, int delta) {
    final item = items.firstWhere((item) => item.id == id);
    item.quantity = (item.quantity + delta).clamp(1, 99);
    notifyListeners();
  }

  void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void removeSelected() {
    items.removeWhere((item) => item.isSelected);
    notifyListeners();
  }
}
