import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class GoogleSocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const GoogleSocialButton({
    super.key,
    required this.onPressed,
    this.label = 'Masuk dengan Google',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryDark,
        side: const BorderSide(color: AppTheme.borderLight, width: 1.2),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GoogleLogo(size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
        ],
      ),
    );
  }
}

/// Official Vector Rendered Google 'G' Logo (100% Accurate & CORS-Safe)
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24.0;

    // 1. Blue Section (#4285F4)
    final bluePath = Path()
      ..moveTo(23.49 * s, 12.27 * s)
      ..cubicTo(23.49 * s, 11.42 * s, 23.42 * s, 10.59 * s, 23.27 * s, 9.80 * s)
      ..lineTo(12.00 * s, 9.80 * s)
      ..lineTo(12.00 * s, 14.47 * s)
      ..lineTo(18.44 * s, 14.47 * s)
      ..cubicTo(18.16 * s, 15.96 * s, 17.31 * s, 17.23 * s, 16.04 * s, 18.08 * s)
      ..lineTo(16.04 * s, 21.08 * s)
      ..lineTo(19.92 * s, 21.08 * s)
      ..cubicTo(22.19 * s, 18.99 * s, 23.49 * s, 15.91 * s, 23.49 * s, 12.27 * s)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));

    // 2. Green Section (#34A853)
    final greenPath = Path()
      ..moveTo(12.00 * s, 24.00 * s)
      ..cubicTo(15.24 * s, 24.00 * s, 17.95 * s, 22.92 * s, 19.93 * s, 21.09 * s)
      ..lineTo(16.04 * s, 18.08 * s)
      ..cubicTo(14.96 * s, 18.80 * s, 13.59 * s, 19.24 * s, 11.99 * s, 19.24 * s)
      ..cubicTo(8.87 * s, 19.24 * s, 6.23 * s, 17.13 * s, 5.28 * s, 14.28 * s)
      ..lineTo(1.34 * s, 14.28 * s)
      ..lineTo(1.34 * s, 17.37 * s)
      ..cubicTo(3.34 * s, 21.32 * s, 7.38 * s, 24.00 * s, 12.00 * s, 24.00 * s)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    // 3. Yellow Section (#FBBC05)
    final yellowPath = Path()
      ..moveTo(5.28 * s, 14.28 * s)
      ..cubicTo(5.04 * s, 13.56 * s, 4.90 * s, 12.79 * s, 4.90 * s, 11.99 * s)
      ..cubicTo(4.90 * s, 11.19 * s, 5.04 * s, 10.42 * s, 5.28 * s, 9.70 * s)
      ..lineTo(5.28 * s, 6.61 * s)
      ..lineTo(1.34 * s, 6.61 * s)
      ..cubicTo(0.49 * s, 8.31 * s, 0.00 * s, 10.22 * s, 0.00 * s, 12.22 * s)
      ..cubicTo(0.00 * s, 14.22 * s, 0.49 * s, 16.13 * s, 1.34 * s, 17.83 * s)
      ..lineTo(5.28 * s, 14.28 * s)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // 4. Red Section (#EA4335)
    final redPath = Path()
      ..moveTo(12.00 * s, 4.75 * s)
      ..cubicTo(13.77 * s, 4.75 * s, 15.35 * s, 5.36 * s, 16.60 * s, 6.55 * s)
      ..lineTo(20.02 * s, 3.13 * s)
      ..cubicTo(17.95 * s, 1.19 * s, 15.24 * s, 0.00 * s, 12.00 * s, 0.00 * s)
      ..cubicTo(7.38 * s, 0.00 * s, 3.34 * s, 2.68 * s, 1.34 * s, 6.62 * s)
      ..lineTo(5.28 * s, 9.70 * s)
      ..cubicTo(6.23 * s, 6.85 * s, 8.87 * s, 4.75 * s, 12.00 * s, 4.75 * s)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
