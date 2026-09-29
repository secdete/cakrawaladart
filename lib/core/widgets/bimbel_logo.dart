import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class BimbelLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isLightMode;

  const BimbelLogo({
    super.key,
    this.size = 44,
    this.showText = true,
    this.isLightMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          image: true,
          label: 'Logo Cakrawala Educentre',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.24),
            child: Image.asset(
              'assets/images/cakrawala_logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'CAKRAWALA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: size * 0.42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isLightMode ? AppColors.textHeading : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'EDUCENTRE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: size * 0.24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'BIMBEL & LES PRIVAT TERPADU',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: isLightMode
                      ? AppColors.accentCyan
                      : const Color(0xFF93C5FD),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
