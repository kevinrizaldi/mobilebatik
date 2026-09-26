import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../data/profile_store.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final profile = ProfileStore.instance;
    return AnimatedBuilder(
      animation: profile,
      builder: (context, _) => Scaffold(
        backgroundColor: AppTheme.bgWarm,
        bottomNavigationBar: const BottomNavBar(currentIndex: 4),
        appBar: _buildAppBar(r),
        body: ListView(
          padding: EdgeInsets.fromLTRB(r.pagePaddingH, 12, r.pagePaddingH, 24),
          children: [
            _ProfileCard(profile: profile),
            const SizedBox(height: 18),
            _Section(
              title: 'AKTIVITAS & AKUN',
              children: [
                _ProfileMenuRow(
                  icon: Icons.badge_outlined,
                  title: 'Data Diri',
                  subtitle: 'Kelola identitas, sandi, dan keamanan',
                  onTap: () => context.push('/profil/data-diri'),
                ),
                _ProfileMenuRow(
                  icon: Icons.location_on_outlined,
                  title: 'Daftar Alamat',
                  subtitle: 'Kelola alamat pengiriman',
                  trailing: '${profile.addresses.length} Tersimpan',
                  onTap: () => context.push('/profil/daftar-alamat'),
                ),
                _ProfileMenuRow(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Pesanan Saya',
                  subtitle: 'Lihat status dan riwayat pesanan',
                  trailing: '1 Aktif',
                  onTap: () => context.go('/pesanan'),
                ),
                _ProfileMenuRow(
                  icon: Icons.rate_review_outlined,
                  title: 'Ulasan Saya',
                  subtitle: 'Produk yang sudah Anda ulas',
                  trailing: '${profile.reviews.length} Ulasan',
                  onTap: () => context.push('/profil/ulasan-saya'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _ProfileMenuRow(
                icon: Icons.tune_rounded,
                title: 'Pengaturan Aplikasi',
                onTap: () => _showNotice(context, 'Pengaturan Aplikasi'),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  backgroundColor: AppTheme.terracottaLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Responsive r) {
    return AppBar(
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
            'Profil',
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
    );
  }

  static void _showNotice(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$text akan tersedia berikutnya.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileStore profile;
  const _ProfileCard({required this.profile});

  Future<void> _pickPhoto(BuildContext context) async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1000,
    );
    if (photo == null) return;
    profile.setPhoto(await photo.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.65)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryDark,
                    foregroundImage: profile.photoBytes == null
                        ? null
                        : MemoryImage(profile.photoBytes!),
                    child: profile.photoBytes == null
                        ? Text(
                            _initials(profile.name),
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -1,
                    child: InkWell(
                      onTap: () => _pickPhoto(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlack,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _ProfileButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profil',
                  onPressed: () => context.push('/profil/edit'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _ProfileButton(
                  icon: Icons.location_on_outlined,
                  label: 'Kelola Alamat',
                  onPressed: () => context.push('/profil/daftar-alamat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }
}

class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 13),
        label: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10)),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.textMain,
          backgroundColor: AppTheme.terracottaLight,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSubtle,
                letterSpacing: 0.35,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: AppTheme.terracottaLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.inputBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            trailing!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: Color(0xFFB7AAA2),
            ),
          ],
        ),
      ),
    );
  }
}
