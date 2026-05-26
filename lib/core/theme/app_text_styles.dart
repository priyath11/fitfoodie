import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTextStyles {
  // ── LOGO FONT — Playfair Display ──
  static TextStyle logoHero({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: AppSizes.fontHero,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -1.0,
    );
  }

  static TextStyle logoLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: AppSizes.fontXXL,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle logoMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: AppSizes.fontXL,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -0.3,
    );
  }

  static TextStyle logoSmall({Color color = AppColors.textPrimary}) {
    return GoogleFonts.playfairDisplay(
      fontSize: AppSizes.fontMD,
      fontWeight: FontWeight.w900,
      color: color,
    );
  }

  // ── NUNITO — Body system ──
  static TextStyle displayLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontDisplay,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -1.5,
    );
  }

  static TextStyle displayMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontHuge,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.8,
    );
  }

  static TextStyle headingLarge({Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontXXL,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle headingMedium({Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontXL,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.3,
    );
  }

  // FIXED: bodyLarge — was too dim
  static TextStyle bodyLarge({Color color = AppColors.textSecondary}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontLG,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  // FIXED: bodyMedium — increased visibility
  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontMD,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.6,
    );
  }

  // FIXED: bodySmall — increased from textMuted to a more visible color
  static TextStyle bodySmall({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontSM,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.accent.withOpacity(0.65),
      height: 1.6,
    );
  }

  // FIXED: label — was almost invisible
  static TextStyle label({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontXS + 1,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.accent.withOpacity(0.55),
      letterSpacing: AppSizes.letterSpacingLabel,
    );
  }

  static TextStyle buttonPrimary() {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontSM,
      fontWeight: FontWeight.w800,
      color: Colors.black,
      letterSpacing: AppSizes.letterSpacingBtn,
    );
  }

  static TextStyle buttonSecondary() {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontSM,
      fontWeight: FontWeight.w700,
      color: AppColors.accent.withOpacity(0.85),
      letterSpacing: AppSizes.letterSpacingBtn,
    );
  }

  static TextStyle calorie({Color color = AppColors.accent}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontDisplay,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -1.5,
    );
  }

  static TextStyle stat({Color color = AppColors.accent}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontXXL,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.5,
    );
  }

  static TextStyle dishName({Color color = AppColors.textPrimary}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontSM,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  // FIXED: dishSub — more visible
  static TextStyle dishSub({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontXS + 1,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.accent.withOpacity(0.55),
      letterSpacing: 0.5,
    );
  }

  static TextStyle calorieRange({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontSM,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.accent.withOpacity(0.8),
    );
  }

  // FIXED: insight — more readable
  static TextStyle insight({Color? color}) {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontSM,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.accent.withOpacity(0.65),
      height: 1.7,
    );
  }

  static TextStyle tag() {
    return GoogleFonts.nunito(
      fontSize: 8,
      fontWeight: FontWeight.w700,
      color: AppColors.accent.withOpacity(0.7),
      letterSpacing: 0.5,
    );
  }

  // NEW: input text
  static TextStyle inputText() {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontLG,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  // NEW: input hint
  static TextStyle inputHint() {
    return GoogleFonts.nunito(
      fontSize: AppSizes.fontLG,
      fontWeight: FontWeight.w400,
      color: AppColors.accent.withOpacity(0.35),
    );
  }
}