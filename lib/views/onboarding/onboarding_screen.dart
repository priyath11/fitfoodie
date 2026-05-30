import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../widgets/common_widgets.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StarBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0.04, 0), end: Offset.zero)
                    .animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: _buildStep(state.currentStep),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0: return const _GoalStep(key: ValueKey('goal'));
      case 1: return const _DietStep(key: ValueKey('diet'));
      case 2: return const _GenderStep(key: ValueKey('gender'));
      case 3: return const _WeightStep(key: ValueKey('weight'));
      default: return const _GoalStep(key: ValueKey('goal'));
    }
  }
}

// ── SHARED HEADER ─────────────────────────
class _OnboardingHeader extends ConsumerWidget {
  final String stepLabel;
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;

  const _OnboardingHeader({
    required this.stepLabel,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (currentStep > 0)
              GestureDetector(
                onTap: () => ref
                    .read(onboardingViewModelProvider.notifier)
                    .previousStep(),
                child: Container(
                  width: 36, height: 36,
                  decoration: AppDecorations.dishIcon(),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.accent.withValues(alpha: 0.7)),
                ),
              )
            else
              const SizedBox(width: 36),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.restaurant_outlined,
                    size: 12, color: AppColors.accent.withValues(alpha: 0.3)),
                const SizedBox(width: 5),
                Text('Fit Foodie',
                    style: AppTextStyles.logoSmall(
                        color: AppColors.accent.withValues(alpha: 0.3))),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingXL),
        StepIndicator(totalSteps: totalSteps, currentStep: currentStep),
        const SizedBox(height: AppSizes.paddingXS),
        Text(stepLabel, style: AppTextStyles.label()),
        const SizedBox(height: AppSizes.paddingXL),
        Text(title, style: AppTextStyles.headingMedium()),
        const SizedBox(height: AppSizes.paddingSM),
        Text(subtitle,
            style: AppTextStyles.bodySmall(
                color: AppColors.accent.withValues(alpha: 0.6))),
      ],
    );
  }
}

// ── CONTINUE BUTTON ───────────────────────
class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _ContinueButton({required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMD + 2),
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          boxShadow: enabled
              ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 4))]
              : null,
        ),
        child: Text(
          'CONTINUE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: enabled ? Colors.black : AppColors.accent.withValues(alpha: 0.3),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── STEP 1 — GOAL ─────────────────────────
class _GoalStep extends ConsumerWidget {
  const _GoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);

    final goals = [
      {'id': 'lose_fat', 'title': 'Lose some fat', 'sub': 'Gradual and sustainable', 'icon': Icons.local_fire_department_outlined},
      {'id': 'stay_fit', 'title': 'Stay fit and healthy', 'sub': 'Maintain energy and weight', 'icon': Icons.bolt_outlined},
      {'id': 'build_muscle', 'title': 'Build muscle', 'sub': 'Strength and protein focus', 'icon': Icons.fitness_center_outlined},
      {'id': 'curious', 'title': 'Just curious', 'sub': 'Know my numbers', 'icon': Icons.restaurant_outlined},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingXXL, AppSizes.paddingXL, AppSizes.paddingXXL, AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingHeader(stepLabel: 'STEP 01 OF 04', currentStep: 0, totalSteps: 4,
              title: "What's your goal?", subtitle: "We build your personal calorie budget around this."),
          const SizedBox(height: AppSizes.paddingXL),
          ...goals.map((g) {
            final sel = state.data.goal == g['id'];
            return GestureDetector(
              onTap: () => vm.setGoal(g['id'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingSM),
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                decoration: sel ? AppDecorations.goalSelected() : AppDecorations.neuCard(),
                child: Row(
                  children: [
                    Icon(g['icon'] as IconData, size: 22,
                        color: sel ? Colors.black : AppColors.accent.withValues(alpha: 0.7)),
                    const SizedBox(width: AppSizes.paddingMD),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g['title'] as String, style: AppTextStyles.bodyLarge(color: sel ? Colors.black : AppColors.textPrimary)),
                      Text(g['sub'] as String, style: AppTextStyles.bodySmall(color: sel ? Colors.black54 : AppColors.accent.withValues(alpha: 0.55))),
                    ])),
                    if (sel) Container(width: 20, height: 20,
                        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 13, color: AppColors.accent)),
                  ],
                ),
              ),
            );
          }),
          if (state.data.goal.isNotEmpty) ...[
            const SizedBox(height: AppSizes.paddingSM),
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              decoration: AppDecorations.personalityCard(),
              child: Text(vm.getPersonalityResponse(),
                  style: AppTextStyles.bodySmall(color: AppColors.accent.withValues(alpha: 0.75))),
            ),
          ],
          const SizedBox(height: AppSizes.paddingXL),
          _ContinueButton(
            enabled: state.data.goal.isNotEmpty,
            onTap: () => ref.read(onboardingViewModelProvider.notifier).nextStep(),
          ),
        ],
      ),
    );
  }
}

