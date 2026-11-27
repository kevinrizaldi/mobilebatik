import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

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
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(r.pagePaddingH, 12, r.pagePaddingH, 24),
          child: Column(
            children: [
              // Card Identitas Profil (Identik dengan customer-sidebar web Laravel)
              _ProfileIdentityCard(profile: profile),
              const SizedBox(height: 16),

              // Card Menu Navigasi
              _NavigationMenuCard(profile: profile),
              const SizedBox(height: 16),

              // Card Keluar (Logout)
              const _LogoutCard(),
            ],
          ),
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

// ─── Card Identitas Profil (Center Aligned, Identik dengan Web Laravel) ────────
class _ProfileIdentityCard extends StatelessWidget {
  final ProfileStore profile;
  const _ProfileIdentityCard({required this.profile});

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ubah Foto Profil',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C130D),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryDark),
                title: const Text('Ambil Foto (Kamera)'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryDark),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        ProfileStore.instance.setPhoto(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'BS';
    final parts = clean.split(RegExp(r'\s+'));
    final chars = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return chars.isNotEmpty ? chars : 'BS';
  }

  @override
  Widget build(BuildContext context) {
    final name = profile.name.isNotEmpty ? profile.name : 'Budi Santoso';
    final email = profile.email.isNotEmpty ? profile.email : 'budi.santoso@email.com';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECE4D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle top blush gradient (persis customer-sidebar.blade.php)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCCF7EFE7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // Centered Avatar with Camera Action Button
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF201A17),
                            border: Border.all(
                              color: const Color(0xFFECE4D8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: profile.photoBytes != null
                                ? Image.memory(
                                    profile.photoBytes!,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  )
                                : Center(
                                    child: Text(
                                      _initials(name),
                                      style: GoogleFonts.outfit(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        // Camera edit icon button at bottom right
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _pickAvatar(context),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF201A17),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // User Full Name
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C130D),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // User Email
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF78716C),
                    ),
                  ),

                  if (profile.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.phone,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFFA8A29E),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Patron Badge (Identik dengan web Laravel)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7EFE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE8DACB),
                      ),
                    ),
                    child: Text(
                      'LESTARI ADIBUSANA PATRON',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF574636),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Menu Navigasi (Identik dengan web Laravel) ──────────────────────────
class _NavigationMenuCard extends StatelessWidget {
  final ProfileStore profile;
  const _NavigationMenuCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECE4D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.person_outline_rounded,
            title: 'Data Diri',
            onTap: () => context.push('/profil/data-diri'),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFF3ECE2), indent: 44),
          _MenuItem(
            icon: Icons.location_on_outlined,
            title: 'Daftar Alamat',
            badge: '${profile.addresses.length}',
            onTap: () => context.push('/profil/daftar-alamat'),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFF3ECE2), indent: 44),
          _MenuItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Pesanan Saya',
            badge: '1 Aktif',
            onTap: () => context.go('/pesanan'),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFF3ECE2), indent: 44),
          _MenuItem(
            icon: Icons.rate_review_outlined,
            title: 'Ulasan Saya',
            badge: '${profile.reviews.length} Ulasan',
            onTap: () => context.push('/profil/ulasan-saya'),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFF3ECE2), indent: 44),
          _MenuItem(
            icon: Icons.confirmation_number_outlined,
            title: 'Voucher & Poin',
            badge: '150 Poin',
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Voucher & Poin loyalitas Anda aktif.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF44403C),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1C130D),
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EDE1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF44403C),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFA8A29E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card Keluar (Logout) (Identik dengan web Laravel) ────────────────────────
class _LogoutCard extends StatelessWidget {
  const _LogoutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await AuthService.instance.logout();
            if (context.mounted) context.go('/home');
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 19,
                  color: Color(0xFFE11D48),
                ),
                const SizedBox(width: 12),
                Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
