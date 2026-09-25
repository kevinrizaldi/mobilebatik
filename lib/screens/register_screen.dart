import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/batik_header_logo.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/heritage_footer.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscuredPassword = true;
  bool _isObscuredConfirm = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  void _handleRegister() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda harus menyetujui Syarat & Ketentuan terlebih dahulu.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pendaftaran berhasil! Silakan masuk dengan akun baru Anda.',
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
                  BatikHeaderLogo(tag: 'REGISTRASI PELANGGAN', compact: isLandscape),
              SizedBox(height: isLandscape ? 12 : 24),

              // Form Card Container
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
                        'Daftar Akun Baru',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bergabunglah bersama komunitas pecinta kriya sirkular dan nikmati layanan eksklusif.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nama Lengkap
                      CustomTextField(
                        label: 'Nama Lengkap',
                        hintText: 'Contoh: Siti Rahmawati',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email
                      CustomTextField(
                        label: 'Email',
                        hintText: 'nama@email.com',
                        controller: _emailController,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!val.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Nomor Telepon / WhatsApp
                      CustomTextField(
                        label: 'Nomor WhatsApp',
                        hintText: '081234567890',
                        controller: _phoneController,
                        prefixIcon: Icons.phone_android_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nomor WhatsApp tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password
                      CustomTextField(
                        label: 'Password',
                        hintText: 'Minimal 8 karakter',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        isObscured: _isObscuredPassword,
                        onToggleVisibility: () {
                          setState(() => _isObscuredPassword = !_isObscuredPassword);
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          if (val.length < 8) {
                            return 'Password minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      CustomTextField(
                        label: 'Konfirmasi Password',
                        hintText: 'Ulangi password di atas',
                        controller: _confirmPasswordController,
                        prefixIcon: Icons.lock_reset_rounded,
                        isPassword: true,
                        isObscured: _isObscuredConfirm,
                        onToggleVisibility: () {
                          setState(() => _isObscuredConfirm = !_isObscuredConfirm);
                        },
                        validator: (val) {
                          if (val != _passwordController.text) {
                            return 'Konfirmasi password tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Syarat & Ketentuan Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _agreeToTerms,
                              activeColor: AppTheme.primaryDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() => _agreeToTerms = val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'Saya menyetujui ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Syarat & Ketentuan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.terracotta,
                                    ),
                                  ),
                                  const TextSpan(text: ' serta '),
                                  TextSpan(
                                    text: 'Kebijakan Privasi',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.terracotta,
                                    ),
                                  ),
                                  const TextSpan(text: ' Hamzah Style Official.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Register Button CTA
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
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
                                  Text('Daftar Akun Baru'),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_outline_rounded, size: 18),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Login Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah memiliki akun? ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Masuk di sini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.terracotta,
                      ),
                    ),
                  ),
                ],
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
