import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../models/transaction_model.dart';
import '../../../viewmodels/budget_viewmodel.dart';
import '../../../util/receipt_parser.dart';
import '../../../util/category_hybrid_matcher.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<TransactionModel> _transactions = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'All',
    'Food & Groceries',
    'Dining & Takeout',
    'Transportation',
    'Utilities',
    'Housing & Rent',
    'Health & Personal Care',
    'Entertainment & Subscriptions',
    'Shopping & Miscellaneous',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snapshot =
        await _db
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .get();

    setState(() {
      _transactions =
          snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();
      _loading = false;
    });
  }

  Future<void> _handleScanReceipt(String rawText) async {
    final data = extractDataFromReceipt(rawText);
    final String matchedCategory = hybridCategoryMatch(data['vendor']);
    final double amount = double.tryParse(data['amount'] ?? '0') ?? 0.0;
    final DateTime timestamp =
        DateTime.tryParse(data['date']) ?? DateTime.now();

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final transaction = TransactionModel(
      id: '',
      categoryId: matchedCategory,
      amount: amount,
      rawText: rawText,
      timestamp: timestamp,
    );

    final docRef = await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(transaction.toMap());

    final addedTransaction = TransactionModel(
      id: docRef.id,
      categoryId: transaction.categoryId,
      amount: transaction.amount,
      rawText: transaction.rawText,
      timestamp: transaction.timestamp,
    );

    setState(() {
      _transactions.insert(0, addedTransaction);
    });

    final budgetProvider = Provider.of<ModernBudgetProvider>(
      context,
      listen: false,
    );
    await budgetProvider.processTransactionForBudgetUpdate(
      transactionCategoryName: matchedCategory,
      transactionAmount: amount,
    );
  }

  Future<void> _showManualEntryDialog() async {
    final _formKey = GlobalKey<FormState>();
    String? category;
    double? amount;
    DateTime timestamp = DateTime.now();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.teal[900],
            title: const Text(
              'Log Transaction Manually',
              style: TextStyle(color: Colors.white),
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Colors.white),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.tealAccent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSaved: (val) => category = val,
                    validator:
                        (val) =>
                            val == null || val.isEmpty
                                ? 'Enter category'
                                : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: Colors.white),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.tealAccent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    onSaved: (val) => amount = double.tryParse(val ?? '0'),
                    validator:
                        (val) =>
                            val == null || double.tryParse(val) == null
                                ? 'Enter valid amount'
                                : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.blueAccent),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Add'),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    final uid = _auth.currentUser?.uid;
                    if (uid == null || category == null || amount == null)
                      return;

                    final newTxn = TransactionModel(
                      id: '',
                      categoryId: category!,
                      amount: amount!,
                      rawText: 'Manual Entry',
                      timestamp: timestamp,
                    );

                    final docRef = await _db
                        .collection('users')
                        .doc(uid)
                        .collection('transactions')
                        .add(newTxn.toMap());

                    final savedTxn = TransactionModel(
                      id: docRef.id,
                      categoryId: newTxn.categoryId,
                      amount: newTxn.amount,
                      rawText: newTxn.rawText,
                      timestamp: newTxn.timestamp,
                    );

                    setState(() {
                      _transactions.insert(0, savedTxn);
                    });

                    final budgetProvider = Provider.of<ModernBudgetProvider>(
                      context,
                      listen: false,
                    );
                    await budgetProvider.processTransactionForBudgetUpdate(
                      transactionCategoryName: category!,
                      transactionAmount: amount!,
                    );

                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
    );
  }

  void _editOrDeleteDialog(TransactionModel txn) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.white),
                title: const Text(
                  'Edit',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // You can extend this to edit the transaction
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  final uid = _auth.currentUser?.uid;
                  if (uid != null) {
                    await _db
                        .collection('users')
                        .doc(uid)
                        .collection('transactions')
                        .doc(txn.id)
                        .delete();
                    setState(() {
                      _transactions.removeWhere((t) => t.id == txn.id);
                    });
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTxns =
        _transactions.where((txn) {
          final matchesSearch = txn.rawText.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          final matchesCategory =
              _selectedCategory == 'All' || txn.categoryId == _selectedCategory;
          final matchesDate = DateUtils.isSameDay(txn.timestamp, _selectedDate);
          return matchesSearch && matchesCategory && matchesDate;
        }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Expenses',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Manual Entry',
            onPressed: _showManualEntryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            tooltip: 'Scan Receipt',
            onPressed: () async {
              String sampleReceipt = '''
                Tesco Malaysia
                Total: RM42.50
                Date: 22/05/2025
              ''';
              await _handleScanReceipt(sampleReceipt);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2022),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.yMMMd().format(_selectedDate),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: Colors.grey[850],
                            value: _selectedCategory,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white70,
                            ),
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            onChanged:
                                (val) =>
                                    setState(() => _selectedCategory = val!),
                            items:
                                _categories
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTxns.isEmpty
                    ? const Center(
                      child: Text(
                        'No transactions found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filteredTxns.length,
                      itemBuilder: (context, index) {
                        final txn = filteredTxns[index];
                        return GestureDetector(
                          onLongPress: () => _editOrDeleteDialog(txn),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            color: Theme.of(context).colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.background,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          txn.categoryId,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          DateFormat.jm().format(txn.timestamp),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "-\$${txn.amount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
