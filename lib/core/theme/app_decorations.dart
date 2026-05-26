import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppDecorations {
  // ── NEUMORPHIC CARD — main card style ──
  static BoxDecoration neuCard({
    double radius = AppSizes.radiusLG,
  }) {
    return BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderFaint),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark,
          offset: const Offset(6, 6),
          blurRadius: 16,
        ),
        BoxShadow(
          color: AppColors.shadowLight,
          offset: const Offset(-4, -4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.04),
          offset: const Offset(0, 1),
          blurRadius: 0,
        ),
      ],
    );
  }

  // ── GLASS CARD ──
  static BoxDecoration glassCard({
    double radius = AppSizes.radiusLG,
    double opacity = 0.045,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark,
          offset: const Offset(4, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: AppColors.shadowLight,
          offset: const Offset(-2, -2),
          blurRadius: 8,
        ),
      ],
    );
  }

  // ── GLASS CARD DARK — for list items ──
  static BoxDecoration glassDark({
    double radius = AppSizes.radiusMD,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.borderFaint),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.3),
          offset: const Offset(2, 2),
          blurRadius: 6,
        ),
      ],
    );
  }

  // ── DISH ICON CONTAINER ──
  static BoxDecoration dishIcon() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.4),
          offset: const Offset(2, 2),
          blurRadius: 6,
        ),
      ],
    );
  }

  // ── PRIMARY BUTTON ──
  static BoxDecoration primaryButton() {
    return BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      boxShadow: [
        BoxShadow(
          color: AppColors.accent.withOpacity(0.1),
          offset: const Offset(0, 4),
          blurRadius: 20,
        ),
        BoxShadow(
          color: AppColors.shadowDark,
          offset: const Offset(4, 4),
          blurRadius: 10,
        ),
      ],
    );
  }

  // ── SECONDARY BUTTON ──
  static BoxDecoration secondaryButton() {
    return BoxDecoration(
      color: AppColors.accent.withOpacity(0.06),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      border: Border.all(color: AppColors.accent.withOpacity(0.15)),
    );
  }

  // ── INSIGHT CARD ──
  static BoxDecoration insightCard() {
    return BoxDecoration(
      color: AppColors.accent.withOpacity(0.025),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(AppSizes.radiusMD),
        bottomRight: Radius.circular(AppSizes.radiusMD),
        bottomLeft: Radius.circular(AppSizes.radiusMD),
      ),
      border: Border(
        left: BorderSide(
          color: AppColors.accent.withOpacity(0.18),
          width: 2,
        ),
        top: BorderSide(
          color: AppColors.accent.withOpacity(0.04),
          width: 1,
        ),
      ),
    );
  }

  // ── INPUT FIELD ──
  static BoxDecoration inputField() {
    return BoxDecoration(
      color: AppColors.accent.withOpacity(0.04),
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      border: Border.all(color: AppColors.borderLight),
    );
  }

  // ── BACKGROUND — main app bg ──
  static BoxDecoration appBackground() {
    return const BoxDecoration(
      color: AppColors.background,
    );
  }

  // ── TAG ──
  static BoxDecoration tag() {
    return BoxDecoration(
      color: AppColors.accent.withOpacity(0.07),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      border: Border.all(color: AppColors.accent.withOpacity(0.1)),
    );
  }

  // ── CAMERA FRAME — corner bracket ──
  static BoxDecoration cameraInner() {
    return BoxDecoration(
      border: Border.all(
        color: AppColors.accent.withOpacity(0.07),
      ),
      borderRadius: BorderRadius.circular(3),
    );
  }

  // ── REGION SELECTED ──
  static BoxDecoration regionSelected() {
    return BoxDecoration(
      color: AppColors.accent.withOpacity(0.92),
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      boxShadow: [
        BoxShadow(
          color: AppColors.accent.withOpacity(0.06),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
      ],
    );
  }

  // ── REGION UNSELECTED ──
  static BoxDecoration regionUnselected() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.3),
          offset: const Offset(4, 4),
          blurRadius: 10,
        ),
        BoxShadow(
          color: AppColors.shadowLight.withOpacity(0.06),
          offset: const Offset(-2, -2),
          blurRadius: 6,
        ),
      ],
    );
  }

  // ── GOAL SELECTED ──
  static BoxDecoration goalSelected() {
    return BoxDecoration(
      color: AppColors.accent.withOpacity(0.92),
      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowDark.withOpacity(0.4),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
      ],
    );
  }

  // ── PERSONALITY CARD ──
  static BoxDecoration personalityCard() {
    return BoxDecoration(
      color: AppColors.accent.withOpacity(0.03),
      borderRadius: BorderRadius.circular(AppSizes.radiusMD),
      border: Border.all(color: AppColors.accent.withOpacity(0.07)),
    );
  }
}
