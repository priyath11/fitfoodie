import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/models.dart';


class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── AUTH ──────────────────────────────────

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Login with email and password
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // ── USER DATA ─────────────────────────────

  // Save user to Firestore
  Future<void> saveUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  // Get user from Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data != null && data['goal'] != null && data['goal'] != '';
    } catch (e) {
      return false;
    }
  }

  // ── MEALS ─────────────────────────────────

  // Save meal
  Future<void> saveMeal(MealModel meal) async {
    await _firestore
        .collection('meals')
        .doc(meal.id)
        .set(meal.toMap());
  }

  // Delete meal
  Future<void> deleteMeal(String mealId, {int caloriesToSubtract = 0, String? userId}) async {
    await _firestore.collection('meals').doc(mealId).delete();
    // Subtract calories from weekly budget when meal is deleted
    if (caloriesToSubtract > 0 && userId != null) {
      try {
        final now = DateTime.now();
        final weekNumber = _getWeekNumber(now);
        final docId = '${userId}_${now.year}_$weekNumber';
        await _firestore.collection('weekly_budgets').doc(docId).update({
          'usedCalories': FieldValue.increment(-caloriesToSubtract),
        });
      } catch (e) {
        // ignore: avoid_print
        print('[FitFoodieAI] Failed to subtract calories: $e');
      }
    }
  }

  // Recalculate weekly budget from scratch based on logged meals
  // Called after all meals deleted to ensure 0% ring
  Future<void> recalculateWeeklyBudget(String userId) async {
    try {
      final now = DateTime.now();
      final weekNumber = _getWeekNumber(now);
      final docId = '${userId}_${now.year}_$weekNumber';
      final weekStart = _getWeekStart(now);

      final snapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .where('loggedAt', isGreaterThanOrEqualTo: weekStart.toIso8601String())
          .get();

      int totalCalories = 0;
      for (final doc in snapshot.docs) {
        final meal = MealModel.fromMap(doc.data());
        totalCalories += meal.avgCalories;
      }

      await _firestore.collection('weekly_budgets').doc(docId).update({
        'usedCalories': totalCalories,
      });
    } catch (e) {
      // ignore: avoid_print
      print('[FitFoodieAI] recalculateWeeklyBudget error: $e');
    }
  }

  // Get today's meals
  Future<List<MealModel>> getTodaysMeals(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .where('loggedAt',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('loggedAt', isLessThan: endOfDay.toIso8601String())
          .orderBy('loggedAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MealModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get this week's meals
  Future<List<MealModel>> getWeeksMeals(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek =
      DateTime(weekStart.year, weekStart.month, weekStart.day);

      final snapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .where('loggedAt',
          isGreaterThanOrEqualTo: startOfWeek.toIso8601String())
          .orderBy('loggedAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MealModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get recent meals for quick log
  Future<List<MealModel>> getRecentMeals(String userId,
      {int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .orderBy('loggedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MealModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── PLATES ───────────────────────────────

  // Save plate
  Future<void> savePlate(PlateModel plate) async {
    await _firestore
        .collection('plates')
        .doc(plate.id)
        .set(plate.toMap(), SetOptions(merge: true));
  }

  // Get user's plates
  Future<List<PlateModel>> getUserPlates(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('plates')
          .where('userId', isEqualTo: userId)
          .orderBy('usageCount', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlateModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Increment plate usage
  Future<void> incrementPlateUsage(String plateId) async {
    await _firestore.collection('plates').doc(plateId).update({
      'usageCount': FieldValue.increment(1),
    });
  }

  // ── STORAGE ──────────────────────────────

  // Upload meal photo
  Future<String> uploadMealPhoto({
    required File file,
    required String userId,
    required String mealId,
    required int photoIndex,
  }) async {
    final ref = _storage
        .ref()
        .child('meals')
        .child(userId)
        .child(mealId)
        .child('photo_$photoIndex.jpg');

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  // Upload plate photo
  Future<String> uploadPlatePhoto({
    required File file,
    required String userId,
    required String plateId,
  }) async {
    final ref = _storage
        .ref()
        .child('plates')
        .child(userId)
        .child('$plateId.jpg');

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  // ── WEEKLY BUDGET ─────────────────────────

  // Get or create weekly budget
  Future<WeeklyBudgetModel> getWeeklyBudget(
      String userId, int budget) async {
    try {
      final now = DateTime.now();
      final weekNumber = _getWeekNumber(now);
      final docId = '${userId}_${now.year}_$weekNumber';

      final doc =
      await _firestore.collection('weekly_budgets').doc(docId).get();

      if (doc.exists && doc.data() != null) {
        return WeeklyBudgetModel.fromMap(doc.data()!);
      }

      // Create new weekly budget
      final newBudget = WeeklyBudgetModel(
        userId: userId,
        weekNumber: weekNumber,
        year: now.year,
        totalBudget: budget,
        usedCalories: 0,
        daysLogged: 0,
        dailyCalories: [0, 0, 0, 0, 0, 0, 0],
        weekStart: _getWeekStart(now),
      );

      await _firestore
          .collection('weekly_budgets')
          .doc(docId)
          .set(newBudget.toMap());

      return newBudget;
    } catch (e) {
      return WeeklyBudgetModel(
        userId: userId,
        weekNumber: 1,
        year: DateTime.now().year,
        totalBudget: budget,
        usedCalories: 0,
        daysLogged: 0,
        dailyCalories: [0, 0, 0, 0, 0, 0, 0],
        weekStart: DateTime.now(),
      );
    }
  }

  // Update weekly budget after meal log
  Future<void> updateWeeklyBudget({
    required String userId,
    required int caloriesAdded,
    required int dayIndex,
  }) async {
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    final docId = '${userId}_${now.year}_$weekNumber';

    await _firestore.collection('weekly_budgets').doc(docId).update({
      'usedCalories': FieldValue.increment(caloriesAdded),
    });
  }

  // Helpers
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(firstDayOfYear).inDays;
    return (daysDiff / 7).ceil() + 1;
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // ── STREAK ───────────────────────────────

  Future<int> getUserStreak(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['streak'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> updateStreak(String userId, int streak) async {
    await _firestore.collection('users').doc(userId).update({
      'streak': streak,
      'lastLogDate': DateTime.now().toIso8601String(),
    });
  }
}