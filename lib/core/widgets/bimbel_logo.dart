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
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: size * 0.52,
              ),
              Positioned(
                top: size * 0.12,
                right: size * 0.15,
                child: Container(
                  width: size * 0.22,
                  height: size * 0.22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: size * 0.18,
                  ),
                ),
              ),
            ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'EDU',
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
