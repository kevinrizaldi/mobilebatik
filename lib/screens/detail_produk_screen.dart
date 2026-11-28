import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/cart_store.dart';
import '../services/api_client.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/notification_button.dart';

class DetailProdukScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const DetailProdukScreen({super.key, this.product});

  @override
  State<DetailProdukScreen> createState() => _DetailProdukScreenState();
}

class _DetailProdukScreenState extends State<DetailProdukScreen> {
  int _selectedImageIndex = 0;
  String _selectedSize = 'L';
  int _quantity = 1;
  bool _isAddingToCart = false;
  Map<String, dynamic>? _fetchedProduct;
  List<Map<String, dynamic>> _fallbackRelated = [];

  List<String> get _sizes {
    final sizeStock = productData['sizeStock'];
    if (sizeStock is Map && sizeStock.isNotEmpty) {
      return sizeStock.keys.map((e) => e.toString()).toList();
    }
    return const ['S', 'M', 'L', 'XL', 'XXL'];
  }

  int get _cartCount => CartStore.instance.productCount;

  Map<String, dynamic> get productData {
    return _fetchedProduct ??
        widget.product ??
        {
          'name': 'Kemeja Batik Parang Classic',
          'category': 'Baju Batik Pria',
          'price': 'Rp 285.000',
          'rating': '4.8',
          'sold': '124',
          'imageUrl': '',
        };
  }

  List<String> get galleryImages {
    final mainImage = (productData['imageUrl'] as String?) ?? '';
    final others = productData['otherImages'];
    final list = <String>[
      if (mainImage.isNotEmpty) mainImage,
      if (others is List)
        ...others.map((e) => e.toString()).where((e) => e.isNotEmpty),
    ];
    if (list.isEmpty) {
      return [''];
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    CartStore.instance.addListener(_onCartChanged);
    _syncSizesSelection();
    _loadDetailIfNeeded();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CartStore.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DetailProdukScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.product?['id'] != oldWidget.product?['id']) {
      _selectedImageIndex = 0;
      _quantity = 1;
      _fetchedProduct = null;
      _fallbackRelated = [];
      _syncSizesSelection();
      _loadDetailIfNeeded();
    }
  }

  void _syncSizesSelection() {
    final available = _sizes;
    if (available.isNotEmpty && !available.contains(_selectedSize)) {
      _selectedSize = available.first;
    }
  }

