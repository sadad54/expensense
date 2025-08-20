// lib/util/transaction_utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import 'package:provider/provider.dart';
import '../viewmodels/budget_viewmodel.dart';
import 'package:flutter/material.dart';

Future<String?> detectIncomeTaxCategoryFromText(String rawText) async {
  try {
    final snap =
        await FirebaseFirestore.instance
            .collection('income_tax_categories')
            .get();
    final lower = rawText.toLowerCase();
    for (final doc in snap.docs) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString();
      final tags = List<String>.from(data['tags'] ?? []);
      if (name.isEmpty) continue;
      final matches = tags.any((t) => lower.contains(t.toLowerCase()));
      if (matches) return name;
    }
  } catch (_) {}
  return null;
}

Future<void> saveTransactionAndUpdateBudget({
  required BuildContext context,
  required String categoryName,
  required double amount,
  required String rawText,
  required DateTime timestamp,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final matchedIncomeTaxCategory = await detectIncomeTaxCategoryFromText(
    rawText,
  );

  final transaction = TransactionModel(
    id: '',
    categoryId: categoryName,
    amount: amount,
    rawText: rawText,
    timestamp: timestamp,
    description: rawText,
    incomeTaxCategory: matchedIncomeTaxCategory,
  );

  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('transactions')
      .add({
        ...transaction.toMap(),
        // Store the scan time separately from the receipt timestamp
        'scannedAt': FieldValue.serverTimestamp(),
      });

  final budgetProvider = Provider.of<ModernBudgetProvider>(
    context,
    listen: false,
  );
  await budgetProvider.processTransactionForBudgetUpdate(
    transactionCategoryName: categoryName,
    transactionAmount: amount,
  );
  await FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .update({'expenses': FieldValue.increment(amount)});
}
