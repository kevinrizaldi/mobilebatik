import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class DetailProdukScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const DetailProdukScreen({super.key, this.product});

  @override
  State<DetailProdukScreen> createState() => _DetailProdukScreenState();
}

class _DetailProdukScreenState extends State<DetailProdukScreen> {
  int _selectedImageIndex = 0;
  String _selectedSize = 'L';
  String _selectedMotif = 'Sogan Klasik';
  int _quantity = 1;
  bool _isFavorite = false;
  int _cartCount = 2;
  int _selectedTabIndex = 0;

  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];

  final List<Map<String, dynamic>> _motifs = [
    {
      'name': 'Sogan Klasik',
      'color': const Color(0xFF6B4226),
    },
    {
      'name': 'Mega Mendung',
      'color': const Color(0xFF1E3A5F),
    },
    {
      'name': 'Kawung Tembaga',
      'color': const Color(0xFF9E6240),
    },
  ];

  Map<String, dynamic> get productData {
    return widget.product ?? {
      'name': 'Kemeja Batik Parang Classic',
      'category': 'Baju Batik Pria',
      'price': 'Rp 285.000',
      'originalPrice': 'Rp 350.000',
      'rating': '4.8',
      'sold': '124',
      'imageUrl': 'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=800&q=80',
    };
  }

  List<String> get galleryImages {
    final mainImage = (productData['imageUrl'] as String?)?.isNotEmpty == true
        ? productData['imageUrl'] as String
        : 'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=800&q=80';

    return [
      mainImage,
      'https://images.unsplash.com/photo-1605806616949-1e87b487cb2a?w=800&q=80',
      'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&q=80',
      'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=800&q=80',
    ];
  }

  void _navigateBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/katalog');
    }
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite
              ? 'Produk berhasil ditambahkan ke Favorit'
              : 'Produk dihapus dari Favorit',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _addToCart() {
    setState(() => _cartCount += _quantity);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$_quantity item ($_selectedSize, $_selectedMotif) masuk ke keranjang!',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                    decoration: const BoxDecoration(color: AppTheme.terracottaLight),
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
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppTheme.terracotta),
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

  Widget _safeImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 36,
              color: AppTheme.terracotta,
            ),
            const SizedBox(height: 6),
            Text(
              'Batik Hamzah',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.terracotta,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isWideScreen = r.screenWidth >= 768 || (r.isLandscape && r.screenWidth >= 600);

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: _buildAppBar(r),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 768 ||
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
                      SizedBox(height: r.spacingLg),
                      _buildTrustBadges(r),
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
                      _buildMotifSelector(r),
                      SizedBox(height: r.spacingMd),
                      _buildSizeSelector(r),
                      SizedBox(height: r.spacingMd),
                      _buildQuantitySelector(r),
                      SizedBox(height: r.spacingLg),
                      _buildActionButtonsRow(r),
                      SizedBox(height: r.spacingLg),
                      _buildStoreCard(r),
                      SizedBox(height: r.spacingLg),
                      _buildProductTabs(r),
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
                _buildMotifSelector(r),
                SizedBox(height: r.spacingMd),
                _buildSizeSelector(r),
                SizedBox(height: r.spacingMd),
                _buildQuantitySelector(r),
                SizedBox(height: r.spacingLg),
                _buildTrustBadges(r),
                SizedBox(height: r.spacingLg),
                _buildStoreCard(r),
                SizedBox(height: r.spacingLg),
                _buildProductTabs(r),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFFD4AF37), size: 14),
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
            // Favorite Button
            Positioned(
              top: 12,
              right: 12,
              child: InkWell(
                onTap: _toggleFavorite,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorite ? AppTheme.errorRed : AppTheme.primaryDark,
                    size: 20,
                  ),
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

  // Thumbnails Strip
  Widget _buildThumbnailStrip(Responsive r) {
    final images = galleryImages;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.isMobile && !r.isLandscape ? r.pagePaddingH : 0,
      ),
      child: Row(
        children: List.generate(images.length, (index) {
          final isSelected = _selectedImageIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedImageIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 64,
                margin: EdgeInsets.only(
                  right: index < images.length - 1 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.terracotta : AppTheme.borderLight,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _safeImage(
                    images[index],
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Trust Badges
  Widget _buildTrustBadges(Responsive r) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.spacingMd, vertical: r.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(r.cardRadius * 0.75),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(child: _trustBadgeItem(Icons.verified_outlined, '100% Asli', r)),
          Container(width: 1, height: 24, color: AppTheme.borderLight),
          Expanded(child: _trustBadgeItem(Icons.replay_rounded, 'Garansi 7 Hari', r)),
          Container(width: 1, height: 24, color: AppTheme.borderLight),
          Expanded(child: _trustBadgeItem(Icons.local_shipping_outlined, 'Kirim Cepat', r)),
        ],
      ),
    );
  }

  Widget _trustBadgeItem(IconData icon, String label, Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.terracotta),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: r.fontXs,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  // Product Header
  Widget _buildProductHeader(Responsive r) {
    final name = productData['name']?.toString() ?? 'Kemeja Batik Parang Classic';
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
              'Stok: 12 Tersedia',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontXs,
                color: AppTheme.successGreen,
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
                const Icon(Icons.star_rounded, color: Color(0xFFE5A93C), size: 18),
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
              '48 Ulasan',
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  // Motif Selector
  Widget _buildMotifSelector(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Pilihan Corak Motif',
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
              _selectedMotif,
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                fontWeight: FontWeight.w600,
                color: AppTheme.terracotta,
              ),
            ),
          ],
        ),
        SizedBox(height: r.spacingSm),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _motifs.map((motif) {
            final isSelected = _selectedMotif == motif['name'];
            return InkWell(
              onTap: () => setState(() => _selectedMotif = motif['name']),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryDark : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryDark : AppTheme.borderLight,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryDark.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: motif['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      motif['name'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontSm,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
                  const Icon(Icons.straighten_rounded,
                      size: 15, color: AppTheme.terracotta),
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
                        color: isSelected ? AppTheme.terracotta : AppTheme.borderLight,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.terracotta.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      size,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontSm,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textMain,
                      ),
                    ),
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
              Text(
                'Maksimal 10 item per transaksi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontXs,
                  color: AppTheme.textSubtle,
                ),
              ),
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
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                color: _quantity < 10 ? AppTheme.textMain : AppTheme.textSubtle,
                onPressed: _quantity < 10
                    ? () => setState(() => _quantity++)
                    : null,
              ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppTheme.primaryDark, size: 18),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // Store Card
  Widget _buildStoreCard(Responsive r) {
    return Container(
      padding: EdgeInsets.all(r.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(r.cardRadius * 0.75),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1C130D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'HS',
                style: GoogleFonts.cinzel(
                  color: const Color(0xFFD4AF37),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          SizedBox(width: r.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Hamzah Official Store',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: r.fontSm,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFFD4AF37), size: 14),
                  ],
                ),
                Text(
                  'Kota Surakarta • Aktif 5 menit lalu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.fontXs,
                    color: AppTheme.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              context.go('/katalog');
            },
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: const BorderSide(color: AppTheme.borderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Kunjungi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontXs,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Product Tabs (Interactive Segmented Pills without nested Viewport)
  Widget _buildProductTabs(Responsive r) {
    final tabTitles = ['Deskripsi', 'Spesifikasi', 'Perawatan'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(tabTitles.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < tabTitles.length - 1 ? 8 : 0),
                child: InkWell(
                  onTap: () => setState(() => _selectedTabIndex = index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryDark : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryDark : AppTheme.borderLight,
                      ),
                    ),
                    child: Text(
                      tabTitles[index],
                      style: GoogleFonts.outfit(
                        fontSize: r.fontSm,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: r.spacingMd),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(r.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(r.cardRadius * 0.75),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: _buildActiveTabContent(r),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent(Responsive r) {
    switch (_selectedTabIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filosofi & Seni Parang Rusak',
              style: GoogleFonts.outfit(
                fontSize: r.fontMd,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Motif Parang Rusak melambangkan keberanian, keteguhan hati, dan kesinambungan perjuangan manusia dalam mengarungi gelombang kehidupan. Dibuat dengan ketelitian tinggi oleh pengrajin maestro batik di Solo.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Potongan kemeja regular-fit modern dengan lapisan furing lembut yang sejuk seharian, sangat ideal untuk acara formal, resepsi pernikahan, dan busana kantor eksekutif.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            _specItem('Bahan Kain', 'Katun Primisima Sanforized (Grade A)', r),
            _specItem('Proses Batik', 'Cap Kombinasi Tulis Canting Tangan', r),
            _specItem('Lapisan Furing', 'Furing Katun Hero Adem & Menyerap', r),
            _specItem('Pewarnaan', 'Sogan Alam Ekstra Ramah Lingkungan', r),
            _specItem('Asal Pembuatan', 'Laweyan, Solo - Jawa Tengah', r),
            _specItem('Berat Produk', '350 gram (1 kg muat 3 pcs)', r),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _careTipItem('1', 'Gunakan sabun khusus lerak atau sampo bayi lembut.'),
            _careTipItem('2', 'Hindari mencuci dengan mesin cuci atau pemutih pakaian.'),
            _careTipItem('3', 'Jangan memeras kain terlalu kencang; cukup angin-anginkan di tempat teduh.'),
            _careTipItem('4', 'Setrika dengan suhu sedang, utamakan menyetrika dari sisi bagian dalam.'),
          ],
        );
    }
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

  Widget _careTipItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.terracottaLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.terracotta,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Customer Reviews Section
  Widget _buildCustomerReviews(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Ulasan Pembeli (48)',
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
        _reviewCard(
          name: 'Raden Bagus Nugroho',
          date: '2 hari lalu',
          rating: 5,
          comment:
              'Kualitas batiknya luar biasa halus. Motifnya nyambung rapi di bagian depan dan kancingnya tersembunyi elegan. Furingnya adem dipakai siang hari.',
          variant: 'Ukuran: L • Sogan Klasik',
          r: r,
        ),
        SizedBox(height: r.spacingSm),
        _reviewCard(
          name: 'Anindya Kirana',
          date: '1 minggu lalu',
          rating: 5,
          comment:
              'Dibeli untuk kado suami, ukurannya pas banget sesuai panduan ukuran. Pengiriman cepat dan kotak pembungkusnya sangat mewah!',
          variant: 'Ukuran: XL • Mega Mendung',
          r: r,
        ),
      ],
    );
  }

  Widget _reviewCard({
    required String name,
    required String date,
    required int rating,
    required String comment,
    required String variant,
    required Responsive r,
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
                    Text(
                      variant,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontXs,
                        color: AppTheme.textSubtle,
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
                color: i < rating ? const Color(0xFFE5A93C) : AppTheme.borderLight,
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
        ],
      ),
    );
  }

  // Related Products
  Widget _buildRelatedProducts(Responsive r) {
    final related = [
      {
        'name': 'Kain Batik Tulis Mega Mendung',
        'price': 'Rp 450.000',
        'rating': '4.9',
        'imageUrl': 'https://images.unsplash.com/photo-1605806616949-1e87b487cb2a?w=300&q=80',
      },
      {
        'name': 'Dress Batik Kawung Modern',
        'price': 'Rp 320.000',
        'rating': '4.7',
        'imageUrl': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=300&q=80',
      },
      {
        'name': 'Blouse Batik Sogan Elegan',
        'price': 'Rp 265.000',
        'rating': '4.8',
        'imageUrl': 'https://images.unsplash.com/photo-1610448154563-39f80cc0faeb?w=300&q=80',
      },
    ];

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
              return Container(
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                      child: _safeImage(
                        item['imageUrl']!,
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
                            item['name']!,
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
                            item['price']!,
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
        border: const Border(
          top: BorderSide(color: AppTheme.borderLight),
        ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: r.spacingMd),
            Text(
              'Konfirmasi Pesanan',
              style: GoogleFonts.outfit(
                fontSize: r.fontLg,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMain,
              ),
            ),
            SizedBox(height: r.spacingSm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _safeImage(
                  galleryImages.first,
                  width: 50,
                  height: 50,
                ),
              ),
              title: Text(
                productData['name']?.toString() ?? '',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                '$_quantity item • $_selectedSize • $_selectedMotif',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSubtle),
              ),
              trailing: Text(
                productData['price']?.toString() ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.terracotta,
                ),
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  productData['price']?.toString() ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: r.spacingLg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pesanan berhasil dibuat! Melanjutkan ke pembayaran...',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                      ),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Lanjutkan ke Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
