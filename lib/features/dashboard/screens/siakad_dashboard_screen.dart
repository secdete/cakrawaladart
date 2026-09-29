import 'package:flutter/material.dart';
import '../../../core/models/announcement.dart';
import '../../../core/models/schedule_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/campus_logo.dart';
import '../../auth/screens/siakad_login_screen.dart';

class SiakadDashboardScreen extends StatefulWidget {
  final Map<String, String> userData;

  const SiakadDashboardScreen({super.key, required this.userData});

  @override
  State<SiakadDashboardScreen> createState() => _SiakadDashboardScreenState();
}

class _SiakadDashboardScreenState extends State<SiakadDashboardScreen> {
  int _activeNavIndex = 0; // 0: Beranda, 1: KRS, 2: Jadwal, 3: KHS, 4: Keuangan

  final List<AcademicScheduleItem> _schedules =
      AcademicScheduleItem.getSampleSchedule();
  final List<AcademicAnnouncement> _announcements =
      AcademicAnnouncement.getSampleAnnouncements();

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Konfirmasi Keluar',
          style: AppTypography.titleSmall,
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari sesi portal SIAKAD Cakrawala?',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SiakadLoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;
    final isStudent = (widget.userData['role'] ?? 'Mahasiswa') == 'Mahasiswa';

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: _buildAppBar(context, isDesktop),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Desktop Sidebar Navigation
            if (isDesktop) _buildDesktopSidebar(isStudent),

            // Main Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 16,
                  vertical: 24,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Profile Hero Banner
                        _buildProfileHeroBanner(isStudent),
                        const SizedBox(height: 24),

                        // Academic Metric Summary Cards
                        if (isStudent) _buildStudentMetricsCards(),
                        if (!isStudent) _buildLecturerMetricsCards(),
                        const SizedBox(height: 28),

