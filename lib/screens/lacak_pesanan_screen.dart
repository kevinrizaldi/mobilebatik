import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/profile_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class LacakPesananScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const LacakPesananScreen({super.key, required this.order});

  String get _status => order['status'] as String? ?? 'Dikirim';
  String get _courier => order['courier'] as String? ?? 'JNE Reguler';
  String get _trackingNumber =>
      order['trackingNumber'] as String? ?? 'Resi belum tersedia';
  String get _orderedAt => order['orderedAt'] as String? ?? '-';

  int get _currentStep {
    return switch (_status) {
      'Selesai' => 4,
      'Dikirim' => 3,
      'Diproses' => 2,
      'Menunggu Pembayaran' => 0,
      _ => 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final primaryAddress = ProfileStore.instance.addresses
        .where((address) => address.isPrimary)
        .firstOrNull;
    final steps = _buildSteps();

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
          'Lacak Pengiriman',
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
                20,
              ),
              children: [
                _buildShipmentCard(context),
                const SizedBox(height: 10),
                _buildAddressCard(primaryAddress),
                const SizedBox(height: 10),
                _buildTimeline(steps),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.terracottaLight,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppTheme.primaryDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
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
                    Text(
                      _courier,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.terracottaLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _status,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
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
                      'NOMOR RESI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SelectableText(
                      _trackingNumber,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Salin nomor resi',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _trackingNumber));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor resi disalin.')),
                  );
                },
                icon: const Icon(
                  Icons.copy_outlined,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(ProfileAddress? address) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppTheme.primaryDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALAMAT PENERIMA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSubtle,
                  ),
                ),
                const SizedBox(height: 4),
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
                    height: 1.45,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<_TrackingStep> steps) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 7),
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
              const Icon(
                Icons.route_outlined,
                size: 17,
                color: AppTheme.primaryDark,
              ),
              const SizedBox(width: 7),
              Text(
                'Status Perjalanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const Spacer(),
              Text(
                _courier,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isDone = index < _currentStep;
            final isCurrent = index == _currentStep;
            final reached = isDone || isCurrent;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 21,
                    child: Column(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: reached
                                ? (isCurrent
                                      ? AppTheme.terracotta
                                      : AppTheme.primaryDark)
                                : AppTheme.inputBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDone ? Icons.check_rounded : step.icon,
                            size: 11,
                            color: reached ? Colors.white : AppTheme.textSubtle,
                          ),
                        ),
                        if (index != steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: isDone
                                  ? AppTheme.primaryDark
                                  : AppTheme.borderLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: reached
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: reached
                                        ? AppTheme.textMain
                                        : AppTheme.textSubtle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                step.time,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  color: AppTheme.textSubtle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              color: AppTheme.textSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Text(
            'Waktu pemesanan: $_orderedAt',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              color: AppTheme.textSubtle,
            ),
          ),
        ],
      ),
    );
  }

  List<_TrackingStep> _buildSteps() => [
    _TrackingStep(
      title: 'Pesanan Dibuat',
      description: 'Pesanan berhasil dibuat',
      time: _orderedAt,
      icon: Icons.receipt_long_outlined,
    ),
    const _TrackingStep(
      title: 'Pembayaran Terverifikasi',
      description: 'Pembayaran berhasil diverifikasi',
      time: '14 Feb · 10:45',
      icon: Icons.payments_outlined,
    ),
    const _TrackingStep(
      title: 'Diproses & Dikemas',
      description: 'Pesanan dikemas oleh penjual',
      time: '14 Feb · 15:00',
      icon: Icons.inventory_2_outlined,
    ),
    const _TrackingStep(
      title: 'Sedang Dikirim',
      description: 'Paket dalam perjalanan menuju alamat tujuan',
      time: '15 Feb · 09:20',
      icon: Icons.local_shipping_outlined,
    ),
    const _TrackingStep(
      title: 'Diterima',
      description: 'Paket diterima oleh penerima',
      time: 'Menunggu',
      icon: Icons.home_outlined,
    ),
  ];
}

class _TrackingStep {
  final String title;
  final String description;
  final String time;
  final IconData icon;

  const _TrackingStep({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
  });
}
