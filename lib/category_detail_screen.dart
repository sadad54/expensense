import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CategoryDetailScreen extends StatelessWidget {
  final String categoryName;

  const CategoryDetailScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Details: $categoryName")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .collection("transactions")
                .where("categoryId", isEqualTo: categoryName)
                .orderBy("timestamp", descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          double total = 0;

          final txList =
              docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] ?? 0).toDouble();
                total += amount;
                final date = (data['timestamp'] as Timestamp).toDate();
                return ListTile(
                  title: Text("₹${amount.toStringAsFixed(2)}"),
                  subtitle: Text(data['rawText'] ?? ''),
                  trailing: Text(DateFormat.yMMMd().format(date)),
                );
              }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "📊 Total: ₹${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...txList,
            ],
          );
        },
      ),
    );
  }
}
