// ─────────────────────────────────────────
// USER MODEL
// ─────────────────────────────────────────
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String goal;
  final String region;
  final String dietType;
  final String gender;
  final double currentWeight;
  final double targetWeight;
  final int weeklyBudget;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.goal,
    required this.region,
    required this.dietType,
    this.gender = '',
    required this.currentWeight,
    required this.targetWeight,
    required this.weeklyBudget,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      goal: map['goal'] ?? '',
      region: map['region'] ?? '',
      dietType: map['dietType'] ?? '',
      gender: map['gender'] ?? '',
      currentWeight: (map['currentWeight'] ?? 70.0).toDouble(),
      targetWeight: (map['targetWeight'] ?? 65.0).toDouble(),
      weeklyBudget: map['weeklyBudget'] ?? 13300,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'goal': goal,
      'region': region,
      'dietType': dietType,
      'gender': gender,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'weeklyBudget': weeklyBudget,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? name,
    String? goal,
    String? region,
    String? dietType,
    double? currentWeight,
    double? targetWeight,
    int? weeklyBudget,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      region: region ?? this.region,
      dietType: dietType ?? this.dietType,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      createdAt: createdAt,
    );
  }

  // Calculate weekly budget based on weight and goal
  static int calculateWeeklyBudget({
    required double currentWeight,
    required double targetWeight,
    required String goal,
  }) {
    double dailyCalories;
    double bmr = 10 * currentWeight + 500; // simplified BMR

    if (goal == 'lose_fat') {
      dailyCalories = bmr - 300;
    } else if (goal == 'build_muscle') {
      dailyCalories = bmr + 200;
    } else {
      dailyCalories = bmr;
    }

    // Clamp between 1200 and 2500 per day
    dailyCalories = dailyCalories.clamp(1200, 2500);
    return (dailyCalories * 7).round();
  }
}

// ─────────────────────────────────────────
// DISH MODEL
// ─────────────────────────────────────────
class DishModel {
  final String name;
  final String category;
  final String serving;
  final int weightGramsMin;
  final int weightGramsMax;
  final int calorieMin;
  final int calorieMax;
  final int proteinMin;
  final int proteinMax;
  final String iconType;

  DishModel({
    required this.name,
    required this.category,
    required this.serving,
    this.weightGramsMin = 0,
    this.weightGramsMax = 0,
    required this.calorieMin,
    required this.calorieMax,
    required this.proteinMin,
    required this.proteinMax,
    required this.iconType,
  });

  factory DishModel.fromMap(Map<String, dynamic> map) {
    return DishModel(
      name: map['name'] ?? '',
      category: map['category'] ?? 'other',
      serving: map['serving'] ?? '1 serving',
      weightGramsMin: (map['weightGramsMin'] as num?)?.toInt() ?? 0,
      weightGramsMax: (map['weightGramsMax'] as num?)?.toInt() ?? 0,
      calorieMin: map['calorieMin'] ?? 0,
      calorieMax: map['calorieMax'] ?? 0,
      proteinMin: map['proteinMin'] ?? 0,
      proteinMax: map['proteinMax'] ?? 0,
      iconType: map['iconType'] ?? 'other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'serving': serving,
      'weightGramsMin': weightGramsMin,
      'weightGramsMax': weightGramsMax,
      'calorieMin': calorieMin,
      'calorieMax': calorieMax,
      'proteinMin': proteinMin,
      'proteinMax': proteinMax,
      'iconType': iconType,
    };
  }

  String get weightRange => weightGramsMin > 0 ? '$weightGramsMin–${weightGramsMax}g' : '';
  String get calorieRange => '$calorieMin–$calorieMax';
  String get proteinRange => '$proteinMin–${proteinMax}g';
}

// ─────────────────────────────────────────
// MEAL MODEL
// ─────────────────────────────────────────
class MealModel {
  final String id;
  final String userId;
  final String mealName;
  final String mealType; // breakfast, lunch, dinner, snack
  final List<DishModel> dishes;
  final int totalCalorieMin;
  final int totalCalorieMax;
  final int totalProteinMin;
  final int totalProteinMax;
  final String oilLevel; // light, medium, heavy
  final String cookingLocation; // home, restaurant, ordered
  final String aiInsight;
  final List<String> photoUrls;
  final String plateId;
  final DateTime loggedAt;

