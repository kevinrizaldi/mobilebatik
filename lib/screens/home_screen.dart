import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/cart_store.dart';
import '../services/api_client.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _featuredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    CartStore.instance.syncFromServer();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ProductService.instance.fetchCategoryObjects(),
        ProductService.instance.fetchProducts(sort: 'latest'),
      ]);

      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _featuredProducts = results[1];
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final pad = r.pagePaddingH;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        final last = _lastBackPressed;
        if (last != null && now.difference(last) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPressed = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tekan kembali sekali lagi untuk keluar'),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: _buildAppBar(context, r),
        bottomNavigationBar: const BottomNavBar(currentIndex: 0),
        body: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/katalog'),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.spacingMd,
                            vertical: r.spacingSm,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.inputBg,
                            borderRadius: BorderRadius.circular(
                              r.cardRadius * 0.75,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: r.iconSm,
                                color: AppTheme.textSubtle,
                              ),
                              SizedBox(width: r.spacingSm),
                              Text(
                                'Cari produk batik...',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: r.fontMd,
                                  color: AppTheme.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: r.spacingSm),
                    // Notification button
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.inputBg,
                          borderRadius: BorderRadius.circular(
                            r.cardRadius * 0.75,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.notifications_outlined,
                                size: r.iconMd,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF401100),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
                child: _HeroBanner(r: r),
              ),
            ),

            // Category Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: r.sectionSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jelajahi Koleksi',
                            style: GoogleFonts.outfit(
                              fontSize: r.fontLg,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMain,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/katalog'),
                            child: Text(
                              'Lihat semua',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: r.fontSm,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.terracotta,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.spacingMd),
                    SizedBox(
                      height: r.categoryCardHeight,
                      child: _categories.isEmpty
                          ? ListView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              children: [
                                _CategoryCard(
                                  r: r,
                                  label: 'Baju Batik',
                                  imageUrl: '',
                                ),
                                SizedBox(width: r.spacingSm),
                                _CategoryCard(
                                  r: r,
                                  label: 'Kain Batik',
                                  imageUrl: '',
                                ),
                                SizedBox(width: r.spacingSm),
                                _CategoryCard(
                                  r: r,
                                  label: 'Olahan Kain Sisa',
                                  imageUrl: '',
                                ),
                              ],
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: pad),
                              itemCount: _categories.length,
                              separatorBuilder: (_, _) =>
                                  SizedBox(width: r.spacingSm),
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                return _CategoryCard(
                                  r: r,
                                  label: cat['name']?.toString() ?? 'Batik',
                                  imageUrl: cat['image_url']?.toString() ?? '',
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Products header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pad,
                  r.sectionSpacing,
                  pad,
                  r.spacingMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Produk Unggulan',
                      style: GoogleFonts.outfit(
                        fontSize: r.fontLg,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/katalog'),
                      child: Text(
                        'Lihat semua',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontSm,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.terracotta,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid (responsive columns)
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.terracotta,
                    ),
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad, vertical: 32),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontSm,
                          color: AppTheme.textSubtle,
                        ),
                      ),
                      SizedBox(height: r.spacingSm),
                      ElevatedButton(
                        onPressed: _loadHomeData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: r.productGridColumns,
                    childAspectRatio: r.productGridAspectRatio,
                    crossAxisSpacing: r.spacingMd,
                    mainAxisSpacing: r.spacingMd,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = _featuredProducts[index];
                      return _ProductCard(
                        r: r,
                        name: p['name']?.toString() ?? '',
                        category: p['category']?.toString() ?? '',
                        price: p['price']?.toString() ?? 'Rp 0',
                        originalPrice: p['originalPrice']?.toString(),
                        rating: p['rating']?.toString() ?? '5.0',
                        sold: p['sold']?.toString() ?? '0',
                        imageUrl: p['imageUrl']?.toString() ?? '',
                        onTap: () => context.push('/detail-produk', extra: p),
                      );
                    },
                    childCount: _featuredProducts.length > 6
                        ? 6
                        : _featuredProducts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Responsive r) {
    return AppBar(
      backgroundColor: AppTheme.bgWarm,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: r.isMedium || r.isLarge || r.isXLarge ? 64 : 56,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1C130D),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              'HS',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: r.fontMd,
              ),
            ),
          ),
          SizedBox(width: r.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hamzah Style',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontMd,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              Text(
                'Official Store',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontXs,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Center(
          child: Text(
            'Home',
            style: GoogleFonts.plusJakartaSans(
              fontSize: r.fontSm,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
        ),
        SizedBox(width: r.spacingSm),
        CircleAvatar(
          radius: r.isMedium || r.isTablet ? 18 : 16,
          backgroundColor: const Color(0xFF1C130D),
          child: Icon(
            Icons.person_outline_rounded,
            color: Colors.white,
            size: r.iconSm,
          ),
        ),
        SizedBox(width: r.pagePaddingH * 0.8),
      ],
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final Responsive r;
  const _HeroBanner({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: r.bannerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.cardRadius),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1762111908858-201b9da429dc?w=800&q=80',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.cardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                    Color(0xCC110703),
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.spacingSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'KOLEKSI TERBARU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontXs,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: r.spacingSm),
                  Text(
                    'Batik Nusantara\nPenuh Makna',
                    style: GoogleFonts.outfit(
                      fontSize: r.isLandscape && r.isMobile
                          ? r.fontLg
                          : r.fontXl,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: r.spacingMd),
                  GestureDetector(
                    onTap: () => context.go('/katalog'),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.spacingMd,
                        vertical: r.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Lihat Koleksi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontMd,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Card ───────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Responsive r;
  final String label;
  final String imageUrl;

  const _CategoryCard({
    required this.r,
    required this.label,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/katalog'),
      child: SizedBox(
        width: r.categoryCardWidth,
        height: r.categoryCardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r.cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppTheme.inputBg,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.terracotta,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.terracottaLight,
                  child: const Center(
                    child: Icon(
                      Icons.category_rounded,
                      color: AppTheme.terracotta,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(r.spacingSm),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontSm,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
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
}

// ─── Product Card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Responsive r;
  final String name;
  final String category;
  final String price;
  final String? originalPrice;
  final String rating;
  final String sold;
  final String imageUrl;
  final VoidCallback onTap;

  const _ProductCard({
    required this.r,
    required this.name,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.sold,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(r.cardRadius),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppTheme.inputBg,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.terracotta,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.terracottaLight,
                        child: const Center(
                          child: Icon(
                            Icons.checkroom_rounded,
                            size: 32,
                            color: AppTheme.terracotta,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          size: r.iconSm - 2,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    if (originalPrice != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.spacingSm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'PROMO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: r.fontXs - 1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Product info
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(r.spacingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontXs,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    SizedBox(height: r.spacingXs),
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontSm + 1,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (originalPrice != null)
                      Text(
                        originalPrice!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontXs + 1,
                          color: AppTheme.textSubtle,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      price,
                      style: GoogleFonts.outfit(
                        fontSize: r.fontLg - 1,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    SizedBox(height: r.spacingXs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: r.iconSm - 4,
                                color: const Color(0xFFF59E0B),
                              ),
                              SizedBox(width: r.spacingXs),
                              Text(
                                rating,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: r.fontXs + 1,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              SizedBox(width: r.spacingXs),
                              Flexible(
                                child: Text(
                                  '|$sold terjual',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: r.fontXs,
                                    color: AppTheme.textSubtle,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart_rounded,
                            size: r.iconSm - 4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
