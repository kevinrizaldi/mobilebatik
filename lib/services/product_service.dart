import 'api_client.dart';
import 'api_config.dart';

class ProductService {
  ProductService._();

  static final ProductService instance = ProductService._();

  Future<List<Map<String, dynamic>>> fetchCategoryObjects() async {
    final res = await ApiClient.instance.get('/categories', auth: false);
    final rawList = res['data'];
    if (rawList is! List) return [];

    return rawList
        .whereType<Map<String, dynamic>>()
        .where((item) => (item['name'] ?? '').toString().isNotEmpty)
        .toList();
  }

  Future<List<String>> fetchCategories() async {
    final rawList = await fetchCategoryObjects();
    final names = rawList
        .map((item) => (item['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toList();

    return ['Semua', ...names];
  }

  Future<List<Map<String, dynamic>>> fetchProducts({
    String? search,
    String? category,
    String sort = 'latest',
  }) async {
    final query = <String, String>{
      'sort': sort,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (category != null && category.isNotEmpty && category != 'Semua')
        'category': category,
    };

    final res = await ApiClient.instance.get(
      '/products',
      query: query,
      auth: false,
    );
    final rawList = res['data'];
    if (rawList is! List) return [];

    return rawList.whereType<Map<String, dynamic>>().map(toUiProduct).toList();
  }

  Future<Map<String, dynamic>> fetchProductDetail(int id) async {
    final res = await ApiClient.instance.get('/products/$id', auth: false);
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      return toUiProduct(data);
    }
    return {};
  }

  /// Kategori produk sebagai string nama untuk layar.
  /// API kanonik mengirim `category` sebagai objek `{id, name}`;
  /// bentuk legacy string dan `category_name` tetap ditangani sebagai fallback.
  String _categoryName(Map<String, dynamic> raw) {
    final category = raw['category'];
    if (category is Map) {
      final name = category['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    } else if (category is String && category.isNotEmpty) {
      return category;
    }

    final legacyName = raw['category_name']?.toString() ?? '';
    if (legacyName.isNotEmpty) return legacyName;

    return 'Batik';
  }

  /// Menyamakan format JSON Laravel ke map yang dipakai layar Flutter.
  Map<String, dynamic> toUiProduct(Map<String, dynamic> raw) {
    final numPrice = (raw['price'] is num)
        ? (raw['price'] as num)
        : num.tryParse(raw['price']?.toString() ?? '0') ?? 0;

    final ratingVal = (raw['rating'] is num)
        ? (raw['rating'] as num).toDouble()
        : double.tryParse(raw['rating']?.toString() ?? '0') ?? 0;

    return {
      'id': raw['id'],
      'sku': raw['sku'],
      'name': raw['name']?.toString() ?? 'Produk Batik',
      'category': _categoryName(raw),
      'price': ApiConfig.formatRupiah(numPrice),
      'rawPrice': numPrice,
      'stock': raw['stock'] ?? 0,
      'status': raw['status']?.toString() ?? 'Tersedia',
      'description': raw['description']?.toString() ?? '',
      'material': raw['material']?.toString() ?? '',
      'size': raw['size']?.toString() ?? '',
      'sizeStock': raw['size_stock'] is Map ? raw['size_stock'] : {},
      'rating': ratingVal > 0 ? ratingVal.toStringAsFixed(1) : '5.0',
      'sold': (raw['reviews_count'] ?? 0).toString(),
      'imageUrl': raw['image_url']?.toString() ?? '',
      'otherImages': raw['other_images'] is List ? raw['other_images'] : [],
      'reviews': raw['reviews'] is List ? raw['reviews'] : [],
    };
  }
}
