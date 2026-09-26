import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/cart_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/bottom_nav_bar.dart';

class KeranjangScreen extends StatelessWidget {
  const KeranjangScreen({super.key});

  String _formatPrice(int price) {
    final digits = price.toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'(?=(?:\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $grouped';
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final store = CartStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgWarm,
          appBar: AppBar(
            backgroundColor: AppTheme.bgWarm,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: r.pagePaddingH,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'HS',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hamzah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'OFFICIAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSubtle,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Keranjang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.fontMd,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryBlack,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: r.iconSm,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCheckoutSummary(context, r, store),
              const BottomNavBar(currentIndex: 2),
            ],
          ),
          body: Column(
            children: [
              Container(height: 1, color: AppTheme.borderLight),
              if (store.items.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.pagePaddingH,
                    8,
                    r.pagePaddingH,
                    4,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: store.allSelected,
                        onChanged: (value) => store.toggleAll(value ?? false),
                        activeColor: AppTheme.primaryBlack,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text(
                        'Pilih Semua (${store.itemCount} item)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontSm,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: store.selectedItemCount == 0
                            ? null
                            : store.removeSelected,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: r.iconSm,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hapus',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: r.fontSm,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: store.items.isEmpty
                    ? _buildEmptyCart(r)
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          r.pagePaddingH,
                          4,
                          r.pagePaddingH,
                          20,
                        ),
                        itemCount: store.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _buildCartItem(r, store.items[index], store),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItem(Responsive r, CartItem item, CartStore store) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.isSelected,
            onChanged: (_) => store.toggleItem(item.id),
            activeColor: AppTheme.primaryBlack,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.network(
              item.imageUrl,
              width: r.isTablet ? 92 : 76,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: r.isTablet ? 92 : 76,
                height: 88,
                color: AppTheme.terracottaLight,
                child: const Icon(
                  Icons.checkroom_rounded,
                  color: AppTheme.terracotta,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: r.fontSm + 1,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 26,
                      child: IconButton(
                        tooltip: 'Hapus item',
                        padding: EdgeInsets.zero,
                        onPressed: () => store.removeItem(item.id),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: r.iconSm - 2,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  item.variant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.fontXs + 1,
                    color: AppTheme.textSubtle,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatPrice(item.unitPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: r.fontMd,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                    _buildQuantityControl(item, store),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item, CartStore store) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(
            icon: Icons.remove_rounded,
            label: 'Kurangi jumlah',
            onPressed: () => store.changeQuantity(item.id, -1),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
              ),
            ),
          ),
          _quantityButton(
            icon: Icons.add_rounded,
            label: 'Tambah jumlah',
            onPressed: () => store.changeQuantity(item.id, 1),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 28,
      height: 30,
      child: IconButton(
        tooltip: label,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 15, color: AppTheme.textMain),
      ),
    );
  }

  Widget _buildCheckoutSummary(
    BuildContext context,
    Responsive r,
    CartStore store,
  ) {
    final canCheckout = store.selectedItemCount > 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.pagePaddingH, 12, r.pagePaddingH, 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'TOTAL PEMBAYARAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontXs,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSubtle,
                ),
              ),
              const Spacer(),
              Text(
                _formatPrice(store.selectedSubtotal),
                style: GoogleFonts.outfit(
                  fontSize: r.fontLg,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: canCheckout
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Melanjutkan ${store.selectedItemCount} item ke checkout',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: AppTheme.primaryDark,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : null,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                'Lanjut ke Checkout (${store.selectedItemCount})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontSm,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.borderLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(Responsive r) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: AppTheme.borderLight,
          ),
          const SizedBox(height: 12),
          Text(
            'Keranjang masih kosong',
            style: GoogleFonts.plusJakartaSans(
              fontSize: r.fontMd,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
