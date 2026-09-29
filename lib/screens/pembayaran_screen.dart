import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class PembayaranScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentData;

  const PembayaranScreen({super.key, this.paymentData});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final TextEditingController _senderNameController =
      TextEditingController(text: 'Budi Santoso (BCA)');
  
  late Timer _timer;
  int _secondsRemaining = 23 * 3600 + 59 * 60 + 42; // ~24 hours countdown
  bool _isGuideExpanded = true;
  bool _isOrderSummaryExpanded = false;

  // Uploaded file state
  String? _uploadedFileName = 'struk_transfer_bca_871238.jpg';
  String? _uploadedFileSize = '1.4 MB • Siap diverifikasi';
  Uint8List? _uploadedImageBytes;

  static const String _bcaAccountNumber = '8820 4912 3340';
  static const String _bcaAccountClean = '882049123340';
  static const String _bcaAccountHolder = 'PT Hamzah Adhikara Nusantara';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _senderNameController.dispose();
    super.dispose();
  }

  String get _orderNumber =>
      widget.paymentData?['orderNumber'] as String? ?? 'HSO-20250218-0190';

  int get _totalAmount {
    if (widget.paymentData != null &&
        widget.paymentData!['totalPayment'] != null) {
      return (widget.paymentData!['totalPayment'] as num).toInt();
    }
    // Default matching Figma screen nominal
    return 871238;
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
  String get _secondsStr =>
      (_secondsRemaining % 60).toString().padLeft(2, '0');

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '$label berhasil disalin ke clipboard!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final sizeInKb = bytes.lengthInBytes / 1024;
        final sizeStr = sizeInKb > 1024
            ? '${(sizeInKb / 1024).toStringAsFixed(1)} MB'
            : '${sizeInKb.toStringAsFixed(0)} KB';

        setState(() {
          _uploadedFileName = pickedFile.name;
          _uploadedFileSize = '$sizeStr • Siap diverifikasi';
          _uploadedImageBytes = bytes;
        });
      }
    } catch (_) {
      // Fallback for simulated environments
      setState(() {
        _uploadedFileName = 'struk_transfer_bca_${DateTime.now().millisecondsSinceEpoch % 1000000}.jpg';
        _uploadedFileSize = '1.8 MB • Siap diverifikasi';
      });
    }
  }

  void _removeUploadedFile() {
    setState(() {
      _uploadedFileName = null;
      _uploadedFileSize = null;
      _uploadedImageBytes = null;
    });
  }

  void _confirmPayment() {
    if (_uploadedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan unggah bukti transfer pembayaran terlebih dahulu.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.bgCard,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppTheme.terracottaLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.terracotta,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Bukti Transfer Terkirim!',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Terima kasih! Bukti transfer untuk pesanan $_orderNumber telah kami terima dan sedang dalam proses verifikasi tim kami.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/pesanan');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Lihat Pesanan Saya',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/home');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Kembali ke Beranda',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
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
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                r.pagePaddingH,
                12,
                r.pagePaddingH,
                30,
              ),
              children: [
                _buildCountdownBanner(r),
                const SizedBox(height: 12),
                _buildOrderMiniSummary(r),
                const SizedBox(height: 12),
                _buildTotalNominalCard(r),
                const SizedBox(height: 12),
                _buildBankAccountCard(r),
                const SizedBox(height: 12),
                _buildTransferGuideAccordion(r),
                const SizedBox(height: 14),
                _buildUploadProofSection(r),
                const SizedBox(height: 14),
                _buildSenderNameSection(r),
                const SizedBox(height: 18),
                _buildConfirmButtonSection(r),
                const SizedBox(height: 14),
                _buildCustomerSupportCard(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. HERO COUNTDOWN BANNER ---
  Widget _buildCountdownBanner(Responsive r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2B1E16),
            Color(0xFF1E140E),
          ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      'Menunggu Pembayaran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFDBCE),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Batas Waktu: 24 Jam',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFD4C8BE),
                  ),
                ),
              ),
            ],
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

  // --- 2. ORDER MINI SUMMARY ---
  Widget _buildOrderMiniSummary(Responsive r) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(
                () => _isOrderSummaryExpanded = !_isOrderSummaryExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=200&q=80',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 38,
                        height: 38,
                        color: AppTheme.terracottaLight,
                        child: const Icon(
                          Icons.checkroom_rounded,
                          color: AppTheme.terracotta,
                          size: 16,
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
                          'Kemeja Parang Seling Kencana & 1 Pouch Tenun',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                        ),
                        Text(
                          '2 Artikel Produk · $_orderNumber',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            color: AppTheme.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isOrderSummaryExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.textSubtle,
                  ),
                ],
              ),
            ),
          ),
          if (_isOrderSummaryExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _orderDetailRow('Nomor Pesanan', _orderNumber),
                  const SizedBox(height: 4),
                  _orderDetailRow('Waktu Transaksi', '18 Feb 2025 · 10:15 WIB'),
                  const SizedBox(height: 4),
                  _orderDetailRow('Kurir Pengiriman', 'JNE Reguler (2-3 hari)'),
                  const SizedBox(height: 4),
                  _orderDetailRow('Status', 'Menunggu Pembayaran Transfer'),
                ],
              ),
            ),
          ],
        ],
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

  // --- 3. TOTAL TAGIHAN NOMINAL CARD ---
  Widget _buildTotalNominalCard(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.terracottaBorder,
          width: 1.2,
        ),
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
                onTap: () => _copyToClipboard('$_totalAmount', 'Nominal Tagihan'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppTheme.terracottaBorder.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppTheme.terracotta,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'PENTING: Transfer nominal tepat hingga 3 digit terakhir (${_formatPrice(_totalAmount)}) untuk memudahkan verifikasi otomatis & manual sistem.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. REKENING TUJUAN BCA CARD ---
  Widget _buildBankAccountCard(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF005DAA), // BCA Blue
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'BCA',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
                      'Bank Central Asia',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      'Transfer Bank Manual',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'REK. RESMI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.terracotta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nomor Rekening:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.textSubtle,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                _bcaAccountNumber,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.primaryBlack,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () =>
                    _copyToClipboard(_bcaAccountClean, 'Nomor Rekening BCA'),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Salin Rekening',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Atas Nama: $_bcaAccountHolder',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. PANDUAN LANGKAH TRANSFER ACCORDION ---
  Widget _buildTransferGuideAccordion(Responsive r) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isGuideExpanded = !_isGuideExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: AppTheme.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Panduan Langkah Transfer BCA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isGuideExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.textSubtle,
                  ),
                ],
              ),
            ),
          ),
          if (_isGuideExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _guideStepItem(
                    stepNum: '1',
                    title: 'Buka Mobile Banking BCA (m-BCA) atau ATM BCA',
                    desc:
                        'Pilih menu m-Transfer > Antar Rekening BCA pada aplikasi perbankan Anda.',
                  ),
                  const SizedBox(height: 10),
                  _guideStepItem(
                    stepNum: '2',
                    title: 'Masukkan Nomor Rekening Tujuan',
                    desc:
                        'Masukkan no. rek $_bcaAccountNumber a/n $_bcaAccountHolder.',
                  ),
                  const SizedBox(height: 10),
                  _guideStepItem(
                    stepNum: '3',
                    title: 'Input Nominal Persis Sesuai Tagihan',
                    desc:
                        'Pastikan memasukkan nominal ${_formatPrice(_totalAmount)} (lengkap dengan 3 digit kode unik).',
                  ),
                  const SizedBox(height: 10),
                  _guideStepItem(
                    stepNum: '4',
                    title: 'Simpan Bukti Pembayaran',
                    desc:
                        'Simpan atau tangkap layar (screenshot) bukti transfer berhasil untuk diunggah di bawah.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _guideStepItem({
    required String stepNum,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppTheme.terracottaLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            stepNum,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.terracotta,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppTheme.textSubtle,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 6. UNGGAH BUKTI TRANSFER ---
  Widget _buildUploadProofSection(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.upload_file_rounded,
                size: 17,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Unggah Bukti Transfer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const Spacer(),
              Text(
                'Format: JPG, PNG, PDF (Maks. 5MB)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_uploadedFileName == null) ...[
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.terracottaBorder,
                    style: BorderStyle.solid,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 28,
                      color: AppTheme.terracotta,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih Berkas atau Tarik ke Sini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ambil foto bukti transfer dari galeri atau kamera',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.terracottaBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.terracottaLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _uploadedImageBytes != null
                        ? Image.memory(
                            _uploadedImageBytes!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.receipt_rounded,
                            color: AppTheme.terracotta,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uploadedFileName!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 10,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _uploadedFileSize ?? 'Siap diverifikasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                color: AppTheme.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ganti atau hapus berkas',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppTheme.textMuted,
                    onPressed: _removeUploadedFile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.refresh_rounded, size: 13),
                label: Text(
                  'Ganti Foto Bukti',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.terracotta,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- 7. FORM NAMA PENGIRIM ---
  Widget _buildSenderNameSection(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nama Rekening Pengirim (sesuai mutasi rekening)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 42,
            child: TextField(
              controller: _senderNameController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.textMain,
              ),
              decoration: InputDecoration(
                hintText: 'Contoh: Budi Santoso (BCA)',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textSubtle,
                ),
                filled: true,
                fillColor: AppTheme.inputBg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Data ini digunakan untuk mempercepat proses pencocokan mutasi rekening oleh tim keuangan kami.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              color: AppTheme.textSubtle,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // --- 8. TOMBOL KONFIRMASI & SECURITY BADGE ---
  Widget _buildConfirmButtonSection(Responsive r) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _confirmPayment,
            icon: const Icon(Icons.verified_rounded, size: 17),
            label: Text(
              'Konfirmasi Pembayaran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlack,
              foregroundColor: Colors.white,
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
              'Transaksi Aman & Terverifikasi Manual Sistem',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSubtle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 9. CS / WHATSAPP SUPPORT CARD ---
  Widget _buildCustomerSupportCard(Responsive r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              size: 20,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ada Kendala Pembayaran?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                  ),
                ),
                Text(
                  'Layanan Bantuan 24/7',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppTheme.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Membuka layanan WhatsApp Customer Service...',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.primaryDark,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF25D366).withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 12,
                    color: Color(0xFF075E54),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Chat via WhatsApp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF075E54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
