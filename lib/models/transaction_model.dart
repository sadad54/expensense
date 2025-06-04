// // lib/models/transaction_model.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

// class Transaction {
//   final String id;
//   final String description;
//   final double amount;
//   final DateTime date;
//   final String categoryName;
//   final String type; // 'income' or 'expense'
//   final String userId;

//   Transaction({
//     required this.id,
//     required this.description,
//     required this.amount,
//     required this.date,
//     required this.categoryName,
//     required this.type,
//     required this.userId,
//   });

//   factory Transaction.fromFirestore(DocumentSnapshot doc) {
//     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//     return Transaction(
//       id: doc.id,
//       description: data['description'] ?? '',
//       amount: (data['amount'] ?? 0).toDouble(),
//       date: (data['date'] as Timestamp).toDate(),
//       categoryName: data['categoryName'] ?? 'Uncategorized',
//       type: data['type'] ?? 'expense',
//       userId: data['userId'] ?? '',
//     );
//   }

//   Map<String, dynamic> toFirestore() {
//     return {
//       'description': description,
//       'amount': amount,
//       'date': Timestamp.fromDate(date),
//       'categoryName': categoryName,
//       'type': type,
//       'userId': userId,
//     };
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String categoryId;
  final double amount;
  final String rawText;
  final DateTime timestamp;
  final String description;

  TransactionModel({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.rawText,
    required this.timestamp,
    this.description = '',
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      categoryId: data['categoryId'],
      amount: (data['amount'] ?? 0).toDouble(),
      rawText: data['rawText'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'amount': amount,
      'rawText': rawText,
      'timestamp': FieldValue.serverTimestamp(),
      'description': description,
    };
  }
}
