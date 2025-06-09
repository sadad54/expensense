// lib/util/transaction_utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import 'package:provider/provider.dart';
import '../viewmodels/budget_viewmodel.dart';
import 'package:flutter/material.dart';

Future<void> saveTransactionAndUpdateBudget({
  required BuildContext context,
  required String categoryName,
  required double amount,
  required String rawText,
  required DateTime timestamp,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final transaction = TransactionModel(
    id: '',
    categoryId: categoryName,
    amount: amount,
    rawText: rawText,
    timestamp: timestamp,
    description: rawText,
  );

  final docRef = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('transactions')
      .add(transaction.toMap());

  final budgetProvider = Provider.of<ModernBudgetProvider>(
    context,
    listen: false,
  );
  await budgetProvider.processTransactionForBudgetUpdate(
    transactionCategoryName: categoryName,
    transactionAmount: amount,
  );
}
