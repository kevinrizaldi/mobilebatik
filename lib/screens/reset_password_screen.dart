import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/batik_header_logo.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/heritage_footer.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscuredNew = true;
  bool _isObscuredConfirm = true;
  bool _isLoading = false;

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kata sandi Anda berhasil diperbarui! Silakan masuk kembali.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.go('/login');
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isLandscape = r.isLandscape;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: r.iconSm),
          color: AppTheme.primaryDark,
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: r.pagePaddingH, vertical: isLandscape ? 4 : 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.formMaxWidth),
              child: Column(
                children: [
                    BatikHeaderLogo(tag: 'BESPOKE CLIENT SECURITY', compact: isLandscape),
              SizedBox(height: isLandscape ? 12 : 28),

              // Form Container Card
              Container(
                padding: const EdgeInsets.all(24),
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
                        'Buat Password Baru',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Silakan buat kombinasi kata sandi baru yang kuat untuk melindungi akun dan riwayat pesanan Anda.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // New Password Field
                      CustomTextField(
                        label: 'Password Baru',
                        hintText: 'Minimal 8 karakter',
                        controller: _newPasswordController,
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isObscured: _isObscuredNew,
                        onToggleVisibility: () {
                          setState(() => _isObscuredNew = !_isObscuredNew);
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Password baru tidak boleh kosong';
                          }
                          if (val.length < 8) {
                            return 'Password minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm New Password Field
                      CustomTextField(
                        label: 'Konfirmasi Password Baru',
                        hintText: 'Ulangi password baru',
                        controller: _confirmPasswordController,
                        prefixIcon: Icons.lock_reset_rounded,
                        isPassword: true,
                        isObscured: _isObscuredConfirm,
                        onToggleVisibility: () {
                          setState(() => _isObscuredConfirm = !_isObscuredConfirm);
                        },
                        validator: (val) {
                          if (val != _newPasswordController.text) {
                            return 'Konfirmasi password tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Strength Guidance Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kriteria Keamanan Password:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildCheckItem('Minimal 8 karakter'),
                            _buildCheckItem('Mengandung kombinasi huruf & angka'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit CTA Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
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
                                  Text('Simpan Password Baru'),
                                  SizedBox(width: 8),
                                  Icon(Icons.shield_outlined, size: 18),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Back to Login Link
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'BATAL & KEMBALI KE LOGIN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.primaryDark,
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

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppTheme.successGreen,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
