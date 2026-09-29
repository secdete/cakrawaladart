import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/campus_logo.dart';
import 'helpdesk_dialog.dart';

class CampusHeader extends StatefulWidget {
  const CampusHeader({super.key});

  @override
  State<CampusHeader> createState() => _CampusHeaderState();
}

class _CampusHeaderState extends State<CampusHeader> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatIndonesianDate(DateTime dt) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final dayStr = dt.day.toString().padLeft(2, '0');
    return '$dayName, $dayStr $monthName ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final timeStr =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
    final formattedDate = _formatIndonesianDate(_currentTime);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Brand Emblem
          const CampusLogo(
            size: 42,
            variant: LogoVariant.darkOnLight,
          ),

          // Right: Academic Metadata & Live Time (Desktop view)
          if (isDesktop)
            Row(
              children: [
                // Server Time Box (Crucial for SIAKAD KRS registration accuracy)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bgSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: AppColors.primaryNavyLight,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waktu Server Kampus (WIB)',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                timeStr,
                                style: AppTypography.labelMedium.copyWith(
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textHeading,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Helpdesk Button
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const HelpdeskDialog(),
                    );
                  },
                  icon: const Icon(
                    Icons.support_agent_rounded,
                    size: 18,
                    color: AppColors.primaryNavyLight,
                  ),
                  label: Text(
                    'Bantuan IT',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primaryNavyLight,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            )
          else
            // Mobile Quick Action
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const HelpdeskDialog(),
                );
              },
              icon: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.primaryNavyLight,
              ),
              tooltip: 'Bantuan IT',
            ),
        ],
      ),
    );
  }
}
