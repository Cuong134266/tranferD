import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === CORE COLORS (from Figma variable tokens) ===
  static const Color background = Color(0xFFF6F6F6);
  static const Color contentBackground = Color(0xFFFFFFFF);
  static const Color brandGreen = Color(0xFF307A62);
  static const Color brandGreenDark = Color(0xFF1B5E20);
  static const Color brandGreenMid = Color(0xFF2E7D32);
  static const Color brandGreenLight = Color(0xFF4CAF50);

  // Lime / Accent
  static const Color limeAccent = Color(0xFFC6F84C);
  static const Color limeButton = Color(0xFFC6F84C);
  static const Color limeBg = Color(0xFFDCFCE7); // card background

  // Text colors (from Figma)
  static const Color textDark = Color(0xFF01250F);
  static const Color textSecondary = Color(0xFF495463);
  static const Color textDescription = Color(0xFF7A8DA3);
  static const Color textGray = Color(0xFF8E8E8E);
  static const Color textLightGray = Color(0xFFB0B0B0);
  static const Color textGreen = Color(0xFF307A62);
  static const Color textGreenBright = Color(0xFF22C55E);

  // Badge
  static const Color badgeBg = Color(0xFF1C1C1C);

  // UI
  static const Color white = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color grayBg = Color(0xFFECEFF3);  // Figma #ECEFF3

  // === TEXT STYLES — font: Be Vietnam Pro (Figma primary font) ===

  // Greeting section
  static TextStyle get greetingSmall => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF7A8DA3), // Figma #7A8DA3
      );

  static TextStyle get userName => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark, // #01250F
        letterSpacing: -0.1,
      );

  static TextStyle get manageButton => GoogleFonts.beVietnamPro(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get searchPlaceholder => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF7A8DA3),
      );

  // Banner
  static TextStyle get bannerSubtitle => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.85),
      );

  static TextStyle get bannerTitle => GoogleFonts.beVietnamPro(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.3,
      );

  // Tabs
  static TextStyle get tabActive => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get tabInactive => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textGray,
      );

  static TextStyle get filterButtonText => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textDark,
      );

  // Card
  static TextStyle get cardUserName => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get cardTag => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: brandGreen,
      );

  static TextStyle get cardDescription => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get cardAmount => GoogleFonts.beVietnamPro(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textDark,
        letterSpacing: -0.3,
      );

  static TextStyle get cardLabel => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get cardRate => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textGreenBright,
      );

  static TextStyle get cardTerm => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  static TextStyle get badgeText => GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: limeAccent,
      );

  static TextStyle get buttonReceive => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
      );

  static TextStyle get viewAllText => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );
}
