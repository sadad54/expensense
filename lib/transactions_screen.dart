// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class TransactionScreen extends StatefulWidget {
//   const TransactionScreen({super.key});

//   @override
//   State<TransactionScreen> createState() => _TransactionScreenState();
// }

// class _TransactionScreenState extends State<TransactionScreen> {
//   final List<Map<String, dynamic>> allTransactions = [
//     {
//       'title': 'Restaurant',
//       'amount': 12.00,
//       'category': 'Food',
//       'type': 'Expense',
//       'date': DateTime(2024, 1, 24, 10, 32),
//     },
//     {
//       'title': 'Groceries',
//       'amount': 55.00,
//       'category': 'Shopping',
//       'type': 'Expense',
//       'date': DateTime(2024, 1, 24, 9, 21),
//     },
//     {
//       'title': 'Movie',
//       'amount': 8.99,
//       'category': 'Entertainment',
//       'type': 'Expense',
//       'date': DateTime(2024, 1, 24, 19, 0),
//     },
//     {
//       'title': 'Gas',
//       'amount': 45.00,
//       'category': 'Transport',
//       'type': 'Expense',
//       'date': DateTime(2024, 1, 24, 8, 16),
//     },
//   ];

//   DateTime selectedDate = DateTime(2024, 1, 24);
//   String selectedCategory = 'All';
//   String searchQuery = '';

//   List<String> categories = [
//     'All',
//     'Food',
//     'Shopping',
//     'Entertainment',
//     'Transport',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final filteredTransactions =
//         allTransactions.where((txn) {
//           final matchesDate = DateUtils.isSameDay(txn['date'], selectedDate);
//           final matchesCategory =
//               selectedCategory == 'All' || txn['category'] == selectedCategory;
//           final matchesSearch = txn['title'].toLowerCase().contains(
//             searchQuery.toLowerCase(),
//           );
//           return matchesDate && matchesCategory && matchesSearch;
//         }).toList();

//     return Scaffold(
//       backgroundColor: const Color(0xFF1C1C1E), // Dark background
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1C1C1E),
//         elevation: 0,
//         title: const Text(
//           'Expenses',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           // Search & Filters
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Column(
//               children: [
//                 TextField(
//                   style: const TextStyle(color: Colors.white),
//                   onChanged: (value) => setState(() => searchQuery = value),
//                   decoration: InputDecoration(
//                     hintText: 'Search',
//                     hintStyle: TextStyle(color: Colors.grey[400]),
//                     filled: true,
//                     fillColor: const Color(0xFF2C2C2E),
//                     prefixIcon: const Icon(Icons.search, color: Colors.white),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: _pickDate,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             vertical: 12,
//                             horizontal: 16,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF2C2C2E),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.calendar_today,
//                                 color: Colors.white,
//                                 size: 18,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 DateFormat.yMMMMd().format(selectedDate),
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2C2C2E),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: DropdownButton<String>(
//                           dropdownColor: const Color(0xFF2C2C2E),
//                           value: selectedCategory,
//                           icon: const Icon(
//                             Icons.keyboard_arrow_down,
//                             color: Colors.white,
//                           ),
//                           isExpanded: true,
//                           underline: const SizedBox(),
//                           onChanged:
//                               (value) =>
//                                   setState(() => selectedCategory = value!),
//                           items:
//                               categories.map((String category) {
//                                 return DropdownMenuItem<String>(
//                                   value: category,
//                                   child: Text(
//                                     category,
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                 );
//                               }).toList(),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child:
//                 filteredTransactions.isEmpty
//                     ? const Center(
//                       child: Text(
//                         'No transactions found',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                     : ListView.builder(
//                       itemCount: filteredTransactions.length,
//                       itemBuilder: (context, index) {
//                         return TransactionCard(
//                           txn: filteredTransactions[index],
//                         );
//                       },
//                     ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _pickDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2022),
//       lastDate: DateTime.now(),
//       builder: (context, child) {
//         return Theme(data: ThemeData.dark(), child: child!);
//       },
//     );

