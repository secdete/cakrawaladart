import 'package:flutter/material.dart';
import '../../../core/constants/academic_constants.dart';
import '../../../core/models/announcement.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'helpdesk_dialog.dart';

class CampusBulletinPanel extends StatelessWidget {
  const CampusBulletinPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final announcements = AcademicAnnouncement.getSampleAnnouncements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Institutional Badge & Headline
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusSuccessBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.statusSuccess.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.statusSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PORTAL AKTIF • TAHUN 2025/2026',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.statusSuccess,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGoldLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                AcademicConstants.accreditation,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.accentGoldDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          'Sistem Informasi Akademik\n& Pembelajaran Terpadu',
          style: AppTypography.displayBold.copyWith(
            fontSize: 32,
            height: 1.2,
            color: AppColors.primaryNavyDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Selamat datang di gerbang layanan digital sivitas akademika Cakrawala Educentre. Silakan masuk menggunakan kredensial resmi institusi Anda untuk mengakses KRS, KHS, jadwal perkuliahan, dan bimbingan akademik.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textBody,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),

        // Key Milestones Banner (SIAKAD Important Notice)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFBFDBFE),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agenda Penting: Pengisian KRS Semester Ganjil',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primaryNavyLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Periode konsultasi dan persetujuan KRS oleh Dosen PA berlangsung hingga 10 Oktober 2025. Perkuliahan aktif dimulai 13 Oktober 2025.',
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Announcements Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    size: 20,
                    color: AppColors.primaryNavyLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warta & Pengumuman Kampus',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Terverifikasi BAAK',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Announcement Items
        ...announcements.take(3).map((item) => _buildAnnouncementCard(context, item)),

        const SizedBox(height: 20),

        // Security Notice Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 22,
                color: AppColors.statusSuccess,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                    children: [
                      const TextSpan(
                        text: 'Peringatan Keamanan: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text:
                            'Selalu periksa bilah alamat browser Anda. Pastikan berakhiran domain resmi institusi. Kendala teknis? ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const HelpdeskDialog(),
                            );
                          },
                          child: Text(
                            'Hubungi IT Helpdesk',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryNavyLight,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(
      BuildContext context, AcademicAnnouncement item) {
    Color badgeColor = AppColors.primaryNavyLight;
    Color badgeBg = const Color(0xFFEFF6FF);

    if (item.category == 'KEUANGAN') {
      badgeColor = AppColors.accentGoldDark;
      badgeBg = AppColors.accentGoldLight;
    } else if (item.category == 'LAYANAN IT') {
      badgeColor = AppColors.statusInfo;
      badgeBg = AppColors.statusInfoBg;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isImportant
              ? AppColors.primaryNavyLight.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.category,
                  style: AppTypography.labelSmall.copyWith(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                item.date,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: AppTypography.titleSmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 13,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                item.author,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
