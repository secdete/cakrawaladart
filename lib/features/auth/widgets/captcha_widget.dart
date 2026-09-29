import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CaptchaWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool>? onValidityChanged;

  const CaptchaWidget({
    super.key,
    required this.controller,
    this.onValidityChanged,
  });

  @override
  State<CaptchaWidget> createState() => CaptchaWidgetState();
}

class CaptchaWidgetState extends State<CaptchaWidget> {
  late int _num1;
  late int _num2;
  late int _expectedSum;

  @override
  void initState() {
    super.initState();
    _generateChallenge();
    widget.controller.addListener(_validateInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateInput);
    super.dispose();
  }

  void _generateChallenge() {
    final random = Random();
    _num1 = random.nextInt(9) + 1; // 1 to 9
    _num2 = random.nextInt(9) + 1; // 1 to 9
    _expectedSum = _num1 + _num2;
    widget.controller.clear();
    widget.onValidityChanged?.call(false);
  }

  void _validateInput() {
    final text = widget.controller.text.trim();
    final isValid = int.tryParse(text) == _expectedSum;
    widget.onValidityChanged?.call(isValid);
  }

  bool verify() {
    final text = widget.controller.text.trim();
    return int.tryParse(text) == _expectedSum;
  }

  void refresh() {
    setState(() {
      _generateChallenge();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Kode Keamanan (Verifikasi SIAKAD)',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textBody,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: refresh,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: AppColors.primaryNavyLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Acak Ulang',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryNavyLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Realistic Captcha Canvas Box
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderMedium, width: 1.2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle strikethrough security lines
                  CustomPaint(
                    size: const Size(90, 48),
                    painter: _CaptchaNoisePainter(),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_num1 + $_num2 = ?',
                        style: AppTypography.titleMedium.copyWith(
                          fontFamily: 'Courier',
                          letterSpacing: 3,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavyDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Input Field
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextFormField(
                  controller: widget.controller,
                  keyboardType: TextInputType.number,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Hasil...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CaptchaNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // A few random security lines
    canvas.drawLine(
      Offset(4, size.height * 0.75),
      Offset(size.width - 4, size.height * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(10, size.height * 0.3),
      Offset(size.width - 10, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
