import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../splash/splash_screen.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final homeState = ref.watch(homeViewModelProvider);

    return StarBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingXXL),
          child: userAsync.when(
            loading: () => const SizedBox(
              height: 400,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 1.5),
              ),
            ),
            error: (e, _) => Center(
              child: Text('Could not load profile',
                  style: AppTextStyles.bodyMedium()),
            ),
            data: (user) {
              if (user == null) {
                return Center(
                  child: Text('No user found',
                      style: AppTextStyles.bodyMedium()),
                );
              }

              // Calculate progress
              final weeklyBudget = homeState.weeklyBudget;
              final used = weeklyBudget?.usedCalories ?? 0;
              final total = user.weeklyBudget;
              final remaining = total - used;
              final pct = total > 0 ? (used / total * 100).round() : 0;

              // Weight progress
              final double current = user.currentWeight;
              final target = user.targetWeight;
              final diff = (current - target).abs();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.paddingXL),
                  Text('Profile', style: AppTextStyles.headingMedium()),
                  const SizedBox(height: AppSizes.paddingXXL),

                  // ── NAME & BASIC INFO ──
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    decoration: AppDecorations.neuCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.accent
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Center(
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'F',
                                  style: AppTextStyles.logoMedium(),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.paddingMD),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isNotEmpty
                                        ? user.name
                                        : 'Fit Foodie User',
                                    style: AppTextStyles.headingMedium(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user.email,
                                    style: AppTextStyles.bodySmall(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.45)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingMD),

                  // ── GOAL & DETAILS ──
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    decoration: AppDecorations.neuCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MY GOAL', style: AppTextStyles.label()),
                        const SizedBox(height: AppSizes.paddingMD),
                        _ProfileRow(
                          icon: Icons.flag_outlined,
                          label: 'Goal',
                          value: _goalLabel(user.goal),
                        ),
                        _ProfileRow(
                          icon: Icons.location_on_outlined,
                          label: 'Region',
                          value: user.region.isNotEmpty
                              ? user.region
                              : 'Not set',
                        ),
                        _ProfileRow(
                          icon: Icons.restaurant_outlined,
                          label: 'Diet',
                          value: _dietLabel(user.dietType),
                        ),
                        _ProfileRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Gender',
                          value: user.gender.isNotEmpty
                              ? _capitalize(user.gender)
                              : 'Not set',
                        ),
                        const Divider(color: Color(0x0AFFFFFF)),
                        const SizedBox(height: AppSizes.paddingXS),
                        Row(
                          children: [
                            Expanded(
                              child: _WeightStat(
                                label: 'CURRENT',
                                value: '${user.currentWeight} kg',
                              ),
                            ),
                            Expanded(
                              child: _WeightStat(
                                label: 'TARGET',
                                value: '${user.targetWeight} kg',
                              ),
                            ),
                            Expanded(
                              child: _WeightStat(
                                label: 'TO GO',
                                value: '${diff.toStringAsFixed(1)} kg',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingMD),

                  // ── WEEKLY BUDGET ──
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    decoration: AppDecorations.neuCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('THIS WEEK',
                                style: AppTextStyles.label()),
                            const Spacer(),
                            Text('$pct% used',
                                style: AppTextStyles.label(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.5))),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        BudgetProgressBar(used: used, total: total),
                        const SizedBox(height: AppSizes.paddingMD),
                        Row(
                          children: [
                            Expanded(
                              child: _WeightStat(
                                  label: 'USED',
                                  value: '$used kcal'),
                            ),
                            Expanded(
                              child: _WeightStat(
                                  label: 'REMAINING',
                                  value: '$remaining kcal'),
                            ),
                            Expanded(
                              child: _WeightStat(
                                  label: 'BUDGET',
                                  value: '$total kcal'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingMD),

                  // ── INSIGHTS SECTION ──
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    decoration: AppDecorations.insightCard(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 14,
                                color: AppColors.accent
                                    .withValues(alpha: 0.6)),
                            const SizedBox(width: 6),
                            Text('INSIGHTS',
                                style: AppTextStyles.label()),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        _InsightTile(
                          insight:
                          _generateInsight(user.goal, pct, used, total),
                        ),
                        const SizedBox(height: AppSizes.paddingSM),
                        _InsightTile(
                          insight: _goalInsight(
                              user.goal, user.currentWeight, user.targetWeight),
                        ),
                        const SizedBox(height: AppSizes.paddingSM),
                        _InsightTile(
                          insight:
                          'Track consistently for 7 days to unlock personalised weekly patterns.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingXXL),

                  // ── SIGN OUT ──
                  GestureDetector(
                    onTap: () async {
                      await ref
                          .read(authViewModelProvider.notifier)
                          .signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SplashScreen()),
                              (route) => false,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.paddingMD),
                      decoration: BoxDecoration(
                        color: const Color(0x10FF5252),
                        borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                            color: const Color(0x30FF5252)),
                      ),
                      child: Center(
                        child: Text('SIGN OUT',
                            style: AppTextStyles.label(
                                color: const Color(0xCCFF5252))),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingHuge),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'lose_fat':
        return 'Lose fat';
      case 'build_muscle':
        return 'Build muscle';
      case 'stay_fit':
        return 'Stay fit';
      case 'curious':
        return 'Just curious';
      default:
        return goal.isNotEmpty ? goal : 'Not set';
    }
  }

  String _dietLabel(String diet) {
    switch (diet) {
      case 'vegetarian':
        return 'Vegetarian';
      case 'eggetarian':
        return 'Eggetarian';
      case 'non_veg':
        return 'Non-vegetarian';
      default:
        return diet.isNotEmpty ? diet : 'Not set';
    }
  }

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  String _generateInsight(
      String goal, int pctUsed, int used, int total) {
    if (pctUsed < 40) {
      return 'You are well within your weekly budget. Great discipline this week!';
    } else if (pctUsed < 70) {
      return 'Halfway through your weekly budget. You are on track.';
    } else if (pctUsed < 90) {
      return 'Getting close to your weekly limit. Choose lighter meals for the next few days.';
    } else {
      return 'You have used most of your weekly budget. Focus on protein-rich, low-calorie meals.';
    }
  }

  String _goalInsight(String goal, double current, double target) {
    final diff = (current - target).abs();
    if (goal == 'lose_fat') {
      return 'You want to lose ${diff.toStringAsFixed(1)} kg. At a safe rate of 0.5 kg per week, that is ${(diff / 0.5).round()} weeks of consistent tracking.';
    } else if (goal == 'build_muscle') {
      return 'Building muscle requires a small calorie surplus and consistent protein intake. Aim for ${(current * 1.6).round()}g of protein per day.';
    } else {
      return 'You are maintaining your weight. Keep your weekly budget around your maintenance calories and stay consistent.';
    }
  }
}

// ── PROFILE ROW ───────────────────────────
class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMD),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent.withValues(alpha: 0.45)),
          const SizedBox(width: AppSizes.paddingMD),
          Text(label,
              style: AppTextStyles.bodySmall(
                  color: AppColors.accent.withValues(alpha: 0.5))),
          const Spacer(),
          Text(value,
              style: AppTextStyles.bodySmall(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── WEIGHT STAT ───────────────────────────
class _WeightStat extends StatelessWidget {
  final String label;
  final String value;

  const _WeightStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label()),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyles.bodyLarge(color: AppColors.accent),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── INSIGHT TILE ──────────────────────────
class _InsightTile extends StatelessWidget {
  final String insight;
  const _InsightTile({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(top: 6, right: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(insight,
              style: AppTextStyles.bodySmall(
                  color: AppColors.accent.withValues(alpha: 0.7))),
        ),
      ],
    );
  }
}