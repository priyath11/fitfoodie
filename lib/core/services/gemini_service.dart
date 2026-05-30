import 'dart:io';
import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';

import '../../models/models.dart';

class GeminiService {
  late final GenerativeModel _visionModel;
  late final GenerativeModel _nutritionModel;

  static const List<String> _models = [
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-2.5-flash',
  ];

  GeminiService() {
    _visionModel = FirebaseAI.googleAI().generativeModel(
      model: _models.first,
    );
    _nutritionModel = FirebaseAI.googleAI().generativeModel(
      model: _models.first,
    );
  }

  GenerativeModel _getModel(int index) {
    final name = _models[index.clamp(0, _models.length - 1)];
    return FirebaseAI.googleAI().generativeModel(model: name);
  }

  // ── STEP 1: IDENTIFY DISHES ──────────────
  Future<List<IdentifiedDish>> identifyDishes({
    required File photo1,
    required File photo2,
    required File photo3,
    required String dietType,
    String region = 'global',
  }) async {
    try {
      final bytes1 = await photo1.readAsBytes();
      final bytes2 = await photo2.readAsBytes();
      final bytes3 = await photo3.readAsBytes();
      final prompt = _identificationPrompt(region, dietType);

      for (int mi = 0; mi < _models.length; mi++) {
        final model = _getModel(mi);
        for (int attempt = 1; attempt <= 2; attempt++) {
          try {
            final response = await model.generateContent([
              Content.multi([
                InlineDataPart('image/jpeg', bytes1),
                InlineDataPart('image/jpeg', bytes2),
                InlineDataPart('image/jpeg', bytes3),
                TextPart(prompt),
              ])
            ]).timeout(const Duration(seconds: 20));
            final text = response.text ?? '';
            // ignore: avoid_print
            print('[FitFoodieAI] ID success model=${_models[mi]}');
            return _parseIdentification(text);
          } catch (e) {
            final err = e.toString();
            final overload = err.contains('overloaded') ||
                err.contains('503') ||
                err.contains('429') ||
                err.contains('RESOURCE_EXHAUSTED') ||
                err.contains('TimeoutException');
            // ignore: avoid_print
            print('[FitFoodieAI] ID fail model=${_models[mi]} attempt=$attempt');
            if (overload && attempt < 2) {
              await Future.delayed(const Duration(seconds: 3));
              continue;
            }
            break;
          }
        }
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('[FitFoodieAI] ID error: $e');
      return [];
    }
  }

  // ── STEP 2: GET NUTRITION ─────────────────
  Future<MealAnalysisResult> getNutritionForConfirmedDishes({
    required List<IdentifiedDish> confirmedDishes,
    required String oilLevel,
    required String cookingLocation,
    required String mealName,
    String region = 'global',
  }) async {
    try {
      final dishList = confirmedDishes
          .map((d) => '- ${d.name} (${d.portion})')
          .join('\n');

      final oilNote = oilLevel == 'none'
          ? 'No oil - use base calorie values. Raw, steamed, boiled or dry.'
          : oilLevel == 'light'
          ? 'Light oil - subtract 15 percent from typical values.'
          : oilLevel == 'heavy'
          ? 'Heavy oil - add 25 percent to typical values.'
          : 'Medium oil - use standard values.';

      final locationNote = cookingLocation == 'restaurant'
          ? 'Restaurant - add 20 to 30 percent more calories vs home cooking.'
          : cookingLocation == 'ordered'
          ? 'Ordered or delivery - add 15 to 25 percent vs home cooking.'
          : 'Home cooked - use standard home cooking values.';

      final prompt = _nutritionPrompt(
        dishList: dishList,
        oilNote: oilNote,
        locationNote: locationNote,
        region: region,
      );

      for (int mi = 0; mi < _models.length; mi++) {
        final model = _getModel(mi);
        for (int attempt = 1; attempt <= 2; attempt++) {
          try {
            final response = await model.generateContent([
              Content.text(prompt),
            ]).timeout(const Duration(seconds: 15));
            final text = response.text ?? '';
            // ignore: avoid_print
            print('[FitFoodieAI] Nutrition success model=${_models[mi]}');
            return _parseNutrition(text, mealName);
          } catch (e) {
            final err = e.toString();
            final overload = err.contains('overloaded') ||
                err.contains('503') ||
                err.contains('429') ||
                err.contains('RESOURCE_EXHAUSTED') ||
                err.contains('TimeoutException');
            // ignore: avoid_print
            print('[FitFoodieAI] Nutrition fail model=${_models[mi]} attempt=$attempt');
            if (overload && attempt < 2) {
              await Future.delayed(const Duration(seconds: 3));
              continue;
            }
            break;
          }
        }
      }
      return _failedResult('All AI models are currently busy. Please try again.');
    } catch (e) {
      // ignore: avoid_print
      print('[FitFoodieAI] Nutrition error: $e');
      return _failedResult(e.toString());
    }
  }

  // ── GENERATE INSIGHT ──────────────────────
  Future<String> generateInsight({
    required String mealName,
    required int totalCalories,
    required int totalProtein,
    required int remainingBudget,
    required int streak,
    required String goal,
  }) async {
    try {
      final model = _getModel(0);
      final response = await model.generateContent([
        Content.text(
          'You are Fit Foodie AI, a warm Indian nutrition assistant. '
              'Never mention Gemini or Google. '
              'User logged $mealName. '
              'Calories: $totalCalories kcal. Protein: $totalProtein g. '
              'Remaining weekly budget: $remainingBudget kcal. '
              'Streak: $streak days. Goal: $goal. '
              'Write exactly 2 warm encouraging sentences referencing Indian food culture. '
              'Maximum 35 words. No emojis.',
        ),
      ]).timeout(const Duration(seconds: 10));
      return response.text?.trim() ?? '';
    } catch (e) {
      return '';
    }
  }

  // ── WEEKLY SUMMARY ────────────────────────
  Future<String> generateWeeklySummary({
    required int totalCaloriesThisWeek,
    required int weeklyBudget,
    required int mealsLogged,
    required String topMeal,
  }) async {
    try {
      final pct = weeklyBudget > 0
          ? (totalCaloriesThisWeek / weeklyBudget * 100).round()
          : 0;
      final model = _getModel(0);
      final response = await model.generateContent([
        Content.text(
          'Weekly: used $totalCaloriesThisWeek of $weeklyBudget kcal ($pct percent), '
              '$mealsLogged meals, top meal: $topMeal. '
              'Write 2 warm encouraging sentences. Maximum 30 words.',
        ),
      ]).timeout(const Duration(seconds: 10));
      return response.text?.trim() ?? '';
    } catch (e) {
      return '';
    }
  }

  // ── IDENTIFICATION PROMPT ─────────────────
  String _identificationPrompt(String region, String dietType) {
    return 'You are the world\'s most accurate food identification and nutrition AI. '
        'You have complete knowledge of every cuisine on earth — Indian (Kerala, Tamil Nadu, '
        'North Indian, Mughlai, street food), Western (burgers, pasta, pizza, salads), '
        'Asian (Chinese, Japanese, Thai, Korean), Middle Eastern, Mediterranean, '
        'and every other regional cuisine. You identify any food from any country accurately.\n\n'
        'You are looking at 3 photos of the same food or drink:\n'
        'Photo 1: Top-down bird eye view - see everything present\n'
        'Photo 2: 45-degree side angle - see shape, depth, volume\n'
        'Photo 3: Close-up with flash - see texture, coating, colour, surface detail\n\n'
        'YOUR TASK: Use your complete knowledge to identify every food item. '
        'Be specific. Name dishes exactly as an Indian would name them.\n\n'
        'BEFORE NAMING ANY DISH, check:\n'
        '1. Shape: flat, round, concave, elongated, irregular, liquid\n'
        '2. Colour: white, golden, dark brown, red, orange, yellow, black\n'
        '3. Texture: crispy, soft, spongy, dry, in gravy, wet, lacy\n'
        '4. Size relative to the 26cm mould frame\n'
        '5. Unique features: lacy edges, fish shape, bone, egg shape, layers\n\n'
        'CRITICAL RULES FOR SIMILAR-LOOKING DISHES:\n\n'
        'WHITE ROUND ITEMS - shape in Photo 2 decides:\n'
        'Appam: concave bowl shape, thick raised spongy white center, thin lacy edges. NEVER flat.\n'
        'Dosa: completely flat like a crepe, large, spread across surface, no raised center.\n'
        'Idli: flat-topped thick round cake, uniform spongy throughout, no lacy edges.\n'
        'Uttapam: thick flat with visible toppings like onion tomato chilli on surface.\n\n'
        'DARK BROWN FRIED ITEMS - outline shape decides:\n'
        'Fish fry: elongated fish body outline, tapered at both ends, dry coating. Fish shape is unmistakable.\n'
        'Egg roast: round oval egg shapes sitting inside dark thick masala gravy.\n'
        'Boiled egg: oval white shape with yellow yolk center, no gravy around it.\n'
        'Chicken fry: irregular bone-in pieces, thicker than fish, rough coating.\n'
        'Beef fry: very small dark dry pieces, almost black, no specific elongated shape.\n'
        'Prawn fry: curved C-shape like a comma, small, orange-brown.\n\n'
        'LIQUID CURRIES - colour and contents:\n'
        'Kerala fish curry: deep red or dark red gravy, fish pieces visible.\n'
        'Chicken curry: brown or orange gravy, bone-in chicken pieces visible.\n'
        'Egg curry: orange gravy with whole boiled eggs sitting in it.\n'
        'Dal: yellow or orange thin liquid, no meat, no bones.\n'
        'Sambar: thin brown liquid, vegetables floating inside.\n\n'
        'DRINKS - container and liquid colour:\n'
        'Use Photo 2 to estimate cup size relative to 26cm mould frame.\n'
        'Small cup is 100ml. Medium cup is 150ml. Large cup is 200ml or more.\n'
        'Tea with milk: light brown milky liquid in cup.\n'
        'Black coffee: very dark or black liquid.\n'
        'Filter coffee: dark coffee in small stainless steel tumbler with davara.\n\n'
        'PORTION ESTIMATION using 26cm mould frame as ruler:\n'
        'Dosa: fills 50 percent of frame = small 55-65g, 70 percent = medium 65-80g, full = 80-110g.\n'
        'Idli: count pieces. Each idli weighs 50-65g.\n'
        'Appam: count pieces. Each appam weighs 55-75g.\n'
        'Bowls and katoris: estimate fill level as full, three-quarter, half, or quarter.\n'
        'Cups: estimate cup size relative to frame.\n'
        'IMPORTANT: Always bias toward smaller estimates. Food looks larger in photos than reality.\n\n'
        'CONFIDENCE:\n'
        'high: certain from clear visual evidence.\n'
        'medium: fairly sure but one feature is unclear.\n'
        'low: can see something but cannot identify precisely.\n\n'
        'REGION: $region\n'
        'DIET: $dietType\n\n'
        'RESPOND WITH ONLY VALID JSON. NO MARKDOWN. NO EXTRA TEXT:\n\n'
        '{\n'
        '  "isEmpty": false,\n'
        '  "dishes": [\n'
        '    {\n'
        '      "name": "exact Indian dish name",\n'
        '      "portion": "estimated portion using mould frame reference",\n'
        '      "confidence": "high or medium or low",\n'
        '      "visualReasoning": "one sentence describing what you saw"\n'
        '    }\n'
        '  ]\n'
        '}';
  }

  // ── NUTRITION PROMPT ──────────────────────
  String _nutritionPrompt({
    required String dishList,
    required String oilNote,
    required String locationNote,
    required String region,
  }) {
    return 'You are an expert nutritionist with complete knowledge of every world cuisine. '
        'You know IFCT values for Indian food and equivalent databases for all other cuisines.\n\n'
        'The user confirmed these dishes with portions:\n'
        '$dishList\n\n'
        'Use the portion shown above as primary reference for weight estimation. '
        'Do not use generic defaults. The portion string tells you exactly what was eaten.\n\n'
        'Location: $locationNote\n'
        'Oil: $oilNote\n'
        'Region: $region\n\n'
        'ACCURATE WEIGHT REFERENCE from real weighing scale measurements:\n'
        'Plain dosa thin home style 1 piece: 55-75g\n'
        'Plain dosa medium restaurant 1 piece: 80-110g\n'
        'Masala dosa 1 piece: 150-200g including filling\n'
        'Idli 1 piece: 50-65g\n'
        'Appam 1 piece: 55-75g\n'
        'Puttu 1 piece: 90-120g\n'
        'Roti or Chapati 1 piece: 35-45g\n'
        'Parotta 1 piece: 60-80g\n'
        'Medium katori of curry: 130-160g\n'
        'Small katori of curry: 80-110g\n'
        'Large bowl of curry: 200-250g\n'
        'Cooked rice 1 cup: 180-200g\n'
        'Fish fry 1 medium piece: 80-110g\n'
        'Boiled egg 1: 45-55g\n'
        'Banana medium: 100-130g\n'
        'Tea or coffee 1 cup: 130-160ml\n\n'
        'CALORIE REFERENCE from IFCT:\n'
        'Appam 1 piece: 90 kcal, 2g protein\n'
        'Idli 1 piece: 39 kcal, 2g protein\n'
        'Dosa plain 1 medium: 120 kcal, 3g protein\n'
        'Dosa masala 1 medium: 200 kcal, 5g protein\n'
        'Upma 1 bowl 200g: 190 kcal, 5g protein\n'
        'Puttu 1 piece 100g: 140 kcal, 4g protein\n'
        'Kerala rice 1 cup 200g: 260 kcal, 5g protein\n'
        'Sambar 1 katori: 60 kcal, 3g protein\n'
        'Coconut chutney 2 tbsp: 60 kcal, 1g protein\n'
        'Fish curry Kerala 1 katori: 160 kcal, 18g protein\n'
        'Fish fry 1 medium piece: 180 kcal, 20g protein\n'
        'Karimeen fry 1 medium: 210 kcal, 22g protein\n'
        'Chicken curry Kerala 1 katori: 220 kcal, 22g protein\n'
        'Beef fry Kerala 1 katori: 280 kcal, 25g protein\n'
        'Egg roast 1 egg: 120 kcal, 8g protein\n'
        'Boiled egg 1: 78 kcal, 6g protein\n'
        'Parotta 1 piece: 160 kcal, 4g protein\n'
        'Roti 1 piece: 90 kcal, 3g protein\n'
        'Dal tadka 1 katori: 150 kcal, 9g protein\n'
        'Paneer butter masala 1 katori: 280 kcal, 15g protein\n'
        'Biryani Kerala 1 plate: 520 kcal, 20g protein\n'
        'Tea with milk small 100ml: 35 kcal, 1g protein\n'
        'Tea with milk medium 150ml: 50 kcal, 2g protein\n'
        'Tea with milk large 200ml: 75 kcal, 3g protein\n'
        'Black coffee medium: 5 kcal, 0g protein\n'
        'Filter coffee medium: 60 kcal, 2g protein\n'
        'Banana medium: 89 kcal, 1g protein\n'
        'Water: 0 kcal, 0g protein\n\n'
        'For any dish not in list above use your complete IFCT knowledge.\n\n'
        'RESPOND WITH ONLY VALID JSON. NO MARKDOWN. NO EXTRA TEXT:\n\n'
        '{\n'
        '  "dishes": [\n'
        '    {\n'
        '      "name": "confirmed dish name",\n'
        '      "category": "rice or curry or roti or fish or chicken or egg or dal or sabzi or snack or chai or biryani or other",\n'
        '      "serving": "confirmed portion",\n'
        '      "weightGramsMin": 55,\n'
        '      "weightGramsMax": 75,\n'
        '      "calorieMin": 80,\n'
        '      "calorieMax": 100,\n'
        '      "proteinMin": 2,\n'
        '      "proteinMax": 3,\n'
        '      "iconType": "rice or curry or roti or fish or chicken or egg or dal or sabzi or snack or chai or biryani or other"\n'
        '    }\n'
        '  ],\n'
        '  "totalCalorieMin": 80,\n'
        '  "totalCalorieMax": 100,\n'
        '  "totalProteinMin": 2,\n'
        '  "totalProteinMax": 3\n'
        '}';
  }

  // ── PARSE IDENTIFICATION ──────────────────
  List<IdentifiedDish> _parseIdentification(String text) {
    try {
      String cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();
      }
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart < 0 || jsonEnd <= jsonStart) return [];

      cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      final isEmpty = json['isEmpty'] as bool? ?? false;
      if (isEmpty) return [];

      final dishesJson = json['dishes'] as List<dynamic>? ?? [];
      return dishesJson.map((d) {
        final map = d as Map<String, dynamic>;
        return IdentifiedDish(
          name: map['name'] as String? ?? 'Unknown dish',
          portion: map['portion'] as String? ?? '1 serving',
          confidence: map['confidence'] as String? ?? 'medium',
          visualReasoning: map['visualReasoning'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[FitFoodieAI] Parse ID error: $e');
      return [];
    }
  }

  // ── PARSE NUTRITION ───────────────────────
  MealAnalysisResult _parseNutrition(String text, String mealName) {
    try {
      String cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();
      }
      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart < 0 || jsonEnd <= jsonStart) {
        return _failedResult('Invalid response format');
      }

      cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      final dishesJson = json['dishes'] as List<dynamic>? ?? [];
      final dishes = dishesJson.map((d) {
        final map = d as Map<String, dynamic>;
        return DishModel(
          name: map['name'] as String? ?? '',
          category: map['category'] as String? ?? 'other',
          serving: map['serving'] as String? ?? '1 serving',
          weightGramsMin: (map['weightGramsMin'] as num?)?.toInt() ?? 0,
          weightGramsMax: (map['weightGramsMax'] as num?)?.toInt() ?? 0,
          calorieMin: (map['calorieMin'] as num?)?.toInt() ?? 0,
          calorieMax: (map['calorieMax'] as num?)?.toInt() ?? 0,
          proteinMin: (map['proteinMin'] as num?)?.toInt() ?? 0,
          proteinMax: (map['proteinMax'] as num?)?.toInt() ?? 0,
          iconType: map['iconType'] as String? ?? 'other',
        );
      }).toList();

      int calMin = (json['totalCalorieMin'] as num?)?.toInt() ?? 0;
      int calMax = (json['totalCalorieMax'] as num?)?.toInt() ?? 0;
      int protMin = (json['totalProteinMin'] as num?)?.toInt() ?? 0;
      int protMax = (json['totalProteinMax'] as num?)?.toInt() ?? 0;

      if (dishes.isNotEmpty) {
        final dishCalMin = dishes.fold(0, (sum, d) => sum + d.calorieMin);
        final dishCalMax = dishes.fold(0, (sum, d) => sum + d.calorieMax);
        if ((dishCalMin - calMin).abs() > 100) {
          calMin = dishCalMin;
          calMax = dishCalMax;
        }
      }

      return MealAnalysisResult(
        mealName: mealName,
        dishes: dishes,
        totalCalorieMin: calMin,
        totalCalorieMax: calMax,
        totalProteinMin: protMin,
        totalProteinMax: protMax,
        isEmpty: false,
        success: true,
        confidence: 'high',
        notes: '',
      );
    } catch (e) {
      return _failedResult('Could not read response. Please try again.');
    }
  }

  // ── FAILED RESULT ─────────────────────────
  MealAnalysisResult _failedResult([String? errorMsg]) {
    String userMsg = 'Analysis failed. Please try again.';
    if (errorMsg != null) {
      if (errorMsg.contains('quota') || errorMsg.contains('429') ||
          errorMsg.contains('overloaded') || errorMsg.contains('503')) {
        userMsg = 'Service busy. Please try again in a moment.';
      } else if (errorMsg.contains('SocketException') ||
          errorMsg.contains('network')) {
        userMsg = 'No internet connection. Please check and try again.';
      } else {
        userMsg = errorMsg.length > 100
            ? errorMsg.substring(0, 100)
            : errorMsg;
      }
    }
    // ignore: avoid_print
    print('[FitFoodieAI] Failed: $userMsg');
    return MealAnalysisResult(
      mealName: 'Could not analyse',
      dishes: [],
      totalCalorieMin: 0,
      totalCalorieMax: 0,
      totalProteinMin: 0,
      totalProteinMax: 0,
      isEmpty: false,
      success: false,
      confidence: 'low',
      notes: userMsg,
    );
  }
}

// ── IDENTIFIED DISH ───────────────────────
class IdentifiedDish {
  final String name;
  final String portion;
  final String confidence;
  final String visualReasoning;

