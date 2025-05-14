// In goals_screen.dart, add this line at the top:
// part 'add_edit_goal_dialog.dart'; // (if you make it a true part file, this content goes there)

// This function can be part of _GoalsScreenState or a standalone helper
// called from _GoalsScreenState.

part of "goals_screen.dart";

void _showAddEditGoalDialog(
  BuildContext context,
  FirestoreService firestoreService, {
  Goal? goal,
}) {
  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController(text: goal?.goalName);
  final _targetAmountController = TextEditingController(
    text: goal?.targetAmount.toStringAsFixed(0) ?? '',
  );
  // Add controllers for targetDate, iconName etc. if needed
  DateTime? _selectedTargetDate = goal?.targetDate?.toDate();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Important for keyboard
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        // For updating date picker in bottom sheet
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.of(ctx).viewInsets.bottom, // Adjust for keyboard
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      goal == null ? 'Create New Goal' : 'Edit Goal',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _goalNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Goal Name',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a goal name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetAmountController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Target Amount',
                        prefixText: '\$ ', // Customize
                        prefixStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.5),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a target amount';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Please enter a valid positive amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Optional: Target Date Picker
                    ListTile(
                      leading: Icon(
                        Icons.calendar_today_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        _selectedTargetDate == null
                            ? 'Set Target Date (Optional)'
                            : DateFormat.yMMMd().format(_selectedTargetDate!),
                        style: TextStyle(
                          color: Colors.white.withOpacity(
                            _selectedTargetDate == null ? 0.7 : 1.0,
                          ),
                        ),
                      ),
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.white38),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedTargetDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            // Theme the date picker
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(
                                  context,
                                ).colorScheme.copyWith(
                                  primary:
                                      Theme.of(context)
                                          .colorScheme
                                          .primary, // header background color
                                  onPrimary: Colors.white, // header text color
                                  onSurface: Colors.white, // body text color
                                ),
                                dialogBackgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context)
                                            .colorScheme
                                            .primary, // button text color
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != _selectedTargetDate) {
                          setModalState(() {
                            // Use setModalState to update UI within the bottom sheet
                            _selectedTargetDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: Icon(
                            goal == null
                                ? Icons.add_circle_outline
                                : Icons.save_outlined,
                          ),
                          label: Text(
                            goal == null ? 'Create Goal' : 'Save Changes',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final String name = _goalNameController.text;
                              final double target = double.parse(
                                _targetAmountController.text,
                              );
                              final currentUserId =
                                  FirebaseAuth.instance.currentUser?.uid;

                              if (currentUserId == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error: User not logged in.'),
                                  ),
                                );
                                return;
                              }

                              if (goal == null) {
                                // Create new goal
                                final newGoal = Goal(
                                  id: '', // Firestore will generate ID
                                  userId: currentUserId,
                                  goalName: name,
                                  targetAmount: target,
                                  currentAmount: 0.0, // New goals start at 0
                                  createdAt: Timestamp.now(),
                                  targetDate:
                                      _selectedTargetDate != null
                                          ? Timestamp.fromDate(
                                            _selectedTargetDate!,
                                          )
                                          : null,
                                  // Add iconName, accentColorHex from form if you implement those fields
                                );
                                await firestoreService.addGoal(newGoal);
                              } else {
                                // Update existing goal
                                final updatedGoal = Goal(
                                  id: goal.id,
                                  userId: goal.userId, // Keep original userId
                                  goalName: name,
                                  targetAmount: target,
                                  currentAmount:
                                      goal.currentAmount, // Keep current amount unless specifically changed
                                  createdAt:
                                      goal.createdAt, // Keep original creation date
                                  targetDate:
                                      _selectedTargetDate != null
                                          ? Timestamp.fromDate(
                                            _selectedTargetDate!,
                                          )
                                          : null,
                                  // Update iconName, accentColorHex
                                );
                                await firestoreService.updateGoal(updatedGoal);
                              }
                              Navigator.of(ctx).pop(); // Close dialog
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ), // Padding for keyboard avoidance
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
