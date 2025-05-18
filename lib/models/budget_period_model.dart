import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BudgetPeriodModel extends Equatable {
  final String id; // e.g., "monthly_2025_05"
  final String budgetName;
  final Timestamp startDate;
  final Timestamp endDate;
  // Totals can be added here if needed, or calculated client-side

  const BudgetPeriodModel({
    required this.id,
    required this.budgetName,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [id, budgetName, startDate, endDate];

  factory BudgetPeriodModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return BudgetPeriodModel(
      id: doc.id,
      budgetName: data['budgetName'] as String,
      startDate: data['startDate'] as Timestamp,
      endDate: data['endDate'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'budgetName': budgetName,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}
