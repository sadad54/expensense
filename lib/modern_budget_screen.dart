import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import "../models/budget_category_model.dart";
import 'package:exp_ocr/providers/modern_budget_provider.dart';
import 'package:exp_ocr/category_form_sheet.dart'; // We'll create this next

class ModernBudgetScreen extends StatelessWidget {
  const ModernBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<ModernBudgetProvider>(context);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(budgetProvider.budgetPeriod?.budgetName ?? 'Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => budgetProvider.refreshBudget(), // Re-fetch
          ),
        ],
      ),
      body: SafeArea(
        child:
            budgetProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : budgetProvider.error != null
                ? Center(child: Text('Error: ${budgetProvider.error}'))
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
                  style: Theme.of(context).textTheme.titleMedium,
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
                    key: ValueKey<double>(
                      provider.totalSpent,
                    ), // Important for AnimatedSwitcher
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining: ${currencyFormat.format(provider.totalAllocated - provider.totalSpent)} of ${currencyFormat.format(provider.totalAllocated)}',
                  style: Theme.of(context).textTheme.bodySmall,
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
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
    if (provider.categories.isEmpty) {
      return Center(
        child: Text(
          'No categories yet.\nTap the "+" button to add one!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ).animate().fadeIn(delay: 500.ms),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final category = provider.categories[index];
        return _buildCategoryCard(context, category, provider, currencyFormat)
            .animate()
            .fadeIn(duration: (300 + index * 50).ms) // Staggered fade-in
            .slideX(
              begin: 0.2,
              end: 0,
              duration: (400 + index * 50).ms,
              curve: Curves.easeOutQuart,
            );
      },
    );
  }

  void _showSpendInputDialog(
    BuildContext context,
    BudgetCategoryModel category,
    ModernBudgetProvider provider,
  ) {
    final TextEditingController _controller = TextEditingController();
    final remaining = category.allocatedAmount - category.spentAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Add Spending to "${category.name}"',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount Spent',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final input = _controller.text.trim();
                  final amount = double.tryParse(input);

                  if (amount == null || amount <= 0) {
                    Navigator.of(ctx).pop();
                    _showCrimsonAlert(
                      context,
                      "❌ Please enter a valid positive number.",
                    );
                    return;
                  }

                  if (amount > remaining) {
                    Navigator.of(ctx).pop();
                    _showCrimsonAlert(
                      context,
                      "⚠️ Spending exceeds allocated budget.\nRemaining: \$${remaining.toStringAsFixed(2)}",
                    );
                    return;
                  }

                  provider.recordSpending(category.id, amount);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "✅ Added \$${amount.toStringAsFixed(2)} to ${category.name}",
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  void _showCrimsonAlert(BuildContext context, String message) {
    final crimson = const Color(0xFFDC143C); // Crimson Red

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: crimson,
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
  ) {
    double progress =
        category.allocatedAmount > 0
            ? (category.spentAmount / category.allocatedAmount).clamp(0.0, 1.0)
            : 0.0;
    double remaining = category.allocatedAmount - category.spentAmount;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias, // Ensures the ripple effect is contained
      child: InkWell(
        onTap:
            () => _showCategoryForm(
              context,
              provider,
              existingCategory: category,
            ),
        onLongPress: () {
          _showSpendInputDialog(context, category, provider);
          // // Simple example of interaction
          // provider.recordSpending(category.id, 10.0); // Spend $10
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text("Spent \$10 on ${category.name}"),
          //     duration: 700.ms,
          //   ),
          // );
        },
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
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text(
                                'Are you sure you want to delete "${category.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
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
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Remaining: ${currencyFormat.format(remaining)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          remaining < 0 ? Colors.redAccent : Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearPercentIndicator(
                //key: ValueKey(progress), // To ensure animation on change if needed
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
      isScrollControlled: true, // Important for keyboard
      backgroundColor:
          Colors.transparent, // Make sheet transparent for custom shape
      builder: (_) {
        // Pass provider down if CategoryFormSheet needs to call methods directly
        // Or handle saving via a callback.
        return ChangeNotifierProvider.value(
          value: provider, // If CategoryFormSheet needs the provider
          child: CategoryFormSheet(existingCategory: existingCategory),
        );
      },
    );
  }
}
