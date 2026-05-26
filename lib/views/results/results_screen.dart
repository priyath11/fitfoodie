import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../widgets/common_widgets.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final File photo1;
  final File photo2;
  final File photo3;
  final String oilLevel;
  final String cookingLocation;
  final List<File> photos;
  final MealAnalysisResult? preloadedResult;
  final String? preloadedMealName;

  const ResultsScreen({
    super.key,
    required this.photo1,
    required this.photo2,
    required this.photo3,
    required this.oilLevel,
    required this.cookingLocation,
    required this.photos,
    this.preloadedResult,
    this.preloadedMealName,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Editable dish list — user can correct any dish
  List<_EditableDish> _editableDishes = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAnalysis());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    // If result is preloaded from confirmation screen — use it directly
    if (widget.preloadedResult != null) {
      await ref.read(resultsViewModelProvider.notifier)
          .setPreloadedResult(widget.preloadedResult!);

      if (!mounted) return;
      setState(() {
        _editableDishes = widget.preloadedResult!.dishes
            .map((d) => _EditableDish.fromDishModel(d))
            .toList();
      });
      _fadeCtrl.forward();
      return;
    }

    // Fallback — should not reach here in normal flow
    final user = await ref.read(currentUserProvider.future);
    if (user == null || !mounted) return;

    final homeState = ref.read(homeViewModelProvider);
    final remaining = homeState.weeklyBudget?.remainingCalories ?? 13300;
    final streak = homeState.streak;

    await ref.read(resultsViewModelProvider.notifier).analyseMeal(
      photo1: widget.photo1,
      photo2: widget.photo2,
      photo3: widget.photo3,
      oilLevel: widget.oilLevel,
      cookingLocation: widget.cookingLocation,
      region: user.region,
      dietType: user.dietType,
      goal: user.goal,
      remainingBudget: remaining,
      streak: streak,
    );

    if (!mounted) return;

    final state = ref.read(resultsViewModelProvider);
    if (state.result != null && state.result!.success) {
      setState(() {
        _editableDishes = state.result!.dishes
            .map((d) => _EditableDish.fromDishModel(d))
            .toList();
      });
    }

    _fadeCtrl.forward();
  }

  Future<void> _confirmMeal() async {
    HapticFeedback.heavyImpact();
    final user = await ref.read(currentUserProvider.future);
    if (user == null || !mounted) return;

    // ignore: use_build_context_synchronously
    final mealState = ref.read(mealLogViewModelProvider);

    // Use edited dishes if user made changes
    final List<DishModel> dishes = _editableDishes.map((e) => e.toDishModel()).toList();
    final totalCalMin = dishes.fold<int>(0, (sum, d) => sum + d.calorieMin);
    final totalCalMax = dishes.fold<int>(0, (sum, d) => sum + d.calorieMax);
    final totalProtMin = dishes.fold<int>(0, (sum, d) => sum + d.proteinMin);
    final totalProtMax = dishes.fold<int>(0, (sum, d) => sum + d.proteinMax);

    await ref.read(resultsViewModelProvider.notifier).saveMealWithDishes(
      userId: user.uid,
      photos: widget.photos,
      oilLevel: widget.oilLevel,
      cookingLocation: widget.cookingLocation,
      plateId: mealState.selectedPlateId ?? '',
      weeklyBudget: user.weeklyBudget,
      dishes: dishes,
      totalCalorieMin: totalCalMin,
      totalCalorieMax: totalCalMax,
      totalProteinMin: totalProtMin,
      totalProteinMax: totalProtMax,
    );

    if (mounted) {
      HapticFeedback.heavyImpact();
      // Recalculate budget from scratch after saving meal
      final firebaseService = ref.read(firebaseServiceProvider);
      final user2 = firebaseService.currentUser;
      if (user2 != null) {
        await firebaseService.recalculateWeeklyBudget(user2.uid);
      }
      if (!mounted) return;
      ref.read(homeViewModelProvider.notifier).refreshAfterDelete();
      // ignore: use_build_context_synchronously
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    }
  }

  // Recalculate totals from edited dishes
  int get _totalCalMin =>
      _editableDishes.fold(0, (sum, d) => sum + d.calorieMin);
  int get _totalCalMax =>
      _editableDishes.fold(0, (sum, d) => sum + d.calorieMax);
  int get _totalProtMin =>
      _editableDishes.fold(0, (sum, d) => sum + d.proteinMin);
  int get _totalProtMax =>
      _editableDishes.fold(0, (sum, d) => sum + d.proteinMax);
  int get _avgCal => ((_totalCalMin + _totalCalMax) / 2).round();
  int get _avgProt => ((_totalProtMin + _totalProtMax) / 2).round();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resultsViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarBackground(child: SizedBox.expand()),

          if (state.isAnalysing)
            _AnalysingView(photo: widget.photo1)
          else if (state.result != null)
            FadeTransition(
              opacity: _fadeAnim,
              child: _buildResults(state),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 1.5),
            ),

          if (state.isSaving)
            Container(
              color: AppColors.background.withValues(alpha: 0.88),
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(dynamic state) {
    final result = state.result!;

    return SafeArea(
      child: Column(
        children: [
          // Photo strip
          SizedBox(
            height: 90,
            child: Row(
              children: [
                Expanded(child: Image.file(widget.photo1, fit: BoxFit.cover)),
                Expanded(child: Image.file(widget.photo2, fit: BoxFit.cover)),
                Expanded(child: Image.file(widget.photo3, fit: BoxFit.cover)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingXXL,
                AppSizes.paddingMD,
                AppSizes.paddingXXL,
                AppSizes.paddingXXL,
              ),
              child: _buildContent(result, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MealAnalysisResult result, dynamic state) {
    // Back button
    final backBtn = GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios_new_rounded,
              size: 14, color: AppColors.accent.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text('Retake',
              style: AppTextStyles.bodySmall(
                  color: AppColors.accent.withValues(alpha: 0.5))),
        ],
      ),
    );

    if (result.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        backBtn,
        const SizedBox(height: AppSizes.paddingXL),
        _EmptyFoodCard(onRetake: () => Navigator.pop(context)),
      ]);
    }

    if (!result.success) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        backBtn,
        const SizedBox(height: AppSizes.paddingXL),
        _FailedCard(
          onRetry: () {
            // Go back to confirmation screen — dishes are pre-filled
            // user just taps CONFIRM & CALCULATE again
            Navigator.pop(context);
          },
          onRetake: () {
            // Go all the way back to camera
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          errorMessage: result.notes,
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back + Edit row
        Row(
          children: [
            backBtn,
            const Spacer(),
            // EDIT button — always visible
            GestureDetector(
              onTap: () {
                setState(() => _isEditing = !_isEditing);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _isEditing
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.accent.withValues(alpha: 0.06),
                  borderRadius:
                  BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: _isEditing
                        ? AppColors.accent.withValues(alpha: 0.5)
                        : AppColors.accent.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isEditing
                          ? Icons.check_rounded
                          : Icons.edit_outlined,
                      size: 14,
                      color: _isEditing
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isEditing ? 'DONE' : 'EDIT',
                      style: AppTextStyles.label(
                        color: _isEditing
                            ? AppColors.accent
                            : AppColors.accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSizes.paddingMD),

        // Meal name + confidence
        Text(result.mealName, style: AppTextStyles.headingMedium()),
        const SizedBox(height: AppSizes.paddingXS),
        Row(
          children: [
            Text(
              _locationLabel(widget.cookingLocation),
              style: AppTextStyles.bodySmall(
                  color: AppColors.accent.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 8),
            _ConfidenceBadge(confidence: result.confidence),
          ],
        ),

        // Low/medium confidence banner — nudge user to review
        if (result.confidence != 'high') ...[
          const SizedBox(height: AppSizes.paddingMD),
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.08),
                borderRadius:
                BorderRadius.circular(AppSizes.radiusLG),
                border: Border.all(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFFF9800)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We are not fully confident about some dishes. Tap EDIT to correct anything that looks wrong.',
                      style: AppTextStyles.bodySmall(
                          color: const Color(0xFFFF9800)
                              .withValues(alpha: 0.9)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('EDIT',
                      style: AppTextStyles.label(
                          color: const Color(0xFFFF9800))),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSizes.paddingXL),

        // DISHES
        Text('WHAT WE FOUND', style: AppTextStyles.label()),
        const SizedBox(height: AppSizes.paddingMD),

        if (_isEditing)
        // Editable dish list
          ..._editableDishes.asMap().entries.map((entry) {
            final i = entry.key;
            final dish = entry.value;
            return _EditableDishCard(
              dish: dish,
              onChanged: (updated) {
                setState(() => _editableDishes[i] = updated);
              },
              onDelete: _editableDishes.length > 1
                  ? () {
                setState(() => _editableDishes.removeAt(i));
                HapticFeedback.mediumImpact();
              }
                  : null,
            );
          })
        else
        // Read-only dish list
          ..._editableDishes.map((dish) => Container(
            margin:
            const EdgeInsets.only(bottom: AppSizes.paddingSM),
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: AppDecorations.neuCard(),
            child: Row(
              children: [
                DishIcon(iconType: dish.iconType),
                const SizedBox(width: AppSizes.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dish.name,
                          style: AppTextStyles.dishName(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      const SizedBox(height: 2),
                      Text(
                          dish.serving,
                          style: AppTextStyles.dishSub(),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      if (dish.weightGramsMin > 0)
                        Text(
                          '${dish.weightGramsMin}–${dish.weightGramsMax}g',
                          style: AppTextStyles.label(
                              color: AppColors.accent.withValues(alpha: 0.4)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.paddingMD),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${((dish.calorieMin + dish.calorieMax) / 2).round()} kcal',
                      style: AppTextStyles.calorieRange(),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center_outlined,
                            size: 10,
                            color: AppColors.accent
                                .withValues(alpha: 0.45)),
                        const SizedBox(width: 3),
                        Text(
                          '${((dish.proteinMin + dish.proteinMax) / 2).round()}g protein',
                          style: AppTextStyles.dishSub(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          )),

        // Add dish button in edit mode
        if (_isEditing) ...[
          GestureDetector(
            onTap: () {
              setState(() {
                _editableDishes.add(_EditableDish(
                  name: 'New dish',
                  serving: '1 serving',
                  calorieMin: 100,
                  calorieMax: 120,
                  proteinMin: 3,
                  proteinMax: 5,
                  iconType: 'other',
                ));
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              margin:
              const EdgeInsets.only(bottom: AppSizes.paddingSM),
              padding: const EdgeInsets.all(AppSizes.paddingMD),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.04),
                borderRadius:
                BorderRadius.circular(AppSizes.radiusLG),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      size: 18,
                      color: AppColors.accent.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text('Add missing dish',
                      style: AppTextStyles.bodySmall(
                          color:
                          AppColors.accent.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSizes.paddingMD),

        // TOTALS — auto-updates from edited dishes
        _TotalsCard(
          totalCalMin: _totalCalMin,
          totalCalMax: _totalCalMax,
          totalProteinMin: _totalProtMin,
          totalProteinMax: _totalProtMax,
        ),

        const SizedBox(height: AppSizes.paddingMD),

        // BUDGET IMPACT
        _BudgetImpactCard(
          calories: _avgCal,
          weeklyBudget:
          ref.watch(homeViewModelProvider).user?.weeklyBudget ??
              13300,
          used: ref
              .watch(homeViewModelProvider)
              .weeklyBudget
              ?.usedCalories ??
              0,
        ),

        // AI INSIGHT
        if (state.aiInsight.isNotEmpty) ...[
          const SizedBox(height: AppSizes.paddingMD),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: AppDecorations.insightCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 13,
                      color: AppColors.accent.withValues(alpha: 0.55)),
                  const SizedBox(width: 6),
                  Text('FIT FOODIE AI',
                      style: AppTextStyles.label(
                          color:
                          AppColors.accent.withValues(alpha: 0.55))),
                ]),
                const SizedBox(height: AppSizes.paddingXS),
                Text(state.aiInsight, style: AppTextStyles.insight()),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSizes.paddingXL),

        // CONFIRM BUTTON
        PrimaryButton(
          label: 'CONFIRM MEAL',
          isLoading: state.isSaving,
          onTap: _confirmMeal,
          margin: EdgeInsets.zero,
        ),

        const SizedBox(height: AppSizes.paddingXS),
        Center(
          child: Text(
            'Calories saved: $_avgCal kcal · ${_avgProt}g protein',
            style: AppTextStyles.label(
                color: AppColors.accent.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }

  String _locationLabel(String loc) {
    switch (loc) {
      case 'home': return 'Home cooked';
      case 'restaurant': return 'Restaurant';
      case 'ordered': return 'Ordered in';
      default: return loc;
    }
  }
}

// ─────────────────────────────────────────
// EDITABLE DISH MODEL
// ─────────────────────────────────────────
class _EditableDish {
  String name;
  String serving;
  int weightGramsMin;
  int weightGramsMax;
  int calorieMin;
  int calorieMax;
  int proteinMin;
  int proteinMax;
  String iconType;

  _EditableDish({
    required this.name,
    required this.serving,
    this.weightGramsMin = 0,
    this.weightGramsMax = 0,
    required this.calorieMin,
    required this.calorieMax,
    required this.proteinMin,
    required this.proteinMax,
    required this.iconType,
  });

  factory _EditableDish.fromDishModel(DishModel d) => _EditableDish(
    name: d.name,
    serving: d.serving,
    weightGramsMin: d.weightGramsMin,
    weightGramsMax: d.weightGramsMax,
    calorieMin: d.calorieMin,
    calorieMax: d.calorieMax,
    proteinMin: d.proteinMin,
    proteinMax: d.proteinMax,
    iconType: d.iconType,
  );

  DishModel toDishModel() => DishModel(
    name: name,
    category: iconType,
    serving: serving,
    weightGramsMin: weightGramsMin,
    weightGramsMax: weightGramsMax,
    calorieMin: calorieMin,
    calorieMax: calorieMax,
    proteinMin: proteinMin,
    proteinMax: proteinMax,
    iconType: iconType,
  );

  _EditableDish copyWith({
    String? name,
    String? serving,
    int? weightGramsMin,
    int? weightGramsMax,
    int? calorieMin,
    int? calorieMax,
    int? proteinMin,
    int? proteinMax,
    String? iconType,
  }) =>
      _EditableDish(
        name: name ?? this.name,
        serving: serving ?? this.serving,
        weightGramsMin: weightGramsMin ?? this.weightGramsMin,
        weightGramsMax: weightGramsMax ?? this.weightGramsMax,
        calorieMin: calorieMin ?? this.calorieMin,
        calorieMax: calorieMax ?? this.calorieMax,
        proteinMin: proteinMin ?? this.proteinMin,
        proteinMax: proteinMax ?? this.proteinMax,
        iconType: iconType ?? this.iconType,
      );
}

// ─────────────────────────────────────────
// EDITABLE DISH CARD
// ─────────────────────────────────────────
class _EditableDishCard extends StatefulWidget {
  final _EditableDish dish;
  final Function(_EditableDish) onChanged;
  final VoidCallback? onDelete;

  const _EditableDishCard({
    required this.dish,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_EditableDishCard> createState() => _EditableDishCardState();
}

class _EditableDishCardState extends State<_EditableDishCard> {
  late TextEditingController _nameCtrl;
  late TextEditingController _servingCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _protCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.dish.name);
    _servingCtrl = TextEditingController(text: widget.dish.serving);
    _calCtrl = TextEditingController(
        text: ((widget.dish.calorieMin + widget.dish.calorieMax) / 2)
            .round()
            .toString());
    _protCtrl = TextEditingController(
        text: ((widget.dish.proteinMin + widget.dish.proteinMax) / 2)
            .round()
            .toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final cal = int.tryParse(_calCtrl.text) ?? widget.dish.calorieMin;
    final prot = int.tryParse(_protCtrl.text) ?? widget.dish.proteinMin;
    widget.onChanged(widget.dish.copyWith(
      name: _nameCtrl.text,
      serving: _servingCtrl.text,
      calorieMin: (cal * 0.92).round(),
      calorieMax: (cal * 1.08).round(),
      proteinMin: (prot * 0.9).round(),
      proteinMax: (prot * 1.1).round(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSM),
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dish name + delete
          Row(
            children: [
              DishIcon(iconType: widget.dish.iconType),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => _notify(),
                  style: AppTextStyles.dishName(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Dish name',
                    hintStyle: AppTextStyles.dishName(
                        color: AppColors.accent.withValues(alpha: 0.3)),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.onDelete != null)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(Icons.remove_circle_outline_rounded,
                      size: 20,
                      color: const Color(0xFFFF5252)
                          .withValues(alpha: 0.7)),
                ),
            ],
          ),

          const SizedBox(height: AppSizes.paddingXS),

          // Serving
          TextField(
            controller: _servingCtrl,
            onChanged: (_) => _notify(),
            style: AppTextStyles.dishSub(),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'e.g. 1 medium katori',
              hintStyle: AppTextStyles.dishSub(
                  color: AppColors.accent.withValues(alpha: 0.3)),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: AppSizes.paddingMD),

          // Calories + Protein editors
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CALORIES',
                        style: AppTextStyles.label(
                            color: AppColors.accent
                                .withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius:
                        BorderRadius.circular(AppSizes.radiusMD),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _calCtrl,
                              onChanged: (_) => _notify(),
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.bodyLarge(
                                  color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Text('kcal',
                              style: AppTextStyles.label(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.4))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.paddingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROTEIN',
                        style: AppTextStyles.label(
                            color: AppColors.accent
                                .withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius:
                        BorderRadius.circular(AppSizes.radiusMD),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _protCtrl,
                              onChanged: (_) => _notify(),
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.bodyLarge(
                                  color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Text('g',
                              style: AppTextStyles.label(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.4))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// TOTALS CARD
// ─────────────────────────────────────────
class _TotalsCard extends StatelessWidget {
  final int totalCalMin;
  final int totalCalMax;
  final int totalProteinMin;
  final int totalProteinMax;

  const _TotalsCard({
    required this.totalCalMin,
    required this.totalCalMax,
    required this.totalProteinMin,
    required this.totalProteinMax,
  });

  @override
  Widget build(BuildContext context) {
    final avgCal = ((totalCalMin + totalCalMax) / 2).round();
    final avgProtein = ((totalProteinMin + totalProteinMax) / 2).round();

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL CALORIES', style: AppTextStyles.label()),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('$avgCal kcal',
                      style: AppTextStyles.displayMedium()),
                ),
                Text('$totalCalMin–$totalCalMax range',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.accent.withValues(alpha: 0.08),
            margin: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMD),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL PROTEIN', style: AppTextStyles.label()),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('${avgProtein}g',
                      style: AppTextStyles.displayMedium()),
                ),
                Text('$totalProteinMin–${totalProteinMax}g range',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// BUDGET IMPACT CARD
// ─────────────────────────────────────────
class _BudgetImpactCard extends StatelessWidget {
  final int calories;
  final int weeklyBudget;
  final int used;

  const _BudgetImpactCard({
    required this.calories,
    required this.weeklyBudget,
    required this.used,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = weeklyBudget - used;
    final afterMeal = remaining - calories;
    final pct = weeklyBudget > 0
        ? ((used + calories) / weeklyBudget * 100).round()
        : 0;

    Color color;
    String message;

    if (afterMeal > weeklyBudget * 0.3) {
      color = const Color(0xFF4CAF50);
      message = 'Good meal. Plenty of weekly budget remaining.';
    } else if (afterMeal > 0) {
      color = const Color(0xFFFF9800);
      message = 'Getting close to your weekly limit. Choose lighter meals for the rest of the week.';
    } else {
      color = const Color(0xFFFF5252);
      message = 'Over weekly budget. Eat lighter for the next few days — no stress.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BUDGET IMPACT', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingMD),
          Row(
            children: [
              _ImpactStat(label: 'This meal', value: '$calories kcal'),
              _ImpactStat(
                  label: 'Left after',
                  value: '${afterMeal > 0 ? afterMeal : 0} kcal'),
              _ImpactStat(label: 'Week used', value: '$pct%'),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                afterMeal > 0
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(message,
                    style: AppTextStyles.bodySmall(
                        color: color.withValues(alpha: 0.9))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final String label;
  final String value;
  const _ImpactStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label()),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodyLarge(color: AppColors.accent),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// CONFIDENCE BADGE
// ─────────────────────────────────────────
class _ConfidenceBadge extends StatelessWidget {
  final String confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (confidence) {
      case 'high':
        color = const Color(0xFF4CAF50);
        label = 'HIGH CONFIDENCE';
        break;
      case 'medium':
        color = const Color(0xFFFF9800);
        label = 'MEDIUM CONFIDENCE';
        break;
      default:
        color = const Color(0xFFFF5252);
        label = 'LOW CONFIDENCE';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppTextStyles.label(color: color)),
    );
  }
}

// ─────────────────────────────────────────
// ANALYSING VIEW
// ─────────────────────────────────────────
class _AnalysingView extends StatefulWidget {
  final File photo;
  const _AnalysingView({required this.photo});

  @override
  State<_AnalysingView> createState() => _AnalysingViewState();
}

class _AnalysingViewState extends State<_AnalysingView> {
  static const List<Map<String, String>> _tips = [
    {
      'label': 'DID YOU KNOW',
      'text': 'Dal and rice together form a complete protein — all 9 essential amino acids your body needs.',
    },
    {
      'label': 'NUTRITION FACT',
      'text': 'A single idli has only 39 kcal. One of the lightest and most nutritious breakfast options in the world.',
    },
    {
      'label': 'HEALTH TIP',
      'text': 'Eating slowly gives your brain time to register fullness. You naturally eat 20% less.',
    },
    {
      'label': 'DID YOU KNOW',
      'text': 'Ghee on hot rice actually slows sugar absorption — helping you feel full longer.',
    },
    {
      'label': 'PROTEIN TIP',
      'text': 'Paneer has 18g of protein per 100g — more than most dals. Great for vegetarians building muscle.',
    },
    {
      'label': 'HEALTH FACT',
      'text': 'Kerala fish curry is one of the healthiest curries — rich in omega-3s and low in saturated fat.',
    },
    {
      'label': 'MINDFUL EATING',
      'text': 'Your body needs 20 minutes to signal fullness. Pause between servings — it works.',
    },
    {
      'label': 'DID YOU KNOW',
      'text': 'Turmeric in curries has anti-inflammatory properties equal to some medicines — and tastes better.',
    },
    {
      'label': 'WEEKLY BUDGET',
      'text': 'One big meal does not ruin your week. Balance over 7 days is what matters — not one day.',
    },
    {
      'label': 'PROTEIN FACT',
      'text': 'An egg has 6g of complete protein and costs less than ₹10. The most efficient protein source available.',
    },
  ];

  int _currentTip = 0;

  @override
  void initState() {
    super.initState();
    _rotateTip();
  }

  void _rotateTip() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentTip = (_currentTip + 1) % _tips.length;
        });
        _rotateTip();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_currentTip];

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 0.12, child: Image.file(widget.photo, fit: BoxFit.cover)),
        Container(color: AppColors.background.withValues(alpha: 0.88)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingXXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                    color: AppColors.accent, strokeWidth: 2),
                const SizedBox(height: AppSizes.paddingXXL),
                Text(
                  'Analysing your meal',
                  style: AppTextStyles.headingMedium(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.paddingXXL),

                // Rotating tip card
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: child,
                  ),
                  child: Container(
                    key: ValueKey(_currentTip),
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          tip['label']!,
                          style: AppTextStyles.label(
                              color: AppColors.accent.withValues(alpha: 0.5)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.paddingMD),
                        Text(
                          tip['text']!,
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.accent.withValues(alpha: 0.8)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_tips.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentTip ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == _currentTip
                            ? AppColors.accent.withValues(alpha: 0.7)
                            : AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// EMPTY PLATE CARD
// ─────────────────────────────────────────
class _EmptyFoodCard extends StatelessWidget {
  final VoidCallback onRetake;
  const _EmptyFoodCard({required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXXL),
      decoration: AppDecorations.neuCard(),
      child: Column(
        children: [
          Icon(Icons.no_food_outlined,
              size: 52, color: AppColors.accent.withValues(alpha: 0.3)),
          const SizedBox(height: AppSizes.paddingLG),
          Text('Nothing detected',
              style: AppTextStyles.headingMedium(),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            'No food was visible in the photos.\nMake sure your food fits inside the frame.',
            style: AppTextStyles.bodySmall(
                color: AppColors.accent.withValues(alpha: 0.55)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingXL),
          PrimaryButton(
              label: 'RETAKE PHOTOS',
              onTap: onRetake,
              margin: EdgeInsets.zero),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// FAILED CARD
// ─────────────────────────────────────────
class _FailedCard extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onRetake;
  final String errorMessage;

  const _FailedCard({
    required this.onRetry,
    required this.onRetake,
    this.errorMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    final isOverload = errorMessage.contains('busy') ||
        errorMessage.contains('overload') ||
        errorMessage.contains('503') ||
        errorMessage.contains('quota');

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingXXL),
      decoration: AppDecorations.neuCard(),
      child: Column(
        children: [
          Icon(
            isOverload
                ? Icons.hourglass_empty_rounded
                : Icons.error_outline_rounded,
            size: 52,
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSizes.paddingLG),
          Text(
            isOverload ? 'Service busy' : 'Could not analyse',
            style: AppTextStyles.headingMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            isOverload
                ? 'The AI service is temporarily busy. Tap Try Again — it usually works within seconds.'
                : errorMessage.isNotEmpty
                ? errorMessage
                : 'Something went wrong. Please try again.',
            style: AppTextStyles.bodySmall(
                color: AppColors.accent.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingXL),
          PrimaryButton(
            label: 'TRY AGAIN',
            onTap: onRetry,
            margin: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSizes.paddingMD),
          GestureDetector(
            onTap: onRetake,
            child: Text(
              'Retake photos from scratch',
              style: AppTextStyles.bodySmall(
                  color: AppColors.accent.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}