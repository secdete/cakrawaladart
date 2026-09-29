import 'package:flutter/material.dart';
import '../../../core/constants/academic_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'captcha_widget.dart';
import 'forgot_password_dialog.dart';
import 'helpdesk_dialog.dart';

class AuthCard extends StatefulWidget {
  final Function(Map<String, String> userData) onLoginSuccess;

  const AuthCard({super.key, required this.onLoginSuccess});

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final _formKey = GlobalKey<FormState>();
  final _captchaKey = GlobalKey<CaptchaWidgetState>();

  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  int _selectedRoleIndex = 0; // 0: Mahasiswa, 1: Dosen, 2: Staf
  String _selectedSemester = AcademicConstants.semesterList[0];
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _roles = ['Mahasiswa', 'Dosen', 'Staf / Tendik'];

  @override
  void initState() {
    super.initState();
    // Default fill with demo student for convenience
    _loadDemoAccount(0);
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _loadDemoAccount(int roleIndex) {
    setState(() {
      _selectedRoleIndex = roleIndex;
      _errorMessage = null;
      if (roleIndex == 0) {
        _idController.text = AcademicConstants.demoStudent['id']!;
        _passwordController.text = AcademicConstants.demoStudent['password']!;
      } else if (roleIndex == 1) {
        _idController.text = AcademicConstants.demoLecturer['id']!;
        _passwordController.text = AcademicConstants.demoLecturer['password']!;
      } else {
        _idController.text = '198804152014021003';
        _passwordController.text = 'cakrawala2025';
      }
    });
  }

  void _handleLogin() async {
    setState(() {
      _errorMessage = null;
    });

    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (id.isEmpty) {
      setState(() {
        _errorMessage = 'Nomor Induk (NIM / NIDN / NIP) wajib diisi.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Kata sandi wajib diisi.';
      });
      return;
    }

    // Verify Captcha
    final captchaVerified = _captchaKey.currentState?.verify() ?? false;
    if (!captchaVerified) {
      setState(() {
        _errorMessage =
            'Hasil perhitungan kode keamanan (CAPTCHA) tidak sesuai. Silakan hitung ulang.';
      });
      _captchaKey.currentState?.refresh();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate authentic network latency
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Build user profile payload
    Map<String, String> userProfile;
    if (_selectedRoleIndex == 0) {
      userProfile = {
        ...AcademicConstants.demoStudent,
        'semesterPeriod': _selectedSemester,
      };
    } else if (_selectedRoleIndex == 1) {
      userProfile = {
        ...AcademicConstants.demoLecturer,
        'semesterPeriod': _selectedSemester,
      };
    } else {
      userProfile = {
        'role': 'Staf Akademik',
        'id': id,
        'name': 'Siti Rahmawati, S.Kom.',
        'program': 'Biro Administrasi Akademik & Kemahasiswaan (BAAK)',
        'faculty': 'Bagian Layanan Registrasi & KRS',
        'semester': 'Semester Ganjil 2025/2026',
        'dosenPA': '-',
        'status': 'Pegawai Aktif',
        'ipk': '-',
        'sksLulus': '-',
        'sksTempuh': '-',
        'semesterPeriod': _selectedSemester,
      };
    }

    widget.onLoginSuccess(userProfile);
  }

  @override
  Widget build(BuildContext context) {
    final String idLabel = _selectedRoleIndex == 0
        ? 'Nomor Induk Mahasiswa (NIM)'
        : (_selectedRoleIndex == 1
            ? 'Nomor Induk Dosen Nasional (NIDN)'
            : 'Nomor Induk Pegawai (NIP)');

    final String idHint = _selectedRoleIndex == 0
        ? 'Contoh: 20230801244'
        : (_selectedRoleIndex == 1 ? 'Contoh: 0412088501' : 'Contoh: 19880415...');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Accent Bar
            Container(
              height: 5,
              color: AppColors.accentGold,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masuk ke Akun SIAKAD',
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.primaryNavyDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Gunakan akun resmi yang terdaftar di PDDIKTI',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Padlock icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: AppColors.primaryNavyLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Role Tabs (Authentic SIAKAD portal feature)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.bgSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: List.generate(_roles.length, (index) {
                          final isSelected = _selectedRoleIndex == index;
                          return Expanded(
                            child: InkWell(
                              onTap: () => _loadDemoAccount(index),
                              borderRadius: BorderRadius.circular(6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _roles[index],
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected
                                        ? AppColors.primaryNavyLight
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Semester Dropdown
                    Text(
                      'Tahun Akademik & Periode',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.inputBorder, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSemester,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_rounded,
                              color: AppColors.textSecondary),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textHeading,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSemester = val);
                            }
                          },
                          items: AcademicConstants.semesterList
                              .map((sem) => DropdownMenuItem(
                                    value: sem,
                                    child: Text(sem),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nomor Induk Input
                    Text(
                      idLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _idController,
                      keyboardType: TextInputType.text,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: idHint,
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kata Sandi / Password',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const ForgotPasswordDialog(),
                            );
                          },
                          child: Text(
                            'Lupa Kata Sandi?',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryNavyLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan kata sandi...',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // CAPTCHA Widget
                    CaptchaWidget(
                      key: _captchaKey,
                      controller: _captchaController,
                    ),

                    const SizedBox(height: 16),

                    // Remember Me & Security Notice
                    Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primaryNavyLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() => _rememberMe = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ingat perangkat ini (30 hari)',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textBody,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Error Alert Box
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusDangerBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.statusDanger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: AppColors.statusDanger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.statusDanger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'MASUK KE PORTAL SIAKAD',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider with text
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ATAU AKSES CEPAT DEMO',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Demo Accounts Quick Fill Chips
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _loadDemoAccount(0),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              side: BorderSide(
                                color: _selectedRoleIndex == 0
                                    ? AppColors.primaryNavyLight
                                    : AppColors.borderSubtle,
                              ),
                              backgroundColor: _selectedRoleIndex == 0
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.school_outlined, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Akun Mahasiswa',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 11,
                                    color: _selectedRoleIndex == 0
                                        ? AppColors.primaryNavyLight
                                        : AppColors.textBody,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _loadDemoAccount(1),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              side: BorderSide(
                                color: _selectedRoleIndex == 1
                                    ? AppColors.primaryNavyLight
                                    : AppColors.borderSubtle,
                              ),
                              backgroundColor: _selectedRoleIndex == 1
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.psychology_outlined, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Akun Dosen',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 11,
                                    color: _selectedRoleIndex == 1
                                        ? AppColors.primaryNavyLight
                                        : AppColors.textBody,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Single Sign-On (Google Workspace for Education)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'SSO Google Workspace Kampus (@cakrawala.ac.id) aktif.'),
                              backgroundColor: AppColors.primaryNavyLight,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderMedium),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.domain_verification_rounded,
                                size: 18, color: AppColors.statusInfo),
                            const SizedBox(width: 8),
                            Text(
                              'Masuk dengan SSO Akun Kampus Google',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textHeading,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Footer Link
                    Center(
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => const HelpdeskDialog(),
                          );
                        },
                        child: Text(
                          'Butuh Bantuan Teknis? Kontak IT Helpdesk',
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
    );
  }
}
