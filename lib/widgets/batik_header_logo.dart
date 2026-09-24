import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BatikHeaderLogo extends StatelessWidget {
  final String tag;
  final bool compact;

  const BatikHeaderLogo({
    super.key,
    this.tag = 'BOUTIQUE ATELIER',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape ||
        MediaQuery.of(context).size.height < 600;
    final isCompact = compact || isLandscape;

    final boxSize = isCompact ? 42.0 : 56.0;
    final fontSize = isCompact ? 18.0 : 22.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Geometric Emblem Icon Box
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withOpacity(0.18),
                blurRadius: isCompact ? 10 : 16,
                offset: Offset(0, isCompact ? 4 : 6),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _BatikMotifPainter(isCompact: isCompact),
          ),
        ),
        SizedBox(height: isCompact ? 6 : 12),
        // Brand Title & Atelier Subtitle
        Text(
          'HAMZAH STYLE',
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: AppTheme.primaryBlack,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isCompact ? 12 : 16,
              height: 1,
              color: AppTheme.terracotta.withOpacity(0.5),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                tag,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppTheme.terracotta,
                ),
              ),
            ),
            Container(
              width: isCompact ? 12 : 16,
              height: 1,
              color: AppTheme.terracotta.withOpacity(0.5),
            ),
          ],
        ),
      ],
    );
  }
}

class _BatikMotifPainter extends CustomPainter {
  final bool isCompact;
  _BatikMotifPainter({this.isCompact = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.terracottaLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 1.5 : 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final offsetVal = isCompact ? 11.0 : 16.0;

    // Diamond Motif
    final path = Path()
      ..moveTo(center.dx, center.dy - offsetVal)
      ..lineTo(center.dx + offsetVal, center.dy)
      ..lineTo(center.dx, center.dy + offsetVal)
      ..lineTo(center.dx - offsetVal, center.dy)
      ..close();
    canvas.drawPath(path, paint);

    // Inner Symmetric Cross Dots
    final fillPaint = Paint()
      ..color = AppTheme.terracotta
      ..style = PaintingStyle.fill;

    final dotRadius = isCompact ? 2.5 : 3.5;
    final outerDotRadius = isCompact ? 1.0 : 1.5;
    final dotOffset = isCompact ? 5.5 : 8.0;

    canvas.drawCircle(center, dotRadius, fillPaint);
    canvas.drawCircle(Offset(center.dx - dotOffset, center.dy - dotOffset), outerDotRadius, fillPaint);
    canvas.drawCircle(Offset(center.dx + dotOffset, center.dy - dotOffset), outerDotRadius, fillPaint);
    canvas.drawCircle(Offset(center.dx - dotOffset, center.dy + dotOffset), outerDotRadius, fillPaint);
    canvas.drawCircle(Offset(center.dx + dotOffset, center.dy + dotOffset), outerDotRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
