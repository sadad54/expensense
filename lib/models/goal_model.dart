import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id; // Document ID from Firestore
  final String userId;
  final String goalName;
  final double targetAmount;
  double currentAmount;
  final Timestamp createdAt;
  final Timestamp? targetDate;
  final String? iconName; // e.g., "laptop_icon" or "beach_icon"
  final String? accentColorHex; // e.g., "#FF0000"

  Goal({
    required this.id,
    required this.userId,
    required this.goalName,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.createdAt,
    this.targetDate,
    this.iconName,
    this.accentColorHex,
  });

  // Factory constructor to create a Goal from a Firestore document
  factory Goal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for goalId: ${snapshot.id}');
    }
    return Goal(
      id: snapshot.id,
      userId: data['userId'] as String,
      goalName: data['goalName'] as String,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currentAmount: (data['currentAmount'] as num? ?? 0.0).toDouble(),
      createdAt: data['createdAt'] as Timestamp,
      targetDate: data['targetDate'] as Timestamp?,
      iconName: data['iconName'] as String?,
      accentColorHex: data['accentColorHex'] as String?,
    );
  }

  // Method to convert a Goal instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'goalName': goalName,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'createdAt': createdAt,
      if (targetDate != null) 'targetDate': targetDate,
      if (iconName != null) 'iconName': iconName,
      if (accentColorHex != null) 'accentColorHex': accentColorHex,
    };
  }

  // Helper to get progress
  double get progress =>
      (targetAmount > 0) ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount;
}
