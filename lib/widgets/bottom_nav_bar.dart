import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/cart_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/home'),
    _NavItem(icon: Icons.grid_view_rounded, label: 'Produk', route: '/katalog'),
    _NavItem(
      icon: Icons.shopping_bag_outlined,
      label: 'Keranjang',
      route: '/keranjang',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      label: 'Pesanan',
      route: '/pesanan',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      label: 'Profil',
      route: '/profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final navHeight = r.isLandscape ? 52.0 : (r.isTablet ? 72.0 : 64.0);
    final iconSize = r.isTablet ? 22.0 : 20.0;
    final labelSize = r.isTablet ? 11.0 : 10.0;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgWarm.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: navHeight,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = index == currentIndex;
              final isCart = index == 2;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isActive) context.go(item.route);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item.icon,
                            size: isCart ? iconSize + 2 : iconSize,
                            color: isActive
                                ? AppTheme.primaryBlack
                                : AppTheme.textSubtle,
                          ),
                          if (isCart)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: AnimatedBuilder(
                                animation: CartStore.instance,
                                builder: (context, _) {
                                  final count = CartStore.instance.itemCount;
                                  if (count == 0)
                                    return const SizedBox.shrink();
                                  return Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF401100),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 99 ? '99+' : '$count',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: labelSize,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.08 * labelSize,
                          color: isActive
                              ? AppTheme.primaryBlack
                              : AppTheme.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
