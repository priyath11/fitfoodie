import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        background: AppColors.background,
        surface: AppColors.cardLight,
        primary: AppColors.accent,
        secondary: AppColors.accentDim,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onPrimary: Colors.black,
      ),

      // Text theme — Nunito
      textTheme: GoogleFonts.nunitoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontHero,
            fontWeight: FontWeight.w900,
            letterSpacing: AppSizes.letterSpacingTight,
          ),
          displayMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontDisplay,
            fontWeight: FontWeight.w800,
            letterSpacing: AppSizes.letterSpacingTight,
          ),
          headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontXXL,
            fontWeight: FontWeight.w800,
            letterSpacing: AppSizes.letterSpacingTight,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontXL,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontLG,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontLG,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: AppColors.textMuted,
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            color: AppColors.textLabel,
            fontSize: AppSizes.fontXS,
            fontWeight: FontWeight.w600,
            letterSpacing: AppSizes.letterSpacingLabel,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.accentFaint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLG,
          vertical: AppSizes.paddingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          borderSide: const BorderSide(
            color: AppColors.accent,
            width: 1.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          borderSide: const BorderSide(color: Color(0x80FF6B6B)),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: AppSizes.fontLG,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: AppSizes.fontLG,
        ),
      ),

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontXL,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xE6141C28),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXXL,
            vertical: AppSizes.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w800,
            letterSpacing: AppSizes.letterSpacingBtn,
          ),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXXL,
            vertical: AppSizes.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w700,
            letterSpacing: AppSizes.letterSpacingBtn,
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.borderFaint,
        thickness: 1,
      ),

      // Snack bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardLight,
        contentTextStyle: GoogleFonts.nunito(
          color: AppColors.textPrimary,
          fontSize: AppSizes.fontMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
