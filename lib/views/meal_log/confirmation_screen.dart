import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/providers.dart';
import '../results/results_screen.dart';
import '../widgets/common_widgets.dart';


// ─────────────────────────────────────────
// CONFIRMATION SCREEN
// Shows after 3 photos are taken
// User verifies each dish name before
// nutrition is calculated
// ─────────────────────────────────────────
class ConfirmationScreen extends ConsumerStatefulWidget {
  final File photo1;
  final File photo2;
  final File photo3;
  final String oilLevel;
  final String cookingLocation;
  final List<File> photos;

  const ConfirmationScreen({
    super.key,
    required this.photo1,
    required this.photo2,
    required this.photo3,
    required this.oilLevel,
    required this.cookingLocation,
    required this.photos,
  });

  @override
  ConsumerState<ConfirmationScreen> createState() =>
      _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen>
    with SingleTickerProviderStateMixin {
  bool _isIdentifying = true;
  bool _isCalculating = false;
  List<IdentifiedDish> _dishes = [];
  String _error = '';

  // Search state
  int? _editingIndex;
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _searchSuggestions = [];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Common Indian dishes for search suggestions
  static const List<String> _allDishes = [
    'Appam', 'Idli', 'Dosa plain', 'Dosa masala', 'Uttapam', 'Upma',
    'Puttu', 'Pathiri', 'Parotta', 'Malabar parotta',
    'Kerala rice', 'White rice', 'Basmati rice', 'Biryani Kerala',
    'Biryani Hyderabadi', 'Fried rice',
    'Fish curry Kerala', 'Fish fry', 'Karimeen fry', 'Karimeen pollichathu',
    'Meen moilee', 'Prawn fry', 'Prawn curry',
    'Chicken curry Kerala', 'Chicken fry', 'Chicken tikka masala',
    'Beef fry Kerala', 'Beef curry',
    'Egg roast', 'Egg curry', 'Boiled egg', 'Omelette',
    'Dal tadka', 'Dal makhani', 'Sambar', 'Rasam',
    'Coconut chutney', 'Tomato chutney',
    'Vegetable stew Kerala', 'Aviyal', 'Thoran', 'Mezhukkupuratti',
    'Paneer butter masala', 'Palak paneer', 'Rajma', 'Chole',
    'Aloo sabzi', 'Aloo paratha',
    'Roti', 'Chapati', 'Paratha plain',
    'Pazham pori', 'Unniyappam', 'Vada', 'Medu vada', 'Bonda',
    'Payasam', 'Halwa',
    'Tea with milk', 'Black coffee', 'Chai',
    'Porotta with beef', 'Porotta with egg curry',
    'Thalassery biryani', 'Malabar biryani',
    'Chappathi', 'Poori', 'Bhatura',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _startIdentification();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  int _retryCount = 0;

  Future<void> _startIdentification() async {
    setState(() {
      _isIdentifying = true;
      _error = '';
    });

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null || !mounted) return;

      final geminiService = ref.read(geminiServiceProvider);

      List<IdentifiedDish> dishes = [];

      // Try up to 5 times with increasing wait between attempts
      for (int attempt = 1; attempt <= 5; attempt++) {
        try {
          dishes = await geminiService.identifyDishes(
            photo1: widget.photo1,
            photo2: widget.photo2,
            photo3: widget.photo3,
            region: user.region,
            dietType: user.dietType,
          );
          if (dishes.isNotEmpty) break; // Success
          // Empty result — wait and retry
          if (attempt < 5) {
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        } catch (e) {
          if (attempt < 5) {
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      }

      if (!mounted) return;

      if (dishes.isEmpty) {
        // After 5 attempts still empty — open manual entry
        setState(() {
          _dishes = [
            const IdentifiedDish(
              name: '',
              portion: '1 serving',
              confidence: 'low',
              visualReasoning: 'Could not identify automatically. Please type the dish name.',
            ),
          ];
          _isIdentifying = false;
          _editingIndex = 0;
        });
        _fadeCtrl.forward();
        return;
      }

      setState(() {
        _dishes = dishes;
        _isIdentifying = false;
        _retryCount = 0;
      });
      _fadeCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isIdentifying = false;
        _retryCount++;
        _error = _retryCount >= 3
            ? 'Service is busy right now. Please retake the photos and try again.'
            : 'Could not analyse. Tap Try Again.';
      });
    }
  }

  void _startEditing(int index) {
    setState(() {
      _editingIndex = index;
      _searchCtrl.text = _dishes[index].name.isEmpty ? '' : _dishes[index].name;
      _searchSuggestions = [];
    });
    HapticFeedback.lightImpact();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchSuggestions = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _searchSuggestions = _allDishes
          .where((d) => d.toLowerCase().contains(q))
          .take(6)
          .toList();
    });
  }

  void _selectDish(int index, String dishName) {
    setState(() {
      _dishes[index] = _dishes[index].copyWith(name: dishName);
      _editingIndex = null;
      _searchCtrl.clear();
      _searchSuggestions = [];
    });
    HapticFeedback.mediumImpact();
  }

  void _confirmDishName(int index) {
    final name = _searchCtrl.text.trim();
    if (name.isNotEmpty) {
      _selectDish(index, name);
    } else {
      setState(() {
        _editingIndex = null;
        _searchCtrl.clear();
        _searchSuggestions = [];
      });
    }
  }

  void _addDish() {
    setState(() {
      _dishes.add(const IdentifiedDish(
        name: 'New dish',
        portion: '1 serving',
        confidence: 'low',
        visualReasoning: 'Added manually',
      ));
      _editingIndex = _dishes.length - 1;
      _searchCtrl.text = '';
      _searchSuggestions = [];
    });
    HapticFeedback.lightImpact();
  }

  void _removeDish(int index) {
    if (_dishes.length <= 1) return;
    setState(() {
      _dishes.removeAt(index);
      if (_editingIndex == index) _editingIndex = null;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _confirmAll() async {
    if (_dishes.isEmpty) return;
    // Block if any dish name is empty
    if (_dishes.any((d) => d.name.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a name for all dishes.',
            style: AppTextStyles.bodySmall(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF5252),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    HapticFeedback.heavyImpact();

    setState(() => _isCalculating = true);

    // Auto-retry up to 3 times before showing error
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final user = await ref.read(currentUserProvider.future);
        if (user == null || !mounted) return;

        final geminiService = ref.read(geminiServiceProvider);

        final mealName = _dishes.length == 1
            ? _dishes.first.name
            : _dishes.take(2).map((d) => d.name).join(' with ');

        final result = await geminiService.getNutritionForConfirmedDishes(
          confirmedDishes: _dishes,
          oilLevel: widget.oilLevel,
          cookingLocation: widget.cookingLocation,
          region: user.region,
          mealName: mealName,
        );

        if (!mounted) return;

        // Success — navigate to results
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              photo1: widget.photo1,
              photo2: widget.photo2,
              photo3: widget.photo3,
              oilLevel: widget.oilLevel,
              cookingLocation: widget.cookingLocation,
              photos: widget.photos,
              preloadedResult: result,
              preloadedMealName: mealName,
            ),
          ),
        );
        return;
      } catch (e) {
        if (!mounted) return;
        // ignore: avoid_print
        print('[FitFoodieAI] Nutrition attempt $attempt failed: $e');
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 3));
          continue;
        }
        // All attempts failed — show error on screen
        setState(() {
          _isCalculating = false;
          _error = 'Service is busy. Tap "Calculate Nutrition" to try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const StarBackground(child: SizedBox.expand()),

          if (_isIdentifying)
            _IdentifyingView(photo: widget.photo1)
          else if (_error.isNotEmpty)
            _ErrorView(
              error: _error,
              onRetry: _startIdentification,
              onRetake: () => Navigator.pop(context),
            )
          else
            FadeTransition(
              opacity: _fadeAnim,
              child: _buildConfirmationUI(),
            ),

          if (_isCalculating)
            _CalculatingView(),
        ],
      ),
    );
  }

  Widget _buildConfirmationUI() {
    return SafeArea(
      child: Column(
        children: [
          // Photo strip
          SizedBox(
            height: 80,
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
              padding: const EdgeInsets.all(AppSizes.paddingXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    _dishes.length == 1 && _dishes.first.name.isEmpty
                        ? 'What did you eat?'
                        : 'We found these dishes',
                    style: AppTextStyles.headingMedium(),
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  Text(
                    _dishes.length == 1 && _dishes.first.name.isEmpty
                        ? 'Type the name of your food or drink below.'
                        : 'Tap any dish name to correct it. Then confirm.',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.6)),
                  ),

                  const SizedBox(height: AppSizes.paddingXL),

                  // Dish list
                  ..._dishes.asMap().entries.map((entry) {
                    final i = entry.key;
                    final dish = entry.value;
                    final isEditing = _editingIndex == i;

                    return _DishConfirmCard(
                      dish: dish,
                      isEditing: isEditing,
                      searchCtrl: _searchCtrl,
                      suggestions: isEditing ? _searchSuggestions : [],
                      canDelete: _dishes.length > 1,
                      onTapEdit: () => _startEditing(i),
                      onSearchChanged: _onSearchChanged,
                      onSelectSuggestion: (name) => _selectDish(i, name),
                      onConfirmEdit: () => _confirmDishName(i),
                      onDelete: () => _removeDish(i),
                    );
                  }),

                  // Add dish button
                  GestureDetector(
                    onTap: _addDish,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.paddingMD),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.04),
                        borderRadius:
                        BorderRadius.circular(AppSizes.radiusLG),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              size: 18,
                              color:
                              AppColors.accent.withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Text('Add a dish we missed',
                              style: AppTextStyles.bodySmall(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingXXL),

                  // Error banner if calculation failed
                  if (_error.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMD),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                        border: Border.all(
                            color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: Color(0xFFFF5252)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error,
                                style: AppTextStyles.bodySmall(
                                    color: const Color(0xFFFF5252)
                                        .withValues(alpha: 0.9))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingMD),
                  ],

                  // Confirm button
                  PrimaryButton(
                    label: _error.isNotEmpty
                        ? 'CALCULATE NUTRITION'
                        : 'CONFIRM & CALCULATE',
                    onTap: () {
                      setState(() => _error = '');
                      _confirmAll();
                    },
                    margin: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSizes.paddingMD),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Retake photos',
                        style: AppTextStyles.bodySmall(
                            color:
                            AppColors.accent.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// DISH CONFIRM CARD
// ─────────────────────────────────────────
class _DishConfirmCard extends StatelessWidget {
  final IdentifiedDish dish;
  final bool isEditing;
  final TextEditingController searchCtrl;
  final List<String> suggestions;
  final bool canDelete;
  final VoidCallback onTapEdit;
  final Function(String) onSearchChanged;
  final Function(String) onSelectSuggestion;
  final VoidCallback onConfirmEdit;
  final VoidCallback onDelete;

  const _DishConfirmCard({
    required this.dish,
    required this.isEditing,
    required this.searchCtrl,
    required this.suggestions,
    required this.canDelete,
    required this.onTapEdit,
    required this.onSearchChanged,
    required this.onSelectSuggestion,
    required this.onConfirmEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: isEditing
            ? AppColors.accent.withValues(alpha: 0.06)
            : AppColors.cardLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusLG),
        border: Border.all(
          color: isEditing
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.accent.withValues(alpha: 0.08),
          width: isEditing ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            child: Row(
              children: [
                // Confidence indicator
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: AppSizes.paddingMD),
                  decoration: BoxDecoration(
                    color: dish.confidence == 'high'
                        ? const Color(0xFF4CAF50)
                        : dish.confidence == 'medium'
                        ? const Color(0xFFFF9800)
                        : const Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),

                // Dish name
                Expanded(
                  child: isEditing
                      ? TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: onSearchChanged,
                    onSubmitted: (_) => onConfirmEdit(),
                    style: AppTextStyles.dishName(),
                    decoration: InputDecoration(
                      hintText: 'Type dish name...',
                      hintStyle: AppTextStyles.dishName(
                          color: AppColors.accent
                              .withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                      : GestureDetector(
                    onTap: onTapEdit,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dish.name.isEmpty
                              ? 'Tap to enter dish name'
                              : dish.name,
                          style: dish.name.isEmpty
                              ? AppTextStyles.dishName(
                              color: AppColors.accent
                                  .withValues(alpha: 0.35))
                              : AppTextStyles.dishName(),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dish.portion,
                          style: AppTextStyles.dishSub(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Edit / Done button
                if (isEditing)
                  GestureDetector(
                    onTap: onConfirmEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text('DONE',
                          style: AppTextStyles.label(color: Colors.black)),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onTapEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull),
                          ),
                          child: Text('EDIT',
                              style: AppTextStyles.label(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.7))),
                        ),
                      ),
                      if (canDelete) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 20,
                            color: const Color(0xFFFF5252)
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),

          // Visual reasoning (why AI thinks this is the dish)
          if (!isEditing && dish.visualReasoning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingXXL + 8,
                  0,
                  AppSizes.paddingMD,
                  AppSizes.paddingMD),
              child: Text(
                dish.visualReasoning,
                style: AppTextStyles.bodySmall(
                    color: AppColors.accent.withValues(alpha: 0.4)),
              ),
            ),

          // Search suggestions
          if (isEditing && suggestions.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.1)),
                ),
              ),
              child: Column(
                children: suggestions.map((suggestion) {
                  return GestureDetector(
                    onTap: () => onSelectSuggestion(suggestion),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingXXL,
                        vertical: AppSizes.paddingMD,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Text(suggestion,
                          style: AppTextStyles.bodySmall(
                              color: AppColors.accent
                                  .withValues(alpha: 0.8))),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// IDENTIFYING VIEW — while AI works
// ─────────────────────────────────────────
class _IdentifyingView extends StatefulWidget {
  final File photo;
  const _IdentifyingView({required this.photo});

  @override
  State<_IdentifyingView> createState() => _IdentifyingViewState();
}

class _IdentifyingViewState extends State<_IdentifyingView> {
  static const List<Map<String, String>> _tips = [
    {'label': 'DID YOU KNOW', 'text': 'Dal and rice together form a complete protein — all 9 essential amino acids your body needs.'},
    {'label': 'NUTRITION FACT', 'text': 'A single idli has only 39 kcal. One of the lightest and most nutritious breakfast options in the world.'},
    {'label': 'HEALTH TIP', 'text': 'Eating slowly gives your brain time to register fullness. You naturally eat 20% less.'},
    {'label': 'DID YOU KNOW', 'text': 'Ghee on hot rice actually slows sugar absorption — helping you feel full longer.'},
    {'label': 'PROTEIN TIP', 'text': 'Paneer has 18g of protein per 100g — more than most dals. Great for vegetarians building muscle.'},
    {'label': 'HEALTH FACT', 'text': 'Kerala fish curry is one of the healthiest curries — rich in omega-3s and low in saturated fat.'},
    {'label': 'MINDFUL EATING', 'text': 'Your body needs 20 minutes to signal fullness. Pause between servings — it works.'},
    {'label': 'DID YOU KNOW', 'text': 'Turmeric in curries has anti-inflammatory properties. Every Kerala meal is quietly medicinal.'},
    {'label': 'WEEKLY BUDGET', 'text': 'One big meal does not ruin your week. Balance over 7 days is what matters — not one day.'},
    {'label': 'PROTEIN FACT', 'text': 'An egg has 6g of complete protein and costs less than ₹10. The most efficient protein source available.'},
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
        setState(() => _currentTip = (_currentTip + 1) % _tips.length);
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
                Text('Identifying your meal',
                    style: AppTextStyles.headingMedium(),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.paddingXXL),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    key: ValueKey(_currentTip),
                    padding: const EdgeInsets.all(AppSizes.paddingLG),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(tip['label']!,
                            style: AppTextStyles.label(
                                color: AppColors.accent.withValues(alpha: 0.5)),
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppSizes.paddingMD),
                        Text(tip['text']!,
                            style: AppTextStyles.bodyMedium(
                                color: AppColors.accent.withValues(alpha: 0.8)),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXL),
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
// ERROR VIEW
// ─────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final VoidCallback onRetake;

  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final isOverload = error.contains('busy') ||
        error.contains('overload') ||
        error.contains('quota') ||
        error.contains('503') ||
        error.contains('429');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              isOverload ? 'AI is busy' : 'Could not identify',
              style: AppTextStyles.headingMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              isOverload
                  ? 'The AI service is under heavy load. Tap Try Again — it retries automatically across multiple AI models.'
                  : error,
              style: AppTextStyles.bodySmall(
                  color: AppColors.accent.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingXXL),
            PrimaryButton(
              label: 'TRY AGAIN',
              onTap: onRetry,
              margin: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSizes.paddingMD),
            GestureDetector(
              onTap: onRetake,
              child: Text(
                'Retake photos',
                style: AppTextStyles.bodySmall(
                    color: AppColors.accent.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// CALCULATING VIEW — health tips while waiting
// ─────────────────────────────────────────
class _CalculatingView extends StatefulWidget {
  @override
  State<_CalculatingView> createState() => _CalculatingViewState();
}

class _CalculatingViewState extends State<_CalculatingView> {
  static const List<Map<String, String>> _insights = [
    {'label': 'PROTEIN TIP', 'text': 'Protein keeps you full longer than carbs or fat. Aim for 20-30g per meal to control hunger naturally.'},
    {'label': 'KERALA WISDOM', 'text': 'Coconut oil in Kerala cooking is rich in medium-chain fatty acids — metabolised faster than most fats.'},
    {'label': 'PORTION FACT', 'text': 'The human stomach is roughly the size of your fist. Most restaurant portions are 2 to 3 times more than you need.'},
    {'label': 'DID YOU KNOW', 'text': 'Fermented foods like idli and dosa improve gut health. The fermentation process increases B vitamins naturally.'},
    {'label': 'CALORIE TRUTH', 'text': 'A 30-minute walk burns roughly 150 kcal. But eating 150 kcal less is far easier — both matter equally.'},
    {'label': 'HYDRATION', 'text': 'Drinking water before a meal reduces calorie intake by up to 13 percent. A glass before every meal works.'},
    {'label': 'SPICE FACT', 'text': 'Turmeric, black pepper, and cumin in Indian cooking have measurable anti-inflammatory effects. Every meal is medicine.'},
    {'label': 'BUDGET TIP', 'text': 'One heavy meal does not break your week. The weekly budget exists precisely so you can balance freely.'},
  ];

  int _current = 0;

  @override
  void initState() {
    super.initState();
    _rotate();
  }

  void _rotate() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _current = (_current + 1) % _insights.length);
        _rotate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final insight = _insights[_current];
    return Container(
      color: AppColors.background.withValues(alpha: 0.93),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2),
              const SizedBox(height: AppSizes.paddingXXL),
              Text('Calculating nutrition',
                  style: AppTextStyles.headingMedium(),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppSizes.paddingXXL),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  key: ValueKey(_current),
                  padding: const EdgeInsets.all(AppSizes.paddingLG),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLG),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(insight['label']!,
                          style: AppTextStyles.label(
                              color: AppColors.accent.withValues(alpha: 0.5)),
                          textAlign: TextAlign.center),
                      const SizedBox(height: AppSizes.paddingMD),
                      Text(insight['text']!,
                          style: AppTextStyles.bodyMedium(
                              color: AppColors.accent.withValues(alpha: 0.85)),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_insights.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 16 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _current
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
    );
  }
}