  Future<void> _loadDetailIfNeeded() async {
    final rawId = widget.product?['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId');
    if (id == null) return;

    try {
      final detail = await ProductService.instance.fetchProductDetail(id);
      if (mounted && detail.isNotEmpty) {
        setState(() {
          _fetchedProduct = detail;
          _syncSizesSelection();
        });
      }
    } catch (_) {
      // Tetap tampilkan data awal dari katalog jika request detail gagal.
    }

    // Jika produk terkait belum ada di detail payload, muat fallback dari katalog produk lain
    final currentRelated = (productData['relatedProducts'] as List?) ?? [];
    if (currentRelated.isEmpty && mounted) {
      try {
        final all = await ProductService.instance.fetchProducts();
        if (mounted && all.isNotEmpty) {
          final fallback = all
              .where((p) => p['id'] != id)
              .take(4)
              .toList();
          if (fallback.isNotEmpty) {
            setState(() {
              _fallbackRelated = fallback;
            });
          }
        }
      } catch (_) {}
    }
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/katalog');
    }
  }

  Future<void> _addToCart() async {
    if (!ApiClient.instance.isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Silakan login terlebih dahulu untuk menambahkan produk ke keranjang.',
          ),
          backgroundColor: AppTheme.errorRed,
          action: SnackBarAction(
            label: 'Login',
            textColor: Colors.white,
            onPressed: () => context.go('/login'),
          ),
        ),
      );
      return;
    }
    if (_isAddingToCart) return;
    setState(() => _isAddingToCart = true);

    final rawId = productData['id'];
    final productId = rawId is int ? rawId : int.tryParse('$rawId');
    final rawPrice = productData['rawPrice'];
    final unitPrice = rawPrice is num
        ? rawPrice.round()
        : int.tryParse(
                (productData['price']?.toString() ?? '0').replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                ),
              ) ??
              0;

    try {
      await CartStore.instance.addProduct(
        productId: productId,
        name: productData['name']?.toString() ?? 'Produk Batik',
        size: _selectedSize,
        imageUrl: galleryImages.first,
        unitPrice: unitPrice,
        quantity: _quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_quantity item (Ukuran $_selectedSize) masuk ke keranjang!',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  void _showSizeGuide(BuildContext context, Responsive r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgWarm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.cardRadius)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          r.spacingLg,
          r.spacingMd,
          r.spacingLg,
          MediaQuery.of(ctx).padding.bottom + r.spacingLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: r.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Panduan Ukuran (Size Chart)',
                    style: GoogleFonts.outfit(
                      fontSize: r.fontLg,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'Standar ukuran kemeja batik pria Hamzah Style (dalam cm):',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontSm,
                  color: AppTheme.textMuted,
                ),
              ),
              SizedBox(height: r.spacingMd),
              Table(
                border: TableBorder.all(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: AppTheme.terracottaLight,
                    ),
                    children: [
                      _tableHeader('Size'),
                      _tableHeader('Lingkar Dada'),
                      _tableHeader('Panjang Baju'),
                      _tableHeader('Panjang Lengan'),
                    ],
                  ),
                  _tableRow('S', '100 cm', '70 cm', '60 cm'),
                  _tableRow('M', '104 cm', '72 cm', '61 cm'),
                  _tableRow('L', '108 cm', '74 cm', '62 cm'),
                  _tableRow('XL', '112 cm', '76 cm', '63 cm'),
                  _tableRow('XXL', '118 cm', '78 cm', '64 cm'),
                ],
              ),
              SizedBox(height: r.spacingMd),
              Container(
                padding: EdgeInsets.all(r.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppTheme.terracotta,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toleransi perbedaan jahitan 1-2 cm karena proses pembuatan handmade batik pengrajin.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontXs,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMain,
        ),
      ),
    );
  }

  TableRow _tableRow(String s, String ld, String pb, String pl) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            s,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            ld,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            pb,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            pl,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _safeImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (url.trim().isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppTheme.terracottaLight,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: const Icon(
          Icons.image_outlined,
          size: 28,
          color: AppTheme.terracotta,
        ),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: AppTheme.inputBg,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppTheme.terracotta,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: AppTheme.terracottaLight,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 32,
                color: AppTheme.terracotta,
              ),
              const SizedBox(height: 4),
              Text(
                'Batik Hamzah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.terracotta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isWideScreen =
        r.screenWidth >= 768 || (r.isLandscape && r.screenWidth >= 600);

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: _buildAppBar(r),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide =
              constraints.maxWidth >= 768 ||
              (r.isLandscape && constraints.maxWidth >= 600);
          return isWide
              ? _buildWideTwoColumnLayout(r, constraints)
              : _buildMobilePortraitLayout(r);
        },
      ),
      bottomNavigationBar: isWideScreen ? null : _buildMobileBottomBar(r),
    );
  }

  PreferredSizeWidget _buildAppBar(Responsive r) {
    return AppBar(
      backgroundColor: AppTheme.bgWarm,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AppTheme.primaryDark,
          ),
        ),
        onPressed: _navigateBack,
      ),
      title: Text(
        'Detail Produk',
        style: GoogleFonts.outfit(
          fontSize: r.fontLg,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMain,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Bagikan',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.share_outlined,
              size: 18,
              color: AppTheme.primaryDark,
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tautan produk disalin ke clipboard!',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
                backgroundColor: AppTheme.primaryDark,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
        Stack(
          children: [
            IconButton(
              tooltip: 'Keranjang',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 18,
                  color: AppTheme.primaryDark,
                ),
              ),
              onPressed: () {},
            ),
            if (_cartCount > 0)
              Positioned(
                top: 4,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.terracotta,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_cartCount',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(width: r.spacingSm),
        const NotificationButton(),
        SizedBox(width: r.pagePaddingH),
      ],
    );
  }

  // WIDE LAYOUT: Tablet / Desktop / Landscape (2 Columns)
  Widget _buildWideTwoColumnLayout(Responsive r, BoxConstraints constraints) {
    final pad = r.pagePaddingH;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: r.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Gallery & Highlights
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildGalleryCard(r, height: 400),
                      SizedBox(height: r.spacingMd),
                      _buildThumbnailStrip(r),
                    ],
                  ),
                ),
              ),
              SizedBox(width: r.spacingLg),
              // Right Column: Product details & actions
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductHeader(r),
                      SizedBox(height: r.spacingMd),
                      _buildPriceCard(r),
                      SizedBox(height: r.spacingMd),
                      _buildSizeSelector(r),
                      SizedBox(height: r.spacingMd),
                      _buildQuantitySelector(r),
                      SizedBox(height: r.spacingLg),
                      _buildActionButtonsRow(r),
                      SizedBox(height: r.spacingLg),
                      _buildProductSpecifications(r),
                      SizedBox(height: r.spacingLg),
                      _buildCustomerReviews(r),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MOBILE PORTRAIT LAYOUT
  Widget _buildMobilePortraitLayout(Responsive r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGalleryCard(r, height: 340),
          SizedBox(height: r.spacingSm),
          _buildThumbnailStrip(r),
          SizedBox(height: r.spacingMd),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: r.pagePaddingH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(r),
                SizedBox(height: r.spacingMd),
                _buildPriceCard(r),
                SizedBox(height: r.spacingMd),
                _buildSizeSelector(r),
                SizedBox(height: r.spacingMd),
                _buildQuantitySelector(r),
                SizedBox(height: r.spacingLg),
                _buildProductSpecifications(r),
                SizedBox(height: r.spacingLg),
                _buildCustomerReviews(r),
                SizedBox(height: r.spacingLg),
                _buildRelatedProducts(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Gallery Card
  Widget _buildGalleryCard(Responsive r, {required double height}) {
    final images = galleryImages;
    final currentIndex = _selectedImageIndex.clamp(0, images.length - 1);

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(
        horizontal: r.isMobile && !r.isLandscape ? r.pagePaddingH : 0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.cardRadius),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.cardRadius),
        child: Stack(
          children: [
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0 &&
                      _selectedImageIndex < images.length - 1) {
                    setState(() => _selectedImageIndex++);
                  } else if (details.primaryVelocity! > 0 &&
                      _selectedImageIndex > 0) {
                    setState(() => _selectedImageIndex--);
                  }
                }
              },
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: _safeImage(
                  images[currentIndex],
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            // Exclusive Badge
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFFD4AF37),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Batik Tulis Premium',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dots Indicator
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentIndex == index ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: currentIndex == index
                          ? AppTheme.terracotta
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thumbnails Strip (Kotak 1:1 Square)
  Widget _buildThumbnailStrip(Responsive r) {
    final images = galleryImages;
    if (images.isEmpty) return const SizedBox.shrink();

    final double thumbSize = r.isMobile ? 64.0 : 72.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.isMobile && !r.isLandscape ? r.pagePaddingH : 0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(images.length, (index) {
              final isSelected = _selectedImageIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedImageIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: thumbSize,
                  height: thumbSize,
                  margin: EdgeInsets.only(
                    right: index < images.length - 1 ? 10 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.terracotta
                          : AppTheme.borderLight,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _safeImage(
                      images[index],
                      width: thumbSize,
                      height: thumbSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // Product Header
  Widget _buildProductHeader(Responsive r) {
    final name =
        productData['name']?.toString() ?? 'Kemeja Batik Parang Classic';
    final category = productData['category']?.toString() ?? 'Baju Batik Pria';
    final rating = productData['rating']?.toString() ?? '4.8';
    final sold = productData['sold']?.toString() ?? '124';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.terracottaLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontXs,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.terracotta,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Stok: ${productData['stock'] ?? 12} ${productData['status'] ?? 'Tersedia'}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontXs,
                color:
                    (productData['stock'] is int &&
                        (productData['stock'] as int) <= 0)
                    ? AppTheme.errorRed
                    : AppTheme.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: r.spacingSm),
        Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: r.val(xs: 18.0, sm: 22.0, md: 24.0, lg: 28.0),
            fontWeight: FontWeight.w800,
            color: AppTheme.textMain,
            height: 1.25,
          ),
        ),
        SizedBox(height: r.spacingSm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFE5A93C),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.fontSm,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
              ],
            ),
            Text(
              '($sold terjual)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                color: AppTheme.textSubtle,
              ),
            ),
            const Text('•', style: TextStyle(color: AppTheme.textSubtle)),
            Text(
              '${productData['sold'] ?? 0} Ulasan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                color: AppTheme.terracotta,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Price Card
  Widget _buildPriceCard(Responsive r) {
    final price = productData['price']?.toString() ?? 'Rp 285.000';
    final originalPrice = productData['originalPrice']?.toString();

    return Container(
      padding: EdgeInsets.all(r.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(r.cardRadius * 0.75),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Harga Spesial:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontXs,
                  color: AppTheme.textSubtle,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: GoogleFonts.outfit(
                  fontSize: r.val(xs: 20.0, sm: 24.0, md: 26.0, lg: 30.0),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.terracotta,
                ),
              ),
            ],
          ),
          if (originalPrice != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'HEMAT 18%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  originalPrice,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.fontSm,
                    decoration: TextDecoration.lineThrough,
                    color: AppTheme.textSubtle,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Size Selector
  Widget _buildSizeSelector(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Pilih Ukuran',
                style: GoogleFonts.outfit(
                  fontSize: r.fontMd,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showSizeGuide(context, r),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.straighten_rounded,
                    size: 15,
                    color: AppTheme.terracotta,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Panduan Ukuran',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: r.fontSm,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.terracotta,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: r.spacingSm),
        Row(
          children: _sizes.map((size) {
            final isSelected = _selectedSize == size;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedSize = size),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.terracotta : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.terracotta
                            : AppTheme.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.terracotta.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Builder(builder: (context) {
                      final sizeStock = productData['sizeStock'];
                      final stockCount = sizeStock is Map ? (sizeStock[size] ?? 0) : 0;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            size,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: r.fontSm,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppTheme.textMain,
                            ),
                          ),
                          if (stockCount is int || stockCount is double)
                            Text(
                              '${stockCount} pcs',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: r.fontXs,
                                fontWeight: FontWeight.w400,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppTheme.textSubtle,
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Quantity Selector
  Widget _buildQuantitySelector(Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jumlah Pembelian',
                style: GoogleFonts.outfit(
                  fontSize: r.fontMd,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              Builder(builder: (context) {
                final sizeStock = productData['sizeStock'];
                final maxStock = sizeStock is Map && _selectedSize != null
                    ? (sizeStock[_selectedSize] ?? productData['stock'] ?? 0)
                    : (productData['stock'] ?? 0);
                final maxInt = maxStock is int ? maxStock : int.tryParse('$maxStock') ?? 0;
                return Text(
                  maxInt > 0 ? 'Stok tersedia: $maxInt pcs' : 'Stok habis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.fontXs,
                    color: maxInt > 0 ? AppTheme.textSubtle : AppTheme.errorRed,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                color: _quantity > 1 ? AppTheme.textMain : AppTheme.textSubtle,
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.fontMd,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
              Builder(builder: (context) {
                final sizeStock = productData['sizeStock'];
                final maxStock = sizeStock is Map && _selectedSize != null
                    ? (sizeStock[_selectedSize] ?? productData['stock'] ?? 0)
                    : (productData['stock'] ?? 0);
                final maxInt = maxStock is int ? maxStock : int.tryParse('$maxStock') ?? 0;
                final canAdd = maxInt <= 0 ? false : _quantity < maxInt;
                return IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  color: canAdd ? AppTheme.textMain : AppTheme.textSubtle,
                  onPressed: canAdd ? () => setState(() => _quantity++) : null,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Action Buttons Row (For Wide screens)
  Widget _buildActionButtonsRow(Responsive r) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Membuka sesi konsultasi dengan Hamzah Batik Studio...',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
                backgroundColor: AppTheme.primaryDark,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            side: const BorderSide(color: AppTheme.borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppTheme.primaryDark,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Chat',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: _addToCart,
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: Text(
              '+ Keranjang',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: r.fontSm,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.terracotta,
              side: const BorderSide(color: AppTheme.terracotta, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: ElevatedButton(
            onPressed: () => _showCheckoutConfirmation(r),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Beli Sekarang',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: r.fontSm,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Product Specifications / Description
  Widget _buildProductSpecifications(Responsive r) {
    final material = (productData['material']?.toString().isNotEmpty == true)
        ? productData['material'].toString()
        : 'Katun Primissima Halus Benang 60s';
    final category = productData['category']?.toString() ?? '';
    final isKain = category.toLowerCase().contains('kain');
    final description = productData['description']?.toString().isNotEmpty == true
        ? productData['description'].toString()
        : 'Koleksi batik berkualitas tinggi yang nyaman dipakai untuk sehari-hari maupun acara formal.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi Produk',
          style: GoogleFonts.outfit(
            fontSize: r.fontMd,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain,
          ),
        ),
        SizedBox(height: r.spacingSm),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(r.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(r.cardRadius * 0.75),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Paragraf deskripsi utama
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontSm,
                  color: AppTheme.textMain,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderLight, height: 1),
              const SizedBox(height: 12),
              // Rincian spesifikasi produk (sesuai format website)
              if (!isKain) ...[
                _buildSpecBullet(
                  'Model',
                  'Regular Fit yang pas di badan, kerah rapi dengan kancing dalam',
                  r,
                ),
                const SizedBox(height: 6),
                _buildSpecBullet('Bahan', material, r),
                const SizedBox(height: 6),
                _buildSpecBullet(
                  'Kancing',
                  'Kancing batok kelapa alami dengan jahitan kuat dan rapi',
                  r,
                ),
                const SizedBox(height: 6),
                _buildSpecBullet(
                  'Saku',
                  'Satu saku di dada kiri dengan motif batik yang menyatu rapi',
                  r,
                ),
              ] else ...[
                _buildSpecBullet('Bahan', material, r),
                const SizedBox(height: 6),
                _buildSpecBullet(
                  'Ukuran',
                  (productData['size']?.toString().isNotEmpty == true)
                      ? productData['size'].toString()
                      : '2.2m x 1.15m',
                  r,
                ),
                const SizedBox(height: 6),
                _buildSpecBullet(
                  'Teknik',
                  'Batik Cap kombinasi Tulis Canting Tradisional',
                  r,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecBullet(String label, String value, Responsive r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: r.fontSm,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                color: AppTheme.textMain,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _specItem(String label, String value, Responsive r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSubtle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Customer Reviews Section
  Widget _buildCustomerReviews(Responsive r) {
    final rawReviews = productData['reviews'];
    final reviews = rawReviews is List
        ? rawReviews.whereType<Map>().toList()
        : <Map>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Ulasan Pelanggan (${reviews.isNotEmpty ? reviews.length : (productData['sold'] ?? 0)})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: r.fontMd,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Lihat Semua',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                fontWeight: FontWeight.w600,
                color: AppTheme.terracotta,
              ),
            ),
          ],
        ),
        SizedBox(height: r.spacingSm),
        if (reviews.isEmpty)
          Text(
            'Belum ada ulasan untuk produk ini.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: r.fontSm,
              color: AppTheme.textSubtle,
            ),
          )
        else
          ...reviews.asMap().entries.map(
            (entry) {
              final revIndex = entry.key;
              final rev = entry.value;
              final reviewId = rev['id'] ?? revIndex;

              final reviewPhotos = <String>[];
              if (rev['photos'] is List) {
                reviewPhotos.addAll(
                  (rev['photos'] as List)
                      .map((e) => e?.toString() ?? '')
                      .where((s) => s.isNotEmpty),
                );
              }
              final singleImg = rev['image_path'] ?? rev['image'];
              if (singleImg != null && singleImg.toString().isNotEmpty) {
                final sStr = singleImg.toString();
                if (!reviewPhotos.contains(sStr)) {
                  reviewPhotos.insert(0, sStr);
                }
              }

              return Padding(
                padding: EdgeInsets.only(bottom: r.spacingSm),
                child: _reviewCard(
                  name: (rev['user_name']?.toString().isNotEmpty == true)
                      ? rev['user_name'].toString()
                      : 'Pelanggan',
                  date: _relativeDate(rev['created_at']?.toString()),
                  rating: rev['rating'] is int
                      ? rev['rating'] as int
                      : int.tryParse('${rev['rating']}') ?? 5,
                  comment: rev['comment']?.toString() ?? '',
                  photos: reviewPhotos,
                  variant: '',
                  r: r,
                  reviewId: reviewId,
                ),
              );
            },
          ),
      ],
    );
  }

  /// Format tanggal ke "1 Okt 2026"
  String _relativeDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return isoString.split('T').first;
    }
  }

  Widget _reviewCard({
    required String name,
    required String date,
    required int rating,
    required String comment,
    required List<String> photos,
    required String variant,
    required Responsive r,
    dynamic reviewId,
  }) {
    return Container(
      padding: EdgeInsets.all(r.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(r.cardRadius * 0.75),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.terracottaLight,
                child: Text(
                  name[0],
                  style: GoogleFonts.outfit(
                    color: AppTheme.terracotta,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontSm,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                date,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontXs,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.star_rounded,
                size: 14,
                color: i < rating
                    ? const Color(0xFFE5A93C)
                    : AppTheme.borderLight,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: GoogleFonts.plusJakartaSans(
              fontSize: r.fontSm,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) => ReviewPhotoThumbnail(
                  imageUrl: photos[index],
                  index: index,
                  allImageUrls: photos,
                  heroTagPrefix: 'prod_review_${reviewId ?? name}',
                  size: 54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Related Products
  Widget _buildRelatedProducts(Responsive r) {
    List<Map<String, dynamic>> related = [];
    final rawRelated = productData['relatedProducts'];
    if (rawRelated is List && rawRelated.isNotEmpty) {
      related = rawRelated.whereType<Map<String, dynamic>>().toList();
    }
    if (related.isEmpty && _fallbackRelated.isNotEmpty) {
      related = _fallbackRelated;
    }

    if (related.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produk Terkait',
          style: GoogleFonts.outfit(
            fontSize: r.fontMd,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain,
          ),
        ),
        SizedBox(height: r.spacingSm),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            itemBuilder: (context, index) {
              final item = related[index];
              final name = item['name']?.toString() ?? 'Produk Batik';
              final price = item['price']?.toString() ?? '';
              final imageUrl = item['imageUrl']?.toString() ?? '';

              return GestureDetector(
                onTap: () {
                  context.push('/detail-produk', extra: item);
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(9),
                        ),
                        child: _safeImage(
                          imageUrl,
                          height: 100,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              price,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.terracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Mobile Bottom Bar (Sticky at bottom for phone portrait)
  Widget _buildMobileBottomBar(Responsive r) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        r.pagePaddingH,
        10,
        r.pagePaddingH,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Menghubungkan ke layanan pelanggan Hamzah Style...',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.primaryDark,
                ),
              );
            },
            icon: const Icon(Icons.chat_outlined),
            color: AppTheme.primaryDark,
            tooltip: 'Chat Penjual',
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: _addToCart,
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
              label: Text(
                '+ Keranjang',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: r.fontXs,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.terracotta,
                side: const BorderSide(color: AppTheme.terracotta, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () => _showCheckoutConfirmation(r),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Beli Sekarang',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: r.fontXs,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckoutConfirmation(Responsive r) {
    final rawId = productData['id'];
    final productId = rawId is int ? rawId : int.tryParse('$rawId');
    final rawPrice = productData['rawPrice'];
    final unitPrice = rawPrice is num
        ? rawPrice.round()
        : int.tryParse(
                (productData['price']?.toString() ?? '0').replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                ),
              ) ??
              0;

    context.push(
      '/checkout',
      extra: {
        'directItem': {
          'id': 'direct_${productId ?? productData['name']}_$_selectedSize',
          'productId': productId,
          'name': productData['name']?.toString() ?? 'Produk Batik',
          'size': _selectedSize,
          'variant': 'Ukuran $_selectedSize',
          'imageUrl': galleryImages.first,
          'unitPrice': unitPrice,
          'quantity': _quantity,
        },
      },
    );
  }
}
