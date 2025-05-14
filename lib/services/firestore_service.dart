import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/goal_model.dart'; // Adjust path as needed

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Get a stream of user's goals
  Stream<List<Goal>> getGoalsStream() {
    final userId = currentUser?.uid;
    if (userId == null) {
      return Stream.value([]); // Return empty stream if no user is logged in
    }
    return _db
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Goal.fromFirestore(
                      doc as DocumentSnapshot<Map<String, dynamic>>,
                    ),
                  )
                  .toList(),
        );
  }

  // Add a new goal
  Future<void> addGoal(Goal goal) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in. Cannot add goal.");
    }
    // Ensure the goal object has the correct userId
    final goalData = goal.toFirestore();
    if (goalData['userId'] != userId) {
      // This should ideally be set correctly when creating the Goal object before calling addGoal
      goalData['userId'] = userId;
    }
    try {
      await _db.collection('goals').add(goalData);
      print("Goal successfully added to database");
    } catch (e) {
      print("Error adding goal to Firestore: $e");
      throw Exception("Failed to save goal: $e");
    }
  }

  // Update an existing goal (e.g., add funds, change name/target)
  Future<void> updateGoal(Goal goal) {
    final userId = currentUser?.uid;
    if (userId == null || goal.userId != userId) {
      throw Exception("User not logged in or permission denied.");
    }
    return _db.collection('goals').doc(goal.id).update(goal.toFirestore());
  }

  // Add funds to a specific goal
  Future<void> addFundsToGoal(String goalId, double amountToAdd) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in.");
    }
    final goalRef = _db.collection('goals').doc(goalId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(goalRef);
      if (!snapshot.exists) {
        throw Exception("Goal does not exist!");
      }
      final goalData = snapshot.data() as Map<String, dynamic>;
      if (goalData['userId'] != userId) {
        throw Exception("Permission denied to update this goal.");
      }
      final newCurrentAmount =
          (goalData['currentAmount'] as num? ?? 0.0) + amountToAdd;
      transaction.update(goalRef, {'currentAmount': newCurrentAmount});
    });
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId) {
    final userId = currentUser?.uid;
    if (userId == null) {
      throw Exception("User not logged in.");
    }
    // Optional: You might want to verify ownership again here before deleting,
    // but Firestore rules should enforce this.
    return _db.collection('goals').doc(goalId).delete();
  }
}
