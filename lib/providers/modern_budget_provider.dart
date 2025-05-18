import 'dart:async';
import 'package:flutter/material.dart';
import 'package:exp_ocr/models/budget_category_model.dart';
import 'package:exp_ocr/models/budget_period_model.dart';
import 'package:exp_ocr/services/modern_budget_service.dart';

class ModernBudgetProvider with ChangeNotifier {
  final ModernBudgetService _budgetService = ModernBudgetService();

  String? _currentBudgetId;
  BudgetPeriodModel? _budgetPeriod;
  List<BudgetCategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  BudgetPeriodModel? get budgetPeriod => _budgetPeriod;
  List<BudgetCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    notifyListeners();
    try {
      _currentBudgetId = await _budgetService.ensureCurrentBudgetPeriodExists();
      _listenToPeriod();
      _listenToCategories();
    } catch (e) {
      _error = "Failed to initialize budget: ${e.toString()}";
      print(_error); // For debugging
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBudget() async {
    // You can add any additional logic here if needed before re-initializing
    print("Refreshing budget data...");
    await _initializeBudget();
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
            // Potentially sort categories here if needed, e.g., by name or creation date
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
    if (_currentBudgetId == null) return;
    try {
      await _budgetService.addCategory(_currentBudgetId!, category);
    } catch (e) {
      _error = "Failed to add category: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> updateCategory(BudgetCategoryModel category) async {
    if (_currentBudgetId == null) return;
    try {
      await _budgetService.updateCategory(_currentBudgetId!, category);
    } catch (e) {
      _error = "Failed to update category: ${e.toString()}";
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_currentBudgetId == null) return;
    try {
      await _budgetService.deleteCategory(_currentBudgetId!, categoryId);
    } catch (e) {
      _error = "Failed to delete category: ${e.toString()}";
      notifyListeners();
    }
  }

  // Example: Manually trigger a spend update (in a real app, this comes from transaction logging)
  Future<void> recordSpending(
    String categoryId,
    double amountSpentIncrement,
  ) async {
    if (_currentBudgetId == null) return;
    final category = _categories.firstWhere((cat) => cat.id == categoryId);
    final newSpentAmount = category.spentAmount + amountSpentIncrement;
    try {
      await _budgetService.updateCategorySpentAmount(
        _currentBudgetId!,
        categoryId,
        newSpentAmount,
      );
    } catch (e) {
      _error = "Failed to record spending: ${e.toString()}";
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _periodSubscription?.cancel();
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
