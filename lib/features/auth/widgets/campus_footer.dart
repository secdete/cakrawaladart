import 'package:flutter/material.dart';
import '../../../core/constants/academic_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'helpdesk_dialog.dart';

class CampusFooter extends StatelessWidget {
  const CampusFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 20,
        vertical: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AcademicConstants.institutionName} • ${AcademicConstants.institutionalSubtitle}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textHeading,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AcademicConstants.campusAddress} | Kontak: ${AcademicConstants.helpdeskPhone}',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right links
                Row(
                  children: [
                    _buildFooterLink(context, 'Panduan SIAKAD', () {
                      _showInfo(context, 'Panduan Penggunaan SIAKAD Cakrawala',
                          'Panduan lengkap pengisian KRS, cetak KHS, dan panduan presensi kuliah digital tersedia dalam format PDF di portal dokumen kampus.');
                    }),
                    const SizedBox(width: 16),
                    _buildFooterLink(context, 'Kebijakan PDDIKTI', () {
                      _showInfo(context, 'Kepatuhan & Sinkronisasi PDDIKTI',
                          'Data akademik di dalam sistem ini disinkronisasikan secara berkala dengan Pangkalan Data Pendidikan Tinggi (PDDIKTI) Kementerian.');
                    }),
                    const SizedBox(width: 16),
                    _buildFooterLink(context, 'Pusat Bantuan', () {
                      showDialog(
                        context: context,
                        builder: (_) => const HelpdeskDialog(),
                      );
                    }),
                  ],
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AcademicConstants.institutionName,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    _buildFooterLink(context, 'Panduan', () {
                      _showInfo(context, 'Panduan SIAKAD',
                          'Silakan unduh panduan di portal akademik.');
                    }),
                    _buildFooterLink(context, 'PDDIKTI Feeder', () {
                      _showInfo(context, 'PDDIKTI', 'SIAKAD tersinkronisasi PDDIKTI.');
                    }),
                    _buildFooterLink(context, 'Helpdesk', () {
                      showDialog(
                        context: context,
                        builder: (_) => const HelpdeskDialog(),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  AcademicConstants.campusAddress,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 13, color: AppColors.statusSuccess),
              const SizedBox(width: 6),
              Text(
                '© 2025 Cakrawala Educentre. Sistem Informasi Akademik Terpadu. All Rights Reserved.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(
      BuildContext context, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primaryNavyLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: AppTypography.titleSmall),
        content: Text(message, style: AppTypography.bodySmall),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
