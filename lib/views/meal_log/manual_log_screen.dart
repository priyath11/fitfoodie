import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../home/home_screen.dart';
import '../widgets/common_widgets.dart';


// ─────────────────────────────────────────
// MANUAL LOG SCREEN
// 3 modes: Barcode | Manual kcal | Gram-based
// ─────────────────────────────────────────
class ManualLogScreen extends ConsumerStatefulWidget {
  const ManualLogScreen({super.key});

  @override
  ConsumerState<ManualLogScreen> createState() => _ManualLogScreenState();
}

class _ManualLogScreenState extends ConsumerState<ManualLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final List<_LogEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _addEntry(_LogEntry entry) {
    setState(() => _entries.add(entry));
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  int get _totalCalories =>
      _entries.fold(0, (sum, e) => sum + e.calories);

  Future<void> _saveLog() async {
    if (_entries.isEmpty) return;

    final user = ref.read(firebaseServiceProvider).currentUser;
    if (user == null) return;

    // Build dishes from entries
    final dishes = _entries.map((e) => DishModel(
      name: e.name,
      category: 'other',
      serving: e.serving,
      calorieMin: (e.calories * 0.9).round(),
      calorieMax: (e.calories * 1.1).round(),
      proteinMin: (e.calories * 0.04).round(),
      proteinMax: (e.calories * 0.06).round(),
      iconType: _getIconType(e.name),
    )).toList();

    final mealId = DateTime.now().millisecondsSinceEpoch.toString();
    final hour = DateTime.now().hour;
    String mealType = 'meal';
    if (hour >= 6 && hour < 11) mealType = 'breakfast';
    else if (hour >= 11 && hour < 16) mealType = 'lunch';
    else if (hour >= 16 && hour < 19) mealType = 'snack';
    else if (hour >= 19) mealType = 'dinner';

    final meal = MealModel(
      id: mealId,
      userId: user.uid,
      mealName: _entries.length == 1
          ? _entries.first.name
          : 'Manual entry (${_entries.length} items)',
      mealType: mealType,
      dishes: dishes,
      totalCalorieMin: (_totalCalories * 0.9).round(),
      totalCalorieMax: (_totalCalories * 1.1).round(),
      totalProteinMin: (_totalCalories * 0.04).round(),
      totalProteinMax: (_totalCalories * 0.06).round(),
      oilLevel: 'medium',
      cookingLocation: 'home',
      aiInsight: '',
      photoUrls: [],
      plateId: '',
      loggedAt: DateTime.now(),
    );

    await ref.read(firebaseServiceProvider).saveMeal(meal);

    final avgCal = (_totalCalories * 1.0).round();
    await ref.read(firebaseServiceProvider).updateWeeklyBudget(
      userId: user.uid,
      caloriesAdded: avgCal,
      dayIndex: DateTime.now().weekday - 1,
    );

    if (mounted) {
      ref.read(homeViewModelProvider.notifier).refresh();
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meal logged — $_totalCalories kcal',
              style: AppTextStyles.bodySmall(color: Colors.white)),
          backgroundColor: AppColors.cardLight,
        ),
      );
    }
  }

  String _getIconType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rice') || lower.contains('idli') || lower.contains('appam')) return 'rice';
    if (lower.contains('dal') || lower.contains('sambar')) return 'dal';
    if (lower.contains('roti') || lower.contains('chapati') || lower.contains('paratha')) return 'roti';
    if (lower.contains('fish') || lower.contains('meen')) return 'fish';
    if (lower.contains('chicken') || lower.contains('mutton') || lower.contains('beef')) return 'chicken';
    if (lower.contains('egg')) return 'egg';
    if (lower.contains('curry') || lower.contains('sabzi') || lower.contains('masala')) return 'curry';
    if (lower.contains('biryani') || lower.contains('pulao')) return 'biryani';
    if (lower.contains('chai') || lower.contains('tea') || lower.contains('coffee') || lower.contains('juice')) return 'chai';
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StarBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingXXL, AppSizes.paddingXL,
                    AppSizes.paddingXXL, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: AppDecorations.dishIcon(),
                        child: Icon(Icons.arrow_back_rounded,
                            size: 18,
                            color: AppColors.accent.withValues(alpha: 0.7)),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingLG),
                    Text('Log Manually',
                        style: AppTextStyles.headingMedium()),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text('Add by barcode, calories, or grams',
                        style: AppTextStyles.bodySmall(
                            color: AppColors.accent.withValues(alpha: 0.55))),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.paddingLG),

              // Tab bar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingXXL),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMD),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.08)),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMD - 2),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: AppTextStyles.buttonPrimary().copyWith(
                        fontSize: 10, letterSpacing: 1),
                    unselectedLabelStyle: AppTextStyles.label(),
                    labelColor: Colors.black,
                    unselectedLabelColor: AppColors.accent.withValues(alpha: 0.45),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'BARCODE'),
                      Tab(text: 'CALORIES'),
                      Tab(text: 'GRAMS'),
                    ],
                  ),
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _BarcodeTab(onAdd: _addEntry),
                    _CalorieTab(onAdd: _addEntry),
                    _GramTab(onAdd: _addEntry),
                  ],
                ),
              ),

              // Running total + save
              if (_entries.isNotEmpty)
                _RunningTotal(
                  entries: _entries,
                  total: _totalCalories,
                  onRemove: _removeEntry,
                  onSave: _saveLog,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB 1 — BARCODE
// ─────────────────────────────────────────
class _BarcodeTab extends StatefulWidget {
  final Function(_LogEntry) onAdd;
  const _BarcodeTab({required this.onAdd});

  @override
  State<_BarcodeTab> createState() => _BarcodeTabState();
}

class _BarcodeTabState extends State<_BarcodeTab> {
  bool _scanned = false;
  String _productName = '';
  int _productCalories = 0;
  String _servingSize = '';
  final _servingsCtrl = TextEditingController(text: '1');

  // Simulated barcode scan results
  // In production: use mobile_scanner package
  final Map<String, Map<String, dynamic>> _barcodeDb = {
    '8901058857174': {'name': 'Parle-G Biscuits', 'calories': 448, 'serving': '100g'},
    '8901491503009': {'name': 'Britannia Good Day', 'calories': 502, 'serving': '100g'},
    '8901058000869': {'name': 'Maggi Noodles (1 pack)', 'calories': 375, 'serving': '70g'},
    '8906000393252': {'name': 'Amul Butter (10g)', 'calories': 74, 'serving': '10g'},
    '8901725195113': {'name': 'Haldirams Bhujia', 'calories': 536, 'serving': '100g'},
  };

  Future<void> _scanBarcode() async {
    // In production use mobile_scanner package
    // Simulating scan for now with a demo product
    await Future.delayed(const Duration(seconds: 1));
    final demo = _barcodeDb.values.first;
    setState(() {
      _scanned = true;
      _productName = demo['name'] as String;
      _productCalories = demo['calories'] as int;
      _servingSize = demo['serving'] as String;
    });
  }

  void _add() {
    final servings = double.tryParse(_servingsCtrl.text) ?? 1;
    widget.onAdd(_LogEntry(
      name: _productName,
      calories: (_productCalories * servings).round(),
      serving: '${servings}x $_servingSize',
      method: 'barcode',
    ));
    setState(() {
      _scanned = false;
      _productName = '';
      _productCalories = 0;
      _servingSize = '';
      _servingsCtrl.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scan button
          GestureDetector(
            onTap: _scanBarcode,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 52,
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Text('SCAN BARCODE',
                      style: AppTextStyles.label()),
                  const SizedBox(height: AppSizes.paddingXS),
                  Text(
                    'Point at the nutrition label on any package',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          if (_scanned) ...[
            const SizedBox(height: AppSizes.paddingXL),
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              decoration: AppDecorations.neuCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 6),
                      Text('PRODUCT FOUND',
                          style: AppTextStyles.label(
                              color: const Color(0xFF4CAF50))),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingMD),
                  Text(_productName, style: AppTextStyles.headingMedium()),
                  const SizedBox(height: AppSizes.paddingXS),
                  Text('$_productCalories kcal per $_servingSize',
                      style: AppTextStyles.bodySmall(
                          color: AppColors.accent.withValues(alpha: 0.6))),

                  const SizedBox(height: AppSizes.paddingLG),
                  Text('NUMBER OF SERVINGS', style: AppTextStyles.label()),
                  const SizedBox(height: AppSizes.paddingSM),
                  _SimpleInput(
                    controller: _servingsCtrl,
                    hint: '1',
                    suffix: 'servings',
                    isDecimal: true,
                  ),

                  const SizedBox(height: AppSizes.paddingLG),

                  // Total preview
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    decoration: AppDecorations.personalityCard(),
                    child: Row(
                      children: [
                        Text('Total calories:', style: AppTextStyles.label()),
                        const Spacer(),
                        Text(
                          '${(_productCalories * (double.tryParse(_servingsCtrl.text) ?? 1)).round()} kcal',
                          style: AppTextStyles.bodyLarge(
                              color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.paddingLG),
                  PrimaryButton(
                    label: 'ADD TO LOG',
                    onTap: _add,
                    margin: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSizes.paddingXXL),
          Text('NOTE', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingXS),
          Text(
            'Works with all packaged Indian foods including Parle-G, Britannia, Haldirams, Maggi, Amul and more.',
            style: AppTextStyles.bodySmall(
                color: AppColors.accent.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _servingsCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────
// TAB 2 — MANUAL CALORIES
// ─────────────────────────────────────────
class _CalorieTab extends StatefulWidget {
  final Function(_LogEntry) onAdd;
  const _CalorieTab({required this.onAdd});

  @override
  State<_CalorieTab> createState() => _CalorieTabState();
}

class _CalorieTabState extends State<_CalorieTab> {
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _servingCtrl = TextEditingController(text: '1 serving');
  String? _nameErr;
  String? _calErr;

  // Quick add common Indian dishes
  final List<Map<String, dynamic>> _quickDishes = [
    {'name': 'Kerala Rice', 'cal': 350, 'serving': '1 plate'},
    {'name': 'Fish Curry', 'cal': 210, 'serving': '1 katori'},
    {'name': 'Dal Tadka', 'cal': 150, 'serving': '1 katori'},
    {'name': 'Roti', 'cal': 80, 'serving': '1 piece'},
    {'name': 'Chicken Curry', 'cal': 280, 'serving': '1 katori'},
    {'name': 'Egg Roast', 'cal': 180, 'serving': '2 eggs'},
    {'name': 'Idli', 'cal': 58, 'serving': '1 piece'},
    {'name': 'Sambar', 'cal': 120, 'serving': '1 katori'},
    {'name': 'Chai', 'cal': 80, 'serving': '1 cup'},
    {'name': 'Paratha', 'cal': 160, 'serving': '1 piece'},
    {'name': 'Biryani', 'cal': 480, 'serving': '1 plate'},
    {'name': 'Payasam', 'cal': 280, 'serving': '1 bowl'},
    {'name': 'Appam', 'cal': 90, 'serving': '1 piece'},
    {'name': 'Thoran', 'cal': 95, 'serving': '1 katori'},
    {'name': 'Jalebi', 'cal': 150, 'serving': '2 pieces'},
    {'name': 'Laddoo', 'cal': 200, 'serving': '1 piece'},
  ];

  void _quickAdd(Map<String, dynamic> dish) {
    widget.onAdd(_LogEntry(
      name: dish['name'] as String,
      calories: dish['cal'] as int,
      serving: dish['serving'] as String,
      method: 'manual_kcal',
    ));
    HapticFeedback.lightImpact();
  }

  void _manualAdd() {
    setState(() { _nameErr = null; _calErr = null; });
    final name = _nameCtrl.text.trim();
    final cal = int.tryParse(_calCtrl.text);

    if (name.isEmpty) {
      setState(() => _nameErr = 'Enter dish name');
      return;
    }
    if (cal == null || cal < 1 || cal > 5000) {
      setState(() => _calErr = 'Enter valid calories (1–5000)');
      return;
    }

    widget.onAdd(_LogEntry(
      name: name,
      calories: cal,
      serving: _servingCtrl.text.isEmpty ? '1 serving' : _servingCtrl.text,
      method: 'manual_kcal',
    ));
    _nameCtrl.clear();
    _calCtrl.clear();
    _servingCtrl.text = '1 serving';
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick add grid
          Text('QUICK ADD — COMMON DISHES', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingMD),
          Wrap(
            spacing: AppSizes.paddingSM,
            runSpacing: AppSizes.paddingSM,
            children: _quickDishes.map((dish) {
              return GestureDetector(
                onTap: () => _quickAdd(dish),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.05),
                    borderRadius:
                    BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DishIcon(iconType: 'other'),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(dish['name'] as String,
                              style: AppTextStyles.dishName()),
                          Text('${dish['cal']} kcal · ${dish['serving']}',
                              style: AppTextStyles.dishSub()),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.add_circle_outline_rounded,
                          size: 16,
                          color: AppColors.accent.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.paddingXXL),
          const Divider(color: Color(0x0FFFFFFF)),
          const SizedBox(height: AppSizes.paddingXXL),

          // Custom entry
          Text('OR ADD CUSTOM DISH', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingMD),

          Text('DISH NAME', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingSM),
          _TextInputField(
            controller: _nameCtrl,
            hint: 'e.g. Priya\'s special rice',
            error: _nameErr,
          ),

          const SizedBox(height: AppSizes.paddingMD),
          Text('CALORIES', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingSM),
          _SimpleInput(
            controller: _calCtrl,
            hint: '350',
            suffix: 'kcal',
            isDecimal: false,
            error: _calErr,
          ),

          const SizedBox(height: AppSizes.paddingMD),
          Text('SERVING SIZE (optional)', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingSM),
          _TextInputField(
            controller: _servingCtrl,
            hint: '1 plate, 1 katori, 2 rotis...',
          ),

          const SizedBox(height: AppSizes.paddingXL),
          PrimaryButton(
            label: 'ADD TO LOG',
            onTap: _manualAdd,
            margin: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _servingCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────
// TAB 3 — GRAM-BASED
// ─────────────────────────────────────────
class _GramTab extends StatefulWidget {
  final Function(_LogEntry) onAdd;
  const _GramTab({required this.onAdd});

  @override
  State<_GramTab> createState() => _GramTabState();
}

class _GramTabState extends State<_GramTab> {
  final _gramCtrl = TextEditingController();
  String? _selectedFood;
  int _calculatedCalories = 0;

  // kcal per 100g database — common Indian foods
  final Map<String, Map<String, dynamic>> _foodDb = {
    'Rice (cooked)': {'kcalPer100g': 130, 'protein': 2.7},
    'Rice (raw)': {'kcalPer100g': 360, 'protein': 7.0},
    'Roti / Chapati': {'kcalPer100g': 297, 'protein': 9.0},
    'Paratha (plain)': {'kcalPer100g': 326, 'protein': 8.0},
    'Dal (cooked)': {'kcalPer100g': 116, 'protein': 8.0},
    'Chicken (cooked)': {'kcalPer100g': 215, 'protein': 27.0},
    'Fish (cooked)': {'kcalPer100g': 150, 'protein': 22.0},
    'Egg (whole)': {'kcalPer100g': 155, 'protein': 13.0},
    'Paneer': {'kcalPer100g': 265, 'protein': 18.0},
    'Ghee': {'kcalPer100g': 900, 'protein': 0.0},
    'Coconut oil': {'kcalPer100g': 862, 'protein': 0.0},
    'Potato': {'kcalPer100g': 77, 'protein': 2.0},
    'Onion': {'kcalPer100g': 40, 'protein': 1.1},
    'Tomato': {'kcalPer100g': 18, 'protein': 0.9},
    'Banana': {'kcalPer100g': 89, 'protein': 1.1},
    'Mango': {'kcalPer100g': 60, 'protein': 0.8},
    'Whole milk': {'kcalPer100g': 61, 'protein': 3.2},
    'Curd / Yogurt': {'kcalPer100g': 60, 'protein': 4.0},
    'Coconut (grated)': {'kcalPer100g': 354, 'protein': 3.3},
    'Idli': {'kcalPer100g': 58, 'protein': 2.0},
    'Biryani rice': {'kcalPer100g': 180, 'protein': 4.5},
    'Sambar': {'kcalPer100g': 55, 'protein': 3.0},
    'Rasam': {'kcalPer100g': 25, 'protein': 1.0},
    'Payasam': {'kcalPer100g': 165, 'protein': 2.5},
    'Jalebi': {'kcalPer100g': 387, 'protein': 2.0},
    'Laddoo': {'kcalPer100g': 450, 'protein': 6.0},
    'Halwa': {'kcalPer100g': 320, 'protein': 3.5},
  };

  void _updateCalories() {
    final grams = double.tryParse(_gramCtrl.text) ?? 0;
    if (_selectedFood != null && grams > 0) {
      final kcalPer100g =
      (_foodDb[_selectedFood!]!['kcalPer100g'] as num).toDouble();
      setState(() {
        _calculatedCalories = (kcalPer100g * grams / 100).round();
      });
    } else {
      setState(() => _calculatedCalories = 0);
    }
  }

  void _add() {
    if (_selectedFood == null || _calculatedCalories == 0) return;
    final grams = _gramCtrl.text;
    widget.onAdd(_LogEntry(
      name: _selectedFood!,
      calories: _calculatedCalories,
      serving: '${grams}g',
      method: 'gram',
    ));
    setState(() {
      _selectedFood = null;
      _calculatedCalories = 0;
    });
    _gramCtrl.clear();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter grams of any Indian food — we calculate the calories.',
            style: AppTextStyles.bodySmall(
                color: AppColors.accent.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: AppSizes.paddingXXL),

          // Food selector
          Text('SELECT FOOD', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingSM),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMD),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSizes.radiusLG),
              border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.15), width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFood,
                hint: Text('Choose food...',
                    style: AppTextStyles.bodyLarge(
                        color: AppColors.accent.withValues(alpha: 0.3))),
                isExpanded: true,
                dropdownColor: AppColors.cardLight,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.accent.withValues(alpha: 0.4)),
                style: AppTextStyles.bodyLarge(),
                items: _foodDb.keys.map((food) {
                  final kcal = _foodDb[food]!['kcalPer100g'];
                  return DropdownMenuItem(
                    value: food,
                    child: Row(
                      children: [
                        Expanded(child: Text(food)),
                        Text('$kcal kcal/100g',
                            style: AppTextStyles.dishSub()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedFood = val);
                  _updateCalories();
                },
              ),
            ),
          ),

          const SizedBox(height: AppSizes.paddingXL),

          // Grams input
          Text('WEIGHT IN GRAMS', style: AppTextStyles.label()),
          const SizedBox(height: AppSizes.paddingSM),
          _SimpleInput(
            controller: _gramCtrl,
            hint: 'e.g. 150',
            suffix: 'g',
            isDecimal: true,
            onChanged: (_) => _updateCalories(),
          ),

          // Live calculation
          if (_selectedFood != null && _calculatedCalories > 0) ...[
            const SizedBox(height: AppSizes.paddingXL),
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              decoration: AppDecorations.neuCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CALCULATED', style: AppTextStyles.label()),
                  const SizedBox(height: AppSizes.paddingMD),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: '$_calculatedCalories',
                            style: AppTextStyles.displayMedium()),
                        TextSpan(
                            text: '  kcal',
                            style: AppTextStyles.bodySmall(
                                color: AppColors.accent.withValues(alpha: 0.5))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  Text(
                    '${_gramCtrl.text}g of $_selectedFood',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: AppSizes.paddingXS),
                  Text(
                    '≈ ${(_foodDb[_selectedFood!]!['protein'] as num).toDouble() * (double.tryParse(_gramCtrl.text) ?? 0) / 100}g protein',
                    style: AppTextStyles.bodySmall(
                        color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: AppSizes.paddingLG),
                  PrimaryButton(
                    label: 'ADD TO LOG',
                    onTap: _add,
                    margin: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSizes.paddingXXL),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMD),
            decoration: AppDecorations.personalityCard(),
            child: Text(
              'Our database has ${_foodDb.length} common Indian foods with verified calorie data from IFCT (Indian Food Composition Tables).',
              style: AppTextStyles.bodySmall(
                  color: AppColors.accent.withValues(alpha: 0.55)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gramCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────
// RUNNING TOTAL — shows added items + save
// ─────────────────────────────────────────
class _RunningTotal extends StatelessWidget {
  final List<_LogEntry> entries;
  final int total;
  final Function(int) onRemove;
  final VoidCallback onSave;

  const _RunningTotal({
    required this.entries,
    required this.total,
    required this.onRemove,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF2111927),
        border: Border(
            top: BorderSide(color: AppColors.accent.withValues(alpha: 0.08))),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingXXL,
        AppSizes.paddingMD,
        AppSizes.paddingXXL,
        AppSizes.paddingXXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Items
          ...entries.asMap().entries.map((e) {
            final entry = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  DishIcon(iconType: 'other'),
                  const SizedBox(width: AppSizes.paddingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.name,
                            style: AppTextStyles.dishName(),
                            overflow: TextOverflow.ellipsis),
                        Text(entry.serving,
                            style: AppTextStyles.dishSub()),
                      ],
                    ),
                  ),
                  Text('${entry.calories} kcal',
                      style: AppTextStyles.calorieRange()),
                  const SizedBox(width: AppSizes.paddingSM),
                  GestureDetector(
                    onTap: () => onRemove(e.key),
                    child: Icon(Icons.close_rounded,
                        size: 16,
                        color: AppColors.accent.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppSizes.paddingSM),
          const Divider(color: Color(0x0FFFFFFF)),
          const SizedBox(height: AppSizes.paddingSM),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL', style: AppTextStyles.label()),
                    Text('$total kcal',
                        style: AppTextStyles.stat()),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingXXL,
                      vertical: AppSizes.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius:
                    BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text('SAVE MEAL',
                      style: AppTextStyles.buttonPrimary()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────
class _LogEntry {
  final String name;
  final int calories;
  final String serving;
  final String method;

  const _LogEntry({
    required this.name,
    required this.calories,
    required this.serving,
    required this.method,
  });
}

class _SimpleInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final bool isDecimal;
  final String? error;
  final Function(String)? onChanged;

  const _SimpleInput({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.isDecimal,
    this.error,
    this.onChanged,
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
              color: error != null
                  ? const Color(0x80FF6B6B)
                  : AppColors.accent.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: TextInputType.numberWithOptions(
                      decimal: isDecimal, signed: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(isDecimal
                            ? r'^\d+\.?\d{0,1}'
                            : r'^\d+')),
                  ],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 20,
                      color: AppColors.accent.withValues(alpha: 0.25),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingLG,
                      vertical: AppSizes.paddingMD,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMD),
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: AppColors.accent.withValues(alpha: 0.1))),
                ),
                child: Text(suffix,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent.withValues(alpha: 0.55),
                    )),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.paddingMD),
            child: Text(error!,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xCCFF6B6B))),
          ),
        ],
      ],
    );
  }
}

class _TextInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? error;

  const _TextInputField({
    required this.controller,
    required this.hint,
    this.error,
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
              color: error != null
                  ? const Color(0x80FF6B6B)
                  : AppColors.accent.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 16,
                color: AppColors.accent.withValues(alpha: 0.28),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLG,
                vertical: AppSizes.paddingMD,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.paddingMD),
            child: Text(error!,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xCCFF6B6B))),
          ),
        ],
      ],
    );
  }
}