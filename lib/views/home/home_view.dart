// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart'; // Assuming you'll use this for actual charts
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';

// // Placeholder Chart Widgets (Replace with your actual charts)
// class PlaceholderPieChart extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return AspectRatio(
//       aspectRatio: 1,
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: Colors.tealAccent.withOpacity(0.3),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.pie_chart_outline_rounded, color: Colors.white70, size: 40),
//                 SizedBox(height: 8),
//                 Text("Pie Chart", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class PlaceholderBarChart extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//      return AspectRatio(
//       aspectRatio: 1,
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: Colors.orangeAccent.withOpacity(0.3),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.bar_chart_rounded, color: Colors.white70, size: 40),
//                 SizedBox(height: 8),
//                 Text("Bar Chart", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class PlaceholderLineChart extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return AspectRatio(
//       aspectRatio: 1,
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         color: Colors.purpleAccent.withOpacity(0.3),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.show_chart_rounded, color: Colors.white70, size: 40),
//                 SizedBox(height: 8),
//                 Text("Line Chart", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   double _balance = 0.0;
//   double _income = 0.0;
//   double _expenses = 0.0;
//   List<Map<String, dynamic>> _recentTransactions = [];
//   List<Map<String, dynamic>> _budgets = [];
//   Map<String, dynamic>? _goal;

//   final String username = "Adnan"; // Consider fetching from Firebase Auth profile

//   @override
//   void initState() {
//     super.initState();
//     _fetchAllData();
//   }

//   void _fetchAllData() {
//     _fetchBalanceAndSummary();
//     _fetchRecentTransactions();
//     _fetchBudgets();
//     _fetchGoal();
//   }

//   void _onTabTapped(int index) {
//     if (_selectedIndex == index && index != 0) return; // Avoid redundant rebuilds

//     setState(() {
//       _selectedIndex = index;
//     });
//     switch (index) {
//       case 0: // Home
//         // Optional: refresh data if needed, or just ensure it's the current view
//         // _fetchAllData(); // Uncomment if you want to refresh data on navigating back to Home
//         break;
//       case 1:
//         Navigator.pushNamed(context, '/transaction');
//         break;
//       case 2:
//         Navigator.pushNamed(context, '/stats');
//         break;
//       case 3: // FAB action
//         Navigator.pushNamed(context, '/scan');
//         break;
//       case 4:
//         Navigator.pushNamed(context, '/goals');
//         break;
//       case 5:
//         Navigator.pushNamed(context, '/budgets');
//         break;
//       case 6:
//         Navigator.pushNamed(context, '/settings');
//         break;
//     }
//   }

//   Future<void> _fetchBalanceAndSummary() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       if (mounted) {
//         setState(() {
//           _income = 0; _expenses = 0; _balance = 0;
//         });
//       }
//       return;
//     }
//     try {
//       final query = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('generalTransactions')
//           .get();
//       double income = 0;
//       double expense = 0;
//       for (var doc in query.docs) {
//         final data = doc.data();
//         final amount = (data['amount'] ?? 0).toDouble();
//         final type = data['type'] ?? 'expense';
//         if (type == 'income')
//           income += amount;
//         else
//           expense += amount;
//       }
//       if (mounted) {
//         setState(() {
//           _income = income;
//           _expenses = expense;
//           _balance = income - expense;
//         });
//       }
//     } catch (e) {
//       print("Error fetching balance and summary: $e");
//       if (mounted) {
//          setState(() {
//           _income = 0; _expenses = 0; _balance = 0;
//         });
//       }
//     }
//   }

//   Future<void> _fetchRecentTransactions() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       if (mounted) setState(() => _recentTransactions = []);
//       return;
//     }
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('generalTransactions')
//           .orderBy('timestamp', descending: true)
//           .limit(3)
//           .get();
//       if (mounted) {
//         setState(() {
//           _recentTransactions = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
//         });
//       }
//     } catch (e) {
//       print("Error fetching recent transactions: $e");
//        if (mounted) setState(() => _recentTransactions = []);
//     }
//   }

