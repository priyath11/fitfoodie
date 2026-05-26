import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFF1A2332);
  static const Color backgroundDark = Color(0xFF131D2B);
  static const Color backgroundDeep = Color(0xFF0E1520);

  // Cards
  static const Color cardLight = Color(0xFF1E2A3C);
  static const Color cardDark = Color(0xFF141C28);

  // Accent — Warm White
  static const Color accent = Color(0xFFF5F0E8);
  static const Color accentDim = Color(0xB3F5F0E8);    // 70% — was 50%
  static const Color accentFaint = Color(0x1AF5F0E8);

  // Text — FIXED VISIBILITY
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xCCFFFFFF);  // 80% — was 60%
  static const Color textMuted = Color(0x99FFFFFF);      // 60% — was 25%
  static const Color textLabel = Color(0x80F5F0E8);      // 50% — was 20%
  static const Color textHint = Color(0x66F5F0E8);       // 40%

  // Borders
  static const Color borderLight = Color(0x1FFFFFFF);    // slightly more visible
  static const Color borderFaint = Color(0x0FFFFFFF);

  // Shadows
  static const Color shadowDark = Color(0xCC0A0E16);
  static const Color shadowLight = Color(0x1A283C5A);

  // Status
  static const Color success = Color(0x99F5F0E8);
  static const Color error = Color(0xCCFF6B6B);

  // Transparent
  static const Color transparent = Colors.transparent;
}