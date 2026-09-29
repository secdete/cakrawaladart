import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (_idController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi NIM/NIDN dan email terdaftar.'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
      return;
    }

    setState(() {
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _submitted ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusWarningBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.statusWarning,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lupa Kata Sandi', style: AppTypography.titleMedium),
                    Text('Pemulihan Akses Akun SIAKAD', style: AppTypography.bodySmall),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Masukkan Nomor Induk (NIM / NIDN) dan alamat surel kampus yang terdaftar. Tautan verifikasi pemulihan sandi akan dikirimkan ke kotak masuk Anda.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 18),
        Text('Nomor Induk Mahasiswa / Dosen', style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        TextField(
          controller: _idController,
          decoration: const InputDecoration(
            hintText: 'Contoh: 20230801244',
            prefixIcon: Icon(Icons.badge_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        Text('Email Kampus Terdaftar (@cakrawala.ac.id)', style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'nama.mahasiswa@student.cakrawala.ac.id',
            prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _handleReset,
              child: const Text('Kirim Tautan Reset'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusSuccessBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.statusSuccess,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text('Tautan Pemulihan Dikirim!', style: AppTypography.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Silakan periksa kotak masuk atau folder spam surel Anda (${_emailController.text}). Ikuti petunjuk di dalam surel untuk menyetel ulang kata sandi SIAKAD.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kembali ke Halaman Login'),
        ),
      ],
    );
  }
}