// ── STEP 2 — REGION ───────────────────────
class _RegionStep extends ConsumerWidget {
  const _RegionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);

    final regions = [
      {'id': 'North India', 'title': 'North India', 'icon': '🌾'},
      {'id': 'South India', 'title': 'South India', 'icon': '🥥'},
      {'id': 'East India', 'title': 'East India', 'icon': '🐟'},
      {'id': 'West India', 'title': 'West India', 'icon': '🫓'},
      {'id': 'Mixed', 'title': 'Mixed', 'icon': '🍱'},
      {'id': 'Other', 'title': 'Other', 'icon': '🌍'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingXXL, AppSizes.paddingXL, AppSizes.paddingXXL, AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingHeader(stepLabel: 'STEP 02 OF 04', currentStep: 1, totalSteps: 4,
              title: 'Where are you from?', subtitle: "We load the right food database for your region."),
          const SizedBox(height: AppSizes.paddingXL),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.paddingSM, mainAxisSpacing: AppSizes.paddingSM,
            childAspectRatio: 1.6,
            children: regions.map((r) {
              final sel = state.data.region == r['id'];
              return GestureDetector(
                onTap: () => vm.setRegion(r['id'] as String),
                child: Container(
                  decoration: sel ? AppDecorations.regionSelected() : AppDecorations.regionUnselected(),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(r['icon'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(r['title'] as String,
                        style: AppTextStyles.bodySmall(color: sel ? Colors.black : AppColors.accent.withValues(alpha: 0.75)),
                        textAlign: TextAlign.center),
                    if (sel) ...[
                      const SizedBox(height: 4),
                      Container(width: 16, height: 16,
                          decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 10, color: AppColors.accent)),
                    ],
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.paddingXL),
          _ContinueButton(
            enabled: state.data.dietType.isNotEmpty,
            onTap: () => ref.read(onboardingViewModelProvider.notifier).nextStep(),
          ),
        ],
      ),
    );
  }
}

// ── STEP 3 — DIET ─────────────────────────
class _DietStep extends ConsumerWidget {
  const _DietStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);

    final diets = [
      {'id': 'vegetarian', 'title': 'Vegetarian', 'sub': 'Dal, paneer, sabzi', 'icon': '🌱'},
      {'id': 'eggetarian', 'title': 'Eggetarian', 'sub': 'Veg + eggs', 'icon': '🥚'},
      {'id': 'non_veg', 'title': 'Non-vegetarian', 'sub': 'Chicken, fish, meat', 'icon': '🍗'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingXXL, AppSizes.paddingXL, AppSizes.paddingXXL, AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingHeader(stepLabel: 'STEP 03 OF 04', currentStep: 2, totalSteps: 4,
              title: 'How do you eat?', subtitle: 'Helps us personalise your protein goals.'),
          const SizedBox(height: AppSizes.paddingXXL),
          ...diets.map((d) {
            final sel = state.data.dietType == d['id'];
            return GestureDetector(
              onTap: () => vm.setDietType(d['id'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingSM),
                padding: const EdgeInsets.all(AppSizes.paddingMD),
                decoration: sel ? AppDecorations.goalSelected() : AppDecorations.neuCard(),
                child: Row(
                  children: [
                    Text(d['icon'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSizes.paddingMD),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['title'] as String, style: AppTextStyles.bodyLarge(color: sel ? Colors.black : AppColors.textPrimary)),
                      Text(d['sub'] as String, style: AppTextStyles.bodySmall(color: sel ? Colors.black54 : AppColors.accent.withValues(alpha: 0.55))),
                    ])),
                    if (sel) Container(width: 20, height: 20,
                        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 13, color: AppColors.accent)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSizes.paddingXL),
          _ContinueButton(
            enabled: state.data.dietType.isNotEmpty,
            onTap: () => ref.read(onboardingViewModelProvider.notifier).nextStep(),
          ),
        ],
      ),
    );
  }
}

