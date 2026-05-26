import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';


// ── NEU CARD ──────────────────────────────
class NeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? radius;
  final VoidCallback? onTap;

  const NeuCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSizes.paddingMD),
        decoration: AppDecorations.neuCard(
          radius: radius ?? AppSizes.radiusLG,
        ),
        child: child,
      ),
    );
  }
}

// ── GLASS CARD ────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSizes.paddingMD),
        decoration: AppDecorations.glassCard(
          radius: radius ?? AppSizes.radiusLG,
        ),
        child: child,
      ),
    );
  }
}

// ── PRIMARY BUTTON ────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? icon;
  final EdgeInsets? margin;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(top: AppSizes.paddingMD),
      width: double.infinity,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXL,
            vertical: AppSizes.paddingMD + 2,
          ),
          decoration: AppDecorations.primaryButton(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              else ...[
                if (icon != null) ...[
                  icon!,
                  const SizedBox(width: 8),
                ],
                Text(label, style: AppTextStyles.buttonPrimary()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── SECONDARY BUTTON ──────────────────────
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final EdgeInsets? margin;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(top: AppSizes.paddingMD),
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXL,
            vertical: AppSizes.paddingMD + 2,
          ),
          decoration: AppDecorations.secondaryButton(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.buttonSecondary()),
            ],
          ),
        ),
      ),
    );
  }
}

// ── LABEL TEXT ────────────────────────────
class LabelText extends StatelessWidget {
  final String text;
  final Color? color;

  const LabelText(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.label(color: color),
    );
  }
}

// ── STEP INDICATOR ────────────────────────
class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final done = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
            height: 2,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.accent.withValues(alpha: 0.7)
                  : AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}

// ── DISH ICON ─────────────────────────────
class DishIcon extends StatelessWidget {
  final String iconType;

  const DishIcon({super.key, required this.iconType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.dishIconSize,
      height: AppSizes.dishIconSize,
      decoration: AppDecorations.dishIcon(),
      child: Center(
        child: CustomPaint(
          size: const Size(AppSizes.dishIconInner, AppSizes.dishIconInner),
          painter: _DishIconPainter(iconType: iconType),
        ),
      ),
    );
  }
}

