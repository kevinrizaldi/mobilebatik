import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Layar pembayaran nyata: membaca status + Snap dari
/// `GET /api/orders/{id}/payment` dan membuka halaman Snap Midtrans
/// lewat `url_launcher` (browser eksternal).
///
/// Contract `state.extra` (`paymentData`):
/// - `orderId` (int, wajib) — id order untuk endpoint payment
/// - `orderNumber` (String) — kode order untuk ditampilkan
/// - `totalPayment` (num) — total tagihan untuk ditampilkan
/// - `items` (List) — opsional, ringkasan item untuk ditampilkan
/// - `productName` (String) — opsional, alternatif ringkasan item
/// - `paymentDeadline` (String ISO8601) — opsional, untuk hitung mundur
/// - `snapRedirectUrl` (String) — opsional, URL Snap awal dari checkout
///
/// Strategi refresh status: tombol "Periksa Status" + refetch saat app
/// kembali ke foreground (`didChangeAppLifecycleState`). Tanpa polling
/// timer — endpoint payment sudah melakukan sync status dari Midtrans
/// pada setiap pemanggilan.
class PembayaranScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentData;

  const PembayaranScreen({super.key, this.paymentData});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  String? _error;
  String _paymentStatus = 'pending';
  String? _snapRedirectUrl;
  bool _isLaunching = false;

  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _snapRedirectUrl = _extraString('snapRedirectUrl');
    _seedDeadline();
    _fetchPayment();
    _startCountdown();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kembali dari browser Snap → refetch status pembayaran.
    if (state == AppLifecycleState.resumed && mounted && !_loading) {
      _fetchPayment();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  int? get _orderId {
    final raw = widget.paymentData?['orderId'];
    if (raw is int) return raw;
    return int.tryParse('${raw ?? ''}');
  }

  String get _orderNumber =>
      widget.paymentData?['orderNumber']?.toString() ?? 'Pesanan';

  int get _totalAmount {
    final raw = widget.paymentData?['totalPayment'];
    if (raw is num) return raw.round();
    return 0;
  }

  List<Map<String, dynamic>> get _items {
    final raw = widget.paymentData?['items'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  String get _summaryProductName {
    final items = _items;
    if (items.isNotEmpty) {
      final name = items.first['name']?.toString() ?? '';
      if (name.isNotEmpty) {
        return items.length > 1 ? '$name +${items.length - 1} lainnya' : name;
      }
    }
    final direct = widget.paymentData?['productName']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    return 'Pesanan Batik';
  }

  String? _extraString(String key) {
    final raw = widget.paymentData?[key]?.toString();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  void _seedDeadline() {
    final raw = _extraString('paymentDeadline');
    if (raw == null) return;
    final deadline = DateTime.tryParse(raw);
    if (deadline == null) return;
    final remaining = deadline.difference(DateTime.now()).inSeconds;
    if (remaining > 0) _secondsRemaining = remaining;
  }

  void _startCountdown() {
    if (_secondsRemaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _fetchPayment() async {
    final orderId = _orderId;
    if (orderId == null) {
      setState(() {
        _loading = false;
        _error = 'Data pesanan tidak lengkap untuk memuat pembayaran.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.instance.get('/orders/$orderId/payment');
      final data = (res['data'] as Map<String, dynamic>?) ?? {};
      if (!mounted) return;
      setState(() {
        _paymentStatus = (data['payment_status']?.toString() ?? 'pending')
            .toLowerCase();
        final url = data['snap_redirect_url']?.toString() ?? '';
        _snapRedirectUrl = url.isEmpty ? null : url;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat status pembayaran. Periksa koneksi Anda.';
      });
    }
  }

  Future<void> _openSnapPayment() async {
    final url = _snapRedirectUrl ?? _extraString('snapRedirectUrl');
    if (url == null || _isLaunching) return;

    setState(() => _isLaunching = true);
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!launched) {
        _showSnackBar(
          'Tidak dapat membuka halaman pembayaran.',
          color: AppTheme.errorRed,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('URL pembayaran tidak valid.', color: AppTheme.errorRed);
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: color ?? AppTheme.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('$label berhasil disalin ke clipboard!');
  }

  String _formatPrice(int price) {
    final digits = price.toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'(?=(?:\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp $grouped';
  }

  String get _hoursStr =>
      (_secondsRemaining ~/ 3600).toString().padLeft(2, '0');
  String get _minutesStr =>
      ((_secondsRemaining % 3600) ~/ 60).toString().padLeft(2, '0');
  String get _secondsStr => (_secondsRemaining % 60).toString().padLeft(2, '0');

  bool get _isPaid =>
      _paymentStatus == 'paid' || _paymentStatus == 'settlement';

  String get _statusLabel => switch (_paymentStatus) {
    'paid' => 'Lunas',
    'failed' => 'Gagal',
    'expired' => 'Kedaluwarsa',
    'cancelled' => 'Dibatalkan',
    _ => 'Menunggu Pembayaran',
  };

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
          'Pembayaran',
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
            onPressed: () => context.go('/pesanan'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(height: 1, color: AppTheme.borderLight),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.terracotta,
                    ),
                  )
                : _error != null
                ? _buildErrorState(r)
                : _isPaid
                ? _buildSuccessState(r)
                : _buildPendingState(r),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Responsive r) {
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(r.pagePaddingH, 24, r.pagePaddingH, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppTheme.terracotta,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Terjadi kesalahan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Kembali',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _fetchPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Coba Lagi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(Responsive r) {
    return ListView(
      padding: EdgeInsets.fromLTRB(r.pagePaddingH, 24, r.pagePaddingH, 30),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.successGreen, width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.terracottaLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successGreen,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Pembayaran Berhasil',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pesanan $_orderNumber sudah lunas ($_statusLabel). '
                'Terima kasih telah berbelanja di Hamzah Adhikara Nusantara.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatPrice(_totalAmount),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/pesanan'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: Text(
                    'Lihat Pesanan Saya',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _fetchPayment,
                child: Text(
                  'Perbarui Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingState(Responsive r) {
    return ListView(
      padding: EdgeInsets.fromLTRB(r.pagePaddingH, 12, r.pagePaddingH, 30),
      children: [
        if (_secondsRemaining > 0) ...[
          _buildCountdownBanner(),
          const SizedBox(height: 12),
        ],
        _buildOrderSummary(r),
        const SizedBox(height: 12),
        _buildTotalCard(r),
        const SizedBox(height: 12),
        _buildSnapPayCard(r),
        const SizedBox(height: 14),
        _buildStatusRefreshRow(r),
      ],
    );
  }

  Widget _buildCountdownBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B1E16), Color(0xFF1E140E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Selesaikan Pembayaran Sebelum',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE9E1D8),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timeBox(_hoursStr, 'Jam'),
              _timeSeparator(),
              _timeBox(_minutesStr, 'Menit'),
              _timeSeparator(),
              _timeBox(_secondsStr, 'Detik'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.terracotta.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.terracotta.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 11,
                  color: Color(0xFFFFDBCE),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_statusLabel · Batas Waktu Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFDBCE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String digits, String label) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF3F2D22),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppTheme.terracotta.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            digits,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8,
            color: const Color(0xFFB5A89E),
          ),
        ),
      ],
    );
  }

  Widget _timeSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        ':',
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.terracotta,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Responsive r) {
    final items = _items;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _summaryProductName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _orderDetailRow('Nomor Pesanan', _orderNumber),
            const SizedBox(height: 4),
            if (items.isNotEmpty) ...[
              _orderDetailRow('Jumlah Item', '${items.length} produk'),
              const SizedBox(height: 4),
            ],
            _orderDetailRow('Status', _statusLabel),
          ],
        ),
      ),
    );
  }

  Widget _orderDetailRow(String label, String val) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.textSubtle,
            ),
          ),
        ),
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCard(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.terracottaBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Tagihan Nominal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSubtle,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () =>
                    _copyToClipboard('$_totalAmount', 'Nominal Tagihan'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.terracottaLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.terracottaBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 11,
                        color: AppTheme.terracotta,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Salin',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.terracotta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatPrice(_totalAmount),
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryDark,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapPayCard(Responsive r) {
    final hasSnap =
        (_snapRedirectUrl ?? _extraString('snapRedirectUrl')) != null;
    final failedLike =
        _paymentStatus == 'failed' ||
        _paymentStatus == 'expired' ||
        _paymentStatus == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.terracottaLight,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'MIDTRANS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.terracotta,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembayaran Online',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      'Kartu · Virtual Account · QRIS · E-wallet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (failedLike)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.terracottaLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.terracottaBorder),
              ),
              child: Text(
                'Status pembayaran $_statusLabel. '
                '${hasSnap ? 'Anda dapat mencoba membuka kembali halaman pembayaran.' : 'Silakan muat ulang status, atau batalkan pesanan dari daftar pesanan.'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                  height: 1.35,
                ),
              ),
            )
          else
            Text(
              'Anda akan diarahkan ke halaman pembayaran resmi Midtrans '
              'di browser. Selesaikan pembayaran, lalu kembali ke aplikasi '
              'untuk memperbarui status.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: hasSnap && !_isLaunching ? _openSnapPayment : null,
              icon: _isLaunching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                hasSnap ? 'Bayar Sekarang' : 'Pembayaran Tidak Tersedia',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.borderLight,
                disabledForegroundColor: AppTheme.textSubtle,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: AppTheme.textSubtle,
              ),
              const SizedBox(width: 4),
              Text(
                'Transaksi aman & terenkripsi oleh Midtrans',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRefreshRow(Responsive r) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _fetchPayment,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text(
              'Periksa Status Pembayaran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMain,
              backgroundColor: AppTheme.terracottaLight,
              side: const BorderSide(color: AppTheme.terracottaBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => context.go('/pesanan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textMuted,
            side: const BorderSide(color: AppTheme.borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: Text(
            'Pesanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
