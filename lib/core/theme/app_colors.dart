import 'package:flutter/material.dart';

class AppColors {
  // ─── Brand Identity ───────────────────────────────────────────────────────
  // BLUE  → dominant brand color (backgrounds, accents, primary UI)
  // ORANGE → vibrant call-to-action / highlight color
  // WHITE/GRAY → for secondary text, subtle surfaces

  static const Color brandNavy = Color(0xFF0A1628);
  static const Color brandNavyLight = Color(0xFF1A2E4A);
  static const Color brandNavyDark = Color(0xFF060D18);

  // Legacy & Compatibility Aliases
  static const Color primaryNavy = Color(0xFF0A1628);
  static const Color primaryNavyLight = Color(0xFF1E3A8A);
  static const Color primaryNavyDark = Color(0xFF060D18);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentGoldLight = Color(0xFFFEF3C7);
  static const Color accentGoldDark = Color(0xFFD97706);
  static const Color textOnNavy = Color(0xFFF8FAFC);

  // ─── Primary Blue (Dominant) ───────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1D4ED8);       // Deep Royal Blue
  static const Color primaryBlueMid = Color(0xFF2563EB);    // Vibrant Blue
  static const Color primaryBlueLight = Color(0xFF3B82F6);  // Sky Blue
  static const Color primaryBluePale = Color(0xFFEFF6FF);   // Very light blue tint
  static const Color primaryBlueSoft = Color(0xFFDBEAFE);   // Soft blue surface
  static const Color accentCyan = Color(0xFF0369A1);        // Deep Cyan
  static const Color accentCyanLight = Color(0xFFE0F2FE);

  // ─── Accent Orange (CTA / Highlight) ──────────────────────────────────────
  static const Color accentOrange = Color(0xFFEA580C);      // Vibrant True Orange
  static const Color accentOrangeDark = Color(0xFFC2410C);  // Deep Orange
  static const Color accentOrangeLight = Color(0xFFFFF7ED); // Pale orange tint
  static const Color accentOrangeMid = Color(0xFFF97316);   // Bright Orange

  // ─── Supporting Accents ────────────────────────────────────────────────────
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentGreenLight = Color(0xFFD1FAE5);
  static const Color accentGreenDark = Color(0xFF059669);

  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleLight = Color(0xFFEDE9FE);

  // ─── Backgrounds & Surfaces ────────────────────────────────────────────────
  // Blue-tinted backgrounds replace old purple/violet tints
  static const Color bgCanvas = Color(0xFFF8FAFC);           // Near-white canvas
  static const Color bgSurface = Color(0xFFFFFFFF);          // Pure white surface
  static const Color bgSubtle = Color(0xFFF1F5F9);           // Subtle gray
  static const Color bgBlue = Color(0xFFEFF6FF);             // Light blue section bg
  static const Color bgBlueSoft = Color(0xFFDBEAFE);         // Slightly deeper blue bg
  static const Color bgHighlight = Color(0xFFF0FDF4);
  static const Color bgCardHover = Color(0xFFF8FAFC);

  // ─── Borders & Dividers ────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color borderBlue = Color(0xFFBFDBFE);         // Blue-tinted border
  static const Color borderFocus = Color(0xFF2563EB);

  // ─── Typography ────────────────────────────────────────────────────────────
  static const Color textHeading = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ─── Status ────────────────────────────────────────────────────────────────
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusSuccessBg = Color(0xFFD1FAE5);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0xFFFEF3C7);
  static const Color statusDanger = Color(0xFFEF4444);
  static const Color statusDangerBg = Color(0xFFFEE2E2);
  static const Color statusInfo = Color(0xFF0EA5E9);
  static const Color statusInfoBg = Color(0xFFE0F2FE);

  // ─── Form Elements ─────────────────────────────────────────────────────────
  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFCBD5E1);
}
