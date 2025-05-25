import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> uploadDummyTransactions() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    print("No user logged in");
    return;
  }

  final categories = [
    "Food & Groceries",
    "Dining & Takeout",
    "Transportation",
    "Utilities",
    "Housing & Rent",
    "Health & Personal Care",
    "Entertainment & Subscriptions",
    "Shopping & Miscellaneous",
  ];

  final now = DateTime.now();
  final firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> dummyData = [];

  // Generate 5 transactions for each of the past 6 months
  for (int m = 0; m < 6; m++) {
    final month = DateTime(now.year, now.month - m, 1);

    for (int i = 0; i < 5; i++) {
      final randomCategory = (categories..shuffle()).first;
      final date = DateTime(month.year, month.month, (i + 1) * 4);
      final amount = (50 + (100 * (i + 1))).toDouble();

      dummyData.add({
        'amount': amount,
        'categoryName': randomCategory,
        'timestamp': Timestamp.fromDate(date),
      });
    }
  }

  // Upload to Firestore
  for (final entry in dummyData) {
    await firestore
        .collection('users')
        .doc(uid)
        .collection('generalTransactions')
        .add(entry);
  }

  print("✅ Dummy transactions uploaded.");
}
