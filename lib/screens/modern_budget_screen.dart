import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import "../models/budget_category_model.dart"; // Assuming this path is correct
import 'package:exp_ocr/providers/modern_budget_provider.dart'; // Assuming this path
import 'package:exp_ocr/category_form_sheet.dart'; // Assuming this path

class ModernBudgetScreen extends StatelessWidget {
  const ModernBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<ModernBudgetProvider>(context);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_US', // Or your preferred locale
      symbol: '\$', // Or your preferred currency symbol
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(budgetProvider.budgetPeriod?.budgetName ?? 'Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => budgetProvider.refreshBudget(),
          ),
        ],
      ),
      body: SafeArea(
        child:
            budgetProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : budgetProvider.error != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${budgetProvider.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                : Column(
                  children: [
                    _buildOverallProgress(
                          context,
                          budgetProvider,
                          currencyFormat,
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(
                          begin: -0.2,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    Expanded(
                      child: _buildCategoryList(
                        context,
                        budgetProvider,
                        currencyFormat,
                      ),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryForm(context, budgetProvider),
        icon: const Icon(Icons.add),
        label: const Text('Category'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildOverallProgress(
    BuildContext context,
    ModernBudgetProvider provider,
    NumberFormat currencyFormat,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spent',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                AnimatedSwitcher(
                  duration: 300.ms,
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    currencyFormat.format(provider.totalSpent),
                    key: ValueKey<double>(provider.totalSpent),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining: ${currencyFormat.format(provider.totalAllocated - provider.totalSpent)} of ${currencyFormat.format(provider.totalAllocated)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 10.0,
            percent: provider.overallProgress,
            center: Text(
              "${(provider.overallProgress * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.5),
          ).animate().rotate(duration: 700.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    ModernBudgetProvider provider,
    NumberFormat currencyFormat,
  ) {
    if (provider.categories.isEmpty && !provider.isLoading) {
      // Check isLoading too
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No categories yet for this budget period.\nTap the "+" button to add custom categories, or they will appear if default categories are set up for new periods.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        // Pass _showSpendInputDialog to _buildCategoryCard
        return _buildCategoryCard(
              context,
              category,
              provider,
              currencyFormat,
              _showSpendInputDialog,
            )
            .animate()
            .fadeIn(duration: (300 + index * 50).ms)
            .slideX(
              begin: 0.2,
              end: 0,
              duration: (400 + index * 50).ms,
              curve: Curves.easeOutQuart,
            );
      },
    );
  }

  // Moved _showSpendInputDialog to be a method of ModernBudgetScreen
  void _showSpendInputDialog(
    BuildContext context,
    BudgetCategoryModel category,
    ModernBudgetProvider provider, // Provider is passed here
  ) {
    final TextEditingController spendController = TextEditingController();
    final currentSpent = category.spentAmount;
    final allocated = category.allocatedAmount;
    // Calculate remaining based on current values before adding new spend
    final double remainingBeforeNewSpend = allocated - currentSpent;

    showDialog(
      context: context,
      barrierDismissible: false, // User must explicitly close
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Add Spending to "${category.name}"',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Allocated: ${NumberFormat.currency(symbol: '\$').format(allocated)}",
                ),
                Text(
                  "Current Spent: ${NumberFormat.currency(symbol: '\$').format(currentSpent)}",
                ),
                Text(
                  "Remaining: ${NumberFormat.currency(symbol: '\$').format(remainingBeforeNewSpend)}",
                  style: TextStyle(
                    color:
                        remainingBeforeNewSpend < 0
                            ? Colors.redAccent
                            : Colors.greenAccent,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: spendController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount Spent',
                    labelStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    // Using theme's inputDecorationTheme so border will match
                  ),
                  autofocus: true,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Add Spend'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final input = spendController.text.trim();
                  final amount = double.tryParse(input);

                  if (amount == null || amount <= 0) {
                    Navigator.of(ctx).pop(); // Close current dialog first
                    _showCrimsonAlert(
                      context,
                      "❌ Please enter a valid positive number for spending.",
                    );
                    return;
                  }

                  // Check against remaining *before* this new spend
                  // if (amount > remainingBeforeNewSpend && allocated > 0) { // Only check if allocated > 0
                  //   Navigator.of(ctx).pop(); // Close current dialog
                  //   _showCrimsonAlert(
                  //     context,
                  //     "⚠️ Spending \$${amount.toStringAsFixed(2)} exceeds remaining \$${remainingBeforeNewSpend.toStringAsFixed(2)}.",
                  //   );
                  //   return;
                  // }

                  // --- THIS IS THE CORRECTED LINE ---
                  provider.processTransactionForBudgetUpdate(
                    transactionCategoryName: category.name,
                    transactionAmount: amount,
                  );
                  Navigator.of(ctx).pop(); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "✅ Added \$${amount.toStringAsFixed(2)} to ${category.name}",
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  void _showCrimsonAlert(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            Theme.of(
              context,
            ).colorScheme.errorContainer, // Use theme error color
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    BudgetCategoryModel category,
    ModernBudgetProvider provider,
    NumberFormat currencyFormat,
    // Add the function as a parameter
    Function(BuildContext, BudgetCategoryModel, ModernBudgetProvider)
    showSpendDialogFn,
  ) {
    double progress =
        category.allocatedAmount > 0
            ? (category.spentAmount / category.allocatedAmount).clamp(0.0, 1.0)
            : 0.0;
    double remaining = category.allocatedAmount - category.spentAmount;

    return Card(
      // Card properties from your theme
      child: InkWell(
        onTap:
            () => showSpendDialogFn(
              context,
              category,
              provider,
            ), // Use the passed function
        onLongPress:
            () => _showCategoryForm(
              context,
              provider,
              existingCategory: category,
            ), // Keep long press for editing form
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(category.iconData, size: 28, color: category.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surface,
                              title: Text(
                                'Confirm Delete',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete "${category.name}"?',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );
                      if (confirm == true) {
                        provider.deleteCategory(category.id);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${currencyFormat.format(category.spentAmount)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    'Remaining: ${currencyFormat.format(remaining)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          remaining < 0
                              ? Theme.of(context).colorScheme.error
                              : Colors
                                  .greenAccent, // Lighter green for dark theme
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                animation: true,
                animationDuration: 700,
                lineHeight: 10.0,
                percent: progress,
                barRadius: const Radius.circular(5),
                progressColor: category.color,
                backgroundColor: category.color.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryForm(
    BuildContext context,
    ModernBudgetProvider provider, {
    BudgetCategoryModel? existingCategory,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: CategoryFormSheet(existingCategory: existingCategory),
        );
      },
    );
  }
}
