import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/cart_store.dart';
import '../data/profile_store.dart';
import '../services/api_client.dart';
import '../services/api_config.dart';
import '../services/order_service.dart';
import '../services/shipping_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? checkoutData;

  const CheckoutScreen({super.key, this.checkoutData});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _notesController = TextEditingController();

  int _selectedCourierIndex = 0;
  int _selectedPaymentIndex = 0;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'manual_bca',
      'title': 'Transfer Bank Manual',
      'badge': 'BCA Menunggu',
      'subtitle': 'BCA Rekening Resmi',
      'description':
          'Transfer langsung ke rekening bank kami. Verifikasi manual dilakukan oleh tim kami setelah unggah bukti transfer.',
      'icon': Icons.account_balance_outlined,
      'isManual': true,
    },
    {
      'id': 'va_otomatis',
      'title': 'Virtual Account Otomatis',
      'badge': 'Otomatis',
      'subtitle': 'BCA, Mandiri, BRI, BNI',
      'description':
          'Verifikasi otomatis 24 jam tanpa perlu unggah bukti transfer secara manual.',
      'icon': Icons.account_balance_wallet_outlined,
      'isManual': false,
    },
    {
      'id': 'qris_instant',
      'title': 'QRIS Instant',
      'badge': 'Realtime',
      'subtitle': 'GoPay, OVO, DANA, ShopeePay',
      'description':
          'Pindai kode QRIS menggunakan aplikasi e-wallet atau mobile banking apa saja.',
      'icon': Icons.qr_code_2_rounded,
      'isManual': false,
    },
    {
      'id': 'cc_debit',
      'title': 'Kartu Kredit / Debit Online',
      'badge': 'Instan',
      'subtitle': 'Visa, Mastercard, JCB',
      'description':
          'Pembayaran aman dengan enkripsi 3D Secure dan verifikasi OTP bank.',
      'icon': Icons.credit_card_rounded,
      'isManual': false,
    },
  ];

  late List<Map<String, dynamic>> _checkoutItems;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _liveServices = [];
  bool _loadingServices = false;
  String? _servicesError;

  @override
  void initState() {
    super.initState();
    _initItems();
    ProfileStore.instance.addListener(_onProfileChanged);
    ProfileStore.instance.syncAddressesFromServer();
    _fetchShippingCosts();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    setState(() {});
    _fetchShippingCosts();
  }

  Future<void> _fetchShippingCosts() async {
    final numericId = int.tryParse(_currentAddress.id);
    if (numericId == null || !mounted) return;

    setState(() => _loadingServices = true);
    try {
      final totalQty = _checkoutItems.fold<int>(
        0,
        (sum, item) => sum + ((item['quantity'] as int?) ?? 1),
      );
      final weight = totalQty * 300 < 1000 ? 1000 : totalQty * 300;
      final services = await ShippingService.instance.fetchCosts(
        addressId: numericId,
        weightGrams: weight,
      );
      if (!mounted) return;
      setState(() {
        _liveServices = services;
        _servicesError = services.isEmpty
            ? 'Biaya ongkir tidak tersedia'
            : null;
        if (_selectedCourierIndex >= services.length) {
          _selectedCourierIndex = 0;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liveServices = [];
        _servicesError = 'Biaya ongkir tidak tersedia';
      });
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  @override
  void dispose() {
    ProfileStore.instance.removeListener(_onProfileChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _initItems() {
    final directItem = widget.checkoutData?['directItem'];
    if (directItem is Map<String, dynamic>) {
      _checkoutItems = [directItem];
      return;
    }

    final storeSelected = CartStore.instance.items
        .where((item) => item.isSelected)
        .toList();

    _checkoutItems = storeSelected
        .map(
          (item) => {
            'id': item.id,
            'cartItemId': item.cartItemId,
            'productId': item.productId,
            'name': item.name,
            'variant': item.variant,
            'imageUrl': item.imageUrl,
            'unitPrice': item.unitPrice,
            'quantity': item.quantity,
          },
        )
        .toList();
  }

  bool get _hasItems => _checkoutItems.isNotEmpty;

  ProfileAddress
  get _currentAddress => ProfileStore.instance.addresses.firstWhere(
    (a) => a.isPrimary,
    orElse: () => ProfileStore.instance.addresses.isNotEmpty
        ? ProfileStore.instance.addresses.first
        : ProfileAddress(
            id: 'default',
            label: 'Utama',
            recipient: ProfileStore.instance.name,
            phone: ProfileStore.instance.phone,
            address:
                'Jl. Malioboro No. 56, Sosromenduran, Gedong Tengen, Kota Yogyakarta, D.I. Yogyakarta 55271',
            isPrimary: true,
          ),
  );

  int get _itemsSubtotal => _checkoutItems.fold(
    0,
    (sum, item) =>
        sum + ((item['unitPrice'] as int) * ((item['quantity'] as int?) ?? 1)),
  );

  int get _totalItemCount => _checkoutItems.fold(
    0,
    (sum, item) => sum + ((item['quantity'] as int?) ?? 1),
  );

  List<Map<String, dynamic>> get _displayCouriers => _liveServices;

  Map<String, dynamic> get _selectedCourier {
    if (_displayCouriers.isEmpty) return const {};
    final index = _selectedCourierIndex.clamp(0, _displayCouriers.length - 1);
    return _displayCouriers[index];
  }

  int get _shippingFee => (_selectedCourier['fee'] as int?) ?? 0;

  int get _totalPayment => (_itemsSubtotal + _shippingFee).clamp(0, 999999999);

  String _formatPrice(int price) => ApiConfig.formatRupiah(price);

  Future<void> _proceedToPayment() async {
    if (_isSubmitting) return;

    if (!_hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Keranjang kosong. Tambahkan produk terlebih dahulu.',
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final selectedCourier = _selectedCourier;
    final selectedPayment = _paymentMethods[_selectedPaymentIndex];
    final primaryAddress = _currentAddress;

    final token = await ApiClient.instance.getToken();
    final cartItemIds = _checkoutItems
        .map((e) => e['cartItemId'])
        .whereType<int>()
        .toList();
    final directItems = _checkoutItems
        .where((e) => e['cartItemId'] == null && e['productId'] != null)
        .map(
          (e) => {
            'product_id': e['productId'],
            if (e['size'] != null) 'size': e['size'],
            'quantity': e['quantity'] ?? 1,
          },
        )
        .toList();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Silakan login terlebih dahulu untuk melanjutkan checkout.',
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

    if (_displayCouriers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Biaya ongkir belum tersedia. Periksa koneksi internet lalu coba lagi.',
          ),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await OrderService.instance.checkout(
        customerName: primaryAddress.recipient,
        phone: primaryAddress.phone,
        address: primaryAddress.address,
        shippingOption: selectedCourier['name'].toString(),
        shippingCost: (_shippingFee).toDouble(),
        paymentMethod: selectedPayment['title'].toString(),
        notes: _notesController.text.trim(),
        cartItemIds: cartItemIds.isNotEmpty ? cartItemIds : null,
        directItems: directItems.isNotEmpty ? directItems : null,
      );

      if (cartItemIds.isNotEmpty) {
        await CartStore.instance.syncFromServer();
      }
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final data = (res['data'] as Map<String, dynamic>?) ?? {};
      final order =
          (data['order'] as Map<String, dynamic>?) ??
          (data['id'] != null ? data : <String, dynamic>{});
      final totals = (res['totals'] as Map<String, dynamic>?) ?? {};
      final serverTotal = (totals['grand_total'] is num)
          ? (totals['grand_total'] as num).round()
          : _totalPayment;
      final serverShipping = (totals['shipping'] is num)
          ? (totals['shipping'] as num).round()
          : _shippingFee;
      final serverDiscount = (totals['discount'] is num)
          ? (totals['discount'] as num).round()
          : 0;
      final snapRedirectUrl = data['snap_redirect_url']?.toString();
      final snapToken = data['snap_token']?.toString();

      final orderSummary = {
        'orderId': order['id'],
        'orderNumber': order['code']?.toString() ?? 'ORD-BARU',
        'totalPayment': serverTotal,
        'paymentDeadline': order['payment_deadline']?.toString(),
        'snapRedirectUrl': (snapRedirectUrl == null || snapRedirectUrl.isEmpty)
            ? null
            : snapRedirectUrl,
        'snapToken': (snapToken == null || snapToken.isEmpty)
            ? null
            : snapToken,
        'items': _checkoutItems,
        'totalItems': _totalItemCount,
        'productSubtotal': _itemsSubtotal,
        'shippingFee': serverShipping,
        'discount': serverDiscount,
        'uniqueCode': 0,
        'courier': selectedCourier,
        'paymentMethod': selectedPayment,
        'address': {
          'recipient': primaryAddress.recipient,
          'phone': primaryAddress.phone,
          'address': primaryAddress.address,
          'label': primaryAddress.label,
        },
        'notes': _notesController.text.trim(),
        'orderedAt': order['created_at']?.toString() ?? 'Baru saja',
      };

      if (!mounted) return;
      context.push('/pembayaran', extra: orderSummary);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    }
  }

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
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => context.go('/keranjang'),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyBottomActionBar(context, r),
      body: Column(
        children: [
          Container(height: 1, color: AppTheme.borderLight),
          _buildStepperHeader(r),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                r.pagePaddingH,
                12,
                r.pagePaddingH,
                24,
              ),
              children: [
                _buildAddressSection(r),
                const SizedBox(height: 14),
                _buildProductListSection(r),
                const SizedBox(height: 14),
                _buildShippingOptionsSection(r),
                const SizedBox(height: 14),
                _buildPaymentMethodSection(r),
                const SizedBox(height: 14),
                _buildOrderNotesSection(r),
                const SizedBox(height: 14),
                _buildPaymentSummarySection(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- STEPPER HEADER ---
  Widget _buildStepperHeader(Responsive r) {
    return Container(
      width: double.infinity,
      color: AppTheme.bgWarm,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepItem(
            step: '1',
            label: 'Keranjang',
            isCompleted: true,
            isActive: false,
          ),
          _stepDivider(isPassed: true),
          _stepItem(
            step: '2',
            label: 'Pengiriman & Bayar',
            isCompleted: false,
            isActive: true,
          ),
          _stepDivider(isPassed: false),
          _stepItem(
            step: '3',
            label: 'Selesai',
            isCompleted: false,
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _stepItem({
    required String step,
    required String label,
    required bool isCompleted,
    required bool isActive,
  }) {
    final bgColor = isCompleted
        ? AppTheme.terracottaLight
        : isActive
        ? AppTheme.primaryDark
        : AppTheme.inputBg;
    final textColor = isCompleted
        ? AppTheme.terracotta
        : isActive
        ? Colors.white
        : AppTheme.textSubtle;
    final labelColor = isActive ? AppTheme.textMain : AppTheme.textSubtle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? AppTheme.primaryDark
                  : isCompleted
                  ? AppTheme.terracotta
                  : AppTheme.borderLight,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppTheme.terracotta,
                )
              : Text(
                  step,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _stepDivider({required bool isPassed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 14,
        color: isPassed ? AppTheme.terracotta : AppTheme.borderLight,
      ),
    );
  }

  // --- 1. ALAMAT PENGIRIMAN ---
  Widget _buildAddressSection(Responsive r) {
    final address = _currentAddress;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: AppTheme.terracotta,
              ),
              const SizedBox(width: 6),
              Text(
                'Alamat Pengiriman',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showChangeAddressBottomSheet(context, r),
                child: Text(
                  'Ubah Alamat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.recipient,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.terracottaLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            address.label.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.terracotta,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address.phone,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address.address,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textSubtle,
                        height: 1.35,
                      ),
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

  void _showChangeAddressBottomSheet(BuildContext context, Responsive r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final addresses = ProfileStore.instance.addresses;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pilih Alamat Pengiriman',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.borderLight),
                    ...addresses.map(
                      (addr) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: GestureDetector(
                          onTap: () {
                            ProfileStore.instance.setPrimaryAddress(addr.id);
                            setSheetState(() {});
                            setState(() {});
                            Navigator.of(context).pop();
                          },
                          child: _RadioDot(
                            selected:
                                addr.id ==
                                addresses
                                    .firstWhere(
                                      (a) => a.isPrimary,
                                      orElse: () => addresses.first,
                                    )
                                    .id,
                            activeColor: AppTheme.primaryDark,
                          ),
                        ),
                        title: Text(
                          '${addr.recipient} (${addr.label})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          addr.address,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.textSubtle,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.add_location_alt_outlined,
                          size: 16,
                        ),
                        label: Text(
                          'Kelola Daftar Alamat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push('/profil/daftar-alamat');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. PRODUK PILIHAN ---
  Widget _buildProductListSection(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 17,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Produk Pilihan ($_totalItemCount)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_hasItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tidak ada produk untuk dibayar. Tambahkan produk ke '
                'keranjang terlebih dahulu.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _checkoutItems.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: AppTheme.borderLight),
                    ),
                  Builder(
                    builder: (context) {
                      final item = _checkoutItems[i];
                      final name = item['name'] as String;
                      final variant = item['variant'] as String;
                      final imageUrl = item['imageUrl'] as String;
                      final unitPrice = item['unitPrice'] as int;
                      final quantity = (item['quantity'] as int?) ?? 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              imageUrl,
                              width: 54,
                              height: 58,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 54,
                                height: 58,
                                color: AppTheme.terracottaLight,
                                child: const Icon(
                                  Icons.checkroom_rounded,
                                  color: AppTheme.terracotta,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMain,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  variant,
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
                                      _formatPrice(unitPrice),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'x $quantity',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // --- 3. OPSI PENGIRIMAN ---
  Widget _buildShippingOptionsSection(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 17,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Opsi Pengiriman',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              if (_loadingServices) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.6),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (_displayCouriers.isEmpty)
            _buildShippingEmptyState()
          else
            Column(
              children: [
                for (
                  int index = 0;
                  index < _displayCouriers.length;
                  index++
                ) ...[
                  if (index > 0) const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final courier = _displayCouriers[index];
                      final isSelected = index == _selectedCourierIndex;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCourierIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.inputBg
                                : AppTheme.bgWarm.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.terracotta
                                  : AppTheme.borderLight,
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              _RadioDot(
                                selected: isSelected,
                                activeColor: AppTheme.terracotta,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      courier['name'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMain,
                                      ),
                                    ),
                                    Text(
                                      courier['estimate'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        color: AppTheme.textSubtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatPrice(courier['fee'] as int),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppTheme.terracotta
                                      : AppTheme.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildShippingEmptyState() {
    if (_loadingServices) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Memuat biaya pengiriman…',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textSubtle,
            ),
          ),
        ],
      );
    }
    if (_servicesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 16,
                color: AppTheme.terracotta,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Biaya ongkir tidak tersedia',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Periksa koneksi internet, lalu coba lagi.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.textSubtle,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadingServices ? null : _fetchShippingCosts,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Coba Lagi'),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // --- 4. METODE PEMBAYARAN ---
  Widget _buildPaymentMethodSection(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 17,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Metode Pembayaran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              for (int index = 0; index < _paymentMethods.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final method = _paymentMethods[index];
                    final isSelected = index == _selectedPaymentIndex;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedPaymentIndex = index),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.inputBg
                              : AppTheme.bgWarm.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.terracotta
                                : AppTheme.borderLight,
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _RadioDot(
                                  selected: isSelected,
                                  activeColor: AppTheme.terracotta,
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  method['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? AppTheme.terracotta
                                      : AppTheme.primaryDark,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method['title'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textMain,
                                        ),
                                      ),
                                      Text(
                                        method['subtitle'] as String,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          color: AppTheme.textSubtle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.terracottaLight
                                        : AppTheme.borderLight.withValues(
                                            alpha: 0.5,
                                          ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    method['badge'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppTheme.terracotta
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected &&
                                (method['description'] as String)
                                    .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 36,
                                  right: 4,
                                ),
                                child: Text(
                                  method['description'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: AppTheme.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. CATATAN PESANAN ---
  Widget _buildOrderNotesSection(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 19,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Catatan Pesanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMain,
            ),
            decoration: InputDecoration(
              hintText:
                  'Tulis catatan khusus untuk penjual (opsional, contoh: bungkus kado, request kartu ucapan)...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.textSubtle,
              ),
              filled: true,
              fillColor: AppTheme.inputBg,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. RINGKASAN PEMBAYARAN ---
  Widget _buildPaymentSummarySection(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ringkasan Pembayaran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          const SizedBox(height: 10),
          _summaryRow(
            'Subtotal Produk ($_totalItemCount item)',
            _formatPrice(_itemsSubtotal),
          ),
          const SizedBox(height: 6),
          _summaryRow(
            'Biaya Pengiriman (${_selectedCourier['name'] ?? '—'})',
            _formatPrice(_shippingFee),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          Row(
            children: [
              Text(
                'Total Tagihan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const Spacer(),
              Text(
                _formatPrice(_totalPayment),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return Row(
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
            color: isDiscount ? AppTheme.successGreen : AppTheme.textMain,
          ),
        ),
      ],
    );
  }

  // --- STICKY BOTTOM ACTION BAR ---
  Widget _buildStickyBottomActionBar(BuildContext context, Responsive r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        r.pagePaddingH,
        10,
        r.pagePaddingH,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Pembayaran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSubtle,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _formatPrice(_totalPayment),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || !_hasItems)
                    ? null
                    : _proceedToPayment,
                iconAlignment: IconAlignment.end,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  !_hasItems
                      ? 'Keranjang Kosong'
                      : _isSubmitting
                      ? 'Memproses...'
                      : 'Bayar Sekarang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: Colors.white,
                  minimumSize: Size.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight custom radio dot — no MouseRegion, no deprecated API.
class _RadioDot extends StatelessWidget {
  final bool selected;
  final Color activeColor;
  const _RadioDot({required this.selected, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? activeColor : AppTheme.borderLight,
              width: selected ? 1.5 : 1.2,
            ),
          ),
          child: selected
              ? Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
