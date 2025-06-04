import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exp_ocr/models/goal_model.dart'; // Adjust import
import 'package:exp_ocr/services/firestore_service.dart'; // Adjust import
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For user check
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // If using slidable

// Placeholder for Add/Edit Goal Dialog
part "add_edit_goal_dialog.dart";
// Placeholder for Add Funds Dialog
part 'add_funds_dialog.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
  ); // Customize as needed

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // This should ideally be handled by an AuthWrapper before reaching this screen
      return Scaffold(
        appBar: AppBar(title: const Text('Goals')),
        body: const Center(child: Text("Please log in to see your goals.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.filter_list),
        //     onPressed: () {
        //       // Implement filter/sort options
        //     },
        //   ),
        // ],
      ),
      body: StreamBuilder<List<Goal>>(
        stream: _firestoreService.getGoalsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final goals = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return GoalCard(
                goal: goal,
                currencyFormat: _currencyFormat,
                onTap: () {
                  // Navigate to goal details or show edit dialog
                  _showAddEditGoalDialog(
                    context,
                    _firestoreService,
                    goal: goal,
                  );
                },
                onAddFunds: () {
                  _showAddFundsDialog(context, _firestoreService, goal);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddEditGoalDialog(context, _firestoreService);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        // backgroundColor: Theme.of(context).colorScheme.primary, // Uses theme
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_circle_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          Text(
            'No Goals Yet!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the + button to add your first financial goal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create First Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              _showAddEditGoalDialog(context, _firestoreService);
            },
          ),
        ],
      ),
    );
  }
}

// --- GoalCard Widget ---
class GoalCard extends StatelessWidget {
  final Goal goal;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;
  final VoidCallback onAddFunds;

  const GoalCard({
    super.key,
    required this.goal,
    required this.currencyFormat,
    required this.onTap,
    required this.onAddFunds,
  });

  IconData _getIconFromString(String? iconName) {
    // Map icon names to actual Icons
    switch (iconName?.toLowerCase()) {
      case 'laptop':
      case 'computer':
        return Icons.laptop_chromebook_outlined;
      case 'vacation':
      case 'travel':
        return Icons.beach_access_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'home':
      case 'house':
        return Icons.home_outlined;
      case 'savings':
        return Icons.savings_outlined;
      default:
        return Icons.star_outline; // Default icon
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final bool isCompleted = goal.isCompleted;
    final Color progressColor =
        isCompleted
            ? Colors.greenAccent.shade700
            : Theme.of(
              context,
            ).colorScheme.primary; // Blue or Green for completed

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: Theme.of(context).colorScheme.surface, // Dark card background
      child: InkWell(
        onTap: onTap, // To edit or view details
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconFromString(goal.iconName),
                    color: progressColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.goalName,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCompleted)
                    Chip(
                      label: const Text('Completed!'),
                      backgroundColor: Colors.greenAccent.shade700.withOpacity(
                        0.3,
                      ),
                      labelStyle: TextStyle(
                        color: Colors.greenAccent.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  else
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      tooltip: "Add Funds",
                      onPressed: onAddFunds,
                    ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currencyFormat.format(goal.currentAmount)} / ${currencyFormat.format(goal.targetAmount)}',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              LinearPercentIndicator(
                percent: progress,
                lineHeight: 12.0,
                animation: true,
                animationDuration: 600,
                barRadius: const Radius.circular(6.0),
                progressColor: progressColor,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.1),
              ),
              if (goal.targetDate != null && !isCompleted) ...[
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Target: ${DateFormat.yMMMd().format(goal.targetDate!.toDate())}',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
