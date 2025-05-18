import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user ID
import 'package:intl/intl.dart';
import 'package:exp_ocr/models/budget_category_model.dart';
import 'package:exp_ocr/models/budget_period_model.dart';

class ModernBudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Assuming user is logged in

  String? get _userId => _auth.currentUser?.uid;

  // --- Budget Period Methods ---
  Future<String> ensureCurrentBudgetPeriodExists() async {
    print("Attempting to ensure budget period exists.");
    print("Current Firebase User: ${_auth.currentUser}");
    print("User ID for Firestore operation: ${_userId}");

    if (_userId == null) throw Exception("User not logged in");
    final now = DateTime.now();
    final budgetId =
        "monthly_${now.year}_${now.month.toString().padLeft(2, '0')}";

    final docRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(
        now.year,
        now.month + 1,
        0,
      ); // Last day of current month
      final newBudgetPeriod = BudgetPeriodModel(
        id: budgetId,
        budgetName: "${DateFormat.MMMM().format(now)} ${now.year} Budget",
        startDate: Timestamp.fromDate(startDate),
        endDate: Timestamp.fromDate(endDate),
      );
      await docRef.set(newBudgetPeriod.toFirestore());
    }
    return budgetId;
  }

  Stream<BudgetPeriodModel?> getBudgetPeriodStream(String budgetId) {
    if (_userId == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .snapshots()
        .map((doc) => doc.exists ? BudgetPeriodModel.fromFirestore(doc) : null);
  }

  // --- Category Methods ---
  Stream<List<BudgetCategoryModel>> getCategoriesStream(String budgetId) {
    if (_userId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .collection('budget_categories')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => BudgetCategoryModel.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<void> addCategory(
    String budgetId,
    BudgetCategoryModel category,
  ) async {
    if (_userId == null) throw Exception("User not logged in");
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .collection('budget_categories')
        .add(category.toFirestore()); // Firestore generates ID
  }

  Future<void> updateCategory(
    String budgetId,
    BudgetCategoryModel category,
  ) async {
    if (_userId == null) throw Exception("User not logged in");
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .collection('budget_categories')
        .doc(category.id)
        .update(category.toFirestore());
  }

  Future<void> deleteCategory(String budgetId, String categoryId) async {
    if (_userId == null) throw Exception("User not logged in");
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .collection('budget_categories')
        .doc(categoryId)
        .delete();
  }

  // Method to update spent amount (e.g., when a transaction is added)
  // This would typically be called from your transaction management logic
  Future<void> updateCategorySpentAmount(
    String budgetId,
    String categoryId,
    double newSpentAmount,
  ) async {
    if (_userId == null) throw Exception("User not logged in");
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .collection('budget_categories')
        .doc(categoryId)
        .update({'spentAmount': newSpentAmount});
  }
}
