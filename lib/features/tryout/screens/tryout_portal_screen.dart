import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bimbel_logo.dart';

class TryoutPortalScreen extends StatefulWidget {
  const TryoutPortalScreen({super.key});

  @override
  State<TryoutPortalScreen> createState() => _TryoutPortalScreenState();
}

class _TryoutPortalScreenState extends State<TryoutPortalScreen> {
  int? _selectedAnswer;
  bool _isAnswerSubmitted = false;

  final Map<String, dynamic> _sampleQuestion = {
    'subtest': 'Penalaran Matematika & TPS Kuantitatif (UTBK-SNBT)',
    'question':
        'Sebuah balok es terapung di permukaan air laut. Jika diketahui massa jenis es adalah 0,9 g/cm³ dan massa jenis air laut adalah 1,03 g/cm³, berapakah persentase volume es yang tercelup di dalam air laut?',
    'options': [
      'A. 87,4%',
      'B. 82,5%',
      'C. 90,0%',
      'D. 75,2%',
      'E. 92,6%',
    ],
    'correctIndex': 0,
    'explanation':
        'Berdasarkan Hukum Archimedes, benda terapung memenuhi:\n'
        'F_apung = W_benda\n'
        'ρ_cairan × V_tercelup × g = ρ_benda × V_total × g\n'
        'V_tercelup / V_total = ρ_benda / ρ_cairan = 0,9 / 1,03 ≈ 0,87378 = 87,4%.\n'
        'Jadi, volume es yang tercelup di dalam air adalah sekitar 87,4%.',
  };

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const BimbelLogo(size: 34),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 6),
                Text(
                  'Sisa Waktu: 48:20 Menit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Tryout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Simulasi Tryout UTBK-SNBT Cakrawala #04',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHeading,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _sampleQuestion['subtest'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.w600,
                            ),
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
                          'Soal No. 12 dari 40',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Card Soal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sampleQuestion['question'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeading,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Options
                      ...List.generate(
                        (_sampleQuestion['options'] as List).length,
                        (index) {
                          final opt = _sampleQuestion['options'][index];
                          final isSelected = _selectedAnswer == index;
                          final isCorrect =
                              _isAnswerSubmitted && index == _sampleQuestion['correctIndex'];
                          final isWrongSelected = _isAnswerSubmitted &&
                              isSelected &&
                              index != _sampleQuestion['correctIndex'];

                          Color borderColor = AppColors.borderSubtle;
                          Color bgColor = Colors.white;

                          if (isCorrect) {
                            borderColor = const Color(0xFF10B981);
                            bgColor = const Color(0xFFD1FAE5);
                          } else if (isWrongSelected) {
                            borderColor = const Color(0xFFEF4444);
                            bgColor = const Color(0xFFFEE2E2);
                          } else if (isSelected) {
                            borderColor = AppColors.primaryBlue;
                            bgColor = AppColors.accentCyanLight.withValues(alpha: 0.3);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: _isAnswerSubmitted
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedAnswer = index;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle_rounded
                                          : (isWrongSelected
                                              ? Icons.cancel_rounded
                                              : (isSelected
                                                  ? Icons.radio_button_checked_rounded
                                                  : Icons.radio_button_off_rounded)),
                                      color: isCorrect
                                          ? const Color(0xFF10B981)
                                          : (isWrongSelected
                                              ? const Color(0xFFEF4444)
                                              : (isSelected
                                                  ? AppColors.primaryBlue
                                                  : AppColors.textSecondary)),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: isSelected || isCorrect
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: AppColors.textHeading,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Action Submit
                      if (!_isAnswerSubmitted) ...[
                        ElevatedButton.icon(
                          onPressed: _selectedAnswer == null
                              ? null
                              : () {
                                  setState(() {
                                    _isAnswerSubmitted = true;
                                  });
                                },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Kunci Jawaban & Cek Pembahasan IRT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pembahasan Master Tutor Cakrawala:',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _sampleQuestion['explanation'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF14532D),
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