//   Future<void> _fetchBudgets() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       if (mounted) setState(() => _budgets = []);
//       return;
//     }
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('budget_categories')
//           .limit(3)
//           .get();
//       if (mounted) {
//         setState(() {
//           _budgets = snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
//         });
//       }
//     } catch (e) {
//       print("Error fetching budgets: $e");
//       if (mounted) setState(() => _budgets = []);
//     }
//   }

//   Future<void> _fetchGoal() async {
//     final uid = FirebaseAuth.instance.currentUser?.uid;
//     if (uid == null) {
//       if (mounted) setState(() => _goal = null);
//       return;
//     }
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('goals')
//           .limit(1)
//           .get();
//       if (mounted) {
//         if (snapshot.docs.isNotEmpty) {
//           setState(() {
//             _goal = snapshot.docs.first.data()..['id'] = snapshot.docs.first.id;
//           });
//         } else {
//            setState(() => _goal = null);
//         }
//       }
//     } catch (e) {
//        print("Error fetching goal: $e");
//        if (mounted) setState(() => _goal = null);
//     }
//   }

//   Widget _buildNavBarIcon(IconData icon, String label, int index) {
//     bool isSelected = _selectedIndex == index;
//     return Expanded( // Ensures icons space out correctly
//       child: InkWell( // Use InkWell for ripple effect
//         onTap: () => _onTabTapped(index),
//         borderRadius: BorderRadius.circular(12), // Optional: for ripple effect shape
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: isSelected ? Colors.tealAccent : Colors.blueGrey, size: 24),
//             SizedBox(height: 4),
//             Text(
//               label,
//               style: GoogleFonts.poppins(
//                 color: isSelected ? Colors.tealAccent : Colors.blueGrey,
//                 fontSize: 10,
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF121212),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E1E1E),
//         elevation: 0,
//         title: Text(
//           'ExpenSense',
//           style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
//         ),
//         centerTitle: true,
//       ),
//       body: RefreshIndicator( // Optional: Add pull-to-refresh
//         onRefresh: () async {
//           _fetchAllData();
//         },
//         child: SingleChildScrollView(
//           physics: AlwaysScrollableScrollPhysics(), // Ensures refresh indicator works even if content is small
//           padding: EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding for FAB
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildUserHeader(),
//               SizedBox(height: 20),
//               _buildBalanceCard(),
//               SizedBox(height: 20),
//               _buildInfoCardsRow(),
//               SizedBox(height: 20),
//               _buildStatsHorizontalScroll(),
//               SizedBox(height: 20),
//               _buildRecentTransactionsCard(),
//               SizedBox(height: 8), // Reduced space between cards
//               _buildBudgetPreviewCard(),
//               SizedBox(height: 8), // Reduced space between cards
//               _buildGoalCard(),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.tealAccent,
//         onPressed: () => _onTabTapped(3),
//         child: Icon(Icons.qr_code_scanner, color: Colors.black),
//         shape: CircleBorder(),
//         elevation: 4.0,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//       bottomNavigationBar: BottomAppBar(
//         color: const Color(0xFF1E1E1E),
//         shape: const CircularNotchedRectangle(),
//         notchMargin: 8.0,
//         elevation: 8.0, // Add some elevation
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
//           child: Row(
//             children: <Widget>[
//               _buildNavBarIcon(Icons.home_filled, "Home", 0),
//               _buildNavBarIcon(Icons.swap_horiz_rounded, "Transactions", 1),
//               _buildNavBarIcon(Icons.bar_chart_rounded, "Stats", 2),
//               SizedBox(width: 50), // Space for FAB
//               _buildNavBarIcon(Icons.flag_rounded, "Goals", 4),
//               _buildNavBarIcon(Icons.account_balance_wallet_rounded, "Budgets", 5),
//               _buildNavBarIcon(Icons.settings_rounded, "Settings", 6),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildUserHeader() {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     final displayName = currentUser?.displayName ?? username;
//     return Row(
//       children: [
//         CircleAvatar(
//           radius: 28,
//           backgroundImage: currentUser?.photoURL != null
//               ? NetworkImage(currentUser!.photoURL!)
//               : NetworkImage('https://i.pravatar.cc/150?u=${currentUser?.uid ?? 'default'}'),
//            onBackgroundImageError: (exception, stackTrace) {
//              print("Error loading user avatar: $exception");
//            },
//            child: currentUser?.photoURL == null && displayName.isNotEmpty
//               ? Text(displayName[0].toUpperCase(), style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
//               : null,
//            backgroundColor: Colors.grey[700],
//         ),
//         SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Welcome back,',
//               style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
//             ),
//             Text(
//               '$displayName 👋',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildBalanceCard() {
//     return Card(
//       color: const Color(0xFF1E1E1E),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Current Balance',
//               style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
//             ),
//             SizedBox(height: 10),
//             Text(
//               'MYR ${_balance.toStringAsFixed(2)}',
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () => Navigator.pushNamed(context, '/incomeTax'),
//               icon: Icon(Icons.receipt_long_rounded, color: Colors.black87),
//               label: Text("Tax Info", style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black87)),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.tealAccent,
//                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCardsRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: Card(
//             color: Colors.teal[700],
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             elevation: 3,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//               child: Column(
//                 children: [
//                   Text('Income', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 14)),
//                   SizedBox(height: 8),
//                   Text(
//                     'MYR ${_income.toStringAsFixed(2)}',
//                     style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         SizedBox(width: 12),
//         Expanded(
//           child: Card(
//             color: Colors.deepOrange[400],
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//             elevation: 3,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//               child: Column(
//                 children: [
//                   Text('Expenses', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8), fontSize: 14)),
//                   SizedBox(height: 8),
//                   Text(
//                     'MYR ${_expenses.toStringAsFixed(2)}',
//                     style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatsHorizontalScroll() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "📈 Stats Overview",
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: 12),
//         Container(
//           height: 150, // Adjust height as needed for your charts
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: [
//               SizedBox(width: 150, child: PlaceholderPieChart()),
//               SizedBox(width: 12),
//               SizedBox(width: 150, child: PlaceholderBarChart()),
//               SizedBox(width: 12),
//               SizedBox(width: 150, child: PlaceholderLineChart()),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildRecentTransactionsCard() {
//     return GestureDetector(
//       onTap: () => Navigator.pushNamed(context, '/transaction'), // Or a specific all transactions page
//       child: Card(
//         color: Color(0xFF1C1C1E), // Slightly different dark shade
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         margin: EdgeInsets.only(top: 12),
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "💳 Recent Transactions",
//                 style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//               SizedBox(height: 10),
//               if (_recentTransactions.isEmpty)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10.0),
//                   child: Text("No recent transactions found.", style: GoogleFonts.poppins(color: Colors.grey[400])),
//                 )
//               else
//                 ..._recentTransactions.map(
//                   (tx) => ListTile(
//                     contentPadding: EdgeInsets.zero,
//                     dense: true,
//                     leading: Icon(
//                         tx['type'] == 'income' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
//                         color: tx['type'] == 'income' ? Colors.greenAccent[400] : Colors.redAccent[200],
//                     ),
//                     title: Text(
//                       tx['categoryName'] ?? "Unknown Category",
//                       style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
//                     ),
//                     subtitle: Text(
//                       DateFormat.yMMMd().add_jm().format((tx['timestamp'] as Timestamp).toDate()), // Added time
//                       style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
//                     ),
//                     trailing: Text(
//                       "${tx['type'] == 'income' ? '+' : '-'}MYR ${(tx['amount'] ?? 0.0).toStringAsFixed(2)}",
//                       style: GoogleFonts.poppins(
//                         color: tx['type'] == 'income' ? Colors.greenAccent[400] : Colors.redAccent[200],
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBudgetPreviewCard() {
//     return GestureDetector(
//       onTap: () => Navigator.pushNamed(context, '/budgets'),
//       child: Card(
//         color: Color(0xFF1C1C1E),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         margin: EdgeInsets.only(top: 12),
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "💼 Budget Overview",
//                 style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//               SizedBox(height: 10),
//               if (_budgets.isEmpty)
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 10.0),
//                   child: Text("No budgets set up yet.", style: GoogleFonts.poppins(color: Colors.grey[400])),
//                 )
//               else
//                 ..._budgets.map(
//                   (budget) => Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           budget['name'] ?? "Unnamed Budget",
//                           style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
//                         ),
//                         Text(
//                           "MYR ${(budget['allocatedAmount'] ?? 0.0).toStringAsFixed(2)}",
//                            style: GoogleFonts.poppins(color: Colors.tealAccent, fontWeight: FontWeight.w500)
//                         ),
//                       ],
//                     ),
//                   )
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildGoalCard() {
//     if (_goal == null) {
//       return GestureDetector( // Still allow navigation even if no goal is set, to the goals page
//         onTap: () => Navigator.pushNamed(context, '/goals'),
//         child: Card(
//           color: Color(0xFF1C1C1E),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           margin: EdgeInsets.only(top: 12),
//           elevation: 2,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "🎯 Goal Progress",
//                   style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//                 SizedBox(height: 10),
//                 Text("No active goal set. Tap to add one!", style: GoogleFonts.poppins(color: Colors.grey[400])),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     final double saved = (_goal!['saved'] ?? 0.0).toDouble();
//     final double target = (_goal!['target'] ?? 1.0).toDouble(); // Avoid division by zero if target is 0
//     final double progress = target == 0 ? 0 : (saved / target).clamp(0.0, 1.0);

//     return GestureDetector(
//       onTap: () => Navigator.pushNamed(context, '/goals'),
//       child: Card(
//         color: Color(0xFF1C1C1E),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         margin: EdgeInsets.only(top: 12),
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "🎯 Goal Progress",
//                 style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//               SizedBox(height: 12),
//               Text(
//                 _goal!['title'] ?? "Untitled Goal",
//                 style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
//                 overflow: TextOverflow.ellipsis,
//               ),
//               SizedBox(height: 8),
//               LinearProgressIndicator(
//                 value: progress,
//                 backgroundColor: Colors.grey[700],
//                 color: Colors.tealAccent,
//                 minHeight: 8,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "MYR ${saved.toStringAsFixed(2)} / ${target.toStringAsFixed(2)}",
//                     style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 12),
//                   ),
//                    Text(
//                     "${(progress * 100).toStringAsFixed(0)}%",
//                     style: GoogleFonts.poppins(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exp_ocr/models/goal_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // For colors if needed

// Remove Placeholder Chart Widgets if they are in this file.
// We will build actual charts.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // Added super.key

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double _balance = 0.0;
  double _income = 0.0;
  Goal? _goal;
  double _manualMonthlyIncome = 0.0;

  double _expenses = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _budgets = [];

  // --- New state variables for Home Screen charts ---
  bool _chartsLoading = true;
  Map<String, double> _homeScreenCategoryTotals = {};
  double _homeScreenTotalSpentForMonth = 0.0;
  final DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // For consistent colors for categories
  final Map<String, Color> _categoryColors = {};
  final List<Color> _baseColors = [
    Colors.tealAccent.shade400,
    Colors.lightBlueAccent.shade400,
    Colors.pinkAccent.shade400,
    Colors.amberAccent.shade400,
    Colors.greenAccent.shade400,
    Colors.purpleAccent.shade400,
  ];
  int _colorIndex = 0;

  Color _getColorForCategory(String categoryName) {
    return _categoryColors.putIfAbsent(categoryName, () {
      final color = _baseColors[_colorIndex % _baseColors.length];
      _colorIndex++;
      return color;
    });
  }
  // --- End new state variables ---

  final String username = "Adnan";

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _fetchHomeScreenChartData(); // Fetch data for home screen charts
  }

  void _fetchAllData() {
    _fetchBalanceAndSummary();
    _fetchRecentTransactions();
    _fetchBudgets();
    _fetchGoal();
  }

  void _showIncomeEntryDialog() {
    final controller = TextEditingController(
      text: _manualMonthlyIncome.toStringAsFixed(2),
    );
    final now = DateTime.now();
    final incomeDocId = '${now.year}_${now.month.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Monthly Income'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (MYR)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;

                final parsed = double.tryParse(controller.text);
                if (parsed == null) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('monthlyIncome')
                    .doc(incomeDocId)
                    .set({'amount': parsed});

                if (mounted) {
                  setState(() {
                    _manualMonthlyIncome = parsed;
                    _income = parsed;
                    _balance = _income - _expenses;
                  });
                }

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- New method to fetch data for Home Screen charts (current month) ---
  Future<void> _fetchHomeScreenChartData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _chartsLoading = false);
      return;
    }
    if (mounted) setState(() => _chartsLoading = true);

    _categoryColors.clear(); // Reset colors on each fetch
    _colorIndex = 0;

    DateTime startDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    DateTime endDate = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection(
                "generalTransactions",
              ) // Ensure this is your correct transactions collection
              .where(
                "timestamp",
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                "timestamp",
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .get();

      final Map<String, double> totals = {};
      double totalSpent = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final String categoryName = data['categoryName'] as String? ?? 'Other';
        final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        // Assuming all transactions in 'generalTransactions' are expenses for this chart
        // If you have a 'type' field (income/expense), filter for expenses here.
        // For simplicity, we'll assume all are spendings for the pie chart.
        // if (data['type'] == 'expense' || data['type'] == null) { // Example if you have a type field
        totals[categoryName] = (totals[categoryName] ?? 0) + amount;
        totalSpent += amount;
        // }
      }
      if (mounted) {
        setState(() {
          _homeScreenCategoryTotals = totals;
          _homeScreenTotalSpentForMonth = totalSpent;
          _chartsLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching home screen chart data: $e");
      if (mounted) {
        setState(() {
          _chartsLoading = false;
          _homeScreenCategoryTotals = {};
          _homeScreenTotalSpentForMonth = 0;
        });
      }
    }
  }
  // --- End new method ---

  void _onTabTapped(int index) {
    // Prevent re-navigating to the current screen if it's not home
    if (_selectedIndex == index &&
        index != 0 &&
        index != 3 /*FAB is special*/ ) {
      if (mounted)
        setState(
          () => _selectedIndex = 0,
        ); // Reset to home visually if tapped again
      return;
    }
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
    switch (index) {
      case 0: // Home
        // Already on home, or navigating back to home visually
        break;
      case 1:
        Navigator.pushNamed(
          context,
          '/transaction',
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.pushNamed(
          context,
          '/stats',
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3: // FAB action (Scan)
        Navigator.pushNamed(context, '/scan').then((_) {
          // Assuming '/scan_receipt_screen' is correct route
          if (mounted)
            setState(
              () => _selectedIndex = 0,
            ); // Reset to home visually after scan
          _fetchAllData(); // Refresh data after potential new transaction
          _fetchHomeScreenChartData();
        });
        break;
      case 4:
        Navigator.pushNamed(
          context,
          '/goals',
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 5:
        Navigator.pushNamed(
          context,
          '/budgets',
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 6:
        // Assuming you have a settings route, e.g., '/settings_screen'
        Navigator.pushNamed(
          context,
          '/settings',
        ).then((_) => setState(() => _selectedIndex = 0));
        print("Settings tapped"); // Placeholder if no route
        if (mounted) setState(() => _selectedIndex = 0); // Reset to home
        break;
    }
  }

  Future<void> _fetchBalanceAndSummary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _income = _expenses = _balance = 0);
      return;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('generalTransactions')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
              .get();

      double expense = 0;
      for (var doc in query.docs) {
        final data = doc.data();
        final category = data['categoryName'] ?? '';
        final amount = (data['amount'] ?? 0).toDouble();

        if (!category.toLowerCase().contains('income')) {
          expense += amount;
        }
      }

      final incomeDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('monthlyIncome')
              .doc('${now.year}_${now.month.toString().padLeft(2, '0')}')
              .get();

      double income = 0;
      if (incomeDoc.exists) {
        income = (incomeDoc.data()?['amount'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _income = income;
          _manualMonthlyIncome = income;
          _expenses = expense;
          _balance = income - expense;
        });
      }
    } catch (e) {
      print("Error calculating balance: $e");
      if (mounted) setState(() => _income = _expenses = _balance = 0);
    }
  }

  Future<void> _fetchRecentTransactions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _recentTransactions = []);
      return;
    }
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection(
                'generalTransactions',
              ) // Reading from generalTransactions
              .orderBy('timestamp', descending: true)
              .limit(3)
              .get();
      if (mounted) {
        setState(() {
          _recentTransactions =
              snapshot.docs.map((doc) {
                final data = doc.data();
                // Assuming all are expenses for display purposes here unless 'type' is present
                data['type'] = data['type'] ?? 'expense';
                return data..['id'] = doc.id;
              }).toList();
        });
      }
    } catch (e) {
      print("Error fetching recent transactions: $e");
      if (mounted) setState(() => _recentTransactions = []);
    }
  }

  Future<void> _fetchBudgets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _budgets = []);
      return;
    }
    try {
      // Fetching from the ModernBudgetScreen's structure
      final now = DateTime.now();
      final budgetId =
          "monthly_${now.year}_${now.month.toString().padLeft(2, '0')}";
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('budgets')
              .doc(budgetId)
              .collection('categories') // These are the budget categories
              .orderBy(
                'allocatedAmount',
                descending: true,
              ) // Show most budgeted
              .limit(3)
              .get();
      if (mounted) {
        setState(() {
          _budgets =
              snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
        });
      }
    } catch (e) {
      print("Error fetching budgets: $e");
      if (mounted) setState(() => _budgets = []);
    }
  }

  Future<void> _fetchGoal() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _goal = null);
      return;
    }
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('goals') // 🔥 Top-level collection
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

      if (mounted) {
        if (snapshot.docs.isNotEmpty) {
          setState(() {
            _goal = Goal.fromFirestore(snapshot.docs.first);
          });
        } else {
          setState(() => _goal = null);
        }
      }
    } catch (e) {
      print("Error fetching goal: $e");
      if (mounted) setState(() => _goal = null);
    }
  }

  Widget _buildNavBarIcon(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    bool isFabPlaceholder = index == 3; // Index 3 is the FAB placeholder

    if (isFabPlaceholder) {
      return const Expanded(child: SizedBox()); // Empty space for FAB
    }

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // Added padding for better touch area and visual spacing
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.tealAccent : Colors.blueGrey[200],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.tealAccent : Colors.blueGrey[200],
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use theme defined in main.dart
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        title: Text(
          'ExpenSense', // Your app name
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchAllData();
          _fetchHomeScreenChartData();
        },
        backgroundColor: theme.colorScheme.surface,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            80,
          ), // Padding for content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(),
              const SizedBox(height: 20),
              _buildBalanceCard(),
              const SizedBox(height: 20),
              _buildInfoCardsRow(),
              const SizedBox(height: 20),
              // --- Replace Placeholder with Actual Charts ---
              _buildStatsPreviewSection(), // New method for stats preview
              // --- End Replacement ---
              const SizedBox(height: 20),
              _buildRecentTransactionsCard(),
              const SizedBox(height: 12),
              _buildBudgetPreviewCard(),
              const SizedBox(height: 12),
              _buildGoalCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor:
            theme.floatingActionButtonTheme.backgroundColor ??
            Colors.tealAccent,
        onPressed: () => _onTabTapped(3), // Index for FAB action (Scan)
        shape: const CircleBorder(),
        elevation: 4.0,
        child: Icon(
          Icons.qr_code_scanner_rounded,
          color:
              theme.floatingActionButtonTheme.foregroundColor ?? Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: theme.bottomAppBarTheme.color ?? const Color(0xFF1E1E1E),
        shape:
            theme.bottomAppBarTheme.shape ?? const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: theme.bottomAppBarTheme.elevation ?? 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
          ), // Reduced vertical padding
          child: SizedBox(
            // Constrain height of BottomAppBar's child
            height: 60, // Typical BottomAppBar height
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavBarIcon(Icons.home_filled, "Home", 0),
                _buildNavBarIcon(Icons.swap_horiz_rounded, "Transactions", 1),
                _buildNavBarIcon(
                  Icons.insert_chart_outlined_rounded,
                  "Stats",
                  2,
                ), // Changed icon
                _buildNavBarIcon(
                  Icons.add,
                  "",
                  3,
                ), // FAB Placeholder, label can be empty
                _buildNavBarIcon(
                  Icons.flag_circle_rounded,
                  "Goals",
                  4,
                ), // Changed icon
                _buildNavBarIcon(
                  Icons.account_balance_wallet_rounded,
                  "Budgets",
                  5,
                ),
                _buildNavBarIcon(Icons.settings_rounded, "Settings", 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final currentUser = FirebaseAuth.instance.currentUser;
    // Fallback to a generic name if display name is null or empty
    final displayName =
        (currentUser?.displayName != null &&
                currentUser!.displayName!.isNotEmpty)
            ? currentUser.displayName!
            : "User"; // Generic fallback
    // Determine if a photo URL exists
    final bool hasPhotoUrl = currentUser?.photoURL != null;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage:
              hasPhotoUrl ? NetworkImage(currentUser!.photoURL!) : null,
          onBackgroundImageError:
              hasPhotoUrl
                  ? (exception, stackTrace) {
                    print("Error loading user avatar: $exception");
                  }
                  : null,
          backgroundColor: Colors.grey[700],
          child:
              (currentUser?.photoURL == null && displayName.isNotEmpty)
                  ? Text(
                    displayName[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
            ),
            Text(
              '$displayName 👋',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance',
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              // Consider using your app's default currency symbol or intl package for proper formatting
              NumberFormat.currency(
                locale: 'en_MY',
                symbol: 'MYR ',
                decimalDigits: 2,
              ).format(_balance),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Example: Navigate to a hypothetical Tax Info screen
                Navigator.pushNamed(context, '/incomeTax');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Tax Info coming soon!"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.black87,
                size: 20,
              ),
              label: Text(
                "Tax Info",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCardsRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showIncomeEntryDialog,
            child: Card(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Text(
                      'Income',
                      style: GoogleFonts.poppins(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        locale: 'en_MY',
                        symbol: 'MYR ',
                      ).format(_income),
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withOpacity(0.5), // Use theme color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  Text(
                    'Expenses',
                    style: GoogleFonts.poppins(
                      color: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(
                      locale: 'en_MY',
                      symbol: 'MYR ',
                      decimalDigits: 2,
                    ).format(_expenses),
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- New method to build the stats preview section ---
  Widget _buildStatsPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "📊 Current Month's Stats",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _onTabTapped(2), // Navigate to full StatsScreen
              child: Text(
                "View All",
                style: GoogleFonts.poppins(
                  color: Colors.tealAccent,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_chartsLoading)
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_homeScreenCategoryTotals.isEmpty)
          SizedBox(
            height: 180,
            child: Center(
              child: Text(
                "No spending data for this month yet.",
                style: GoogleFonts.poppins(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SizedBox(
            height: 180, // Adjusted height for previews
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                // Preview Pie Chart
                SizedBox(
                  width: 200, // Fixed width for preview chart
                  height: 180,
                  child: Column(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: _buildHomeScreenPieSections(),
                            centerSpaceRadius: 40, // Make it a donut
                            sectionsSpace: 2,
                            startDegreeOffset: -90,

                            // Add swap animations from your StatsScreen if fl_chart version is correct
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Spending Breakdown",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Preview Bar Chart (Top 3 categories)
                _buildHomeScreenBarChartPreview(),
              ],
            ),
          ),
      ],
    );
  }

  List<PieChartSectionData> _buildHomeScreenPieSections() {
    if (_homeScreenTotalSpentForMonth == 0) return [];
    // Sort by value to show prominent sections, or take top N
    var sortedTotals =
        _homeScreenCategoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 for pie chart, group rest into "Other"
    List<MapEntry<String, double>> topEntries = sortedTotals.take(4).toList();
    double otherTotal = sortedTotals
        .skip(4)
        .fold(0.0, (sum, entry) => sum + entry.value);
    if (otherTotal > 0) {
      topEntries.add(MapEntry("Other", otherTotal));
    }

    return topEntries.map((entry) {
      final percentage = (entry.value / _homeScreenTotalSpentForMonth) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50, // Smaller radius for preview
        color: _getColorForCategory(entry.key),
        titleStyle: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.black.withOpacity(0.7),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1.5,
        ),
      );
    }).toList();
  }

  Widget _buildHomeScreenBarChartPreview() {
    if (_homeScreenCategoryTotals.isEmpty) return const SizedBox.shrink();

    // Get top 3-4 categories for the bar chart preview
    var sortedTotals =
        _homeScreenCategoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    var topCategories = sortedTotals.take(3).toList();

    if (topCategories.isEmpty) return const SizedBox.shrink();

    final barGroups =
        topCategories.asMap().entries.map((entryMap) {
          final index = entryMap.key;
          final categoryEntry = entryMap.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: categoryEntry.value,
                color: _getColorForCategory(categoryEntry.key),
                width: 22, // Wider bars for preview
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList();

    double maxY =
        topCategories.isNotEmpty ? topCategories.first.value * 1.2 : 10.0;
    if (maxY == 0 && topCategories.isNotEmpty) maxY = 10;

    return SizedBox(
      width: 220, // Fixed width for preview bar chart
      height: 180,
      child: Column(
        children: [
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                maxY: maxY,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topCategories.length) {
                          final categoryName = topCategories[index].key;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4.0,
                            child: Text(
                              categoryName.length > 7
                                  ? '${categoryName.substring(0, 6)}...'
                                  : categoryName,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.grey[800]!,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String catName = topCategories[group.x].key;
                      return BarTooltipItem(
                        '$catName\n${NumberFormat.currency(locale: 'en_MY', symbol: 'MYR ').format(rod.toY)}',
                        GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                      );
                    },
                  ),
                ),

                // Add swap animations if fl_chart version is correct
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Top Categories",
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }
  // --- End new method ---

  Widget _buildRecentTransactionsCard() {
    return GestureDetector(
      onTap: () => _onTabTapped(1), // Use _onTabTapped for consistency
      child: Card(
        color: const Color(0xFF1C1C1E), // Slightly different dark shade
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(top: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "💳 Recent Transactions",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (_recentTransactions.isEmpty &&
                  !_chartsLoading) // Also check loading
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    "No recent transactions found.",
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                )
              else if (_chartsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height: 30,
                    child: Center(child: LinearProgressIndicator(minHeight: 2)),
                  ),
                )
              else
                ..._recentTransactions.map(
                  (tx) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      // Determine icon based on 'type' or category heuristics
                      tx['type'] == 'income'
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color:
                          tx['type'] == 'income'
                              ? Colors.greenAccent[400]
                              : Colors.redAccent[200],
                    ),
                    title: Text(
                      tx['categoryName'] ??
                          "Unknown Category", // Using categoryName
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      // Ensure timestamp is not null before formatting
                      tx['timestamp'] != null
                          ? DateFormat.yMMMd().add_jm().format(
                            (tx['timestamp'] as Timestamp).toDate(),
                          )
                          : "No date",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      "${tx['type'] == 'income' ? '+' : '-'}MYR ${(tx['amount'] ?? 0.0).toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        color:
                            tx['type'] == 'income'
                                ? Colors.greenAccent[400]
                                : Colors.redAccent[200],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetPreviewCard() {
    return GestureDetector(
      onTap: () => _onTabTapped(5), // Use _onTabTapped
      child: Card(
        color: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(top: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "💼 Budget Overview (Current Month)",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (_budgets.isEmpty && !_chartsLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    "No budgets set up for this month yet.",
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                )
              else if (_chartsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height: 30,
                    child: Center(child: LinearProgressIndicator(minHeight: 2)),
                  ),
                )
              else
                ..._budgets.map((budget) {
                  double spent = (budget['spentAmount'] ?? 0.0).toDouble();
                  double allocated =
                      (budget['allocatedAmount'] ?? 0.0).toDouble();
                  double progress =
                      allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              budget['name'] ?? "Unnamed Budget",
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${NumberFormat.currency(locale: 'en_MY', symbol: '').format(spent)} / ${NumberFormat.currency(locale: 'en_MY', symbol: 'MYR ').format(allocated)}",
                              style: GoogleFonts.poppins(
                                color: Colors.tealAccent.shade200,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[700],
                          color: (budget['colorHex'] != null
                                  ? Color(
                                    int.parse(budget['colorHex'], radix: 16),
                                  )
                                  : Colors.tealAccent)
                              .withOpacity(0.7),
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    if (_goal == null) {
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/goals'),
        child: Card(
          color: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.only(top: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🎯 Goal Progress",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "No active goal set. Tap to add one!",
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double progress = _goal!.progress;
    final double saved = _goal!.currentAmount;
    final double target = _goal!.targetAmount;
    final String title = _goal!.goalName;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/goals'),
      child: Card(
        color: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.only(top: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🎯 Goal Progress",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[700],
                color: Colors.tealAccent,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "MYR ${saved.toStringAsFixed(2)} / ${target.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: GoogleFonts.poppins(
                      color: Colors.tealAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
