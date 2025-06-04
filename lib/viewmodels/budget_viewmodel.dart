import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/budget_category_model.dart';
import '../models/budget_period_model.dart';
import '../services/modern_budget_service.dart';

class ModernBudgetProvider with ChangeNotifier {
  final ModernBudgetService _budgetService = ModernBudgetService();

  String? _currentBudgetId; // This is important to know which budget to update
  BudgetPeriodModel? _budgetPeriod;
  List<BudgetCategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  BudgetPeriodModel? get budgetPeriod => _budgetPeriod;
  List<BudgetCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentBudgetId => _currentBudgetId; // Expose current budget ID

  double get totalAllocated =>
      _categories.fold(0.0, (sum, item) => sum + item.allocatedAmount);
  double get totalSpent =>
      _categories.fold(0.0, (sum, item) => sum + item.spentAmount);
  double get overallProgress =>
      totalAllocated > 0 ? (totalSpent / totalAllocated).clamp(0.0, 1.0) : 0.0;

  StreamSubscription? _periodSubscription;
  StreamSubscription? _categoriesSubscription;

  ModernBudgetProvider() {
    _initializeBudget();
  }

  Future<void> _initializeBudget() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notify UI that loading has started
    try {
      // ensureCurrentBudgetPeriodExists now also creates default categories if period is new
      _currentBudgetId = await _budgetService.ensureCurrentBudgetPeriodExists();
      _listenToPeriod();
      _listenToCategories();
    } catch (e) {
      _error = "Failed to initialize budget: ${e.toString()}";
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify UI that loading is complete (or error occurred)
    }
  }

  // Public method to refresh
  Future<void> refreshBudget() async {
    print("Refreshing budget data...");
    await _initializeBudget(); // This will re-run the initialization logic
  }

  void _listenToPeriod() {
    _periodSubscription?.cancel();
    if (_currentBudgetId == null) return;
    _periodSubscription = _budgetService
        .getBudgetPeriodStream(_currentBudgetId!)
        .listen(
          (periodData) {
            _budgetPeriod = periodData;
            notifyListeners();
          },
          onError: (e) {
            _error = "Error fetching budget period: ${e.toString()}";
            print(_error);
            notifyListeners();
          },
        );
  }

  void _listenToCategories() {
    _categoriesSubscription?.cancel();
    if (_currentBudgetId == null) return;
    _categoriesSubscription = _budgetService
        .getCategoriesStream(_currentBudgetId!)
        .listen(
          (categoriesData) {
            _categories = categoriesData;
            notifyListeners();
          },
          onError: (e) {
            _error = "Error fetching categories: ${e.toString()}";
            print(_error);
            notifyListeners();
          },
        );
  }

  Future<void> addCategory(BudgetCategoryModel category) async {
    if (_currentBudgetId == null) {
      _error = "No current budget period selected to add category.";
      notifyListeners();
      return;
    }
    try {
      // Ensure createdAt is set if not already
      final categoryToAdd =
          category.createdAt.seconds ==
                  0 // A simple check if it's a default Timestamp
              ? category.copyWith(createdAt: Timestamp.now())
              : category;
      await _budgetService.addCategory(_currentBudgetId!, categoryToAdd);
      // The stream _listenToCategories will update the UI
    } catch (e) {
      _error = "Failed to add category: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> updateCategory(BudgetCategoryModel category) async {
    if (_currentBudgetId == null) {
      _error = "No current budget period selected to update category.";
      notifyListeners();
      return;
    }
    try {
      await _budgetService.updateCategory(_currentBudgetId!, category);
    } catch (e) {
      _error = "Failed to update category: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_currentBudgetId == null) {
      _error = "No current budget period selected to delete category.";
      notifyListeners();
      return;
    }
    try {
      await _budgetService.deleteCategory(_currentBudgetId!, categoryId);
    } catch (e) {
      _error = "Failed to delete category: ${e.toString()}";
      notifyListeners();
    }
  }

  // --- NEW: Method to be called from transaction screens ---
  Future<void> processTransactionForBudgetUpdate({
    required String transactionCategoryName, // e.g., "Food & Groceries"
    required double transactionAmount,
  }) async {
    if (_currentBudgetId == null) {
      print(
        "Warning: No current budget ID available in ModernBudgetProvider. Cannot update spending.",
      );
      // Optionally set an error or handle this state
      return;
    }
    if (transactionAmount <= 0) return;

    try {
      await _budgetService.recordTransactionSpending(
        budgetId: _currentBudgetId!,
        transactionCategoryName: transactionCategoryName,
        amountToIncrement: transactionAmount,
      );
      // UI will update via the stream from _listenToCategories
      print(
        "Successfully processed transaction for budget update: $transactionCategoryName, Amount: $transactionAmount",
      );
    } catch (e) {
      _error =
          "Failed to update budget spending for transaction: ${e.toString()}";
      print(_error); // For debugging
      notifyListeners(); // Notify UI of the error
    }
  }

  @override
  void dispose() {
    _periodSubscription?.cancel();
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
