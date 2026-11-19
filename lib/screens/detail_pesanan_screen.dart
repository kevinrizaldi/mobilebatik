import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/profile_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class DetailPesananScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const DetailPesananScreen({super.key, required this.order});

  String get _productName => order['productName'] as String? ?? 'Produk Batik';
  String get _variant => order['variant'] as String? ?? 'Varian standar';
  String get _imageUrl => order['imageUrl'] as String? ?? '';
  int get _quantity => (order['quantity'] as num?)?.toInt() ?? 1;
  int get _unitPrice => (order['price'] as num?)?.toInt() ?? 0;
  int get _shippingFee => (order['shippingFee'] as num?)?.toInt() ?? 0;
  int get _voucherDiscount => (order['voucherDiscount'] as num?)?.toInt() ?? 0;
  String get _orderNumber => order['orderNumber'] as String? ?? '-';
  String get _orderedAt => order['orderedAt'] as String? ?? '-';
  String get _status => order['status'] as String? ?? 'Diproses';
  String get _courier =>
      order['courier'] as String? ?? 'Kurir belum ditentukan';
  String? get _trackingNumber => order['trackingNumber'] as String?;
  bool get _isPaid => order['isPaid'] as bool? ?? false;
  int get _productSubtotal => _unitPrice * _quantity;
  int get _total => _productSubtotal + _shippingFee - _voucherDiscount;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        backgroundColor: AppTheme.bgWarm,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 19),
        ),
        title: Text(
          'Detail Pesanan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryBlack,
              child: Icon(
                Icons.person_outline_rounded,
                size: r.iconSm - 1,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(height: 1, color: AppTheme.borderLight),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                r.pagePaddingH,
                12,
                r.pagePaddingH,
                16,
              ),
              children: [
                _buildOrderSummary(),
                const SizedBox(height: 10),
                _buildCourierAndAddress(context),
                const SizedBox(height: 10),
                _buildProductSection(context, r),
                const SizedBox(height: 12),
                _buildCostSummary(),
              ],
            ),
          ),
          _buildActions(context, r),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final statusColor = _isPaid ? AppTheme.successGreen : AppTheme.terracotta;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'No. Pesanan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppTheme.textSubtle,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: _isPaid ? AppTheme.terracottaLight : AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  _status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            _orderNumber,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Waktu pemesanan: $_orderedAt',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppTheme.textSubtle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierAndAddress(BuildContext context) {
    final address = ProfileStore.instance.addresses
        .cast<ProfileAddress?>()
        .firstWhere(
          (item) => item?.isPrimary == true,
          orElse: () => ProfileStore.instance.addresses.isEmpty
              ? null
              : ProfileStore.instance.addresses.first,
        );
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 17,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kurir Pengiriman',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _courier,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isPaid && _trackingNumber != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'No. Resi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    Text(
                      _trackingNumber!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alamat Pengiriman',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address?.recipient ?? ProfileStore.instance.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      address == null
                          ? 'Alamat belum tersedia'
                          : '${address.address}\n${address.phone}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        height: 1.4,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isPaid && _trackingNumber != null) ...[
          const SizedBox(height: 7),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/lacak-pesanan', extra: order),
              icon: const Icon(Icons.route_outlined, size: 15),
              label: Text(
                'Lacak Pengiriman',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryDark,
                backgroundColor: AppTheme.terracottaLight,
                side: const BorderSide(color: AppTheme.terracottaLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductSection(BuildContext context, Responsive r) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Rincian Produk ($_quantity)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: r.fontMd,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
              Text(
                'Batik tulis pilihan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _imageUrl.isEmpty
                    ? _productFallback()
                    : Image.network(
                        _imageUrl,
                        width: 76,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _productFallback(),
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _variant,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatPrice(_unitPrice),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                        Text(
                          'x $_quantity',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productFallback() => Container(
    width: 76,
    height: 84,
    color: AppTheme.terracottaLight,
    child: const Icon(
      Icons.checkroom_outlined,
      color: AppTheme.terracotta,
      size: 27,
    ),
  );

  Widget _buildCostSummary() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ringkasan Biaya',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'RINCIAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _costRow('Subtotal Produk', _formatPrice(_productSubtotal)),
          const SizedBox(height: 7),
          _costRow('Biaya Pengiriman', _formatPrice(_shippingFee)),
          const SizedBox(height: 7),
          _costRow(
            'Voucher Diskon',
            _voucherDiscount == 0
                ? _formatPrice(0)
                : '-${_formatPrice(_voucherDiscount)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PEMBAYARAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              Text(
                _formatPrice(_total),
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMain,
        ),
      ),
    ],
  );

  Widget _buildActions(BuildContext context, Responsive r) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        r.pagePaddingH,
        10,
        r.pagePaddingH,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgWarm,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _showActionNotice(context, 'WhatsApp Penjual'),
              icon: const Icon(Icons.chat_outlined, size: 16),
              label: Text(
                'Hubungi Penjual via WhatsApp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showActionNotice(context, 'Bantuan Pesanan & Pengembalian'),
              icon: const Icon(Icons.support_agent_outlined, size: 15),
              label: Text(
                'Bantuan Pesanan & Pengembalian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textMain,
                backgroundColor: AppTheme.terracottaLight,
                side: const BorderSide(color: AppTheme.terracottaLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionNotice(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$action akan tersedia berikutnya.'),
          behavior: SnackBarBehavior.floating,
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