  const IdentifiedDish({
    required this.name,
    required this.portion,
    required this.confidence,
    required this.visualReasoning,
  });

  IdentifiedDish copyWith({String? name, String? portion}) => IdentifiedDish(
    name: name ?? this.name,
    portion: portion ?? this.portion,
    confidence: confidence,
    visualReasoning: visualReasoning,
  );
}

// ── MEAL ANALYSIS RESULT ──────────────────
class MealAnalysisResult {
  final String mealName;
  final List<DishModel> dishes;
  final int totalCalorieMin;
  final int totalCalorieMax;
  final int totalProteinMin;
  final int totalProteinMax;
  final bool isEmpty;
  final bool success;
  final String confidence;
  final String notes;

  const MealAnalysisResult({
    required this.mealName,
    required this.dishes,
    required this.totalCalorieMin,
    required this.totalCalorieMax,
    required this.totalProteinMin,
    required this.totalProteinMax,
    required this.isEmpty,
    required this.success,
    required this.confidence,
    required this.notes,
  });

  String get calorieRange =>
      isEmpty ? '0' : '$totalCalorieMin--$totalCalorieMax';
  String get proteinRange =>
      isEmpty ? '0g' : '$totalProteinMin--${totalProteinMax}g';
  int get avgCalories =>
      isEmpty ? 0 : ((totalCalorieMin + totalCalorieMax) / 2).round();
  int get avgProtein =>
      isEmpty ? 0 : ((totalProteinMin + totalProteinMax) / 2).round();
}