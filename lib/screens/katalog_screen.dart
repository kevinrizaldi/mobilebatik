import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/bottom_nav_bar.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _selectedSort = 'Terpopuler';
  final List<String> _categories = ['Semua', 'Baju Batik', 'Kain Batik', 'Olahan Kain', 'Aksesoris'];

  final List<Map<String, dynamic>> _products = [
    {'name': 'Kemeja Batik Parang Classic', 'price': 'Rp 285.000', 'originalPrice': 'Rp 350.000', 'rating': '4.8', 'sold': '124', 'imageUrl': 'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=300&q=80', 'category': 'Baju Batik'},
    {'name': 'Kain Batik Tulis Mega Mendung', 'price': 'Rp 450.000', 'rating': '4.9', 'sold': '89', 'imageUrl': 'https://images.unsplash.com/photo-1605806616949-1e87b487cb2a?w=300&q=80', 'category': 'Kain Batik'},
    {'name': 'Dress Batik Kawung Modern', 'price': 'Rp 320.000', 'originalPrice': 'Rp 390.000', 'rating': '4.7', 'sold': '67', 'imageUrl': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=300&q=80', 'category': 'Baju Batik'},
    {'name': 'Sarung Batik Lereng Premium', 'price': 'Rp 195.000', 'rating': '4.6', 'sold': '203', 'imageUrl': 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=300&q=80', 'category': 'Kain Batik'},
    {'name': 'Blouse Batik Sogan Elegan', 'price': 'Rp 265.000', 'originalPrice': 'Rp 310.000', 'rating': '4.8', 'sold': '55', 'imageUrl': 'https://images.unsplash.com/photo-1610448154563-39f80cc0faeb?w=300&q=80', 'category': 'Baju Batik'},
    {'name': 'Set Batik Couple Sido Mukti', 'price': 'Rp 575.000', 'rating': '5.0', 'sold': '38', 'imageUrl': 'https://images.unsplash.com/photo-1583391733958-d25e07fac661?w=300&q=80', 'category': 'Baju Batik'},
    {'name': 'Tas Anyaman Batik Nusantara', 'price': 'Rp 175.000', 'rating': '4.5', 'sold': '91', 'imageUrl': 'https://images.unsplash.com/photo-1610448154563-39f80cc0faeb?w=300&q=80', 'category': 'Aksesoris'},
    {'name': 'Selendang Batik Motif Truntum', 'price': 'Rp 130.000', 'rating': '4.7', 'sold': '145', 'imageUrl': 'https://images.unsplash.com/photo-1596766779493-2782e3d36015?w=300&q=80', 'category': 'Aksesoris'},
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    var list = _selectedCategory == 'Semua' ? _products : _products.where((p) => p['category'] == _selectedCategory).toList();
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => (p['name'] as String).toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    final r = Responsive.of(context);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(r.cardRadius))),
      backgroundColor: AppTheme.bgWarm,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(r.spacingLg, r.spacingMd, r.spacingLg, r.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: r.spacingMd),
            Text('Urutkan', style: GoogleFonts.outfit(fontSize: r.fontLg, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
            SizedBox(height: r.spacingSm),
            ...['Terpopuler', 'Harga Terendah', 'Harga Tertinggi', 'Terbaru'].map((sort) => ListTile(
              title: Text(sort, style: GoogleFonts.plusJakartaSans(fontSize: r.fontMd, fontWeight: _selectedSort == sort ? FontWeight.w600 : FontWeight.w400, color: _selectedSort == sort ? AppTheme.terracotta : AppTheme.textMuted)),
              trailing: _selectedSort == sort ? Icon(Icons.check_rounded, color: AppTheme.terracotta, size: r.iconSm) : null,
              onTap: () { setState(() => _selectedSort = sort); Navigator.pop(ctx); },
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
            SizedBox(height: r.spacingMd),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final pad = r.pagePaddingH;
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: AppTheme.bgWarm,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFF1C130D), borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text('HS', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: r.fontMd)),
            ),
            SizedBox(width: r.spacingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hamzah Style', style: GoogleFonts.plusJakartaSans(fontSize: r.fontMd, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
                Text('Official Store', style: GoogleFonts.plusJakartaSans(fontSize: r.fontXs, fontWeight: FontWeight.w500, color: AppTheme.textSubtle)),
              ],
            ),
          ],
        ),
        actions: [
          Center(child: Text('Produk', style: GoogleFonts.plusJakartaSans(fontSize: r.fontSm, fontWeight: FontWeight.w600, color: AppTheme.textMain))),
          SizedBox(width: r.spacingSm),
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1C130D),
            child: Icon(Icons.person_outline_rounded, color: Colors.white, size: r.iconSm),
          ),
          SizedBox(width: pad * 0.8),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 12, pad, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.inputBg,
                      borderRadius: BorderRadius.circular(r.cardRadius * 0.75),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.plusJakartaSans(fontSize: r.fontMd, color: AppTheme.textMain),
                      decoration: InputDecoration(
                        hintText: 'Cari produk batik...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: r.fontMd, color: AppTheme.textSubtle),
                        prefixIcon: Icon(Icons.search_rounded, size: r.iconSm, color: AppTheme.textSubtle),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, size: r.iconSm - 2, color: AppTheme.textSubtle),
                                onPressed: () { _searchController.clear(); setState(() {}); })
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: r.spacingMd, vertical: r.spacingSm),
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: r.spacingSm),
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(r.cardRadius * 0.75)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, color: AppTheme.textMain, size: r.iconMd),
                      Positioned(
                        right: 11, top: 11,
                        child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF401100), shape: BoxShape.circle)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category chips
          Padding(
            padding: EdgeInsets.only(top: r.spacingSm),
            child: SizedBox(
              height: r.isTablet || r.isDesktop ? 42 : 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: pad),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => SizedBox(width: r.spacingXs),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: r.spacingMd, vertical: r.spacingXs),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryDark : AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppTheme.primaryDark : AppTheme.borderLight),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontSm,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Count + sort
          Padding(
            padding: EdgeInsets.fromLTRB(pad, r.spacingSm, pad, r.spacingXs),
            child: Row(
              children: [
                Text('${filtered.length} produk',
                    style: GoogleFonts.plusJakartaSans(fontSize: r.fontSm, color: AppTheme.textSubtle)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showFilterSheet(context),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded, size: r.iconSm - 4, color: AppTheme.terracotta),
                      SizedBox(width: r.spacingXs),
                      Text(_selectedSort,
                          style: GoogleFonts.plusJakartaSans(fontSize: r.fontSm, fontWeight: FontWeight.w600, color: AppTheme.terracotta)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product grid (responsive)
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: r.isTablet ? 64 : 48, color: AppTheme.borderLight),
                        SizedBox(height: r.spacingSm),
                        Text('Produk tidak ditemukan',
                            style: GoogleFonts.plusJakartaSans(fontSize: r.fontMd, color: AppTheme.textSubtle)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: r.productGridColumns,
                      childAspectRatio: r.productGridAspectRatio,
                      crossAxisSpacing: r.spacingMd,
                      mainAxisSpacing: r.spacingMd,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return _KatalogProductCard(
                        r: r,
                        name: p['name'],
                        category: p['category'],
                        price: p['price'],
                        originalPrice: p['originalPrice'],
                        rating: p['rating'],
                        sold: p['sold'],
                        imageUrl: p['imageUrl'],
                        onTap: () => context.push('/detail-produk', extra: p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _KatalogProductCard extends StatelessWidget {
  final Responsive r;
  final String name;
  final String category;
  final String price;
  final String? originalPrice;
  final String rating;
  final String sold;
  final String imageUrl;
  final VoidCallback onTap;

  const _KatalogProductCard({
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(r.cardRadius)),
                  image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Icon(Icons.favorite_border_rounded, size: r.iconSm - 2, color: AppTheme.primaryDark),
                      ),
                    ),
                    if (originalPrice != null)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: r.spacingSm, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.errorRed, borderRadius: BorderRadius.circular(5)),
                          child: Text('PROMO', style: GoogleFonts.plusJakartaSans(fontSize: r.fontXs - 1, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(r.spacingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: GoogleFonts.plusJakartaSans(fontSize: r.fontXs, fontWeight: FontWeight.w500, color: AppTheme.textSubtle)),
                    SizedBox(height: r.spacingXs),
                    Text(name,
                        style: GoogleFonts.plusJakartaSans(fontSize: r.fontSm + 1, fontWeight: FontWeight.w600, color: AppTheme.textMain, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    if (originalPrice != null)
                      Text(originalPrice!, style: GoogleFonts.plusJakartaSans(fontSize: r.fontXs + 1, color: AppTheme.textSubtle, decoration: TextDecoration.lineThrough)),
                    Text(price, style: GoogleFonts.outfit(fontSize: r.fontLg - 1, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                    SizedBox(height: r.spacingXs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded, size: r.iconSm - 4, color: const Color(0xFFF59E0B)),
                              SizedBox(width: r.spacingXs),
                              Text(rating, style: GoogleFonts.plusJakartaSans(fontSize: r.fontXs + 1, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                              SizedBox(width: r.spacingXs),
                              Flexible(child: Text('|$sold terjual', style: GoogleFonts.plusJakartaSans(fontSize: r.fontXs, color: AppTheme.textSubtle), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: AppTheme.primaryDark, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.add_shopping_cart_rounded, size: r.iconSm - 4, color: Colors.white),
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
