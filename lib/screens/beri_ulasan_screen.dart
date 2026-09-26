import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../data/profile_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class BeriUlasanScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const BeriUlasanScreen({super.key, required this.order});

  @override
  State<BeriUlasanScreen> createState() => _BeriUlasanScreenState();
}

class _BeriUlasanScreenState extends State<BeriUlasanScreen> {
  static const List<String> _ratingLabels = [
    'Sangat tidak memuaskan',
    'Kurang memuaskan',
    'Cukup memuaskan',
    'Memuaskan',
    'Sangat memuaskan',
  ];

  static const List<String> _reviewTags = [
    'Kualitas bahan sangat baik',
    'Jahitan rapi',
    'Warna sesuai foto',
    'Ukuran pas di badan',
    'Pengiriman cepat',
    'Kemasan ramah lingkungan',
  ];

  final TextEditingController _reviewController = TextEditingController();
  final Set<String> _selectedTags = {};
  final List<Uint8List> _photos = [];
  int _rating = 0;
  bool _isSubmitting = false;

  String get _productName =>
      widget.order['productName'] as String? ?? 'Produk Batik';
  String get _orderId =>
      widget.order['orderNumber'] as String? ?? 'HSO-DUMMY-0001';
  String get _variant => widget.order['variant'] as String? ?? 'Ukuran L';
  String get _imageUrl => widget.order['imageUrl'] as String? ?? '';

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
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
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        title: Text(
          'Beri Ulasan',
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
                color: Colors.white,
                size: r.iconSm - 1,
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
                10,
                r.pagePaddingH,
                16,
              ),
              children: [
                _buildOrderProduct(),
                const SizedBox(height: 10),
                _buildRatingPanel(),
                const SizedBox(height: 10),
                _buildReviewTextPanel(),
                const SizedBox(height: 10),
                _buildPhotoPanel(),
              ],
            ),
          ),
          _buildBottomActions(context, r),
        ],
      ),
    );
  }

  Widget _buildOrderProduct() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'NO. $_orderId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: AppTheme.textSubtle,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'Terverifikasi Beli',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _imageUrl.isEmpty
                    ? _productImageFallback()
                    : Image.network(
                        _imageUrl,
                        width: 48,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _productImageFallback(),
                      ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ukuran · $_variant',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 12,
                          color: AppTheme.successGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Batik tulis pilihan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
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

  Widget _productImageFallback() => Container(
    width: 48,
    height: 54,
    color: AppTheme.terracottaLight,
    child: const Icon(
      Icons.checkroom_outlined,
      color: AppTheme.terracotta,
      size: 20,
    ),
  );

  Widget _buildRatingPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          _sectionLabel('PENILAIAN KUALITAS PRODUK'),
          const SizedBox(height: 4),
          Text(
            _rating == 0 ? 'Pilih penilaian' : _ratingLabels[_rating - 1],
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final selected = index < _rating;
              return IconButton(
                tooltip: _ratingLabels[index],
                onPressed: () => setState(() => _rating = index + 1),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
                icon: Icon(
                  selected ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 28,
                  color: selected ? AppTheme.terracotta : AppTheme.borderLight,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Kesan yang paling Anda sukai',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: AppTheme.textSubtle,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _reviewTags.map((tag) {
              final selected = _selectedTags.contains(tag);
              return FilterChip(
                selected: selected,
                showCheckmark: false,
                label: Text(tag),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textMuted,
                ),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                side: BorderSide.none,
                backgroundColor: AppTheme.inputBg,
                selectedColor: AppTheme.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) => setState(() {
                  if (value) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTextPanel() {
    final length = _reviewController.text.length;
    final meetsMinimum = length >= 30;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('TULIS ULASAN ANDA'),
              const Spacer(),
              Text(
                'Batik Storyteller',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: AppTheme.terracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _reviewController,
            minLines: 4,
            maxLines: 5,
            maxLength: 1000,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              height: 1.4,
              color: AppTheme.textMain,
            ),
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalaman Anda menggunakan produk ini...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppTheme.textSubtle,
              ),
              filled: true,
              fillColor: AppTheme.bgWarm,
              counterText: '',
              contentPadding: const EdgeInsets.all(9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppTheme.terracotta),
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                meetsMinimum ? Icons.check_circle : Icons.info_outline,
                size: 11,
                color: meetsMinimum
                    ? AppTheme.successGreen
                    : AppTheme.terracotta,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  meetsMinimum
                      ? 'Batas minimal ulasan terpenuhi'
                      : 'Tulis minimal 30 karakter',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    color: meetsMinimum
                        ? AppTheme.successGreen
                        : AppTheme.terracotta,
                  ),
                ),
              ),
              Text(
                '$length/1000',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPanel() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('MEDIA PRODUK'),
              const Spacer(),
              Text(
                '${_photos.length}/3 Terunggah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
          Text(
            'Foto kain & tampilan riil',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppTheme.textSubtle,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 66,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._photos.indexed.map(
                  (entry) => _photoTile(entry.$1, entry.$2),
                ),
                if (_photos.length < 3) _addPhotoTile(),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 13,
                  color: AppTheme.terracotta,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Tips Hamzah Style: Foto dengan pencahayaan alami akan membantu pembeli lain melihat detail kain dan warna sebenarnya.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      height: 1.4,
                      color: AppTheme.textMuted,
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

  Widget _photoTile(int index, Uint8List bytes) {
    return Container(
      width: 62,
      height: 62,
      margin: const EdgeInsets.only(right: 7),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(bytes, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: () => setState(() => _photos.removeAt(index)),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 17,
                height: 17,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlack,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoTile() {
    return InkWell(
      onTap: _pickPhotos,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: AppTheme.inputBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              size: 17,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              'TAMBAH',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final remaining = 3 - _photos.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(
      limit: remaining,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (picked.isEmpty || !mounted) return;
    final images = await Future.wait(
      picked.take(remaining).map((file) => file.readAsBytes()),
    );
    if (!mounted) return;
    setState(() => _photos.addAll(images));
  }

  Widget _buildBottomActions(BuildContext context, Responsive r) {
    final canSubmit = _rating > 0 && _reviewController.text.trim().length >= 30;
    return Container(
      padding: EdgeInsets.fromLTRB(
        r.pagePaddingH,
        9,
        r.pagePaddingH,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgWarm,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: canSubmit && !_isSubmitting ? _submitReview : null,
              icon: const Icon(Icons.verified_outlined, size: 15),
              label: Text(
                _isSubmitting
                    ? 'Mengirim Ulasan...'
                    : 'Kirim Ulasan Terverifikasi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.borderLight,
                disabledForegroundColor: AppTheme.textSubtle,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSubtle,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
            child: Text(
              'Kembali ke Pesanan Saya',
              style: GoogleFonts.plusJakartaSans(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0 || _reviewController.text.trim().length < 30) return;
    setState(() => _isSubmitting = true);
    ProfileStore.instance.addReview(
      ProfileReview(
        product: _productName,
        date: _formatToday(),
        rating: _rating,
        comment: _reviewController.text.trim(),
        imageUrl: _imageUrl,
        orderId: _orderId,
        tags: _selectedTags.toList(),
        photos: List.unmodifiable(_photos),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ulasan berhasil dikirim. Terima kasih!',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      color: AppTheme.textMuted,
      letterSpacing: 0.15,
    ),
  );

  String _formatToday() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
