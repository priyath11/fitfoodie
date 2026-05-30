// ─────────────────────────────────────────
// AUTH VIEWMODEL
// ─────────────────────────────────────────
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/firebase_service.dart';
import '../core/services/gemini_service.dart';
import '../models/models.dart';
import 'dart:io';

// AUTH STATE
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final FirebaseService _firebaseService;

  AuthViewModel(this._firebaseService) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firebaseService.login(email: email, password: password);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firebaseService.signUp(email: email, password: password);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─────────────────────────────────────────
// ONBOARDING VIEWMODEL
// ─────────────────────────────────────────
class OnboardingState {
  final bool isLoading;
  final String? error;
  final OnboardingData data;
  final int currentStep;
  final bool isComplete;

  const OnboardingState({
    this.isLoading = false,
    this.error,
    required this.data,
    this.currentStep = 0,
    this.isComplete = false,
  });

  OnboardingState copyWith({
    bool? isLoading,
    String? error,
    OnboardingData? data,
    int? currentStep,
    bool? isComplete,
  }) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
      currentStep: currentStep ?? this.currentStep,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class OnboardingViewModel extends StateNotifier<OnboardingState> {
  final FirebaseService _firebaseService;

  OnboardingViewModel(this._firebaseService)
      : super(OnboardingState(data: OnboardingData()));

  void setGoal(String goal) {
    final newData = state.data..goal = goal;
    state = state.copyWith(data: newData);
  }

  void setRegion(String region) {
    final newData = state.data..region = region;
    state = state.copyWith(data: newData);
  }

  void setSubRegion(String subRegion) {
    final newData = state.data..subRegion = subRegion;
    state = state.copyWith(data: newData);
  }

  void setDietType(String dietType) {
    final newData = state.data..dietType = dietType;
    state = state.copyWith(data: newData);
  }

  void setGender(String gender) {
    final newData = state.data..gender = gender;
    state = state.copyWith(data: newData);
  }

  void setWeeklyBudget(int budget) {
    final newData = state.data..weeklyBudgetOverride = budget;
    state = state.copyWith(data: newData);
  }

  void setCurrentWeight(double weight) {
    final newData = state.data..currentWeight = weight;
    state = state.copyWith(data: newData);
  }

  void setTargetWeight(double weight) {
    final newData = state.data..targetWeight = weight;
    state = state.copyWith(data: newData);
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<bool> completeOnboarding(String uid, String email) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = UserModel(
        uid: uid,
        email: email,
        name: state.data.name.isNotEmpty
            ? state.data.name
            : email.split('@')[0],
        goal: state.data.goal,
        region: 'global',
        dietType: state.data.dietType,
        gender: state.data.gender,
        currentWeight: state.data.currentWeight,
        targetWeight: state.data.targetWeight,
        weeklyBudget: state.data.weeklyBudget,
        createdAt: DateTime.now(),
      );

      await _firebaseService.saveUser(user);
      state = state.copyWith(isLoading: false, isComplete: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  String getPersonalityResponse() {
    switch (state.data.goal) {
      case 'lose_fat':
        return 'Losing fat while eating what you love. That\'s exactly what we\'re built for.';
      case 'stay_fit':
        return 'Staying fit without giving up your favourite food. Smart choice.';
      case 'build_muscle':
        return 'Building muscle on Indian food is very possible. We\'ll help you hit your protein.';
      case 'curious':
        return 'Curiosity is a great place to start. Let\'s see what you\'ve been eating.';
      default:
        return '';
    }
  }
}

// ─────────────────────────────────────────
// HOME VIEWMODEL
// ─────────────────────────────────────────
class HomeState {
  final bool isLoading;
  final UserModel? user;
  final List<MealModel> todaysMeals;
  final WeeklyBudgetModel? weeklyBudget;
  final int streak;
  final int todayProtein;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.user,
    this.todaysMeals = const [],
    this.weeklyBudget,
    this.streak = 0,
    this.todayProtein = 0,
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    UserModel? user,
    List<MealModel>? todaysMeals,
    WeeklyBudgetModel? weeklyBudget,
    int? streak,
    int? todayProtein,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      todaysMeals: todaysMeals ?? this.todaysMeals,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      streak: streak ?? this.streak,
      todayProtein: todayProtein ?? this.todayProtein,
      error: error,
    );
  }

  int get usedCalories {
    if (todaysMeals.isEmpty) return 0;
    return todaysMeals.fold(0, (sum, meal) {
      final avg = ((meal.totalCalorieMin + meal.totalCalorieMax) / 2).round();
      return sum + avg;
    });
  }

  int get remainingBudget {
    return (weeklyBudget?.remainingCalories ?? 13300);
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class HomeViewModel extends StateNotifier<HomeState> {
  final FirebaseService _firebaseService;

  HomeViewModel(this._firebaseService) : super(const HomeState());

  Future<void> loadHomeData() async {
    state = state.copyWith(isLoading: true);
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) return;

      final user = await _firebaseService.getUser(currentUser.uid);
      final meals = await _firebaseService.getTodaysMeals(currentUser.uid);

      // Always recalculate budget from actual meals in Firestore
      // This prevents stale calories showing after deletes or on fresh load
      await _firebaseService.recalculateWeeklyBudget(currentUser.uid);

      final budget = await _firebaseService.getWeeklyBudget(
        currentUser.uid,
        user?.weeklyBudget ?? 13300,
      );
      final streak = await _firebaseService.getUserStreak(currentUser.uid);

      int totalProtein = 0;
      for (final meal in meals) {
        totalProtein += meal.avgProtein;
      }

      state = state.copyWith(
        isLoading: false,
        user: user,
        todaysMeals: meals,
        weeklyBudget: budget,
        streak: streak,
        todayProtein: totalProtein,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    // Immediately clear displayed data so UI shows 0 while reloading
    // This prevents stale calories showing after meal delete
    state = state.copyWith(
      todaysMeals: [],
      weeklyBudget: state.weeklyBudget?.copyWith(usedCalories: 0),
      todayProtein: 0,
    );
    await loadHomeData();
  }

  // Called specifically after meal delete
  // Immediately zeroes display then reloads fresh from Firestore
  Future<void> refreshAfterDelete() async {
    state = state.copyWith(
      todaysMeals: [],
      weeklyBudget: state.weeklyBudget?.copyWith(usedCalories: 0),
      todayProtein: 0,
    );
    await loadHomeData();
  }
}

// ─────────────────────────────────────────
// MEAL LOG VIEWMODEL
// ─────────────────────────────────────────
class MealLogState {
  final bool isLoading;
  final File? photo1;
  final File? photo2;
  final File? photo3;
  final int currentPhotoStep; // 1, 2, 3
  final String oilLevel; // light, medium, heavy
  final String cookingLocation; // home, restaurant, ordered
  final String? selectedPlateId;
  final String? selectedPlateName;
  final String? selectedPlateSize;
  final bool useKnownPlate;
  final bool photosComplete;
  final String? error;

  const MealLogState({
    this.isLoading = false,
    this.photo1,
    this.photo2,
    this.photo3,
    this.currentPhotoStep = 1,
    this.oilLevel = 'medium',
    this.cookingLocation = 'home',
    this.selectedPlateId,
    this.selectedPlateName,
    this.selectedPlateSize,
    this.useKnownPlate = false,
    this.photosComplete = false,
    this.error,
  });

  MealLogState copyWith({
    bool? isLoading,
    File? photo1,
    File? photo2,
    File? photo3,
    int? currentPhotoStep,
    String? oilLevel,
    String? cookingLocation,
    String? selectedPlateId,
    String? selectedPlateName,
    String? selectedPlateSize,
    bool? useKnownPlate,
    bool? photosComplete,
    String? error,
  }) {
    return MealLogState(
      isLoading: isLoading ?? this.isLoading,
      photo1: photo1 ?? this.photo1,
      photo2: photo2 ?? this.photo2,
      photo3: photo3 ?? this.photo3,
      currentPhotoStep: currentPhotoStep ?? this.currentPhotoStep,
      oilLevel: oilLevel ?? this.oilLevel,
      cookingLocation: cookingLocation ?? this.cookingLocation,
      selectedPlateId: selectedPlateId ?? this.selectedPlateId,
      selectedPlateName: selectedPlateName ?? this.selectedPlateName,
      selectedPlateSize: selectedPlateSize ?? this.selectedPlateSize,
      useKnownPlate: useKnownPlate ?? this.useKnownPlate,
      photosComplete: photosComplete ?? this.photosComplete,
      error: error,
    );
  }

  bool get allPhotosReady {
    if (useKnownPlate) {
      return photo1 != null && photo2 != null;
    }
    return photo1 != null && photo2 != null && photo3 != null;
  }
}

class MealLogViewModel extends StateNotifier<MealLogState> {
  final FirebaseService _firebaseService;
  final GeminiService _geminiService;

  MealLogViewModel(this._firebaseService, this._geminiService)
      : super(const MealLogState());

  void setPhoto1(File file) {
    state = state.copyWith(photo1: file, currentPhotoStep: 2);
  }

  void setPhoto2(File file) {
    state = state.copyWith(photo2: file, currentPhotoStep: 3);
  }

  void setPhoto3(File file) {
    state = state.copyWith(
      photo3: file,
      photosComplete: true,
    );
  }

  void setOilLevel(String level) {
    state = state.copyWith(oilLevel: level);
  }

  void setCookingLocation(String location) {
    state = state.copyWith(cookingLocation: location);
  }

  void selectPlate({
    required String plateId,
    required String plateName,
    required String plateSize,
  }) {
    state = state.copyWith(
      selectedPlateId: plateId,
      selectedPlateName: plateName,
      selectedPlateSize: plateSize,
      useKnownPlate: true,
    );
  }

  void useNewPlate() {
    state = state.copyWith(
      useKnownPlate: false,
      selectedPlateId: null,
    );
  }

  void reset() {
    state = const MealLogState();
  }
}

// ─────────────────────────────────────────
// RESULTS VIEWMODEL
// ─────────────────────────────────────────
class ResultsState {
  final bool isAnalysing;
  final bool isSaving;
  final MealAnalysisResult? result;
  final String aiInsight;
  final bool isSaved;
  final String? error;

  const ResultsState({
    this.isAnalysing = false,
    this.isSaving = false,
    this.result,
    this.aiInsight = '',
    this.isSaved = false,
    this.error,
  });

  ResultsState copyWith({
    bool? isAnalysing,
    bool? isSaving,
    MealAnalysisResult? result,
    String? aiInsight,
    bool? isSaved,
    String? error,
  }) {
    return ResultsState(
      isAnalysing: isAnalysing ?? this.isAnalysing,
      isSaving: isSaving ?? this.isSaving,
      result: result ?? this.result,
      aiInsight: aiInsight ?? this.aiInsight,
      isSaved: isSaved ?? this.isSaved,
      error: error,
    );
  }
}

class ResultsViewModel extends StateNotifier<ResultsState> {
  final FirebaseService _firebaseService;

  ResultsViewModel(this._firebaseService)
      : super(const ResultsState());

  // Analysis now happens in confirmation_screen.dart
  // This method is kept for fallback only
  Future<void> analyseMeal({
    required File photo1,
    required File photo2,
    required File photo3,
    required String oilLevel,
    required String cookingLocation,
    required String region,
    required String dietType,
    required String goal,
    required int remainingBudget,
    required int streak,
  }) async {
    // No longer used - flow goes through confirmation screen
    // Kept for backward compatibility
    state = state.copyWith(isAnalysing: false);
  }

  Future<bool> saveMeal({
    required String userId,
    required List<File> photos,
    required String oilLevel,
    required String cookingLocation,
    required String plateId,
    required int weeklyBudget,
  }) async {
    if (state.result == null) return false;

    state = state.copyWith(isSaving: true);
    try {
      final mealId = DateTime.now().millisecondsSinceEpoch.toString();
      final photoUrls = <String>[];

      // Upload photos
      for (int i = 0; i < photos.length; i++) {
        final url = await _firebaseService.uploadMealPhoto(
          file: photos[i],
          userId: userId,
          mealId: mealId,
          photoIndex: i + 1,
        );
        photoUrls.add(url);
      }

      // Determine meal type
      final hour = DateTime.now().hour;
      String mealType = 'meal';
      if (hour >= 6 && hour < 11) mealType = 'breakfast';
      if (hour >= 11 && hour < 16) mealType = 'lunch';
      if (hour >= 16 && hour < 19) mealType = 'snack';
      if (hour >= 19) mealType = 'dinner';

      final meal = MealModel(
        id: mealId,
        userId: userId,
        mealName: state.result!.mealName,
        mealType: mealType,
        dishes: state.result!.dishes,
        totalCalorieMin: state.result!.totalCalorieMin,
        totalCalorieMax: state.result!.totalCalorieMax,
        totalProteinMin: state.result!.totalProteinMin,
        totalProteinMax: state.result!.totalProteinMax,
        oilLevel: oilLevel,
        cookingLocation: cookingLocation,
        aiInsight: state.aiInsight,
        photoUrls: photoUrls,
        plateId: plateId,
        loggedAt: DateTime.now(),
      );

      await _firebaseService.saveMeal(meal);

      // Update weekly budget
      final avgCalories =
      ((state.result!.totalCalorieMin + state.result!.totalCalorieMax) / 2)
          .round();
      await _firebaseService.updateWeeklyBudget(
        userId: userId,
        caloriesAdded: avgCalories,
        dayIndex: DateTime.now().weekday - 1,
      );

      state = state.copyWith(isSaving: false, isSaved: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save meal. Please try again.',
      );
      return false;
    }
  }


  Future<bool> saveMealWithDishes({
    required String userId,
    required List<File> photos,
    required String oilLevel,
    required String cookingLocation,
    required String plateId,
    required int weeklyBudget,
    required List<DishModel> dishes,
    required int totalCalorieMin,
    required int totalCalorieMax,
    required int totalProteinMin,
    required int totalProteinMax,
  }) async {
    if (state.result == null) return false;

    state = state.copyWith(isSaving: true);
    try {
      final mealId = DateTime.now().millisecondsSinceEpoch.toString();

      // Try to upload photos — if it fails, save meal without photos
      final photoUrls = <String>[];
      try {
        for (int i = 0; i < photos.length; i++) {
          final url = await _firebaseService.uploadMealPhoto(
            file: photos[i],
            userId: userId,
            mealId: mealId,
            photoIndex: i + 1,
          );
          photoUrls.add(url);
        }
      } catch (photoError) {
        // ignore: avoid_print
        print('[FitFoodieAI] Photo upload failed — saving meal without photos: $photoError');
        // Continue without photos — meal data is more important
      }

      final hour = DateTime.now().hour;
      String mealType = 'meal';
      if (hour >= 6 && hour < 11) mealType = 'breakfast';
      if (hour >= 11 && hour < 16) mealType = 'lunch';
      if (hour >= 16 && hour < 19) mealType = 'snack';
      if (hour >= 19) mealType = 'dinner';

      final meal = MealModel(
        id: mealId,
        userId: userId,
        mealName: state.result!.mealName,
        mealType: mealType,
        dishes: dishes,
        totalCalorieMin: totalCalorieMin,
        totalCalorieMax: totalCalorieMax,
        totalProteinMin: totalProteinMin,
        totalProteinMax: totalProteinMax,
        oilLevel: oilLevel,
        cookingLocation: cookingLocation,
        aiInsight: state.aiInsight,
        photoUrls: photoUrls,
        plateId: plateId,
        loggedAt: DateTime.now(),
      );

      // Save meal to Firestore — this is the critical step
      await _firebaseService.saveMeal(meal);

      // Update weekly budget
      final avgCalories = ((totalCalorieMin + totalCalorieMax) / 2).round();
      await _firebaseService.updateWeeklyBudget(
        userId: userId,
        caloriesAdded: avgCalories,
        dayIndex: DateTime.now().weekday - 1,
      );

      state = state.copyWith(isSaving: false, isSaved: true);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[FitFoodieAI] Save meal error: $e');
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> setPreloadedResult(MealAnalysisResult result) async {
    state = state.copyWith(
      isAnalysing: false,
      result: result,
    );

    // Generate insight using a local GeminiService instance
    try {
      final geminiService = GeminiService();
      final insight = await geminiService.generateInsight(
        mealName: result.mealName,
        totalCalories: result.avgCalories,
        totalProtein: result.avgProtein,
        remainingBudget: 13300,
        streak: 0,
        goal: 'stay_fit',
      );
      state = state.copyWith(aiInsight: insight);
    } catch (e) {
      // Insight is optional
    }
  }

  void reset() {
    state = const ResultsState();
  }
}

// ─────────────────────────────────────────
// WEEKLY VIEWMODEL
// ─────────────────────────────────────────
class WeeklyState {
  final bool isLoading;
  final WeeklyBudgetModel? weeklyBudget;
  final List<MealModel> weeksMeals;
  final String weeklyInsight;
  final String? error;

  const WeeklyState({
    this.isLoading = false,
    this.weeklyBudget,
    this.weeksMeals = const [],
    this.weeklyInsight = '',
    this.error,
  });

  WeeklyState copyWith({
    bool? isLoading,
    WeeklyBudgetModel? weeklyBudget,
    List<MealModel>? weeksMeals,
    String? weeklyInsight,
    String? error,
  }) {
    return WeeklyState(
      isLoading: isLoading ?? this.isLoading,
      weeklyBudget: weeklyBudget ?? this.weeklyBudget,
      weeksMeals: weeksMeals ?? this.weeksMeals,
      weeklyInsight: weeklyInsight ?? this.weeklyInsight,
      error: error,
    );
  }

  int get avgProtein {
    if (weeksMeals.isEmpty) return 0;
    final total = weeksMeals.fold(0, (sum, meal) {
      return sum +
          ((meal.totalProteinMin + meal.totalProteinMax) / 2).round();
    });
    return (total / weeksMeals.length).round();
  }

  List<int> get dailyCalories {
    final daily = List<int>.filled(7, 0);
    for (final meal in weeksMeals) {
      final dayIndex = meal.loggedAt.weekday - 1;
      if (dayIndex >= 0 && dayIndex < 7) {
        daily[dayIndex] +=
            ((meal.totalCalorieMin + meal.totalCalorieMax) / 2).round();
      }
    }
    return daily;
  }

  int get daysLogged {
    final days = <int>{};
    for (final meal in weeksMeals) {
      days.add(meal.loggedAt.weekday);
    }
    return days.length;
  }
}

class WeeklyViewModel extends StateNotifier<WeeklyState> {
  final FirebaseService _firebaseService;
  final GeminiService _geminiService;

  WeeklyViewModel(this._firebaseService, this._geminiService)
      : super(const WeeklyState());

  Future<void> loadWeeklyData(UserModel user) async {
    state = state.copyWith(isLoading: true);
    try {
      final meals = await _firebaseService.getWeeksMeals(user.uid);
      final budget =
      await _firebaseService.getWeeklyBudget(user.uid, user.weeklyBudget);

      final topDishes = meals
          .expand((m) => m.dishes.map((d) => d.name))
          .toList()
          .take(3)
          .toList();

      final insight = await _geminiService.generateWeeklySummary(
        totalCaloriesThisWeek: budget.usedCalories,
        weeklyBudget: budget.totalBudget,
        mealsLogged: meals.length,
        topMeal: topDishes.isNotEmpty ? topDishes.first : 'various dishes',
      );

      state = state.copyWith(
        isLoading: false,
        weeksMeals: meals,
        weeklyBudget: budget,
        weeklyInsight: insight,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}