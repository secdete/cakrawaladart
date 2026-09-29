import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/bimbel_program.dart';
import '../../../core/theme/app_colors.dart';
import '../services/landing_api_service.dart';

class LandingLeadDialog extends StatefulWidget {
  const LandingLeadDialog({
    required this.source,
    required this.grade,
    this.program,
    super.key,
  });

  final String source;
  final String grade;
  final BimbelProgram? program;

  @override
  State<LandingLeadDialog> createState() => _LandingLeadDialogState();
}

class _LandingLeadDialogState extends State<LandingLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _api = LandingApiService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  late String _grade;
  bool _consent = false;
  bool _submitting = false;
  String? _error;

  static const _grades = [
    'SMA - Kelas 12',
    'SMA - Kelas 11',
    'SMA - Kelas 10',
    'SMP - Kelas 9',
    'SD - Kelas 6',
    'UTBK - SNBT',
    'Kedinasan',
    'Semua Jenjang',
  ];

  @override
  void initState() {
    super.initState();
    _grade = _grades.contains(widget.grade) ? widget.grade : _grades.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      setState(() => _error = 'Setujui persetujuan kontak untuk melanjutkan.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.submitLead(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        grade: _grade,
        source: widget.source,
        programId: widget.program?.id,
        message: _messageController.text,
        consent: _consent,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is LandingApiException
            ? error.message
            : 'Server belum tersambung. Jalankan backend/server.py lalu coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.program == null ? 'Konsultasi Belajar' : 'Minat Paket Belajar',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textHeading,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.program != null) ...[
                  Text(
                    widget.program!.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama orang tua / siswa',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Nama minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '08xxxxxxxxxx',
                  ),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                    return digits.length < 8 || digits.length > 15
                        ? 'Masukkan nomor WhatsApp yang valid.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (opsional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isNotEmpty &&
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                      return 'Format email belum valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _grade,
                  decoration: const InputDecoration(
                    labelText: 'Jenjang belajar',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: _grades
                      .map(
                        (grade) => DropdownMenuItem(
                          value: grade,
                          child: Text(grade),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _grade = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Pertanyaan (opsional)',
                    alignLabelWithHint: true,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _consent,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Saya bersedia dihubungi tim Cakrawala terkait permintaan ini.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.4),
                  ),
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _consent = value ?? false),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.statusDanger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded, size: 16),
          label: Text(_submitting ? 'Mengirim...' : 'Kirim permintaan'),
        ),
      ],
    );
  }
}