                        // Two column content: Today's schedule + Announcements & KRS status
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Schedule & Classes
                              Expanded(
                                flex: 6,
                                child: _buildScheduleSection(),
                              ),
                              const SizedBox(width: 24),
                              // Right: Academic Status & Alerts
                              Expanded(
                                flex: 5,
                                child: _buildSideAcademicSection(isStudent),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildScheduleSection(),
                              const SizedBox(height: 24),
                              _buildSideAcademicSection(isStudent),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(isStudent),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: isDesktop ? 32 : 16,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.borderSubtle),
      ),
      title: Row(
        children: [
          const CampusLogo(size: 34, showSubtitle: false),
          if (isDesktop) ...[
            const SizedBox(width: 16),
            Container(
              height: 24,
              width: 1,
              color: AppColors.borderSubtle,
            ),
            const SizedBox(width: 16),
            Text(
              'Portal Akademik Terpadu',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Semester Badge
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school_rounded,
                  size: 14, color: AppColors.primaryNavyLight),
              const SizedBox(width: 6),
              Text(
                '2025/2026 Ganjil',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primaryNavyLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // User Avatar Chip
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryNavy,
                child: Text(
                  widget.userData['name']?[0] ?? 'U',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userData['name'] ?? 'Pengguna SIAKAD',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.userData['id'] ?? '-',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Logout Button
        IconButton(
          onPressed: _handleLogout,
          tooltip: 'Keluar dari SIAKAD',
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.statusDanger,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDesktopSidebar(bool isStudent) {
    final navItems = isStudent
        ? [
            {'icon': Icons.dashboard_outlined, 'label': 'Beranda Akademik'},
            {'icon': Icons.edit_calendar_rounded, 'label': 'Rencana Studi (KRS)'},
            {'icon': Icons.schedule_rounded, 'label': 'Jadwal Kuliah'},
            {'icon': Icons.grading_rounded, 'label': 'Hasil Studi (KHS)'},
            {'icon': Icons.receipt_long_rounded, 'label': 'Tagihan & UKT'},
            {'icon': Icons.description_outlined, 'label': 'Transkrip Nilai'},
          ]
        : [
            {'icon': Icons.dashboard_outlined, 'label': 'Beranda Dosen'},
            {'icon': Icons.groups_outlined, 'label': 'Bimbingan PA'},
            {'icon': Icons.schedule_rounded, 'label': 'Jadwal Mengajar'},
            {'icon': Icons.fact_check_outlined, 'label': 'Input Nilai Akhir'},
            {'icon': Icons.assignment_outlined, 'label': 'RPS & Materi Kuliah'},
          ];

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.borderSubtle, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'NAVIGASI UTAMA',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = _activeNavIndex == index;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFEFF6FF),
                    leading: Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: isSelected
                          ? AppColors.primaryNavyLight
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      item['label'] as String,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.primaryNavyLight
                            : AppColors.textBody,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      setState(() => _activeNavIndex = index);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perlu Bimbingan?',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hubungi BAAK atau Dosen Pembimbing melalui helpdesk resmi.',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav(bool isStudent) {
    return BottomNavigationBar(
      currentIndex: _activeNavIndex.clamp(0, 3),
      onTap: (index) => setState(() => _activeNavIndex = index),
      selectedItemColor: AppColors.primaryNavyLight,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit_calendar_outlined),
          activeIcon: Icon(Icons.edit_calendar_rounded),
          label: 'KRS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule_outlined),
          activeIcon: Icon(Icons.schedule_rounded),
          label: 'Jadwal',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
    );
  }

  Widget _buildProfileHeroBanner(bool isStudent) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo / Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentGold, width: 2),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),

          // Identity Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.userData['name'] ?? 'Farhan Arya Nugraha',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavyDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccessBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.userData['status'] ?? 'Aktif',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.statusSuccess,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${isStudent ? "NIM" : "NIDN"}: ${widget.userData['id']} • ${widget.userData['program']}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fakultas: ${widget.userData['faculty']} | Dosen PA: ${widget.userData['dosenPA']}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentMetricsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final cardWidth = isNarrow
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        final metrics = [
          {
            'title': 'IPK Kumulatif',
            'value': '3.82',
            'subtitle': 'Skala 4.00 (Cumlaude)',
            'icon': Icons.emoji_events_outlined,
            'color': AppColors.accentGold,
            'bg': AppColors.accentGoldLight,
          },
          {
            'title': 'SKS Diselesaikan',
            'value': '76 SKS',
            'subtitle': 'Target Kelulusan: 144 SKS',
            'icon': Icons.check_circle_outline_rounded,
            'color': AppColors.statusSuccess,
            'bg': AppColors.statusSuccessBg,
          },
          {
            'title': 'SKS Semester Ini',
            'value': '22 SKS',
            'subtitle': '7 Mata Kuliah Terdaftar',
            'icon': Icons.class_outlined,
            'color': AppColors.primaryNavyLight,
            'bg': const Color(0xFFEFF6FF),
          },
          {
            'title': 'Presensi Rata-rata',
            'value': '96.5%',
            'subtitle': 'Minimal Syarat Ujian: 75%',
            'icon': Icons.how_to_reg_outlined,
            'color': const Color(0xFF0D9488),
            'bg': const Color(0xFFCCFBF1),
          },
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics.map((m) {
            return Container(
              width: cardWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m['title'] as String,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: m['bg'] as Color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          m['icon'] as IconData,
                          size: 16,
                          color: m['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    m['value'] as String,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m['subtitle'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLecturerMetricsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 3;
        final metrics = [
          {
            'title': 'Beban Mengajar',
            'value': '18 SKS',
            'subtitle': '4 Kelas Paralel',
            'icon': Icons.menu_book_rounded,
            'color': AppColors.primaryNavyLight,
          },
          {
            'title': 'Mahasiswa Bimbingan PA',
            'value': '34 Orang',
            'subtitle': '29 Telah Menyetujui KRS',
            'icon': Icons.people_outline_rounded,
            'color': AppColors.accentGold,
          },
          {
            'title': 'Jadwal Perkuliahan Hari Ini',
            'value': '2 Sesi',
            'subtitle': 'Sesi 1: 08.00 WIB • Sesi 2: 13.00 WIB',
            'icon': Icons.alarm_rounded,
            'color': AppColors.statusSuccess,
          },
        ];

        return Row(
          children: metrics.map((m) {
            return Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['title'] as String,
                    style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m['value'] as String,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m['subtitle'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_note_rounded,
                    size: 20,
                    color: AppColors.primaryNavyLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jadwal Kuliah Pekan Ini',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Sinkronisasi BAAK',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._schedules.map((course) => _buildScheduleItemCard(course)),
        ],
      ),
    );
  }

  Widget _buildScheduleItemCard(AcademicScheduleItem course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderMedium),
            ),
            child: Column(
              children: [
                Text(
                  course.day,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryNavyLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${course.sks} SKS',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Course info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${course.courseCode} • ${course.courseName}',
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: course.mode == 'Praktikum Lab'
                            ? const Color(0xFFEFF6FF)
                            : AppColors.bgSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        course.mode,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.primaryNavyLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(course.time,
                        style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.room_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        course.room,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Dosen: ${course.lecturer}',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideAcademicSection(bool isStudent) {
    return Column(
      children: [
        // KRS Status Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status Rencana Studi (KRS)',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccessBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DISETUJUI DOSEN PA',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'KRS Semester Ganjil 2025/2026 telah diverifikasi oleh Dosen Pembimbing Akademik pada 27 September 2025.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Mengunduh Dokumen KRS Digital bertanda tangan elektronik (QR)...'),
                            backgroundColor: AppColors.primaryNavyLight,
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Cetak KRS (PDF)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Financial & Tuition Status Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status Keuangan & UKT',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccessBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LUNAS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.statusSuccess,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Pembayaran SPP/UKT Semester Ganjil 2025/2026 terverifikasi via Virtual Account Mandiri.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'No. Kuitansi: KW-202509-0824',
                      style: AppTypography.codeFont.copyWith(fontSize: 11),
                    ),
                    const Icon(Icons.check_circle,
                        size: 16, color: AppColors.statusSuccess),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Recent Academic Notices Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pengumuman Terkini',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.campaign_outlined,
                    size: 18,
                    color: AppColors.primaryNavyLight,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._announcements.take(2).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryNavyLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.date} • ${item.author}',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
