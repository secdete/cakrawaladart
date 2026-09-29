import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum LogoVariant { lightOnDark, darkOnLight, emblemOnly }

class CampusLogo extends StatelessWidget {
  final double size;
  final LogoVariant variant;
  final bool showSubtitle;

  const CampusLogo({
    super.key,
    this.size = 48,
    this.variant = LogoVariant.darkOnLight,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = variant == LogoVariant.lightOnDark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emblem Crest
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : AppColors.primaryNavy.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.accentGold,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background geometric ring
              Container(
                width: size * 0.75,
                height: size * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDark ? AppColors.primaryNavy : Colors.white)
                        .withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
              ),
              // Institutional Icon
              Icon(
                Icons.school_rounded,
                size: size * 0.54,
                color: isDark ? AppColors.primaryNavy : AppColors.accentGoldLight,
              ),
            ],
          ),
        ),

        if (variant != LogoVariant.emblemOnly) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'CAKRAWALA',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.primaryNavy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: size * 0.38,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SIAKAD',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.20,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 2),
                Text(
                  'EDUCENTRE • INSTITUT TERPADU',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontSize: size * 0.22,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
