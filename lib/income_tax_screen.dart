import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IncomeTaxEstimatorScreen extends StatefulWidget {
  const IncomeTaxEstimatorScreen({super.key});

  @override
  State<IncomeTaxEstimatorScreen> createState() =>
      _IncomeTaxEstimatorScreenState();
}

class _IncomeTaxEstimatorScreenState extends State<IncomeTaxEstimatorScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  bool loading = true;

  double totalIncome = 0.0;
  double totalDeductible = 0.0;
  double chargeableIncome = 0.0;
  double estimatedTax = 0.0;
  double manualRelief = 9000.00;

  final TextEditingController _reliefController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reliefController.text = manualRelief.toStringAsFixed(2);
    fetchIncomeAndDeductions();
  }

  Future<void> fetchIncomeAndDeductions() async {
    if (uid == null) return;
    setState(() => loading = true);

    final snapshot =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("transactions")
            .get();

    double income = 0;
    double deductible = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] ?? 'expense';
      final amount = (data['amount'] ?? 0).toDouble();

      if (type == 'income') {
        income += amount;
      } else if (type == 'deductible') {
        deductible += amount;
      }
    }

    double chargeable = income - deductible - manualRelief;
    chargeable = chargeable < 0 ? 0 : chargeable;

    final tax = calculateMalaysianIncomeTax(chargeable.toDouble());

    setState(() {
      totalIncome = income;
      totalDeductible = deductible;
      chargeableIncome = chargeable.toDouble();
      estimatedTax = tax;
      loading = false;
    });
  }

  double calculateMalaysianIncomeTax(double chargeable) {
    double tax = 0;
    double remaining = chargeable;

    final List<Map<String, dynamic>> bands = [
      {'limit': 5000, 'rate': 0.00},
      {'limit': 20000, 'rate': 0.01},
      {'limit': 20000, 'rate': 0.03},
      {'limit': 15000, 'rate': 0.08},
      {'limit': 15000, 'rate': 0.13},
      {'limit': 20000, 'rate': 0.21},
      {'limit': 30000, 'rate': 0.24},
      {'limit': 150000, 'rate': 0.245},
      {'limit': 200000, 'rate': 0.25},
      {'limit': 1000000, 'rate': 0.26},
    ];

    for (var band in bands) {
      if (remaining <= 0) break;

      final bandAmount = band['limit'] as int;
      final bandRate = band['rate'] as double;

      final taxedAmount =
          remaining > bandAmount ? bandAmount.toDouble() : remaining;
      tax += taxedAmount * bandRate;
      remaining -= taxedAmount;
    }

    if (remaining > 0) {
      tax += remaining * 0.28;
    }

    return tax;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Income Tax Estimator")),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchIncomeAndDeductions,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "💰 Total Income",
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        "MYR ${totalIncome.toStringAsFixed(2)}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "📉 Total Deductions",
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        "MYR ${totalDeductible.toStringAsFixed(2)}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "🎁 Manual Relief (e.g. EPF, Insurance, Parental Support)",
                        style: theme.textTheme.titleMedium,
                      ),
                      TextField(
                        controller: _reliefController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            manualRelief = double.tryParse(value) ?? 0;
                          });
                        },
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus();
                          fetchIncomeAndDeductions();
                        },
                        decoration: const InputDecoration(
                          hintText: "Enter additional relief (e.g. 9000)",
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "🧾 Chargeable Income",
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        "MYR ${chargeableIncome.toStringAsFixed(2)}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "💸 Estimated Tax Payable",
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        "MYR ${estimatedTax.toStringAsFixed(2)}",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Divider(),
                      const Text(
                        "ℹ️ Note: This is an estimate based on LHDN Malaysia brackets and does not account for all possible tax reliefs or rebates.",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
