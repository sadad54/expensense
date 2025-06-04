import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initializeDefaultBudgetCategories() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final budgetRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('budget_categories');

  final snapshot = await budgetRef.get();

  if (snapshot.docs.isEmpty) {
    final List<Map<String, dynamic>> defaultCategories = [
      {"name": "Food & Groceries", "allocatedAmount": 0.0, "spentAmount": 0.0},
      {"name": "Dining & Takeout", "allocatedAmount": 0.0, "spentAmount": 0.0},
      {"name": "Transportation", "allocatedAmount": 0.0, "spentAmount": 0.0},
      {"name": "Utilities", "allocatedAmount": 0.0, "spentAmount": 0.0},
      {"name": "Housing & Rent", "allocatedAmount": 0.0, "spentAmount": 0.0},
      {"name": "Health & Personal Care", "allocatedAmount": 0.0, "spentAmount": 0.0},
      {"name": "Entertainment & Subscriptions", "allocatedAmount": 0.0, "spentAmount": 0.0},
      {"name": "Shopping & Miscellaneous", "allocatedAmount": 0.0, "spentAmount": 0.0},
    ];

    for (final category in defaultCategories) {
      await budgetRef.add(category);
    }

    print("✅ Default budget categories initialized.");
  } else {
    print("ℹ️ Budget categories already exist.");
  }
}
