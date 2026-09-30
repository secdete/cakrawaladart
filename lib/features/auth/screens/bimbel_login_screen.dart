import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/bimbel_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bimbel_logo.dart';
import '../../parent/screens/parent_monitoring_screen.dart';
import '../../student/screens/student_dashboard_screen.dart';
import '../../tutor/screens/tutor_dashboard_screen.dart';
import '../../../core/services/portal_api_service.dart';

class BimbelLoginScreen extends StatefulWidget {
  const BimbelLoginScreen({super.key});

  @override
  State<BimbelLoginScreen> createState() => _BimbelLoginScreenState();
}

class _BimbelLoginScreenState extends State<BimbelLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  static final _accounts = [
    BimbelConstants.demoStudent,
    BimbelConstants.demoParent,
    BimbelConstants.demoTutor,
  ];

  Map<String, dynamic>? get _recognizedAccount {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return null;
    for (final account in _accounts) {
      if ((account['email'] as String).toLowerCase() == email) return account;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    setState(() => _errorMessage = null);
  }

  void _fillDemo(Map<String, dynamic> account) {
    setState(() {
      _emailController.text = account['email'] as String;
      _passwordController.text = account['password'] as String;
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await PortalApiService.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final role = user['role'];
      await PortalApiService.instance.dashboard(role as String);
      if (!mounted) return;
      if (role == 'parent') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentMonitoringScreen()),
        );
      } else if (role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
        );
      } else if (role == 'tutor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TutorDashboardScreen()),
        );
      } else {
        await PortalApiService.instance.logout();
        setState(() => _errorMessage = 'Role akun belum memiliki dashboard.');
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textHeading,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const BimbelLogo(size: 38),
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -170,
            right: -100,
            child: _DecorativeOrb(size: 390, color: Color(0x1A2563EB)),
          ),
          const Positioned(
            bottom: -210,
            left: -90,
            child: _DecorativeOrb(size: 430, color: Color(0x1538BDF8)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: _buildWelcomePanel()),
                          const SizedBox(width: 52),
                          SizedBox(width: 510, child: _buildLoginCard()),
                        ],
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 510),
                          child: _buildLoginCard(),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePanel() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'RUANG BELAJAR CAKRAWALA',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Satu langkah kecil untuk masa depan yang lebih besar.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 38,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF14213D),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Masuk untuk melanjutkan kelas, melihat perkembangan belajar, dan terhubung dengan tim Cakrawala.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              height: 1.7,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 30),
          const _BenefitRow(
            icon: Icons.menu_book_rounded,
            title: 'Materi dan kelas terjadwal',
            subtitle: 'Semua kebutuhan belajarmu dalam satu ruang.',
          ),
          const SizedBox(height: 18),
          const _BenefitRow(
            icon: Icons.insights_rounded,
            title: 'Pantau progres belajar',
            subtitle: 'Lihat perkembangan dan target belajarmu.',
          ),
          const SizedBox(height: 18),
          const _BenefitRow(
            icon: Icons.support_agent_rounded,
            title: 'Didampingi tim Cakrawala',
            subtitle: 'Bantuan belajar selalu lebih dekat.',
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142B3B58),
            blurRadius: 45,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masuk ke Ruang Belajar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Gunakan email akun Cakrawala yang terdaftar.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF71819B),
              ),
            ),
            const SizedBox(height: 26),
            _fieldLabel('Email akun'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              decoration: _inputDecoration(
                hint: 'nama@email.com',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Email wajib diisi.';
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                  return 'Masukkan format email yang valid.';
                }
                return null;
              },
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _recognizedAccount == null
                  ? const SizedBox(height: 14, key: ValueKey('empty-role'))
                  : _recognizedRoleBadge(_recognizedAccount!),
            ),
            _fieldLabel('Kata sandi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _handleLogin(),
              decoration:
                  _inputDecoration(
                    hint: 'Masukkan kata sandi',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ),
              validator: (value) =>
                  (value?.isEmpty ?? true) ? 'Kata sandi wajib diisi.' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Hubungi admin Cakrawala untuk bantuan kata sandi.',
                    ),
                  ),
                ),
                child: Text(
                  'Lupa kata sandi?',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFBE123C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleLogin,
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                label: Text(
                  _isLoading ? 'Memeriksa akun...' : 'Masuk Sekarang',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _buildDemoAccounts(),
          ],
        ),
      ),
    );
  }

  Widget _recognizedRoleBadge(Map<String, dynamic> account) {
    final role = account['role'] as String;
    final roleLabel = role == 'Master Tutor' ? 'Tutor' : role;
    return Container(
      key: ValueKey(role),
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF059669),
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Akun dikenali sebagai $roleLabel',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF047857),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccounts() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 17,
                color: Color(0xFF0284C7),
              ),
              const SizedBox(width: 7),
              Text(
                'Akses cepat untuk uji coba',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF24324A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _demoChip('Akun Siswa', _accounts[0]),
              _demoChip('Akun Orang Tua', _accounts[1]),
              _demoChip('Akun Tutor', _accounts[2]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoChip(String label, Map<String, dynamic> account) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _fillDemo(account);
        _handleLogin();
      },
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFBAE6FD)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryBlue,
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1E293B),
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFD9E2EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFD9E2EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
  );
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x102B3B58),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 22),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF24324A),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF71819B),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
