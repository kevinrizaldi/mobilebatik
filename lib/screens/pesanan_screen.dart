import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/profile_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/bottom_nav_bar.dart';

class PesananScreen extends StatefulWidget {
  const PesananScreen({super.key});

  @override
  State<PesananScreen> createState() => _PesananScreenState();
}

class _PesananScreenState extends State<PesananScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedStatus = 0;

  final List<_OrderData> _orders = const [
    _OrderData(
      orderNumber: 'HSO-20250218-0190',
      date: '18 Feb 2025',
      status: 'Menunggu Pembayaran',
      productName: 'Kemeja Batik Parang Seling',
      variant: 'L · Ukuran L (Slim Fit)',
      price: 871000,
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=300&q=80',
      notice: 'Sisa waktu: 05 Jam 21 menit',
      noticeDetail: 'Batas bayar 19:12 WIB',
      primaryAction: 'Bayar Sekarang',
      secondaryAction: 'Lihat Detail',
      statusIndex: 1,
      orderedAt: '18 Feb 2025 · 10:15 WIB',
      courier: 'JNE Reguler',
      trackingNumber: null,
      shippingFee: 20000,
      voucherDiscount: 20000,
    ),
    _OrderData(
      orderNumber: 'HSO-20250214-0182',
      date: '14 Feb 2025',
      status: 'Dikirim',
      productName: 'Artisan Patchwork Batik Tote Bag',
      variant: 'Edisi Terbatas (Batik Indigo)',
      price: 265000,
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=300&q=80',
      notice: 'Paket dalam perjalanan via JNE Reguler',
      noticeDetail: 'Resi: JNE-8820193921',
      primaryAction: 'Lacak Pengiriman',
      secondaryAction: 'Lihat Detail',
      statusIndex: 3,
      orderedAt: '14 Feb 2025 · 10:15 WIB',
      courier: 'JNE Reguler',
      trackingNumber: 'JNE-8820193921',
      shippingFee: 20000,
      voucherDiscount: 20000,
    ),
    _OrderData(
      orderNumber: 'HSO-20250129-0164',
      date: '29 Jan 2025',
      status: 'Selesai',
      productName: 'Kain Batik Tulis Motif Truntum',
      variant: 'Panjang 2.5 m · 1.15 m',
      price: 650000,
      quantity: 1,
      imageUrl:
          'https://images.unsplash.com/photo-1605806616949-1e87b487cb2a?w=300&q=80',
      notice: 'Diterima oleh Hamzah pada 30 Jan 2025',
      noticeDetail: '',
      primaryAction: 'Beri Ulasan',
      secondaryAction: 'Beli Lagi',
      statusIndex: 4,
      orderedAt: '29 Jan 2025 · 09:20 WIB',
      courier: 'JNE Reguler',
      trackingNumber: 'JNE-2901250164',
      shippingFee: 20000,
      voucherDiscount: 20000,
    ),
  ];

  static const List<String> _statuses = [
    'Semua',
    'Menunggu Pembayaran',
    'Diproses',
    'Dikirim',
    'Selesai',
  ];

  List<_OrderData> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _orders.where((order) {
      final matchesStatus =
          _selectedStatus == 0 || order.statusIndex == _selectedStatus;
      final matchesQuery =
          query.isEmpty ||
          order.orderNumber.toLowerCase().contains(query) ||
          order.productName.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  int _countForStatus(int statusIndex) {
    if (statusIndex == 0) return _orders.length;
    return _orders.where((order) => order.statusIndex == statusIndex).length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final orders = _filteredOrders;

    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
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
                  'HAMZAH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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
              'Pesanan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontMd,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(width: 9),
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
      body: Column(
        children: [
          Container(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: EdgeInsets.fromLTRB(r.pagePaddingH, 10, r.pagePaddingH, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.plusJakartaSans(
                fontSize: r.fontSm,
                color: AppTheme.textMain,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nomor pesanan atau nama produk...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: r.fontSm,
                  color: AppTheme.textSubtle,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: r.iconSm,
                  color: AppTheme.textSubtle,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                filled: true,
                fillColor: AppTheme.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppTheme.terracotta),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: r.pagePaddingH),
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final isActive = index == _selectedStatus;
                final count = _countForStatus(index);
                return ChoiceChip(
                  selected: isActive,
                  onSelected: (_) => setState(() => _selectedStatus = index),
                  label: Text('${_statuses[index]} ($count)'),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.white : AppTheme.textMuted,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  backgroundColor: AppTheme.inputBg,
                  selectedColor: AppTheme.primaryDark,
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyState(r)
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      r.pagePaddingH,
                      8,
                      r.pagePaddingH,
                      16,
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => AnimatedBuilder(
                      animation: ProfileStore.instance,
                      builder: (context, _) =>
                          _buildOrderCard(context, r, orders[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Responsive r, _OrderData order) {
    final reviewSubmitted = ProfileStore.instance.reviewedOrderIds.contains(
      order.orderNumber,
    );
    final primaryAction = reviewSubmitted
        ? 'Ulasan Terkirim'
        : order.primaryAction;
    final statusColor = switch (order.statusIndex) {
      1 => AppTheme.terracotta,
      3 => AppTheme.successGreen,
      _ => AppTheme.textMuted,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 5, color: AppTheme.textSubtle),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  order.statusIndex == 3
                      ? '#${order.orderNumber}  •  ${order.date}'
                      : order.date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppTheme.textSubtle,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.statusIndex == 1
                      ? AppTheme.terracottaLight
                      : AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.network(
                  order.imageUrl,
                  width: 58,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 58,
                    height: 64,
                    color: AppTheme.terracottaLight,
                    child: const Icon(
                      Icons.checkroom_rounded,
                      color: AppTheme.terracotta,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: r.fontSm,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.quantity}x · ${order.variant}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Total: ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.textSubtle,
                          ),
                        ),
                        Text(
                          _formatPrice(order.price),
                          style: GoogleFonts.outfit(
                            fontSize: r.fontMd,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  order.statusIndex == 1
                      ? Icons.timer_outlined
                      : order.statusIndex == 3
                      ? Icons.local_shipping_outlined
                      : Icons.check_rounded,
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    order.notice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                if (order.noticeDetail.isNotEmpty)
                  Flexible(
                    child: Text(
                      order.noticeDetail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  order.secondaryAction,
                  order: order,
                  outlined: true,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _actionButton(
                  context,
                  primaryAction,
                  order: order,
                  outlined: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    String label, {
    _OrderData? order,
    required bool outlined,
  }) {
    final isReviewAction = label == 'Beri Ulasan';
    final isDetailAction = label == 'Lihat Detail';
    final isTrackingAction = label == 'Lacak Pengiriman';
    final isCompletedReview = label == 'Ulasan Terkirim';
    final icon = switch (label) {
      'Bayar Sekarang' => Icons.arrow_forward_rounded,
      'Lacak Pengiriman' => Icons.local_shipping_outlined,
      'Beri Ulasan' => Icons.rate_review_outlined,
      'Ulasan Terkirim' => Icons.check_circle_outline_rounded,
      'Lihat Detail' => Icons.receipt_long_outlined,
      'Beli Lagi' => Icons.refresh_rounded,
      _ => Icons.receipt_long_outlined,
    };

    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: isCompletedReview
            ? null
            : isReviewAction && order != null
            ? () => context.push(
                '/beri-ulasan',
                extra: {
                  'orderNumber': order.orderNumber,
                  'productName': order.productName,
                  'variant': order.variant,
                  'price': order.price,
                  'quantity': order.quantity,
                  'imageUrl': order.imageUrl,
                  'status': order.status,
                  'orderedAt': order.orderedAt,
                  'courier': order.courier,
                  'trackingNumber': order.trackingNumber,
                  'isPaid': order.statusIndex > 1,
                  'shippingFee': order.shippingFee,
                  'voucherDiscount': order.voucherDiscount,
                },
              )
            : isDetailAction && order != null
            ? () => context.push(
                '/detail-pesanan',
                extra: {
                  'orderNumber': order.orderNumber,
                  'productName': order.productName,
                  'variant': order.variant,
                  'price': order.price,
                  'quantity': order.quantity,
                  'imageUrl': order.imageUrl,
                  'status': order.status,
                  'orderedAt': order.orderedAt,
                  'courier': order.courier,
                  'trackingNumber': order.trackingNumber,
                  'isPaid': order.statusIndex > 1,
                  'shippingFee': order.shippingFee,
                  'voucherDiscount': order.voucherDiscount,
                },
              )
            : isTrackingAction && order != null
            ? () => context.push(
                '/lacak-pesanan',
                extra: {
                  'orderNumber': order.orderNumber,
                  'productName': order.productName,
                  'variant': order.variant,
                  'price': order.price,
                  'quantity': order.quantity,
                  'imageUrl': order.imageUrl,
                  'status': order.status,
                  'orderedAt': order.orderedAt,
                  'courier': order.courier,
                  'trackingNumber': order.trackingNumber,
                  'isPaid': order.statusIndex > 1,
                  'shippingFee': order.shippingFee,
                  'voucherDiscount': order.voucherDiscount,
                },
              )
            : () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        '$label akan tersedia berikutnya.',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white),
                      ),
                      backgroundColor: AppTheme.primaryDark,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              },
        icon: Icon(icon, size: 13),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isCompletedReview
              ? AppTheme.successGreen
              : outlined
              ? AppTheme.textMain
              : Colors.white,
          backgroundColor: isCompletedReview
              ? AppTheme.terracottaLight
              : outlined
              ? AppTheme.terracottaLight
              : AppTheme.primaryBlack,
          side: BorderSide(
            color: isCompletedReview
                ? AppTheme.terracottaLight
                : outlined
                ? AppTheme.terracottaLight
                : AppTheme.primaryBlack,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildEmptyState(Responsive r) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 46,
            color: AppTheme.borderLight,
          ),
          const SizedBox(height: 10),
          Text(
            'Pesanan tidak ditemukan',
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

  String _formatPrice(int price) {
    final digits = price.toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'(?=(?:\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $grouped';
  }
}

class _OrderData {
  final String orderNumber;
  final String date;
  final String status;
  final String productName;
  final String variant;
  final int price;
  final int quantity;
  final String imageUrl;
  final String notice;
  final String noticeDetail;
  final String primaryAction;
  final String secondaryAction;
  final int statusIndex;
  final String orderedAt;
  final String courier;
  final String? trackingNumber;
  final int shippingFee;
  final int voucherDiscount;

  const _OrderData({
    required this.orderNumber,
    required this.date,
    required this.status,
    required this.productName,
    required this.variant,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.notice,
    required this.noticeDetail,
    required this.primaryAction,
    required this.secondaryAction,
    required this.statusIndex,
    required this.orderedAt,
    required this.courier,
    required this.trackingNumber,
    required this.shippingFee,
    required this.voucherDiscount,
  });
}
