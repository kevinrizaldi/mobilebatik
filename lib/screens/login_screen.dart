import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/batik_header_logo.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_social_button.dart';
import '../widgets/heritage_footer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'pelanggan@hamzahstyle.id');
  final _passwordController = TextEditingController(text: 'secret123');
  bool _isObscured = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selamat datang kembali! Berhasil masuk ke Hamzah Style.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      context.go('/home');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape || mediaQuery.size.height < 600;

    final verticalPadding = isLandscape ? 8.0 : 16.0;
    final horizontalPadding = r.pagePaddingH;
    final cardPadding = isLandscape ? 16.0 : 24.0;
    final topSpacing = isLandscape ? 8.0 : 16.0;
    final headerSpacing = isLandscape ? 14.0 : 28.0;
    final formSpacing = isLandscape ? 16.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.formMaxWidth),
              child: Column(
                children: [
                    SizedBox(height: topSpacing),
                    BatikHeaderLogo(compact: isLandscape),
                    SizedBox(height: headerSpacing),

                    // Form Container Card
                    Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Selamat Datang Kembali',
                              style: GoogleFonts.outfit(
                                fontSize: isLandscape ? 19 : 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Masuk ke akun Anda untuk melanjutkan belanja koleksi batik dan kriya sirkular.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isLandscape ? 12 : 13,
                                color: AppTheme.textMuted,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: formSpacing),

                            // Email Field
                            CustomTextField(
                              label: 'Email',
                              hintText: 'pelanggan@hamzahstyle.id',
                              controller: _emailController,
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!value.contains('@')) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password Field
                            CustomTextField(
                              label: 'Password',
                              hintText: '••••••••••••',
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              isObscured: _isObscured,
                              onToggleVisibility: () {
                                setState(() => _isObscured = !_isObscured);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                if (value.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),

                            // Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppTheme.primaryDark,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (val) {
                                          setState(() => _rememberMe = val ?? false);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ingat saya',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => context.push('/forgot-password'),
                                  child: Text(
                                    'Lupa Password?',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.terracotta,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isLandscape ? 12.0 : 20.0),

                            // Login Button CTA
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text('Masuk'),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                            SizedBox(height: isLandscape ? 12 : 16),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AppTheme.borderLight)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'atau',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.textSubtle,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: AppTheme.borderLight)),
                              ],
                            ),
                            SizedBox(height: isLandscape ? 12 : 16),

                            // Google Social Login Button
                            GoogleSocialButton(
                              label: 'Masuk dengan Google',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Menghubungkan ke layanan Google Sign-In...'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isLandscape ? 12.0 : 20.0),

                    // Register Prompt Text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text(
                            'Daftar sekarang',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.terracotta,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isLandscape ? 12.0 : 20.0),

                    // Curator & Staff Anchor Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.terracottaLight.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.terracottaBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: AppTheme.terracotta,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Akses Portal Admin Kurator?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Membuka Portal Kurator & Staff...'),
                                ),
                              );
                            },
                            child: Text(
                              'MASUK DI SINI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const HeritageFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
