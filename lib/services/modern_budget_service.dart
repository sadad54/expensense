import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exp_ocr/util/expense_categories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget_category_model.dart';
import '../models/budget_period_model.dart';
import 'package:intl/intl.dart'; // For DateFormat
// Import the default categories data

class ModernBudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Future<String> ensureCurrentBudgetPeriodExists() async {
    if (_userId == null) throw Exception("User not logged in");
    final now = DateTime.now();
    // Using monthly_YYYY_MM format for budgetId
    final budgetId =
        "monthly_${now.year}_${now.month.toString().padLeft(2, '0')}";
    final userBudgetsCollection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets');
    final budgetDocRef = userBudgetsCollection.doc(budgetId);
    final snapshot = await budgetDocRef.get();

    if (!snapshot.exists) {
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);
      final newBudgetPeriod = BudgetPeriodModel(
        id: budgetId,
        budgetName: "${DateFormat.MMMM().format(now)} ${now.year} Budget",
        startDate: Timestamp.fromDate(startDate),
        endDate: Timestamp.fromDate(endDate),
      );
      await budgetDocRef.set(newBudgetPeriod.toFirestore());

      // --- Automatically add default categories for the new budget period ---
      final categoriesCollectionRef = budgetDocRef.collection('categories');
      WriteBatch batch = _firestore.batch();

      for (var catData in defaultBudgetCategoryData) {
        final newCategoryDocRef =
            categoriesCollectionRef.doc(); // Auto-generate ID
        final defaultCategory = BudgetCategoryModel(
          id:
              newCategoryDocRef
                  .id, // Will be set by Firestore, but good to have in model
          name: catData['name'] as String,
          allocatedAmount: 0.0, // Default allocated amount
          spentAmount: 0.0,
          iconCodepoint: catData['iconCodepoint'] as int,
          iconFontFamily: catData['iconFontFamily'] as String,
          colorHex: catData['colorHex'] as String,
          createdAt: Timestamp.now(),
          // You could add 'isDefault': catData['isDefault'] if you need to distinguish later
        );
        batch.set(newCategoryDocRef, defaultCategory.toFirestore());
      }
      await batch.commit();
      print("Created new budget period '$budgetId' with default categories.");
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

  Stream<List<BudgetCategoryModel>> getCategoriesStream(String budgetId) {
    if (_userId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .collection('categories')
        .orderBy(
          'createdAt',
          descending: false,
        ) // Or 'name' if you prefer alphabetical
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
    // Firestore will auto-generate an ID if .add() is used.
    // If category.id is already set (e.g. by Uuid()), use .doc(category.id).set()
    final categoryCollection = _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .collection('categories');

    // If your BudgetCategoryModel generates its own ID:
    // await categoryCollection.doc(category.id).set(category.toFirestore());
    // If you want Firestore to generate the ID (and you update your model with it later if needed):
    await categoryCollection.add(category.toFirestore());
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
        .collection('categories')
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
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // --- NEW/MODIFIED: Method to update spent amount based on transaction category name ---
  Future<void> recordTransactionSpending({
    required String budgetId,
    required String
    transactionCategoryName, // The general name, e.g., "Food & Groceries"
    required double amountToIncrement,
  }) async {
    if (_userId == null) throw Exception("User not logged in");
    if (amountToIncrement <= 0) return; // No need to update for zero/negative

    final categoriesRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('budgets')
        .doc(budgetId)
        .collection('categories');

    // Query for the category by its name
    final querySnapshot =
        await categoriesRef
            .where('name', isEqualTo: transactionCategoryName)
            .limit(
              1,
            ) // Names should be unique within a budget period, but limit just in case
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      final categoryDoc = querySnapshot.docs.first;
      // Increment the spentAmount
      await categoryDoc.reference.update({
        'spentAmount': FieldValue.increment(amountToIncrement),
      });
      print(
        "Updated spent amount for '$transactionCategoryName' in budget '$budgetId' by $amountToIncrement.",
      );
    } else {
      print(
        "Warning: Budget category named '$transactionCategoryName' not found in budget '$budgetId'. Cannot update spent amount.",
      );
      // Optionally, you could create it here if it's a default one somehow missing,
      // or log this as an unbudgeted expense if that's a feature.
    }
  }

  // This was the old method, can be removed or kept if you update spent amounts by ID elsewhere
  // Future<void> updateCategorySpentAmount(
  //     String budgetId, String categoryId, double newSpentAmount) async {
  //   // ...
  // }
}
