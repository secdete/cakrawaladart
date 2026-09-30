import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/bimbel_constants.dart';
import '../../../core/models/bimbel_program.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bimbel_logo.dart';
import '../../auth/screens/bimbel_login_screen.dart';
import '../../classes/screens/classes_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../parent/screens/parent_monitoring_screen.dart';
import '../../profile/screens/account_profile_screen.dart';
import '../../profile/widgets/account_menu_button.dart';
import '../../student/screens/student_dashboard_screen.dart';
import '../../tutor/screens/tutor_dashboard_screen.dart';
import '../../../core/services/portal_api_service.dart';
import '../services/landing_api_service.dart';
import '../widgets/landing_lead_dialog.dart';

class BimbelLandingScreen extends StatefulWidget {
  const BimbelLandingScreen({super.key});

  @override
  State<BimbelLandingScreen> createState() => _BimbelLandingScreenState();
}

class _BimbelLandingScreenState extends State<BimbelLandingScreen> {
  static const _ceoImageAsset = 'assets/images/ceo_cakrawala.jpg';
  String _selectedGradeFilter = 'SMA - Kelas 12';
  final _api = LandingApiService();
  late Future<List<BimbelProgram>> _programsFuture;
  final _aboutSectionKey = GlobalKey();
  final _programsSectionKey = GlobalKey();
  final _contactSectionKey = GlobalKey();

  void _scrollToAbout() => _scrollTo(_aboutSectionKey);

