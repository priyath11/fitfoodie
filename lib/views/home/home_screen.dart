import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../meal_log/meal_log_screen.dart';
import '../profile/profile_screen.dart';
import '../weekly/weekly_screen.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  void _openMealLog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MealLogScreen()),
    ).then((_) => ref.read(homeViewModelProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(onLogMeal: _openMealLog),
          const WeeklyScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── WORLD CLASS NAV ───────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF5111927),
        border: Border(
            top: BorderSide(color: AppColors.accent.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Weekly',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive
                    ? AppColors.accent
                    : AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.accent
                    : AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HOME TAB ──────────────────────────────
class _HomeTab extends ConsumerStatefulWidget {
  final VoidCallback onLogMeal;
  const _HomeTab({required this.onLogMeal});

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).loadHomeData();
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final hasMeals = state.todaysMeals.isNotEmpty;
    final userName = state.user?.name ?? '';

    return StarBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
          color: AppColors.accent,
          backgroundColor: AppColors.cardLight,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingXXL, AppSizes.paddingXL,
                    AppSizes.paddingXXL, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── GREETING — no slogan ──
                    Text(
                      _greeting().toUpperCase(),
                      style: AppTextStyles.label(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName.isNotEmpty ? userName : 'Welcome',
                      style: AppTextStyles.logoLarge(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),

                    const SizedBox(height: AppSizes.paddingXL),

                    // ── BUDGET RING WITH % ──
                    state.isLoading
                        ? _LoadingCard()
                        : _BudgetCard(state: state),

                    const SizedBox(height: AppSizes.paddingSM),

                    // ── PROTEIN + MEALS STATS ──
                    if (!state.isLoading)
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'PROTEIN TODAY',
                              value: '${state.todayProtein}g',
                              icon: Icons.fitness_center_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSM),
                          Expanded(
                            child: _StatTile(
                              label: 'MEALS TODAY',
                              value: '${state.todaysMeals.length}',
                              icon: Icons.restaurant_outlined,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: AppSizes.paddingXXL),

                    // ── MEALS or EMPTY STATE ──
                    if (hasMeals) ...[
                      Text('TODAY', style: AppTextStyles.label()),
                      const SizedBox(height: AppSizes.paddingSM),
                      ...state.todaysMeals.map((meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _DismissibleMealRow(
                          meal: meal,
                          onDelete: () async {
                            final firebaseService = ref.read(firebaseServiceProvider);
                            final user = firebaseService.currentUser;
                            await firebaseService.deleteMeal(
                              meal.id,
                              caloriesToSubtract: meal.avgCalories,
                              userId: user?.uid,
                            );
                            // Recalculate from scratch to ensure accuracy
                            if (user != null) {
                              await firebaseService.recalculateWeeklyBudget(user.uid);
                            }
                            ref.read(homeViewModelProvider.notifier).refreshAfterDelete();
                          },
                        ),
                      )),

                      if (state.todaysMeals.last.aiInsight.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.paddingMD),
                        InsightCard(
                            insight: state.todaysMeals.last.aiInsight),
                      ],

                      const SizedBox(height: AppSizes.paddingXXL),
                      _LogButton(
                          onTap: widget.onLogMeal,
                          label: 'LOG ANOTHER MEAL'),
                    ] else ...[
                      _EmptyState(onTap: widget.onLogMeal),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── BUDGET CARD WITH % RING ───────────────
class _BudgetCard extends StatelessWidget {
  final dynamic state;
  const _BudgetCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.user?.weeklyBudget ?? 13300;
    final rawUsed = state.weeklyBudget?.usedCalories ?? 0;
    final used = rawUsed.clamp(0, total);
    final remaining = total - used;
    // Guard: if used is 0 force pct to exactly 0.0 — no floating point drift
    final pct = (total > 0 && used > 0) ? (used / total).clamp(0.0, 1.0) : 0.0;
    final pctDisplay = (pct * 100).round();

    // Safety colour
    Color ringColor;
    String status;
    if (pct < 0.7) {
      ringColor = AppColors.accent.withValues(alpha: 0.7);
      status = 'On track';
    } else if (pct < 0.9) {
      ringColor = const Color(0xFFFF9800);
      status = 'Getting close';
    } else {
      ringColor = const Color(0xFFFF5252);
      status = 'Near limit';
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      decoration: AppDecorations.neuCard(),
      child: Row(
        children: [
          // Ring with %
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _RingPainter(
                  progress: pct, color: ringColor),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$pctDisplay%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ringColor,
                      ),
                    ),
                    Text(
                      'used',
                      style: AppTextStyles.label(
                          color: AppColors.accent.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WEEKLY BUDGET', style: AppTextStyles.label()),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: '$remaining',
                          style: AppTextStyles.displayMedium()),
                      TextSpan(
                          text: ' kcal left',
                          style: AppTextStyles.bodySmall(
                              color: AppColors.accent
                                  .withValues(alpha: 0.5))),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),
                BudgetProgressBar(used: used, total: total),
                const SizedBox(height: 4),
                Text(status,
                    style: AppTextStyles.label(color: ringColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.06)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress * 2 * 3.14159,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── STAT TILE ─────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: AppDecorations.glassCard(),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent.withValues(alpha: 0.5)),
          const SizedBox(width: AppSizes.paddingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.label(),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.stat(),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── EMPTY STATE — no slogan ───────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSizes.paddingXXL),
        Icon(Icons.restaurant_outlined,
            size: 52, color: AppColors.accent.withValues(alpha: 0.15)),
        const SizedBox(height: AppSizes.paddingLG),
        Text(
          'No meals logged yet',
          style: AppTextStyles.logoMedium(
              color: AppColors.accent.withValues(alpha: 0.55)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.paddingSM),
        Text(
          'Log your first meal and start\nbuilding your weekly picture.',
          style: AppTextStyles.bodySmall(
              color: AppColors.accent.withValues(alpha: 0.4)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.paddingXXL),
        _LogButton(onTap: onTap, label: 'LOG YOUR FIRST MEAL'),
      ],
    );
  }
}

// ── LOG BUTTON ────────────────────────────
class _LogButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _LogButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.paddingMD + 4,
          horizontal: AppSizes.paddingXXL,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_rounded,
                color: Colors.black, size: 20),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.buttonPrimary()),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: AppDecorations.neuCard(),
      child: const Center(
        child: CircularProgressIndicator(
            color: AppColors.accent, strokeWidth: 1.5),
      ),
    );
  }
}

