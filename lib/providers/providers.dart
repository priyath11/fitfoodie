import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/firebase_service.dart';
import '../core/services/gemini_service.dart';
import '../models/models.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/meal_log_viewmodel.dart';
import '../viewmodels/results_viewmodel.dart';
import '../viewmodels/weekly_viewmodel.dart';

// ── SERVICES ──────────────────────────────

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

// ── AUTH ──────────────────────────────────

final authViewModelProvider =
StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(ref.read(firebaseServiceProvider));
});

// Current user stream
final authStateProvider = StreamProvider<dynamic>((ref) {
  return ref.read(firebaseServiceProvider).authStateChanges;
});

// ── USER ──────────────────────────────────

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseService = ref.read(firebaseServiceProvider);
  final user = firebaseService.currentUser;
  if (user == null) return null;
  return firebaseService.getUser(user.uid);
});

// ── ONBOARDING ────────────────────────────

final onboardingViewModelProvider =
StateNotifierProvider<OnboardingViewModel, OnboardingState>((ref) {
  return OnboardingViewModel(
    ref.read(firebaseServiceProvider),
  );
});

// ── HOME ──────────────────────────────────

final homeViewModelProvider =
StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  return HomeViewModel(
    ref.read(firebaseServiceProvider),
  );
});

// ── MEAL LOG ──────────────────────────────

final mealLogViewModelProvider =
StateNotifierProvider<MealLogViewModel, MealLogState>((ref) {
  return MealLogViewModel(
    ref.read(firebaseServiceProvider),
    ref.read(geminiServiceProvider),
  );
});

// ── RESULTS ───────────────────────────────

final resultsViewModelProvider =
StateNotifierProvider<ResultsViewModel, ResultsState>((ref) {
  return ResultsViewModel(
    ref.read(firebaseServiceProvider),
  );
});

// ── WEEKLY ────────────────────────────────

final weeklyViewModelProvider =
StateNotifierProvider<WeeklyViewModel, WeeklyState>((ref) {
  return WeeklyViewModel(
    ref.read(firebaseServiceProvider),
    ref.read(geminiServiceProvider),
  );
});

// ── TODAY'S MEALS ─────────────────────────

final todaysMealsProvider = FutureProvider<List<MealModel>>((ref) async {
  final firebaseService = ref.read(firebaseServiceProvider);
  final user = firebaseService.currentUser;
  if (user == null) return [];
  return firebaseService.getTodaysMeals(user.uid);
});

// ── USER PLATES ───────────────────────────

final userPlatesProvider = FutureProvider<List<PlateModel>>((ref) async {
  final firebaseService = ref.read(firebaseServiceProvider);
  final user = firebaseService.currentUser;
  if (user == null) return [];
  return firebaseService.getUserPlates(user.uid);
});

// ── STREAK ───────────────────────────────

final streakProvider = FutureProvider<int>((ref) async {
  final firebaseService = ref.read(firebaseServiceProvider);
  final user = firebaseService.currentUser;
  if (user == null) return 0;
  return firebaseService.getUserStreak(user.uid);
});