  void _scrollTo(GlobalKey key) {
    final sectionContext = key.currentContext;
    if (sectionContext == null) return;
    Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  void _loadPrograms() {
    _programsFuture = _api.fetchPrograms(_selectedGradeFilter);
  }

  Future<void> _openDashboard(Map<String, dynamic> user) async {
    final role = user['role'] as String?;
    if (role == null) return;
    try {
      await PortalApiService.instance.dashboard(role);
      if (!mounted) return;
      final Widget screen = switch (role) {
        'student' => const StudentDashboardScreen(),
        'parent' => const ParentMonitoringScreen(),
        'tutor' => const TutorDashboardScreen(),
        'admin' => const AdminDashboardScreen(),
        _ => const BimbelLoginScreen(),
      };
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesi tidak dapat dibuka: $error')),
        );
      }
    }
  }

  void _openProfile() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountProfileScreen()));

  void _openClasses() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassesScreen()));

  Future<void> _logoutFromHome() async {
    await PortalApiService.instance.logout();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamu sudah keluar dari akun.')));
  }

  void _onGradeFilterChanged(String grade) {
    setState(() {
      _selectedGradeFilter = grade;
      _loadPrograms();
    });
  }

  Future<void> _showLeadDialog({
    required String source,
    BimbelProgram? program,
  }) async {
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => LandingLeadDialog(
        source: source,
        grade: _selectedGradeFilter,
        program: program,
      ),
    );
    if (!mounted || submitted != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permintaan terkirim. Tim Cakrawala akan menghubungi kamu.',
        ),
        backgroundColor: AppColors.accentGreenDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 16,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: BimbelLogo(size: 34),
        ),
        actions: [
          if (MediaQuery.of(context).size.width >= 1150) ...[
            _buildNavItem('Program Bimbel'),
            _buildNavItem('Les Privat'),
            _buildNavItem('Tryout SNBT'),
            _buildNavItem('Tentang Kami'),
            const SizedBox(width: 8),
          ],
          ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: PortalApiService.instance.activeSession,
            builder: (context, user, _) => Row(mainAxisSize: MainAxisSize.min, children: [
              if (user == null)
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BimbelLoginScreen())),
                  icon: const Icon(Icons.login_rounded, size: 17),
                  label: Text('Masuk', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryBlue, side: const BorderSide(color: AppColors.primaryBlue), padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                )
              else
                AccountMenuButton(
                  label: 'Profil',
                  onProfile: _openProfile,
                  onClasses: _openClasses,
                  onDashboard: () => _openDashboard(user),
                  onLogout: () { _logoutFromHome(); },
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: user == null
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BimbelLoginScreen()))
                    : () => _openDashboard(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(user == null ? 'Ruang Belajar' : 'Dashboard', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroBanner(context, isDesktop),
            _buildKeyMetricsBar(isDesktop),
            _buildPopularPackagesSection(isDesktop),
            _buildFeaturesComparison(isDesktop),
            _buildAboutSection(),
            _buildCeoSection(),
            _buildTestimonialsSection(isDesktop),
            _buildCtaConsultationSection(context),
            _buildFooter(isDesktop),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final url = Uri.parse(
            'https://wa.me/6281324868790?text=${Uri.encodeComponent('Halo Tim Cakrawala, saya ingin berkonsultasi mengenai bimbingan belajar.')}',
          );
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_rounded),
        label: Text(
          'Chat Kami',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildNavItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: label == 'Tentang Kami'
            ? _scrollToAbout
            : () => _scrollTo(_programsSectionKey),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textBody,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 60 : 36,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildHeroTextContent(context)),
                    const SizedBox(width: 48),
                    Expanded(child: _buildHeroCardPreview()),
                  ],
                )
              : Column(
                  children: [
                    _buildHeroTextContent(context),
                    const SizedBox(height: 32),
                    _buildHeroCardPreview(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeroTextContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
            border: Border.all(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF38BDF8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Layanan Resmi Bimbel PT Indo Prestasi Utama',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFE0F2FE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Belajar Lebih Asyik, Kuasai Konsep & Tembus PTN Impian!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Bimbingan belajar dan les privat terpadu untuk jenjang TK, SD, SMP, SMA hingga persiapan intensif UTBK-SNBT. Metode adaptif dengan Master Tutor berpengalaman.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: const Color(0xFFCBD5E1),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                final user = PortalApiService.instance.user;
                if (user != null) {
                  _openDashboard(user);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BimbelLoginScreen()));
                }
              },
              icon: const Icon(Icons.rocket_launch_rounded, size: 18),
              label: const Text('Mulai Belajar Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showLeadDialog(source: 'hero_consultation'),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Konsultasi Gratis via WA'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF64748B)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCardPreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentCyanLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesi Live Class Hari Ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Fisika SMA: Dinamika Rotasi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          _buildHeroFeatureRow(
            Icons.person_pin_rounded,
            'Master Tutor Alumnus PTN Terkemuka (ITB, UI, UGM)',
          ),
          const SizedBox(height: 10),
          _buildHeroFeatureRow(
            Icons.schedule_rounded,
            'Jadwal Fleksibel: Guru Datang ke Rumah / Live Zoom',
          ),
          const SizedBox(height: 10),
          _buildHeroFeatureRow(
            Icons.analytics_rounded,
            'Simulasi Tryout IRT & Laporan Kemajuan ke Orang Tua',
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tingkat Kepuasan Siswa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.9 / 5.0 (2.400+ Siswa)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Garansi Cocok',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMetricsBar(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEF4FF),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 24,
            runSpacing: 20,
            children: [
              _buildMetricItem('15.000+', 'Sesi Les Terselesaikan'),
              _buildMetricItem('94.8%', 'Siswa Lolos PTN & Sekolah Impian'),
              _buildMetricItem(
                '350+',
                'Master Tutor & Pengajar Tersertifikasi',
              ),
              _buildMetricItem(
                '4.9 / 5.0',
                'Rating Kepuasan Orang Tua & Siswa',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularPackagesSection(bool isDesktop) {
    return Container(
      key: _programsSectionKey,
      width: double.infinity,
      color: const Color(0xFFF7F4FF),
      padding: EdgeInsets.symmetric(
        vertical: 40,
        horizontal: isDesktop ? 64 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: ⭐ Paket populer untuk [ Dropdown: SMA - Kelas 12 ∨ ]
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Paket populer untuk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isDesktop ? 26 : 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGradeFilter,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF475569),
                          size: 22,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _onGradeFilterChanged(newValue);
                          }
                        },
                        items:
                            <String>[
                              'SMA - Kelas 12',
                              'SMA - Kelas 11',
                              'SMA - Kelas 10',
                              'SMP - Kelas 9',
                              'SD - Kelas 6',
                              'UTBK - SNBT',
                              'Kedinasan',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Horizontal Scrollable Cards Container
              SizedBox(
                height: 565,
                child: FutureBuilder<List<BimbelProgram>>(
                  future: _programsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _buildProgramLoadError();
                    }
                    final programs = snapshot.data ?? const <BimbelProgram>[];
                    if (programs.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada paket untuk jenjang ini.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: programs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 16),
                      itemBuilder: (context, index) => SizedBox(
                        width: 285,
                        child: _buildRuangguruStyleCard(programs[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramLoadError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary),
        const SizedBox(height: 8),
        Text(
          'Katalog belum tersambung ke server.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(_loadPrograms),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
  );

  Widget _buildRuangguruStyleCard(BimbelProgram program) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Image.asset(
            program.imageAsset,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 160,
                width: double.infinity,
                color: program.cardBgColor,
                child: Center(
                  child: Icon(
                    program.badgeIcon,
                    size: 48,
                    color: program.badgeBgColor.withValues(alpha: 0.5),
                  ),
                ),
              );
            },
          ),
          // Top Neutral Header Section (Clean white, no colored background)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Badge + Clean Icon
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              program.badgeIcon,
                              size: 13,
                              color: const Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                program.badgeText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildCleanCardIcon(program.illustrationType),
                  ],
                ),
                const SizedBox(height: 14),

                // Category Tag
                Text(
                  program.categoryTag,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),

                // Title
                Text(
                  program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Bottom Section - Price and Action
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.packageSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      if (program.packageDetail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          program.packageDetail!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      if (program.originalPriceFormatted != null) ...[
                        Row(
                          children: [
                            Text(
                              program.originalPriceFormatted!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (program.discountPercentage != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  program.discountPercentage!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              program.priceFormatted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (program.periodFormatted.isNotEmpty) ...[
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                program.periodFormatted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // Orange Beli Paket Button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => _showLeadDialog(
                        source: 'package_interest',
                        program: program,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Beli Paket',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
    );
  }

  Widget _buildCleanCardIcon(String type) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'snbt':
        icon = Icons.auto_stories_rounded;
        iconColor = const Color(0xFF2563EB);
        break;
      case 'privat':
        icon = Icons.person_search_rounded;
        iconColor = const Color(0xFF059669);
        break;
      case 'english':
        icon = Icons.language_rounded;
        iconColor = const Color(0xFF7C3AED);
        break;
      case 'liveteaching':
        icon = Icons.videocam_rounded;
        iconColor = const Color(0xFFEA580C);
        break;
      case 'kedinasan':
        icon = Icons.local_police_rounded;
        iconColor = const Color(0xFF1D4ED8);
        break;
      default:
        icon = Icons.school_rounded;
        iconColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }

  Widget _buildFeaturesComparison(bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      color: const Color(0xFFF2F7FC),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildCoveragePanel()),
                    const SizedBox(width: 22),
                    Expanded(flex: 7, child: _buildAdvantagesPanel()),
                  ],
                )
              : Column(
                  children: [
                    _buildCoveragePanel(),
                    const SizedBox(height: 20),
                    _buildAdvantagesPanel(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCoveragePanel() {
    const programAreas = [
      'SD, SMP & SMA',
      'TKA SD & SMP',
      'Bahasa Indonesia',
      'IPAS',
      'English Club',
      'Maths Club',
      'UTBK',
      'Kedinasan',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9E7F4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E3A8A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionEyebrow('LAYANAN & PROGRAM'),
          const SizedBox(height: 12),
          Text(
            'Cakupan Layanan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cakrawala menyediakan les privat akademik dan non-akademik dengan pilihan belajar online maupun offline. Ketersediaan pertemuan tatap muka mengikuti program dan lokasi siswa, jadi silakan konfirmasi terlebih dahulu.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.65,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Program yang dipublikasikan',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: programAreas
                .map(
                  (program) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6FC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC7EAF8)),
                    ),
                    child: Text(
                      program,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF075985),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_searching_rounded,
                  color: AppColors.accentOrangeDark,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Untuk area les tatap muka, tim kami akan membantu mengecek ketersediaan tutor sesuai lokasi.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _showLeadDialog(source: 'landing_consultation'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: const Text('Tanyakan cakupan layanan'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantagesPanel() {
    final advantages = [
      (
        Icons.person_search_rounded,
        'Pendampingan privat',
        'Les privat untuk kebutuhan belajar yang lebih terarah.',
        AppColors.accentOrange,
      ),
      (
        Icons.devices_rounded,
        'Online & offline',
        'Pilih format belajar sesuai program dan kebutuhan.',
        AppColors.primaryBlue,
      ),
      (
        Icons.menu_book_rounded,
        'Kurikulum beragam',
        'Berfokus pada kurikulum Nasional dan Internasional.',
        AppColors.accentGreen,
      ),
      (
        Icons.school_rounded,
        'Akademik & non-akademik',
        'Layanan belajar mencakup kedua bidang tersebut.',
        const Color(0xFF7C3AED),
      ),
      (
        Icons.assignment_turned_in_rounded,
        'Program persiapan ujian',
        'Pilihan program TKA, UTBK, dan Kedinasan.',
        const Color(0xFF0891B2),
      ),
      (
        Icons.support_agent_rounded,
        'Konsultasi program',
        'Diskusikan pilihan program dan format kelas.',
        const Color(0xFFDB2777),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7FC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFCBEAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionEyebrow('KENALI CARA BELAJARNYA'),
          const SizedBox(height: 12),
          Text(
            'Keunggulan Cakrawala Educentre',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final columns = constraints.maxWidth > 560 ? 3 : 2;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: advantages
                    .map(
                      (item) => SizedBox(
                        width: cardWidth,
                        child: _buildValuePropCard(
                          item.$1,
                          item.$2,
                          item.$3,
                          item.$4,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionEyebrow(String text) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 10,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w800,
      color: AppColors.primaryBlue,
    ),
  );

  Widget _buildValuePropCard(
    IconData icon,
    String title,
    String desc,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textBody,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      key: _aboutSectionKey,
      width: double.infinity,
      color: const Color(0xFFF8F6FF),
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1E3A8A),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionEyebrow('PROFIL LEMBAGA'),
                const SizedBox(height: 12),
                Text(
                  'Tentang Cakrawala Educentre',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cakrawala Educentre adalah merek layanan pendidikan di bawah naungan ${BimbelConstants.companyName}. Layanannya mencakup les privat akademik maupun non-akademik, dengan pilihan penyelenggaraan secara online dan offline. Cakrawala Educentre menyatakan fokus pada kurikulum Nasional dan Internasional.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.8,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Program yang dipublikasikan meliputi TKA untuk SD dan SMP, Bahasa Indonesia, IPAS, English Club, Maths Club, UTBK, serta Kedinasan. Pilihan ini mencakup pendampingan untuk kebutuhan belajar sekolah dan persiapan seleksi. Siswa dan orang tua dapat berkonsultasi untuk mengetahui program, format kelas, serta ketersediaan tutor yang sesuai dengan lokasi dan jadwal.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.8,
                    color: AppColors.textBody,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    _buildAboutFact(
                      Icons.business_rounded,
                      BimbelConstants.companyName,
                    ),
                    _buildAboutFact(
                      Icons.laptop_chromebook_rounded,
                      'Online & offline',
                    ),
                    _buildAboutFact(
                      Icons.menu_book_rounded,
                      'Kurikulum Nasional & Internasional',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://cakrawalaeducentre.com/'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Lihat informasi di situs resmi'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutFact(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F7FC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryBlue),
        const SizedBox(width: 7),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textBody,
          ),
        ),
      ],
    ),
  );

  Widget _buildCeoSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              final photo = AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    _ceoImageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    semanticLabel: 'CEO Cakrawala Educentre',
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE8EEF7),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 72,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              );
              final message = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionEyebrow('PESAN DARI CEO'),
                  const SizedBox(height: 14),
                  Text(
                    'Tumbuh bersama potensi terbaik setiap anak.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isWide ? 28 : 24,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sebagai CEO Cakrawala Educentre, saya percaya setiap anak memiliki potensi yang perlu pendampingan belajar yang tepat. Kami hadir sebagai mitra orang tua untuk mendampingi tumbuh kembang anak melalui layanan yang personal, profesional, dan bermakna.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      height: 1.8,
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 46,
                    height: 3,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'CEO Cakrawala Educentre',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              );

              if (!isWide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 240, child: photo),
                    const SizedBox(height: 30),
                    message,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: 330, child: photo),
                  const SizedBox(width: 72),
                  Expanded(child: message),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialsSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F5FF),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'Kisah Sukses Siswa Cakrawala Educentre',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dari nilai rapor yang naik drastis hingga tembus kampus impian se-Indonesia',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              isDesktop
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildTestimonialItem(
                            'Farhan Arya Nugraha',
                            'Lolos STEI ITB 2025',
                            '"Belajar di Cakrawala bikin materi fisika yang rumit jadi masuk akal banget. Soal tryout IRT-nya persis banget sama pola SNBT!"',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildTestimonialItem(
                            'Nadia Safira & Ibu Hendrawan',
                            'Siswa SMP Kelas 8 & Wali Murid',
                            '"Tutor les privatnya sabar banget datang ke rumah. Nadia yang tadinya takut matematika sekarang malah jadi juara kelas!"',
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildTestimonialItem(
                          'Farhan Arya Nugraha',
                          'Lolos STEI ITB 2025',
                          '"Materi fisika jadi mudah dipahami, tryout IRT-nya sangat mirip dengan ujian aslinya!"',
                        ),
                        const SizedBox(height: 16),
                        _buildTestimonialItem(
                          'Nadia Safira & Ibu Hendrawan',
                          'Siswa SMP Kelas 8 & Wali Murid',
                          '"Tutor datang ke rumah tepat waktu dan cara ngajarnya ramah. Nilai raport anak naik pesat!"',
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestimonialItem(String name, String role, String quote) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textBody,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          Text(
            role,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.accentCyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaConsultationSection(BuildContext context) {
    return Container(
      key: _contactSectionKey,
      width: double.infinity,
      color: AppColors.brandNavy,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Ingin Konsultasi Jadwal atau Pilihan Tutor?',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Tim Education Consultant Cakrawala siap membantu menentukan paket dan tutor terbaik yang sesuai dengan kebutuhan dan target anak Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFFCBD5E1),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showLeadDialog(source: 'landing_consultation'),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
            label: const Text('Hubungi Konsultan Pendidikan (WhatsApp)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDesktop) {
    final mapUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(BimbelConstants.operationalHeadquarters)}',
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F0FF),
        border: Border(top: BorderSide(color: Color(0xFFE3E0FA))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 13, child: _buildFooterBrand()),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 9,
                      child: _buildFooterList('Area & format belajar', [
                        'Kantor di Ciketing, Kota Bekasi',
                        'Pilihan kelas online dan offline',
                        'Cek area tatap muka ke konsultan',
                      ]),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      flex: 9,
                      child: _buildFooterList('Program', [
                        'Les privat akademik & non-akademik',
                        'TKA SD & SMP, Bahasa Indonesia, IPAS',
                        'English Club & Maths Club',
                        'UTBK & Kedinasan',
                      ]),
                    ),
                    const SizedBox(width: 28),
                    Expanded(flex: 11, child: _buildFooterLinks(mapUrl)),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFooterBrand(),
                    const SizedBox(height: 28),
                    _buildFooterList('Area & format belajar', [
                      'Kantor di Ciketing, Kota Bekasi',
                      'Pilihan kelas online dan offline',
                      'Cek area tatap muka ke konsultan',
                    ]),
                    const SizedBox(height: 24),
                    _buildFooterList('Program', [
                      'Les privat akademik & non-akademik',
                      'TKA SD & SMP, Bahasa Indonesia, IPAS',
                      'English Club & Maths Club',
                      'UTBK & Kedinasan',
                    ]),
                    const SizedBox(height: 24),
                    _buildFooterLinks(mapUrl),
                  ],
                ),
              const SizedBox(height: 32),
              const Divider(color: Color(0xFFD9D6EE), height: 1),
              const SizedBox(height: 16),
              Text(
                '© 2026 ${BimbelConstants.appName} · ${BimbelConstants.companyName}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF68708A),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BimbelLogo(size: 38),
        const SizedBox(height: 12),
        Text(
          'Pendamping belajar personal untuk membantu siswa tumbuh dan meraih target akademiknya.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF555E78),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 14),
        _buildFooterContactRow(
          Icons.location_on_outlined,
          BimbelConstants.operationalHeadquarters,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () =>
              launchUrl(Uri(scheme: 'tel', path: BimbelConstants.contactPhone)),
          child: _buildFooterContactRow(
            Icons.phone_outlined,
            BimbelConstants.contactPhone,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => launchUrl(
            Uri(scheme: 'mailto', path: BimbelConstants.contactEmail),
          ),
          child: _buildFooterContactRow(
            Icons.email_outlined,
            BimbelConstants.contactEmail,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterList(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFooterHeading(title),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Text(
              item,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF555E78),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks(Uri mapUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFooterHeading('Tentang Kami'),
        const SizedBox(height: 8),
        _buildFooterAction('Profil Cakrawala', _scrollToAbout),
        _buildFooterAction(
          'Program Belajar',
          () => _scrollTo(_programsSectionKey),
        ),
        _buildFooterAction('Hubungi Kami', () => _scrollTo(_contactSectionKey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => launchUrl(mapUrl, mode: LaunchMode.externalApplication),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE4EAF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD5DCEC)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CustomPaint(painter: _MapGridPainter()),
                  ),
                ),
                const Icon(
                  Icons.location_pin,
                  color: AppColors.accentOrangeDark,
                  size: 34,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lihat di Google Maps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterHeading(String text) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: AppColors.textHeading,
    ),
  );

  Widget _buildFooterAction(String label, VoidCallback onPressed) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF555E78),
        padding: const EdgeInsets.symmetric(vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
    ),
  );

  Widget _buildFooterContactRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.primaryBlue),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: const Color(0xFF555E78),
            height: 1.4,
          ),
        ),
      ),
    ],
  );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    final minorRoadPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final roads = [
      Path()
        ..moveTo(0, size.height * .25)
        ..lineTo(size.width, size.height * .72),
      Path()
        ..moveTo(size.width * .12, 0)
        ..lineTo(size.width * .64, size.height),
      Path()
        ..moveTo(size.width, size.height * .18)
        ..lineTo(size.width * .35, size.height),
    ];
    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
      canvas.drawPath(road, minorRoadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
