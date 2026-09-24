import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HeritageFooter extends StatelessWidget {
  const HeritageFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: AppTheme.textSubtle,
              ),
              const SizedBox(width: 6),
              Text(
                'Enkripsi 256-bit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSubtle,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: AppTheme.terracotta,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                'Konservasi Warisan Budaya',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSubtle,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '© 2026 Hamzah Style Official. All Rights Reserved.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppTheme.textSubtle.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
