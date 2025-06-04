import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IncomeTaxTrackerScreen extends StatefulWidget {
  @override
  State<IncomeTaxTrackerScreen> createState() => _IncomeTaxTrackerScreenState();
}

class _IncomeTaxTrackerScreenState extends State<IncomeTaxTrackerScreen> {
  bool _loading = true;
  List<TaxDeductionCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadTaxCategories();
  }

  Future<void> _loadTaxCategories() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print("❌ No user logged in.");
        return;
      }

      final categoriesSnap =
          await FirebaseFirestore.instance
              .collection("income_tax_categories")
              .get();

      print("✅ Fetched ${categoriesSnap.docs.length} tax category documents");

      final transactionsSnap =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("generalTransactions")
              .get();

      List<TaxDeductionCategory> all = [];

      for (var doc in categoriesSnap.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unnamed';
        final cap = (data['cap'] ?? 0).toDouble();
        final tags = List<String>.from(data['tags'] ?? []);
        double used = 0;

        for (var tx in transactionsSnap.docs) {
          final txData = tx.data();
          final desc = (txData['description'] ?? '').toString().toLowerCase();

          if (tags.any((tag) => desc.contains(tag.toLowerCase()))) {
            final amt = (txData['amount'] ?? 0).toDouble();
            used += amt;
          }
        }

        all.add(
          TaxDeductionCategory(name: name, cap: cap, used: used, tags: tags),
        );
      }

      setState(() {
        _categories = all;
        _loading = false;
      });
    } catch (e) {
      print("❌ Error loading categories: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Tax Deduction Tracker")),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: cat.usagePercent,
                            color: Colors.tealAccent,
                            backgroundColor: Colors.grey[800],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Used: RM${cat.used.toStringAsFixed(2)} / RM${cat.cap.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class TaxDeductionCategory {
  final String name;
  final double cap;
  final double used;
  final List<String> tags;

  TaxDeductionCategory({
    required this.name,
    required this.cap,
    required this.used,
    required this.tags,
  });

  double get usagePercent => (used / cap).clamp(0, 1);
}
