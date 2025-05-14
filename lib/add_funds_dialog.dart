// In goals_screen.dart, add this line at the top:
// part 'add_funds_dialog.dart'; // (if you make it a true part file, this content goes there)

part of 'goals_screen.dart';

void _showAddFundsDialog(
  BuildContext context,
  FirestoreService firestoreService,
  Goal goal,
) {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Add Funds to "${goal.goalName}"',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Current: ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(goal.currentAmount)} / ${NumberFormat.currency(locale: 'en_US', symbol: '\$').format(goal.targetAmount)}',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount to Add',
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  if (goal.currentAmount + amount > goal.targetAmount) {
                    // Optionally allow exceeding, or show a warning
                    // return 'Amount exceeds target. Max: ${goal.targetAmount - goal.currentAmount}';
                  }
                  return null;
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
                    icon: const Icon(Icons.add_card_outlined),
                    label: const Text('Add Funds'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(
                            context,
                          ).colorScheme.secondary, // Teal for add funds
                      foregroundColor:
                          Colors.black, // Or white, depending on teal shade
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final double amount = double.parse(
                          _amountController.text,
                        );
                        try {
                          await firestoreService.addFundsToGoal(
                            goal.id,
                            amount,
                          );
                          Navigator.of(ctx).pop(); // Close dialog
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Funds added to ${goal.goalName}!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error adding funds: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}
