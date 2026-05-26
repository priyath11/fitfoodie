// ─────────────────────────────────────────
// WEEKLY SCREEN
// ─────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_decorations.dart';
import '../../providers/providers.dart';
import '../widgets/common_widgets.dart';

class WeeklyScreen extends ConsumerStatefulWidget {
  const WeeklyScreen({super.key});

  @override
  ConsumerState<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends ConsumerState<WeeklyScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = await ref.read(currentUserProvider.future);
      if (user != null) {
        ref.read(weeklyViewModelProvider.notifier).loadWeeklyData(user);
        _ringController.forward();
      }
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  String _getWeekDateRange() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[monday.month - 1]} ${monday.day} — ${months[sunday.month - 1]} ${sunday.day}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weeklyViewModelProvider);

    return StarBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingXXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingXL),

              // Header
              Text(AppStrings.thisWeek, style: AppTextStyles.logoLarge()),
              LabelText(_getWeekDateRange()),

              const SizedBox(height: AppSizes.paddingXL),

              // Ring chart
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                decoration: AppDecorations.neuCard(),
                child: Column(
                  children: [
                    LabelText(AppStrings.weeklyCalories),
                    const SizedBox(height: AppSizes.paddingMD),
                    AnimatedBuilder(
                      animation: _ringAnimation,
                      builder: (context, child) {
                        return _WeeklyRing(
                          used: state.weeklyBudget?.usedCalories ?? 0,
                          total: state.weeklyBudget?.totalBudget ?? 13300,
                          progress: _ringAnimation.value *
                              (state.weeklyBudget?.usedPercentage ?? 0),
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                    TagWidget(
                      state.weeklyBudget?.isUnderBudget == true
                          ? '${AppStrings.underBudget} ✓'
                          : 'Over budget',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingSM),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMD),
                      decoration: AppDecorations.glassCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LabelText(AppStrings.daysLogged),
                          const SizedBox(height: AppSizes.paddingXS),
                          Text(
                            '${state.daysLogged}/7',
                            style: AppTextStyles.stat(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSM),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMD),
                      decoration: AppDecorations.glassCard(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LabelText(AppStrings.avgProtein),
                          const SizedBox(height: AppSizes.paddingXS),
                          Text(
                            '${state.avgProtein}g',
                            style: AppTextStyles.stat(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingSM),

              // Bar chart
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                decoration: AppDecorations.neuCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabelText(AppStrings.dailyBreakdown),
                    const SizedBox(height: AppSizes.paddingMD),
                    _DailyBarChart(dailyCalories: state.dailyCalories),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingSM),

              // Weekly insight
              if (state.weeklyInsight.isNotEmpty)
                InsightCard(insight: state.weeklyInsight),

              const SizedBox(height: AppSizes.paddingXXL),
            ],
          ),
        ),
      ),
    );
  }
}

// ── WEEKLY RING ───────────────────────────
class _WeeklyRing extends StatelessWidget {
  final int used;
  final int total;
  final double progress;

  const _WeeklyRing({
    required this.used,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(140, 140),
      painter: _RingPainter(progress: progress.clamp(0.0, 1.0)),
      child: SizedBox(
        width: 140,
        height: 140,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                used.toString(),
                style: AppTextStyles.stat(),
              ),
              Text(
                'of $total kcal',
                style: AppTextStyles.label(
                    color: AppColors.accent.withOpacity(0.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.accent.withOpacity(0.04)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke,
    );

    // Glow ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 degrees
      progress * 2 * 3.14159,
      false,
      Paint()
        ..color = AppColors.accent.withOpacity(0.07)
        ..strokeWidth = 16
        ..style = PaintingStyle.stroke,
    );

    // Progress ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress * 2 * 3.14159,
      false,
      Paint()
        ..color = AppColors.accent.withOpacity(0.55)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ── DAILY BAR CHART ───────────────────────
class _DailyBarChart extends StatelessWidget {
  final List<int> dailyCalories;

  const _DailyBarChart({required this.dailyCalories});

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxCalorie =
        dailyCalories.isEmpty ? 1 : dailyCalories.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final calories = i < dailyCalories.length ? dailyCalories[i] : 0;
        final heightFactor =
            maxCalorie > 0 ? (calories / maxCalorie) : 0.0;

        return Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 400 + i * 80),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    height: 52 * heightFactor.clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(
                          calories > 0 ? 0.42 : 0.07),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                days[i],
                style: AppTextStyles.label(
                    color: AppColors.accent.withOpacity(0.18)),
              ),
            ],
          ),
        );
      }),
    );
  }
}