//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//     }
//   }
// }

// // TransactionCard is reused from previous message
// class TransactionCard extends StatelessWidget {
//   final Map<String, dynamic> txn;

//   const TransactionCard({super.key, required this.txn});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       color: const Color(0xFF2C2C2E),
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF3A3A3C),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 _getIconForCategory(txn['category']),
//                 color: Colors.tealAccent,
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     txn['title'],
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     "${_formatTime(txn['date'])} • ${txn['category']}",
//                     style: TextStyle(color: Colors.grey[400], fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               "\$${txn['amount'].toStringAsFixed(2)}",
//               style: TextStyle(
//                 color:
//                     txn['type'] == 'Expense'
//                         ? Colors.redAccent
//                         : Colors.greenAccent,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData _getIconForCategory(String category) {
//     switch (category.toLowerCase()) {
//       case 'food':
//         return Icons.restaurant;
//       case 'shopping':
//         return Icons.shopping_bag;
//       case 'entertainment':
//         return Icons.movie;
//       case 'transport':
//         return Icons.directions_car;
//       default:
//         return Icons.category;
//     }
//   }

//   String _formatTime(DateTime dateTime) {
//     final time = TimeOfDay.fromDateTime(dateTime);
//     final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
//     final period = time.period == DayPeriod.am ? 'AM' : 'PM';
//     return '${hour}:${time.minute.toString().padLeft(2, '0')} $period';
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
// import 'package:firebase_auth/firebase_auth.dart'; // Import Auth if using user IDs