class _DishIconPainter extends CustomPainter {
  final String iconType;
  _DishIconPainter({required this.iconType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    switch (iconType) {
      case 'rice':
        _drawRice(canvas, size, paint);
        break;
      case 'curry':
      case 'dal':
        _drawCurry(canvas, size, paint);
        break;
      case 'roti':
        _drawRoti(canvas, size, paint);
        break;
      case 'fish':
        _drawFish(canvas, size, paint);
        break;
      case 'chicken':
        _drawChicken(canvas, size, paint);
        break;
      case 'egg':
        _drawEgg(canvas, size, paint);
        break;
      case 'sabzi':
        _drawSabzi(canvas, size, paint);
        break;
      case 'chai':
        _drawChai(canvas, size, paint);
        break;
      case 'snack':
        _drawSnack(canvas, size, paint);
        break;
      case 'biryani':
        _drawBiryani(canvas, size, paint);
        break;
      default:
        _drawPlate(canvas, size, paint);
    }
  }

  void _drawRice(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final oval = Rect.fromLTWH(w * 0.1, h * 0.6, w * 0.8, h * 0.35);
    canvas.drawArc(oval, 0, 3.14159, false, paint);
    canvas.drawLine(Offset(w * 0.1, h * 0.6), Offset(w * 0.1, h * 0.45), paint);
    canvas.drawLine(Offset(w * 0.9, h * 0.6), Offset(w * 0.9, h * 0.45), paint);
    canvas.drawLine(Offset(w * 0.1, h * 0.45), Offset(w * 0.9, h * 0.45), paint);
    final dotPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.35, h * 0.35), 1.2, dotPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.28), 1.2, dotPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.35), 1.2, dotPaint);
  }

  void _drawCurry(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.15, h * 0.4);
    path.lineTo(w * 0.25, h * 0.8);
    path.quadraticBezierTo(w * 0.5, h * 0.9, w * 0.75, h * 0.8);
    path.lineTo(w * 0.85, h * 0.4);
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(w * 0.15, h * 0.4), Offset(w * 0.85, h * 0.4), paint);
    final steamPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.4, h * 0.35), Offset(w * 0.38, h * 0.2), steamPaint);
    canvas.drawLine(Offset(w * 0.6, h * 0.35), Offset(w * 0.62, h * 0.2), steamPaint);
  }

  void _drawRoti(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.55), width: w * 0.75, height: h * 0.45),
        paint);
    final innerPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.55), width: w * 0.45, height: h * 0.28),
        innerPaint);
  }

  void _drawFish(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.1, h * 0.5);
    path.quadraticBezierTo(w * 0.3, h * 0.25, w * 0.75, h * 0.38);
    path.quadraticBezierTo(w * 0.85, h * 0.5, w * 0.75, h * 0.62);
    path.quadraticBezierTo(w * 0.3, h * 0.75, w * 0.1, h * 0.5);
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(w * 0.75, h * 0.38), Offset(w * 0.95, h * 0.25), paint);
    canvas.drawLine(Offset(w * 0.75, h * 0.62), Offset(w * 0.95, h * 0.75), paint);
    final eyePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.28, h * 0.5), 1.5, eyePaint);
  }

  void _drawChicken(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.3, h * 0.75);
    path.quadraticBezierTo(w * 0.2, h * 0.55, w * 0.35, h * 0.35);
    path.quadraticBezierTo(w * 0.55, h * 0.2, w * 0.7, h * 0.35);
    path.quadraticBezierTo(w * 0.8, h * 0.55, w * 0.65, h * 0.75);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.75), Offset(w * 0.5, h * 0.9), paint);
  }

  void _drawEgg(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, h * 0.15);
    path.cubicTo(w * 0.85, h * 0.15, w * 0.9, h * 0.5, w * 0.85, h * 0.7);
    path.cubicTo(w * 0.8, h * 0.9, w * 0.2, h * 0.9, w * 0.15, h * 0.7);
    path.cubicTo(w * 0.1, h * 0.5, w * 0.15, h * 0.15, w * 0.5, h * 0.15);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.6),
        w * 0.18,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  void _drawSabzi(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(w * 0.5, h * 0.85), Offset(w * 0.5, h * 0.3), paint);
    final path1 = Path();
    path1.moveTo(w * 0.5, h * 0.85);
    path1.quadraticBezierTo(w * 0.2, h * 0.55, w * 0.35, h * 0.3);
    path1.quadraticBezierTo(w * 0.5, h * 0.4, w * 0.5, h * 0.85);
    canvas.drawPath(path1, paint);
    final path2 = Path();
    path2.moveTo(w * 0.5, h * 0.85);
    path2.quadraticBezierTo(w * 0.8, h * 0.55, w * 0.65, h * 0.3);
    path2.quadraticBezierTo(w * 0.5, h * 0.4, w * 0.5, h * 0.85);
    canvas.drawPath(path2, paint);
  }

  void _drawChai(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.2, h * 0.3);
    path.lineTo(w * 0.3, h * 0.8);
    path.quadraticBezierTo(w * 0.5, h * 0.88, w * 0.7, h * 0.8);
    path.lineTo(w * 0.8, h * 0.3);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawArc(
        Rect.fromLTWH(w * 0.7, h * 0.4, w * 0.2, h * 0.3), -1.57, 3.14, false, paint);
  }

  void _drawSnack(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.15, h * 0.3, w * 0.7, h * 0.4),
            const Radius.circular(4)),
        paint);
    final dotPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.35, h * 0.45), 1.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), 1.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.45), 1.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.58), 1.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.58), 1.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.65, h * 0.58), 1.0, dotPaint);
  }

  void _drawBiryani(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.15, h * 0.45);
    path.lineTo(w * 0.25, h * 0.82);
    path.quadraticBezierTo(w * 0.5, h * 0.92, w * 0.75, h * 0.82);
    path.lineTo(w * 0.85, h * 0.45);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(w * 0.12, h * 0.45), Offset(w * 0.88, h * 0.45), paint);
    canvas.drawArc(
        Rect.fromLTWH(w * 0.15, h * 0.22, w * 0.7, h * 0.3), 3.14159, 3.14159, false, paint);
  }

  void _drawPlate(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.4, paint);
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.5),
        w * 0.25,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── TAG WIDGET ────────────────────────────