  MealModel({
    required this.id,
    required this.userId,
    required this.mealName,
    required this.mealType,
    required this.dishes,
    required this.totalCalorieMin,
    required this.totalCalorieMax,
    required this.totalProteinMin,
    required this.totalProteinMax,
    required this.oilLevel,
    required this.cookingLocation,
    required this.aiInsight,
    required this.photoUrls,
    required this.plateId,
    required this.loggedAt,
  });

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      mealName: map['mealName'] ?? '',
      mealType: map['mealType'] ?? 'meal',
      dishes: (map['dishes'] as List<dynamic>? ?? [])
          .map((d) => DishModel.fromMap(d as Map<String, dynamic>))
          .toList(),
      totalCalorieMin: map['totalCalorieMin'] ?? 0,
      totalCalorieMax: map['totalCalorieMax'] ?? 0,
      totalProteinMin: map['totalProteinMin'] ?? 0,
      totalProteinMax: map['totalProteinMax'] ?? 0,
      oilLevel: map['oilLevel'] ?? 'medium',
      cookingLocation: map['cookingLocation'] ?? 'home',
      aiInsight: map['aiInsight'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      plateId: map['plateId'] ?? '',
      loggedAt: map['loggedAt'] != null
          ? DateTime.parse(map['loggedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'mealName': mealName,
      'mealType': mealType,
      'dishes': dishes.map((d) => d.toMap()).toList(),
      'totalCalorieMin': totalCalorieMin,
      'totalCalorieMax': totalCalorieMax,
      'totalProteinMin': totalProteinMin,
      'totalProteinMax': totalProteinMax,
      'oilLevel': oilLevel,
      'cookingLocation': cookingLocation,
      'aiInsight': aiInsight,
      'photoUrls': photoUrls,
      'plateId': plateId,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }

  String get calorieRange => '$totalCalorieMin–$totalCalorieMax';
  String get proteinRange => '$totalProteinMin–${totalProteinMax}g';
  int get avgCalories => ((totalCalorieMin + totalCalorieMax) / 2).round();
  int get avgProtein => ((totalProteinMin + totalProteinMax) / 2).round();

  String get timeFormatted {
    final h = loggedAt.hour;
    final m = loggedAt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
}

// ─────────────────────────────────────────
// PLATE MODEL
// ─────────────────────────────────────────
class PlateModel {
  final String id;
  final String userId;
  final String name;
  final String shape; // round, square, oval
  final String size; // small, medium, large
  final String photoUrl;
  final int usageCount;
  final DateTime savedAt;

  PlateModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.shape,
    required this.size,
    required this.photoUrl,
    required this.usageCount,
    required this.savedAt,
  });

  factory PlateModel.fromMap(Map<String, dynamic> map) {
    return PlateModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'My plate',
      shape: map['shape'] ?? 'round',
      size: map['size'] ?? 'medium',
      photoUrl: map['photoUrl'] ?? '',
      usageCount: map['usageCount'] ?? 0,
      savedAt: map['savedAt'] != null
          ? DateTime.parse(map['savedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'shape': shape,
      'size': size,
      'photoUrl': photoUrl,
      'usageCount': usageCount,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}

// ─────────────────────────────────────────
// WEEKLY BUDGET MODEL
// ─────────────────────────────────────────
class WeeklyBudgetModel {
  final String userId;
  final int weekNumber;
  final int year;
  final int totalBudget;
  final int usedCalories;
  final int daysLogged;
  final List<int> dailyCalories; // 7 values Mon-Sun
  final DateTime weekStart;

  WeeklyBudgetModel({
    required this.userId,
    required this.weekNumber,
    required this.year,
    required this.totalBudget,
    required this.usedCalories,
    required this.daysLogged,
    required this.dailyCalories,
    required this.weekStart,
  });

  int get remainingCalories => (totalBudget - usedCalories).clamp(0, totalBudget);
  double get usedPercentage => totalBudget > 0 ? (usedCalories / totalBudget).clamp(0.0, 1.0) : 0.0;
  bool get isUnderBudget => usedCalories <= totalBudget;

  WeeklyBudgetModel copyWith({
    int? usedCalories,
    int? totalBudget,
    int? daysLogged,
    List<int>? dailyCalories,
  }) {
    return WeeklyBudgetModel(
      userId: userId,
      weekNumber: weekNumber,
      year: year,
      totalBudget: totalBudget ?? this.totalBudget,
      usedCalories: usedCalories ?? this.usedCalories,
      daysLogged: daysLogged ?? this.daysLogged,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      weekStart: weekStart,
    );
  }

  factory WeeklyBudgetModel.fromMap(Map<String, dynamic> map) {
    return WeeklyBudgetModel(
      userId: map['userId'] ?? '',
      weekNumber: map['weekNumber'] ?? 1,
      year: map['year'] ?? DateTime.now().year,
      totalBudget: map['totalBudget'] ?? 13300,
      usedCalories: map['usedCalories'] ?? 0,
      daysLogged: map['daysLogged'] ?? 0,
      dailyCalories: List<int>.from(map['dailyCalories'] ?? [0,0,0,0,0,0,0]),
      weekStart: map['weekStart'] != null
          ? DateTime.parse(map['weekStart'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'weekNumber': weekNumber,
      'year': year,
      'totalBudget': totalBudget,
      'usedCalories': usedCalories,
      'daysLogged': daysLogged,
      'dailyCalories': dailyCalories,
      'weekStart': weekStart.toIso8601String(),
    };
  }
}

// ─────────────────────────────────────────
// ONBOARDING MODEL
// ─────────────────────────────────────────
class OnboardingData {
  String name;
  String goal;
  String region;
  String subRegion;
  String dietType;
  String gender;
  double currentWeight;
  double targetWeight;
  int weeklyBudgetOverride;

  OnboardingData({
    this.name = '',
    this.goal = '',
    this.region = '',
    this.subRegion = '',
    this.dietType = '',
    this.gender = '',
    this.currentWeight = 70.0,
    this.targetWeight = 65.0,
    this.weeklyBudgetOverride = 0,
  });

  int get weeklyBudget => weeklyBudgetOverride > 0
      ? weeklyBudgetOverride
      : UserModel.calculateWeeklyBudget(
    currentWeight: currentWeight,
    targetWeight: targetWeight,
    goal: goal,
  );
}