// Import the placeholder screens
import 'package:exp_ocr/add_expenses_screen.dart';
import 'package:exp_ocr/categories_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Remove the hardcoded list
  // final List<Map<String, dynamic>> allTransactions = [ ... ];

  // --- State Variables ---
  DateTime selectedDate = DateTime.now(); // Default to today
  String selectedCategory = 'All';
  String searchQuery = '';

  // --- Firestore Instance ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance; // If using authentication

  // --- Categories ---
  // Keep this list for the dropdown filter for now.
  // For a fully dynamic solution, fetch categories from Firestore as well.
  List<String> categories = [
    'All',
    'Food',
    'Shopping',
    'Entertainment',
    'Transport',
    'Salary', // Example Income Category
    'Other',
  ];

  // --- Navigation ---
  void _navigateToAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
  }

  void _navigateToCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoriesScreen()),
    );
  }

  // --- Date Picker ---
  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2022), // Adjust as needed
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // Allow future dates?
      builder: (context, child) {
        // Use app's theme for consistency
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // --- Get Current User ID (Important for multi-user apps) ---
    // String? userId = _auth.currentUser?.uid;
    // if (userId == null) {
    //   // Handle case where user is not logged in (e.g., show login screen or error)
    //   return const Scaffold(
    //       body: Center(child: Text("Please log in", style: TextStyle(color: Colors.white))));
    // }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text(
          'Expenses', // Consider changing to 'Transactions' if including income
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, color: Colors.white),
            tooltip: 'Manage Categories',
            onPressed: _navigateToCategories, // Calls the navigation method
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters
          _buildFilterSection(),
          const SizedBox(height: 8),
          // Transaction List (using StreamBuilder)
          Expanded(
            child: _buildTransactionList(
              /*userId: userId*/
            ), // Pass userId if needed
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExpense, // Navigate to Add Expense screen
        tooltip: 'Add Expense',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // --- Filter Section Widget ---
  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Field
          TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => setState(() => searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by title...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          // Date and Category Filters Row
          Row(
            children: [
              // Date Picker Button
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                          DateFormat.yMMMd().format(
                            selectedDate,
                          ), // Short date format
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Category Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ), // Adjust padding
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    // Hide default underline
                    child: DropdownButton<String>(
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      value: selectedCategory,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                      ),
                      isExpanded: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ), // Consistent text style
                      onChanged:
                          (value) => setState(() => selectedCategory = value!),
                      items:
                          categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Transaction List Widget (StreamBuilder) ---
  Widget _buildTransactionList(/*{required String userId}*/) {
    // --- Build Firestore Query ---
    Query query = _firestore
        .collection('transactions')
        // .where('userId', isEqualTo: userId) // ** UNCOMMENT FOR USER-SPECIFIC DATA **
        .orderBy('date', descending: true); // Order by date descending

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(), // Listen to the stream of data
      builder: (context, snapshot) {
        // --- Handle Loading State ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- Handle Error State ---
        if (snapshot.hasError) {
          print("Firestore Error: ${snapshot.error}"); // Log the error
          return Center(
            child: Text(
              'Error loading transactions: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        // --- Handle No Data State ---
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No transactions yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // --- Process Data ---
        final allDocs = snapshot.data!.docs;
        final transactions =
            allDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Convert Firestore Timestamp to DateTime
              final timestamp = data['date'] as Timestamp?;
              return {
                'id': doc.id, // Keep document ID if needed for updates/deletes
                'title': data['title'] ?? 'No Title',
                'amount': (data['amount'] ?? 0.0).toDouble(),
                'category': data['category'] ?? 'Uncategorized',
                'type': data['type'] ?? 'Expense',
                'date':
                    timestamp?.toDate() ?? DateTime.now(), // Handle null date
                // 'userId': data['userId'], // Include if needed elsewhere
              };
            }).toList();

        // --- Apply Local Filters ---
        final filteredTransactions =
            transactions.where((txn) {
              // Ensure txn['date'] is a DateTime
              final DateTime transactionDate = txn['date'] as DateTime;

              final matchesDate = DateUtils.isSameDay(
                transactionDate,
                selectedDate,
              );
              final matchesCategory =
                  selectedCategory == 'All' ||
                  txn['category'] == selectedCategory;
              final matchesSearch = txn['title'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
              return matchesDate && matchesCategory && matchesSearch;
            }).toList();

        // --- Display Filtered List ---
        if (filteredTransactions.isEmpty) {
          return const Center(
            child: Text(
              'No transactions match your filters.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80), // Space for FAB
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            // Pass the individual transaction map to the card
            return TransactionCard(txn: filteredTransactions[index]);
          },
        );
      },
    );
  }
}

// --- TransactionCard Widget (Keep as is, but ensure it handles data correctly) ---
class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> txn;

  const TransactionCard({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    // Determine color based on transaction type
    final Color amountColor =
        (txn['type'] == 'Expense')
            ? Colors.redAccent
            : Colors.greenAccent; // Green for Income

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ), // Adjust margin
      color: Theme.of(context).colorScheme.surface, // Use theme color
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Slightly less rounded
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ), // Adjust padding
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    Theme.of(
                      context,
                    ).colorScheme.background, // Darker background for icon
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconForCategory(txn['category']),
                color:
                    Theme.of(
                      context,
                    ).colorScheme.primary, // Use primary theme color
                size: 24,
              ),
            ),
            const SizedBox(width: 14), // Adjust spacing
            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600, // Slightly bolder
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5), // Adjust spacing
                  Text(
                    // Ensure date is DateTime before formatting
                    "${_formatTime(txn['date'] as DateTime)} • ${txn['category']}",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ), // Slightly larger subtitle
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Text(
              "${txn['type'] == 'Expense' ? '-' : '+'}\$${(txn['amount'] as double).toStringAsFixed(2)}", // Add sign +/-
              style: TextStyle(
                color: amountColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Get Icon for Category ---
  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_menu_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'transport':
        return Icons.directions_car_filled_outlined;
      case 'groceries':
        return Icons.local_grocery_store_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'salary':
        return Icons.attach_money_outlined; // Income example
      default:
        return Icons.category_outlined;
    }
  }

  // --- Helper: Format Time ---
  String _formatTime(DateTime dateTime) {
    // Use intl package for more robust time formatting if needed
    return DateFormat.jm().format(dateTime); // e.g., 5:08 PM
  }
}