// ── STEP 4 — GENDER ───────────────────────
class _GenderStep extends ConsumerWidget {
  const _GenderStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingViewModelProvider);
    final vm = ref.read(onboardingViewModelProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingXXL, AppSizes.paddingXL, AppSizes.paddingXXL, AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingHeader(stepLabel: 'STEP 04 OF 04', currentStep: 3, totalSteps: 4,
              title: 'Tell us about you', subtitle: 'Calorie needs differ by gender. This ensures accuracy.'),
          const SizedBox(height: AppSizes.paddingXXL),
          Text('GENDER', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingMD),
          Row(
            children: [
              Expanded(child: GestureDetector(
                onTap: () => vm.setGender('male'),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingLG),
                  decoration: state.data.gender == 'male' ? AppDecorations.goalSelected() : AppDecorations.neuCard(),
                  child: Column(children: [
                    Icon(Icons.male_rounded, size: 36,
                        color: state.data.gender == 'male' ? Colors.black : AppColors.accent.withValues(alpha: 0.6)),
                    const SizedBox(height: AppSizes.paddingSM),
                    Text('Male', style: AppTextStyles.bodyLarge(
                        color: state.data.gender == 'male' ? Colors.black : AppColors.textPrimary)),
                  ]),
                ),
              )),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(child: GestureDetector(
                onTap: () => vm.setGender('female'),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.paddingLG),
                  decoration: state.data.gender == 'female' ? AppDecorations.goalSelected() : AppDecorations.neuCard(),
                  child: Column(children: [
                    Icon(Icons.female_rounded, size: 36,
                        color: state.data.gender == 'female' ? Colors.black : AppColors.accent.withValues(alpha: 0.6)),
                    const SizedBox(height: AppSizes.paddingSM),
                    Text('Female', style: AppTextStyles.bodyLarge(
                        color: state.data.gender == 'female' ? Colors.black : AppColors.textPrimary)),
                  ]),
                ),
              )),
            ],
          ),
          const SizedBox(height: AppSizes.paddingXL),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: AppDecorations.personalityCard(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('WHY WE ASK', style: AppTextStyles.label()),
              const SizedBox(height: AppSizes.paddingXS),
              Text(
                'Men and women have different Basal Metabolic Rates. Using the Harris-Benedict formula, your gender helps us calculate exactly how many calories your body needs — making your budget far more accurate.',
                style: AppTextStyles.bodySmall(color: AppColors.accent.withValues(alpha: 0.65)),
              ),
            ]),
          ),
          const SizedBox(height: AppSizes.paddingXL),
          _ContinueButton(
            enabled: state.data.gender.isNotEmpty,
            onTap: () => ref.read(onboardingViewModelProvider.notifier).nextStep(),
          ),
        ],
      ),
    );
  }
}

// ── STEP 5 — WEIGHT + DATE ────────────────
class _WeightStep extends ConsumerStatefulWidget {
  const _WeightStep({super.key});