// ── DISMISSIBLE MEAL ROW ──────────────────
// Swipe left to delete, or tap delete icon
class _DismissibleMealRow extends StatelessWidget {
  final dynamic meal;
  final VoidCallback onDelete;

  const _DismissibleMealRow({
    required this.meal,
    required this.onDelete,
  });


  void _showMealDetails(BuildContext context, dynamic meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MealDetailsSheet(meal: meal, onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.paddingLG),
        decoration: BoxDecoration(
          color: const Color(0x20FF5252),
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xCCFF5252),
          size: 22,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardLight,
            title: Text('Delete meal?',
                style: AppTextStyles.headingMedium()),
            content: Text(
              'This will remove "${meal.mealName}" from today and update your budget.',
              style: AppTextStyles.bodySmall(
                  color: AppColors.accent.withValues(alpha: 0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.5))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: AppTextStyles.bodySmall(
                        color: const Color(0xCCFF5252))),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingMD),
        decoration: AppDecorations.neuCard(),
        child: Row(
          children: [
            DishIcon(iconType: meal.dishes.isNotEmpty ? meal.dishes.first.iconType : 'other'),
            const SizedBox(width: AppSizes.paddingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.mealName,
                      style: AppTextStyles.dishName(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(height: 2),
                  Text(
                    '${meal.mealType.toUpperCase()} · ${meal.timeFormatted}',
                    style: AppTextStyles.dishSub(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.paddingSM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(meal.calorieRange,
                    style: AppTextStyles.calorieRange()),
                const SizedBox(height: 2),
                Text(meal.proteinRange,
                    style: AppTextStyles.dishSub()),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showMealDetails(context, meal),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text('EDIT',
                        style: AppTextStyles.label(
                            color: AppColors.accent.withValues(alpha: 0.6))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// MEAL DETAILS SHEET
// Shows full dish breakdown with delete
// ─────────────────────────────────────────
class _MealDetailsSheet extends ConsumerStatefulWidget {
  final dynamic meal;
  final VoidCallback onDelete;

  const _MealDetailsSheet({required this.meal, required this.onDelete});

  @override
  ConsumerState<_MealDetailsSheet> createState() => _MealDetailsSheetState();
}

class _MealDetailsSheetState extends ConsumerState<_MealDetailsSheet> {
  late List<Map<String, dynamic>> _dishes;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _dishes = widget.meal.dishes.map<Map<String, dynamic>>((d) => {
      'name': d.name,
      'serving': d.serving,
      'weightGramsMin': d.weightGramsMin,
      'weightGramsMax': d.weightGramsMax,
      'calories': ((d.calorieMin + d.calorieMax) / 2).round(),
      'protein': ((d.proteinMin + d.proteinMax) / 2).round(),
      'iconType': d.iconType,
      'calorieMin': d.calorieMin,
      'calorieMax': d.calorieMax,
      'proteinMin': d.proteinMin,
      'proteinMax': d.proteinMax,
    }).toList();
  }

  int get _totalCal => _dishes.fold(0, (s, d) => s + (d['calories'] as int));
  int get _totalProt => _dishes.fold(0, (s, d) => s + (d['protein'] as int));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.paddingLG),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title + Edit toggle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.meal.mealName, style: AppTextStyles.headingMedium()),
                      const SizedBox(height: AppSizes.paddingXS),
                      Text(
                        '${widget.meal.mealType.toUpperCase()} · ${widget.meal.timeFormatted}',
                        style: AppTextStyles.bodySmall(
                            color: AppColors.accent.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isEditing = !_isEditing),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _isEditing
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: _isEditing
                            ? AppColors.accent.withValues(alpha: 0.4)
                            : AppColors.accent.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      _isEditing ? 'DONE' : 'EDIT',
                      style: AppTextStyles.label(
                        color: _isEditing
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.paddingXL),

            // Dish list
            ..._dishes.asMap().entries.map((entry) {
              final i = entry.key;
              final dish = entry.value;
              if (_isEditing) {
                return _EditableDishRow(
                  dish: dish,
                  canDelete: _dishes.length > 1,
                  onChanged: (updated) => setState(() => _dishes[i] = updated),
                  onDelete: () => setState(() => _dishes.removeAt(i)),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingSM),
                child: Row(
                  children: [
                    DishIcon(iconType: dish['iconType'] as String),
                    const SizedBox(width: AppSizes.paddingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dish['name'] as String, style: AppTextStyles.dishName()),
                          Text(dish['serving'] as String, style: AppTextStyles.dishSub()),
                          if ((dish['weightGramsMin'] as int? ?? 0) > 0)
                            Text(
                              '${dish['weightGramsMin']}–${dish['weightGramsMax']}g',
                              style: AppTextStyles.label(
                                  color: AppColors.accent.withValues(alpha: 0.4)),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${dish['calories']} kcal', style: AppTextStyles.calorieRange()),
                        Text('${dish['protein']}g protein', style: AppTextStyles.dishSub()),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppSizes.paddingLG),
            const Divider(color: Color(0x10FFFFFF)),
            const SizedBox(height: AppSizes.paddingMD),

            // Totals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL', style: AppTextStyles.label()),
                Row(
                  children: [
                    Text('$_totalCal kcal', style: AppTextStyles.calorieRange()),
                    const SizedBox(width: 12),
                    Text('${_totalProt}g protein', style: AppTextStyles.dishSub()),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppSizes.paddingXXL),

            // Delete button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMD),
                decoration: BoxDecoration(
                  color: const Color(0x15FF5252),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: const Color(0x40FF5252)),
                ),
                child: Text(
                  'DELETE MEAL',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label(color: const Color(0xCCFF5252)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// EDITABLE DISH ROW — inside meal details
// ─────────────────────────────────────────
class _EditableDishRow extends StatefulWidget {
  final Map<String, dynamic> dish;
  final bool canDelete;
  final Function(Map<String, dynamic>) onChanged;
  final VoidCallback onDelete;

  const _EditableDishRow({
    required this.dish,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_EditableDishRow> createState() => _EditableDishRowState();
}

class _EditableDishRowState extends State<_EditableDishRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _protCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.dish['name'] as String);
    _calCtrl = TextEditingController(text: '${widget.dish['calories']}');
    _protCtrl = TextEditingController(text: '${widget.dish['protein']}');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final cal = int.tryParse(_calCtrl.text) ?? widget.dish['calories'] as int;
    final prot = int.tryParse(_protCtrl.text) ?? widget.dish['protein'] as int;
    widget.onChanged({
      ...widget.dish,
      'name': _nameCtrl.text,
      'calories': cal,
      'protein': prot,
      'calorieMin': (cal * 0.92).round(),
      'calorieMax': (cal * 1.08).round(),
      'proteinMin': (prot * 0.9).round(),
      'proteinMax': (prot * 1.1).round(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSM),
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              DishIcon(iconType: widget.dish['iconType'] as String),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => _notify(),
                  style: AppTextStyles.dishName(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Dish name',
                    hintStyle: AppTextStyles.dishName(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                ),
              ),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.remove_circle_outline_rounded,
                      size: 20,
                      color: const Color(0xFFFF5252).withValues(alpha: 0.6)),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _calCtrl,
                          onChanged: (_) => _notify(),
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.bodySmall(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Text('kcal', style: AppTextStyles.label(
                          color: AppColors.accent.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingSM),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _protCtrl,
                          onChanged: (_) => _notify(),
                          keyboardType: TextInputType.number,
                          style: AppTextStyles.bodySmall(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Text('g', style: AppTextStyles.label(
                          color: AppColors.accent.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}