class TagWidget extends StatelessWidget {
  final String text;

  const TagWidget(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: 3,
      ),
      decoration: AppDecorations.tag(),
      child: Text(text.toUpperCase(), style: AppTextStyles.tag()),
    );
  }
}

// ── INSIGHT CARD ─────────────────────────
class InsightCard extends StatelessWidget {
  final String insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: AppDecorations.insightCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI INSIGHT',
            style: AppTextStyles.label(
              color: AppColors.accent.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppSizes.paddingXS),
          Text(
            insight,
            style: AppTextStyles.insight(),
          ),
        ],
      ),
    );
  }
}

// ── MEAL ITEM ROW ─────────────────────────
class MealItemRow extends StatelessWidget {
  final String dishName;
  final String timeLabel;
  final String calorieRange;
  final String iconType;
  final String proteinRange;

  const MealItemRow({
    super.key,
    required this.dishName,
    required this.timeLabel,
    required this.calorieRange,
    required this.iconType,
    this.proteinRange = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical: AppSizes.paddingSM + 2,
      ),
      decoration: AppDecorations.glassDark(),
      child: Row(
        children: [
          DishIcon(iconType: iconType),
          const SizedBox(width: AppSizes.paddingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dishName,
                  style: AppTextStyles.dishName(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel.toUpperCase(),
                  style: AppTextStyles.dishSub(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.paddingSM),
          Text(
            calorieRange,
            style: AppTextStyles.calorieRange(),
          ),
        ],
      ),
    );
  }
}

// ── BUDGET PROGRESS BAR ───────────────────
class BudgetProgressBar extends StatelessWidget {
  final int used;
  final int total;

  const BudgetProgressBar({
    super.key,
    required this.used,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.accent.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.accent.withValues(alpha: 0.65),
            ),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$used USED',
              style: AppTextStyles.label(
                color: AppColors.accent.withValues(alpha: 0.45),
              ),
            ),
            Text(
              '$total TOTAL',
              style: AppTextStyles.label(
                color: AppColors.accent.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── STAR BACKGROUND ───────────────────────
class StarBackground extends StatelessWidget {
  final Widget child;

  const StarBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _StarPainter(),
          ),
        ),
        child,
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Offset> _stars = const [
    Offset(0.13, 0.06),
    Offset(0.87, 0.04),
    Offset(0.46, 0.13),
    Offset(0.79, 0.18),
    Offset(0.18, 0.25),
    Offset(0.92, 0.32),
    Offset(0.34, 0.48),
    Offset(0.69, 0.08),
    Offset(0.95, 0.45),
    Offset(0.06, 0.55),
    Offset(0.51, 0.58),
    Offset(0.85, 0.68),
    Offset(0.23, 0.75),
    Offset(0.63, 0.82),
    Offset(0.40, 0.88),
    Offset(0.82, 0.92),
    Offset(0.14, 0.92),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _stars.length; i++) {
      final opacity = 0.15 + (i % 3) * 0.08;
      paint.color = AppColors.accent.withValues(alpha: opacity);
      final radius = 0.7 + (i % 2) * 0.4;
      canvas.drawCircle(
        Offset(_stars[i].dx * size.width, _stars[i].dy * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── LOADING OVERLAY ───────────────────────
class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, this.message = 'Analysing...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              message.toUpperCase(),
              style: AppTextStyles.label(),
            ),
          ],
        ),
      ),
    );
  }
}