  @override
  ConsumerState<_WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends ConsumerState<_WeightStep> {
  late TextEditingController _currentCtrl;
  late TextEditingController _targetCtrl;
  late TextEditingController _ageCtrl;
  DateTime? _targetDate;
  String? _currentErr;
  String? _targetErr;
  String? _dateErr;

  @override
  void initState() {
    super.initState();
    final d = ref.read(onboardingViewModelProvider).data;
    _currentCtrl = TextEditingController(text: d.currentWeight.toStringAsFixed(1));
    _targetCtrl = TextEditingController(text: d.targetWeight.toStringAsFixed(1));
    _ageCtrl = TextEditingController(text: '28');
    _targetDate = DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _targetCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 14)),
      lastDate: now.add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.black,
            surface: AppColors.cardLight,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _targetDate = picked; _dateErr = null; });
    }
  }

  // ── HARRIS-BENEDICT + RANGES ──
  _BudgetResult _calculate() {
    final current = double.tryParse(_currentCtrl.text) ?? 70;
    final target = double.tryParse(_targetCtrl.text) ?? 65;
    final age = int.tryParse(_ageCtrl.text) ?? 28;
    final state = ref.read(onboardingViewModelProvider);
    final gender = state.data.gender;
    final goal = state.data.goal;

    double bmr;
    if (gender == 'male') {
      bmr = 88.362 + (13.397 * current) + (4.799 * 170) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * current) + (3.098 * 157) - (4.330 * age);
    }
    final tdee = bmr * 1.375;

    // Protein range: 1.6–2.0g per kg bodyweight
    final proteinMin = (current * 1.6).round();
    final proteinMax = (current * 2.0).round();

    final daysToGoal = _targetDate != null
        ? _targetDate!.difference(DateTime.now()).inDays
        : 90;
    final weeksToGoal = (daysToGoal / 7).round();

    double dailyCalMin;
    double dailyCalMax;
    double kgPerWeek = 0;
    bool isSafe = true;
    String safetyNote;
    String goalExplanation;
    String deficitLabel;

    switch (goal) {
      case 'lose_fat':
        final weightToLose = (current - target).abs();
        final totalDeficit = weightToLose * 7700;
        final dailyDeficitNeeded = totalDeficit / daysToGoal;

        if (dailyDeficitNeeded > 1000) {
          isSafe = false;
          dailyCalMin = tdee - 800;
          dailyCalMax = tdee - 650;
          final minW = (weightToLose * 7700 / 750 / 7).ceil();
          safetyNote = 'Timeline too aggressive. We recommend at least $minW weeks for safe fat loss.';
        } else if (dailyDeficitNeeded > 500) {
          isSafe = true;
          dailyCalMin = tdee - dailyDeficitNeeded - 50;
          dailyCalMax = tdee - dailyDeficitNeeded + 100;
          safetyNote = 'Aggressive but achievable. Stay consistent, sleep well, stay hydrated.';
        } else {
          isSafe = true;
          dailyCalMin = tdee - dailyDeficitNeeded - 50;
          dailyCalMax = tdee - dailyDeficitNeeded + 100;
          safetyNote = 'Perfect timeline. Gradual and sustainable — the best approach.';
        }
        kgPerWeek = (dailyDeficitNeeded * 7 / 7700);
        deficitLabel = 'DAILY DEFICIT';
        final dAmt = dailyDeficitNeeded.round();
        final dMin = dailyCalMin.round();
        final dMax = dailyCalMax.round();
        goalExplanation =
        'HOW FAT LOSS WORKS\n\n'
            'Fat is lost when you eat less than you burn. Your body uses stored fat as fuel.\n\n'
            'YOUR PLAN\n'
            'Daily calories: $dMin - $dMax kcal\n'
            'Daily deficit: $dAmt kcal below maintenance\n'
            'Loss rate: ${kgPerWeek.toStringAsFixed(2)} kg per week\n'
            'Protein: $proteinMin - ${proteinMax}g per day (preserves muscle while losing fat)\n\n'
            'WHAT TO FOCUS ON\n'
            'Eat high protein — chicken, fish, dal, eggs, paneer\n'
            'Never skip meals — it slows your metabolism\n'
            'Your weekly budget gives flexibility — balance big meals across the week\n'
            'Sleep 7-8 hours — poor sleep makes fat loss much harder';
        break;

      case 'build_muscle':
      // SURPLUS — must be crystal clear it is NOT a deficit
        dailyCalMin = tdee + 200;
        dailyCalMax = tdee + 350;
        isSafe = true;
        deficitLabel = 'DAILY SURPLUS';
        final bMin = dailyCalMin.round();
        final bMax = dailyCalMax.round();
        safetyNote = 'You eat MORE than you burn. This is a SURPLUS — not a deficit. Extra calories fuel muscle growth.';
        goalExplanation =
        'HOW MUSCLE BUILDING WORKS\n\n'
            'Muscle is built when you train hard AND eat enough. You must eat MORE than you burn — this is called a calorie surplus.\n\n'
            'YOUR PLAN\n'
            'Daily calories: $bMin - $bMax kcal (above your maintenance of ${tdee.round()} kcal)\n'
            'Daily surplus: 200 - 350 kcal MORE than what you burn\n'
            'Protein: $proteinMin - ${proteinMax}g per day (non-negotiable for muscle)\n\n'
            'WHAT TO FOCUS ON\n'
            'Hit your protein every day — chicken, eggs, paneer, dal, fish\n'
            'Strength train 3-4 days a week — without training, extra calories become fat\n'
            'Eat your largest meal after your workout\n'
            'Dal + rice together is a complete protein — eat it daily\n'
            'Be patient — visible muscle takes 8-12 weeks minimum';
        break;

      case 'stay_fit':
        dailyCalMin = tdee - 100;
        dailyCalMax = tdee + 100;
        isSafe = true;
        deficitLabel = 'DAILY RANGE';
        final sMin = dailyCalMin.round();
        final sMax = dailyCalMax.round();
        safetyNote = 'Maintenance range. Stay within this and your weight stays stable.';
        goalExplanation =
        'HOW MAINTENANCE WORKS\n\n'
            'Staying fit means eating roughly what you burn. Small fluctuations are completely normal.\n\n'
            'YOUR PLAN\n'
            'Daily calories: $sMin - $sMax kcal\n'
            'Protein: $proteinMin - ${proteinMax}g per day\n\n'
            'WHAT TO FOCUS ON\n'
            'Consistent tracking matters more than perfection\n'
            'Move your body — walk, swim, cycle, whatever you enjoy\n'
            'Your weekly budget means one feast day does not break anything\n'
            'Real Indian food — dal, sabzi, rice — is genuinely healthy';
        break;

      default:
        dailyCalMin = tdee - 100;
        dailyCalMax = tdee + 100;
        isSafe = true;
        deficitLabel = 'DAILY RANGE';
        final cMin = dailyCalMin.round();
        final cMax = dailyCalMax.round();
        safetyNote = 'Start tracking and discover what your body needs.';
        goalExplanation =
        'START BY TRACKING\n\n'
            'Most people have no idea how many calories they eat. Tracking for 2 weeks teaches you more than any diet plan.\n\n'
            'YOUR PLAN\n'
            'Daily calories: $cMin - $cMax kcal\n'
            'Protein: $proteinMin - ${proteinMax}g per day\n\n'
            'No restrictions. Just awareness.';
    }

    dailyCalMin = dailyCalMin.clamp(1100.0, 2900.0);
    dailyCalMax = dailyCalMax.clamp(1200.0, 3000.0);

    final weeklyMin = (dailyCalMin * 7).round();
    final weeklyMax = (dailyCalMax * 7).round();
    final weeklyBudget = ((weeklyMin + weeklyMax) / 2).round();
    final dailyDeficit = (tdee - ((dailyCalMin + dailyCalMax) / 2)).round();

    return _BudgetResult(
      weeklyBudget: weeklyBudget,
      weeklyMin: weeklyMin,
      weeklyMax: weeklyMax,
      dailyMin: dailyCalMin.round(),
      dailyMax: dailyCalMax.round(),
      proteinMin: proteinMin,
      proteinMax: proteinMax,
      dailyDeficit: dailyDeficit,
      deficitLabel: deficitLabel,
      kgPerWeek: double.parse(kgPerWeek.abs().toStringAsFixed(2)),
      weeksToGoal: weeksToGoal,
      tdee: tdee.round(),
      isSafe: isSafe,
      safetyNote: safetyNote,
      goalExplanation: goalExplanation,
    );
  }

  bool _validate() {
    setState(() { _currentErr = null; _targetErr = null; _dateErr = null; });
    final c = double.tryParse(_currentCtrl.text);
    final t = double.tryParse(_targetCtrl.text);
    bool ok = true;
    if (c == null || c < 30 || c > 300) { setState(() => _currentErr = 'Enter a valid weight (30-300 kg)'); ok = false; }
    if (t == null || t < 30 || t > 300) { setState(() => _targetErr = 'Enter a valid weight (30-300 kg)'); ok = false; }
    if (_targetDate == null) { setState(() => _dateErr = 'Please pick your target date'); ok = false; }
    return ok;
  }

  Future<void> _complete() async {
    if (!_validate()) return;
    final current = double.parse(_currentCtrl.text);
    final target = double.parse(_targetCtrl.text);
    final result = _calculate();
    final vm = ref.read(onboardingViewModelProvider.notifier);
    vm.setCurrentWeight(current);
    vm.setTargetWeight(target);
    vm.setWeeklyBudget(result.weeklyBudget);
    final firebaseService = ref.read(firebaseServiceProvider);
    final user = firebaseService.currentUser;
    if (user == null) return;
    final success = await vm.completeOnboarding(user.uid, user.email ?? '');
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingViewModelProvider);
    final result = _calculate();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSizes.paddingXXL, AppSizes.paddingXL, AppSizes.paddingXXL, AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingHeader(
            stepLabel: 'STEP 04 OF 04 - Almost there',
            currentStep: 3, totalSteps: 4,
            title: 'Your numbers',
            subtitle: 'We calculate your personal calorie budget using the Harris-Benedict formula.',
          ),
          const SizedBox(height: AppSizes.paddingXXL),

          // Age
          Text('YOUR AGE', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingSM),
          _WeightField(controller: _ageCtrl, hint: '28', suffix: 'yrs', isDecimal: false, onChanged: (_) => setState(() {})),
          const SizedBox(height: AppSizes.paddingXL),

          // Current weight
          Text('CURRENT WEIGHT', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingSM),
          _WeightField(controller: _currentCtrl, hint: '72.0', suffix: 'kg', isDecimal: true, error: _currentErr, onChanged: (_) => setState(() {})),
          const SizedBox(height: AppSizes.paddingXL),

          // Target weight
          Text('TARGET WEIGHT', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingSM),
          _WeightField(controller: _targetCtrl, hint: '65.0', suffix: 'kg', isDecimal: true, error: _targetErr, onChanged: (_) => setState(() {})),
          const SizedBox(height: AppSizes.paddingXL),

          // Date picker
          Text('GOAL DATE', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingXS),
          Text('When do you want to reach your target?',
              style: AppTextStyles.bodySmall(color: AppColors.accent.withValues(alpha: 0.55))),
          const SizedBox(height: AppSizes.paddingSM),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG, vertical: AppSizes.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                border: Border.all(
                  color: _dateErr != null ? const Color(0x80FF6B6B) : AppColors.accent.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.accent.withValues(alpha: 0.55)),
                  const SizedBox(width: AppSizes.paddingMD),
                  Expanded(
                    child: Text(
                      _targetDate != null ? _formatDate(_targetDate!) : 'Pick a date...',
                      style: _targetDate != null
                          ? const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)
                          : TextStyle(fontSize: 18, color: AppColors.accent.withValues(alpha: 0.25)),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.accent.withValues(alpha: 0.3)),
                ],
              ),
            ),
          ),
          if (_dateErr != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.paddingMD),
              child: Text(_dateErr!, style: const TextStyle(fontSize: 11, color: Color(0xCCFF6B6B))),
            ),
          ],

          const SizedBox(height: AppSizes.paddingXXL),

          // ── BUDGET RESULT CARD ──
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            decoration: AppDecorations.neuCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Weekly range
                Text('YOUR WEEKLY BUDGET', style: AppTextStyles.label()),
                const SizedBox(height: AppSizes.paddingSM),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(text: '${result.weeklyMin} – ${result.weeklyMax}', style: AppTextStyles.displayMedium()),
                      TextSpan(text: '  kcal / week', style: AppTextStyles.bodySmall(color: AppColors.accent.withValues(alpha: 0.5))),
                    ]),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXS),
                Text('${result.dailyMin} – ${result.dailyMax} kcal per day',
                    style: AppTextStyles.bodySmall(color: AppColors.accent.withValues(alpha: 0.5))),

                const SizedBox(height: AppSizes.paddingMD),
                const Divider(color: Color(0x10FFFFFF)),
                const SizedBox(height: AppSizes.paddingMD),

                // Three stats
                Row(children: [
                  _BudgetStat(label: 'CALORIES/DAY', value: '${result.dailyMin}–${result.dailyMax}'),
                  _BudgetStat(label: 'PROTEIN/DAY', value: '${result.proteinMin}–${result.proteinMax}g'),
                  if (result.kgPerWeek > 0)
                    _BudgetStat(label: 'LOSS/WEEK', value: '${result.kgPerWeek} kg')
                  else
                    _BudgetStat(label: result.deficitLabel, value: '${result.dailyDeficit.abs()} kcal'),
                ]),

                const SizedBox(height: AppSizes.paddingMD),
                const Divider(color: Color(0x10FFFFFF)),
                const SizedBox(height: AppSizes.paddingMD),

                // Safety/surplus note
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  decoration: BoxDecoration(
                    color: result.isSafe
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.06)
                        : const Color(0xFFFF9800).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    border: Border.all(
                      color: result.isSafe
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                          : const Color(0xFFFF9800).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(result.isSafe ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                          size: 16,
                          color: result.isSafe ? const Color(0xFF4CAF50) : const Color(0xFFFF9800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(result.safetyNote,
                            style: AppTextStyles.bodySmall(
                                color: result.isSafe
                                    ? const Color(0xFF4CAF50).withValues(alpha: 0.9)
                                    : const Color(0xFFFF9800).withValues(alpha: 0.9))),
                      ),
                    ],
                  ),
                ),

                // Projection for fat loss
                if (_targetDate != null && result.kgPerWeek > 0) ...[
                  const SizedBox(height: AppSizes.paddingMD),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    decoration: AppDecorations.personalityCard(),
                    child: Text(
                      'At this rate you will reach ${_targetCtrl.text} kg by ${_formatDate(_targetDate!)} — ${result.weeksToGoal} weeks from now.',
                      style: AppTextStyles.bodySmall(color: AppColors.accent.withValues(alpha: 0.7)),
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.paddingMD),
                const Divider(color: Color(0x10FFFFFF)),
                const SizedBox(height: AppSizes.paddingMD),

                // Goal explanation
                Text('YOUR GAME PLAN', style: AppTextStyles.label()),
                const SizedBox(height: AppSizes.paddingMD),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    result.goalExplanation,
                    style: AppTextStyles.bodySmall(color: AppColors.accent.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.paddingXXL),

          PrimaryButton(
            label: "LET'S EAT",
            isLoading: state.isLoading,
            onTap: _complete,
            margin: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── BUDGET STAT ───────────────────────────
class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  const _BudgetStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label()),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.bodyLarge(color: AppColors.accent), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── WEIGHT FIELD ──────────────────────────
class _WeightField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final bool isDecimal;
  final String? error;
  final Function(String) onChanged;

  const _WeightField({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.isDecimal,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppSizes.radiusLG),
            border: Border.all(
              color: error != null ? const Color(0x80FF6B6B) : AppColors.accent.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: TextInputType.numberWithOptions(decimal: isDecimal, signed: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(isDecimal ? r'^\d+\.?\d{0,1}' : r'^\d+')),
                  ],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: AppColors.accent.withValues(alpha: 0.25)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG, vertical: AppSizes.paddingMD),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD, vertical: AppSizes.paddingMD),
                decoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.accent.withValues(alpha: 0.1)))),
                child: Text(suffix, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent.withValues(alpha: 0.55))),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.paddingMD),
            child: Text(error!, style: const TextStyle(fontSize: 11, color: Color(0xCCFF6B6B))),
          ),
        ],
      ],
    );
  }
}

// ── BUDGET RESULT MODEL ───────────────────
class _BudgetResult {
  final int weeklyBudget;
  final int weeklyMin;
  final int weeklyMax;
  final int dailyMin;
  final int dailyMax;
  final int proteinMin;
  final int proteinMax;
  final int dailyDeficit;
  final String deficitLabel;
  final double kgPerWeek;
  final int weeksToGoal;
  final int tdee;
  final bool isSafe;
  final String safetyNote;
  final String goalExplanation;

  const _BudgetResult({
    required this.weeklyBudget,
    required this.weeklyMin,
    required this.weeklyMax,
    required this.dailyMin,
    required this.dailyMax,
    required this.proteinMin,
    required this.proteinMax,
    required this.dailyDeficit,
    required this.deficitLabel,
    required this.kgPerWeek,
    required this.weeksToGoal,
    required this.tdee,
    required this.isSafe,
    required this.safetyNote,
    required this.goalExplanation,
  });
}