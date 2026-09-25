import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/batik_header_logo.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/heritage_footer.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  void _handleSendReset() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSent = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                    BatikHeaderLogo(tag: 'OTENTIKASI AMAN', compact: isLandscape),
              SizedBox(height: isLandscape ? 12 : 28),

              // Main Card Container
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
                child: _isSent ? _buildSuccessState() : _buildFormState(),
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
                      'KEMBALI KE LOGIN',
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

              const SizedBox(height: 24),

              // Help & Support Links
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    'Butuh Bantuan Personal?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.terracotta,
                      shape: BoxShape.circle,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menghubungkan ke Bespoke Concierge WhatsApp...'),
                        ),
                      );
                    },
                    child: Text(
                      'Bespoke Concierge WhatsApp',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
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

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Lupa Kata Sandi?',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlack,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan email terdaftar Anda. Kami akan mengirimkan instruksi dan tautan untuk mereset kata sandi.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Email Field
          CustomTextField(
            label: 'Email Terdaftar',
            hintText: 'nama@email.com',
            controller: _emailController,
            prefixIcon: Icons.mark_email_read_outlined,
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
          const SizedBox(height: 20),

          // Action Button CTA
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSendReset,
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
                      Text('Kirim Tautan Reset'),
                      SizedBox(width: 8),
                      Icon(Icons.send_rounded, size: 18),
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          // Helper Guidance Callout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.terracotta,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Periksa juga folder ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: 'Spam',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        const TextSpan(text: ' atau '),
                        TextSpan(
                          text: 'Promosi',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        const TextSpan(
                          text: ' jika email verifikasi belum diterima dalam 2 menit.',
                        ),
                      ],
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

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.terracottaLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: AppTheme.terracotta,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Email Verifikasi Terkirim!',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tautan pemulihan password telah dikirim ke:\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.push('/reset-password'),
          child: const Text('Buka Halaman Reset Password'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            setState(() => _isSent = false);
          },
          child: const Text('Kirim Ulang Email'),
        ),
      ],
    );
  }
}
