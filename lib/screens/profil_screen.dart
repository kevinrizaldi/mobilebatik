import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/profile_store.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/notification_button.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  @override
  void initState() {
    super.initState();
    AuthService.instance.fetchCurrentUser().catchError((_) => null);
    ProfileStore.instance.syncAddressesFromServer();
  }

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
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: TextButton.icon(
                onPressed: () async {
                  await AuthService.instance.logout();
                  if (context.mounted) context.go('/home');
                },
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
        ],
      ),
      actions: [
        NotificationButton(
          padding: EdgeInsets.only(right: r.pagePaddingH),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ProfileStore profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryDark,
            child: Text(
              _initials(profile.name),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
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
                if (profile.phone.isNotEmpty) ...[
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'P';
    final parts = clean.split(RegExp(r'\s+'));
    final chars = parts.where((p) => p.isNotEmpty).take(2).map((part) => part[0]).join().toUpperCase();
    return chars.isNotEmpty ? chars : 'P';
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
