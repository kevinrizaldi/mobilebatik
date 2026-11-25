import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/batik_header_logo.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _resendCooldown = 60; // detik
  static const int _otpExpireMinutes = 10;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;

  // Countdown OTP expired (10 menit)
  late Timer _expireTimer;
  int _expireSeconds = _otpExpireMinutes * 60;

  // Cooldown kirim ulang (60 detik)
  Timer? _resendTimer;
  int _resendCooldownLeft = 0;

  @override
  void initState() {
    super.initState();
    _startExpireCountdown();
    // Cooldown aktif langsung dari awal — user harus tunggu 1 menit
    // sebelum bisa kirim ulang OTP pertama kali maupun berikutnya.
    _startResendCooldown();
  }

  void _startExpireCountdown() {
    _expireTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _expireSeconds--);
      if (_expireSeconds <= 0) {
        t.cancel();
      }
    });
  }

  void _startResendCooldown() {
    setState(() => _resendCooldownLeft = _resendCooldown);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendCooldownLeft--);
      if (_resendCooldownLeft <= 0) t.cancel();
    });
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '$name***@$domain';
    return '${name.substring(0, 2)}***@$domain';
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste: sebar ke kotak-kotak berikutnya
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _controllers[index + i < _otpLength ? index + i : _otpLength - 1]
            .text = digits[i];
      }
      final nextIndex = (index + digits.length).clamp(0, _otpLength - 1);
      _focusNodes[nextIndex].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    // Auto-submit jika semua terisi
    if (_otpCode.length == _otpLength) {
      Future.delayed(const Duration(milliseconds: 150), _verifyOtp);
    }

    setState(() {});
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCode;
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan 6 digit kode OTP terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final res = await ApiClient.instance.post(
        '/verify-otp',
        body: {'email': widget.email, 'otp': otp},
        auth: false,
      );

      if (!mounted) return;

      // Pakai go() agar seluruh navigation stack diganti dari awal →
      // OTP screen benar-benar hilang, user tidak bisa kembali ke sini.
      context.go('/reset-password', extra: {
        'token': res['token'] as String,
        'email': res['email'] as String,
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);

      // Kosongkan semua kotak jika OTP salah
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      await ApiClient.instance.post(
        '/forgot-password',
        body: {'email': widget.email},
        auth: false,
      );

      if (!mounted) return;

      // Reset expire countdown
      _expireTimer.cancel();
      setState(() => _expireSeconds = _otpExpireMinutes * 60);
      _startExpireCountdown();
      _startResendCooldown();

      // Kosongkan input
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP baru telah dikirim ke email Anda.'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _expireTimer.cancel();
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.of(context);
    final isLandscape = r.isLandscape;
    final expired = _expireSeconds <= 0;

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
            padding: EdgeInsets.symmetric(
              horizontal: r.pagePaddingH,
              vertical: isLandscape ? 4 : 8,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.formMaxWidth),
              child: Column(
                children: [
                  BatikHeaderLogo(tag: 'VERIFIKASI KEAMANAN', compact: isLandscape),
                  SizedBox(height: isLandscape ? 12 : 28),

                  // Card
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: AppTheme.terracottaLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 32,
                              color: AppTheme.terracotta,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Masukkan Kode OTP',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kode 6 digit telah dikirim ke:\n${_maskEmail(widget.email)}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 6 kotak OTP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(_otpLength, (i) {
                            final filled = _controllers[i].text.isNotEmpty;
                            return SizedBox(
                              width: 46,
                              height: 58,
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF110703), // primaryBlack hardcoded agar pasti muncul
                                  height: 1.2,
                                ),
                                cursorColor: AppTheme.terracotta,
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: filled
                                      ? AppTheme.terracottaLight
                                      : AppTheme.bgCard,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppTheme.borderLight),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppTheme.terracotta, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: filled
                                          ? AppTheme.terracotta
                                          : AppTheme.borderLight,
                                      width: filled ? 1.5 : 1,
                                    ),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val.isEmpty) {
                                    // Backspace: pindah ke kotak sebelumnya
                                    if (i > 0) {
                                      _controllers[i - 1].clear();
                                      _focusNodes[i - 1].requestFocus();
                                    }
                                  } else {
                                    _onDigitChanged(i, val);
                                  }
                                  setState(() {});
                                },
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Countdown
                        Center(
                          child: expired
                              ? Text(
                                  'Kode OTP sudah kadaluarsa. Kirim ulang.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppTheme.errorRed,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer_outlined,
                                        size: 14, color: AppTheme.textSubtle),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Berlaku: ${_formatTime(_expireSeconds)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: _expireSeconds < 60
                                            ? AppTheme.errorRed
                                            : AppTheme.textSubtle,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Tombol Verifikasi
                        ElevatedButton(
                          onPressed: (_isVerifying || expired)
                              ? null
                              : _verifyOtp,
                          child: _isVerifying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text('Verifikasi OTP'),
                                    SizedBox(width: 8),
                                    Icon(Icons.verified_outlined, size: 18),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Kirim Ulang
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tidak terima kode? ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            _resendCooldownLeft > 0
                                ? Text(
                                    'Kirim Ulang (${_resendCooldownLeft}d)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: AppTheme.textSubtle,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _isResending ? null : _resendOtp,
                                    child: _isResending
                                        ? const SizedBox(
                                            height: 14,
                                            width: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppTheme.terracotta),
                                          )
                                        : Text(
                                            'Kirim Ulang',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              color: AppTheme.terracotta,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Kembali ke login
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_rounded,
                            size: 16, color: AppTheme.primaryDark),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
