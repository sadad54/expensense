import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exp_ocr/widgets/chart_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations
import 'package:intl/intl.dart';
import 'dart:math'; // For random colors, etc.

/// 🔵 Scatter Chart Widget
/// 🔵 Scatter Chart Widget
/// 🔵 Scatter Chart Widget
class CategoryScatterChart extends StatelessWidget {
  final List<ScatterSpot> points;
  final String title;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final String bottomTitle; // New: Label for X-axis
  final String leftTitle; // New: Label for Y-axis

  const CategoryScatterChart({
    required this.points,
    required this.title,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.bottomTitle = '', // Default empty
    this.leftTitle = '', // Default empty
    super.key,
  });

  // Helper method for generating ScatterTooltipItems
  List<ScatterTooltipItem>? _getScatterTooltipItems(
    List<ScatterSpot> touchedSpots,
  ) {
    return touchedSpots.map((spot) {
      return ScatterTooltipItem(
        'Day: ${spot.x.toStringAsFixed(0)}\nMYR${spot.y.toStringAsFixed(2)}',
        textStyle: const TextStyle(color: Colors.white, fontSize: 10),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              width: 350,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: points,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (maxY) / 4,
                    verticalInterval: (maxX - minX) / 5,
                    getDrawingHorizontalLine:
                        (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                    getDrawingVerticalLine:
                        (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                      axisNameWidget: Text(
                        bottomTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      axisNameSize: 20,
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                      axisNameWidget: Text(
                        leftTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      axisNameSize: 20,
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  scatterTouchData: ScatterTouchData(
                    touchTooltipData: ScatterTouchTooltipData(
                      //getTooltipItems: _getScatterTooltipItems(ScatterSpot), // Assign the helper method here
                    ),
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enum for chart filtering
enum ChartFilter { daily, weekly, monthly }

// Helper for consistent section styling
class ChartSection extends StatelessWidget {
  final String title;
  final List<Widget> chartWidgets; // Allow multiple charts in a row
  final double? sectionHeight;
  final Color? backgroundColor; // New property for background color

  const ChartSection({
    super.key,
    required this.title,
    required this.chartWidgets,
    this.sectionHeight,
    this.backgroundColor, // Initialize the new property
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color:
          backgroundColor ??
          Theme.of(
            context,
          ).cardColor, // Use provided color or default card color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.onSurface, // Adjusted for card background
                ),
              ).animate().fadeIn(delay: 200.ms),
            ),
            SizedBox(
              height: sectionHeight ?? 250, // Default height, can be overridden
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                ), // Removed horizontal padding from here
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      chartWidgets
                          .map(
                            (widget) => Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: widget,
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // For dynamic maxY in scatter chart
  double _scatterChartMaxY = 500.0; // Initialize with a default value
  /// Prepares daily spending data for WormLineChart for the selected month.
  List<FlSpot> _getDailySpendingSpots() {
    final List<FlSpot> spots = [];
    final selectedMonthStart = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final selectedMonthEnd = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ); // Last day of the month

    // Filter _dailyTotals for the _selectedMonth and sort them chronologically
    final dailyTotalsForSelectedMonth =
        _dailyTotals.entries.where((entry) {
            final date = DateFormat('yyyy-MM-dd').parse(entry.key);
            return date.isAfter(
                  selectedMonthStart.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(selectedMonthEnd.add(const Duration(days: 1)));
          }).toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    for (int i = 0; i < dailyTotalsForSelectedMonth.length; i++) {
      final dayKey = dailyTotalsForSelectedMonth[i].key;
      final amount = dailyTotalsForSelectedMonth[i].value;
      final dayOfMonth = DateFormat('yyyy-MM-dd').parse(dayKey).day;
      spots.add(FlSpot(dayOfMonth.toDouble(), amount));
    }
    return spots;
  }

  /// Prepares weekly spending data for WormLineChart (for last 6 months).
  List<FlSpot> _getWeeklySpendingSpots() {
    final List<FlSpot> spots = [];
    // Sort weekly totals chronologically based on their keys (assuming 'YYYY-MM-WW' or similar)
    final sortedWeeklyTotals =
        _weeklyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    for (int i = 0; i < sortedWeeklyTotals.length; i++) {
      final amount = sortedWeeklyTotals[i].value;
      // Use index as x-axis for continuous trend
      spots.add(FlSpot(i.toDouble(), amount));
    }
    return spots;
  }

  /// Prepares category spending data for ScatterChart for the selected month.
  List<ScatterSpot> _getCategorySpendingScatterSpots() {
    final List<ScatterSpot> spots = [];
    final selectedMonthKey = DateFormat('yyyy-MM').format(_selectedMonth);
    double maxAmountFound = 0; // To determine dynamic maxY for the chart

    // Filter transactions for the _selectedMonth
    final transactionsForSelectedMonth =
        _allTransactionsLast6Months.where((transaction) {
          return DateFormat('yyyy-MM').format(transaction.date) ==
              selectedMonthKey;
        }).toList();

    for (var transaction in transactionsForSelectedMonth) {
      final dayOfMonth = transaction.date.day.toDouble();
      final amount = transaction.amount;
      if (amount > maxAmountFound) maxAmountFound = amount; // Track max amount

      spots.add(
        ScatterSpot(
          dayOfMonth, // X-axis: Day of the month
          amount, // Y-axis: Amount
          dotPainter: FlDotCirclePainter(
            color: _getColorForCategory(transaction.categoryName),
            radius:
                4 +
                (amount / 100).clamp(0, 10), // Dynamic radius based on amount
          ),
        ),
      );
    }
    // Update the max Y value for the scatter chart state
    setState(() {
      _scatterChartMaxY =
          maxAmountFound * 1.2; // Add 20% padding to the max amount
      if (_scatterChartMaxY < 100)
        _scatterChartMaxY = 100; // Ensure a minimum Y scale
    });
    return spots;
  }

  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  bool _loading = true;
  Map<String, double> _categoryTotalsForMonth = {};
  Map<String, List<TransactionDataPoint>> _categoryMonthlyTrends =
      {}; // For line charts over several months
  List<TransactionDataPoint> _allTransactionsLast6Months = [];
  double _totalSpentForMonth = 0.0;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<String> _insights = []; // We can populate this later

  // New state variables for daily/weekly/monthly charts
  ChartFilter _selectedFilter = ChartFilter.monthly;
  Map<String, double> _dailyTotals = {}; // Date string (YYYY-MM-DD) -> amount
  Map<String, double> _weeklyTotals = {}; // Week string (YYYY-WW) -> amount
  Map<String, double> _monthlyTotals = {}; // Month string (YYYY-MM) -> amount

  // For consistent colors across charts for the same category
  final Map<String, Color> _categoryColors = {};
  final List<Color> _baseColors = [
    Colors.tealAccent,
    Colors.lightBlueAccent,
    Colors.pinkAccent,
    Colors.amberAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.cyanAccent,
    Colors.redAccent,
    Colors.indigoAccent,
  ];
  int _colorIndex = 0;

  Color _getColorForCategory(String categoryName) {
    return _categoryColors.putIfAbsent(categoryName, () {
      final color = _baseColors[_colorIndex % _baseColors.length];
      _colorIndex++;
      return color;
    });
  }

  @override
  void initState() {
    super.initState();
    if (uid != null) {
      _fetchTransactionDataForPastMonths(6); // Fetch data for trends
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchTransactionDataForPastMonths(int numberOfMonths) async {
    if (uid == null) return;
    setState(() => _loading = true);
    _categoryColors.clear(); // Reset colors on fetch
    _colorIndex = 0;

    DateTime startDate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - (numberOfMonths - 1),
      1,
    );

    // End of the selected month for current month's specific stats
    DateTime endDateForSelectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("generalTransactions")
            .where(
              "timestamp",
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
            )
            .where(
              "timestamp",
              isLessThanOrEqualTo: Timestamp.fromDate(endDateForSelectedMonth),
            )
            .orderBy("timestamp", descending: true)
            .get();

    final List<TransactionDataPoint> allFetchedTransactions = [];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (timestamp == null) continue;
      allFetchedTransactions.add(
        TransactionDataPoint(
          categoryName: data['categoryName'] ?? 'Other',
          amount: (data['amount'] ?? 0.0).toDouble(),
          date: timestamp,
        ),
      );
    }
    _allTransactionsLast6Months = allFetchedTransactions;
    _processDataForSelectedMonth(); // Process for pie chart, current month totals etc.
    _processDataForTrends(); // Process for line charts over months

    _processDailyData();
    _processWeeklyData();
    _processMonthlyData();

    setState(() => _loading = false);
  }

  Future<void> _processDataForSelectedMonth() async {
    final Map<String, double> totals = {};
    double totalSpent = 0;
    for (var transaction in _allTransactionsLast6Months) {
      if (transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month) {
        totals[transaction.categoryName] =
            (totals[transaction.categoryName] ?? 0) + transaction.amount;
        totalSpent += transaction.amount;
      }
    }

    // 🔍 Generate Smart Insights
    final List<String> newInsights = [];

    // Insight 1: Spending by Category
    totals.forEach((category, amount) {
      if (amount > 50) {
        newInsights.add(" 🧠 You spent a lot on $category this month.");
      } else {
        newInsights.add(" 👍 Spending on $category is under control.");
      }
    });

    // Insight 2: Total Spending for the Month
    if (totalSpent > 100) {
      newInsights.add(
        " 💸 Total spending crossed MYR${totalSpent.toStringAsFixed(2)} this month. Consider budgeting tighter.",
      );
    } else if (totalSpent < 50 && totalSpent > 0) {
      newInsights.add(" 🎉 Great job! Very low spending this month.");
    } else if (totalSpent == 0) {
      newInsights.add(" ✨ No spending recorded this month. Keep it up!");
    }

    // Insight 3: Biggest Spending Category
    final biggestCategory = totals.entries.fold<MapEntry<String, double>?>(
      null,
      (prev, e) => prev == null || e.value > prev.value ? e : prev,
    );
    if (biggestCategory != null) {
      newInsights.add(
        " 📊 Most spending this month is in '${biggestCategory.key}' with MYR${biggestCategory.value.toStringAsFixed(2)}.",
      );
    }

    // Insight 4: General overview if no specific insights yet (added by Gemini)
    if (newInsights.isEmpty && totalSpent == 0) {
      newInsights.add(
        " 🤔 No transactions recorded for this month yet. Start tracking your spending!",
      );
    } else if (newInsights.isEmpty) {
      newInsights.add(
        " 📈 Overall, your spending is well-balanced this month.",
      );
    }

    // ✅ Trigger UI update
    setState(() {
      _categoryTotalsForMonth = totals;
      _totalSpentForMonth = totalSpent;
      _insights = newInsights;
    });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("monthlyInsights")
        .doc("${_selectedMonth.year}-${_selectedMonth.month}")
        .set({
          "insights": newInsights,
          "totalSpent": totalSpent,
          "generatedAt": Timestamp.now(),
        });
  }

  void _processDataForTrends() {
    final Map<String, Map<String, double>> trendsData =
        {}; // Category -> MonthKey (YYYY-MM) -> Amount
    for (var transaction in _allTransactionsLast6Months) {
      final monthKey = DateFormat('yyyy-MM').format(transaction.date);
      trendsData.putIfAbsent(transaction.categoryName, () => {});
      trendsData[transaction.categoryName]![monthKey] =
          (trendsData[transaction.categoryName]![monthKey] ?? 0) +
          transaction.amount;
    }

    _categoryMonthlyTrends.clear();
    trendsData.forEach((category, monthlyData) {
      final List<TransactionDataPoint> points = [];
      final List<MapEntry<DateTime, double>> sortedEntries =
          monthlyData.entries
              .map(
                (entry) => MapEntry(
                  DateFormat('yyyy-MM').parse(entry.key),
                  entry.value,
                ),
              )
              .toList();
      sortedEntries.sort((a, b) => a.key.compareTo(b.key));
      sortedEntries.forEach((entry) {
        points.add(
          TransactionDataPoint(
            categoryName: category,
            amount: entry.value,
            date: entry.key,
          ),
        );
      });
      _categoryMonthlyTrends[category] = points;
    });
  }

  void _processDailyData() {
    _dailyTotals.clear();
    for (var transaction in _allTransactionsLast6Months) {
      if (transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month) {
        final dayKey = DateFormat('yyyy-MM-dd').format(transaction.date);
        _dailyTotals[dayKey] = (_dailyTotals[dayKey] ?? 0) + transaction.amount;
      }
    }
    // Sort daily totals by date
    _dailyTotals = Map.fromEntries(
      _dailyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void _processWeeklyData() {
    _weeklyTotals.clear();
    for (var transaction in _allTransactionsLast6Months) {
      if (transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month) {
        final weekKey = _getWeekString(transaction.date);
        _weeklyTotals[weekKey] =
            (_weeklyTotals[weekKey] ?? 0) + transaction.amount;
      }
    }
    // Sort weekly totals by week string
    _weeklyTotals = Map.fromEntries(
      _weeklyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void _processMonthlyData() {
    _monthlyTotals.clear();
    for (var transaction in _allTransactionsLast6Months) {
      final monthKey = DateFormat('yyyy-MM').format(transaction.date);
      _monthlyTotals[monthKey] =
          (_monthlyTotals[monthKey] ?? 0) + transaction.amount;
    }
    // Sort monthly totals by month string
    _monthlyTotals = Map.fromEntries(
      _monthlyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  String _getWeekString(DateTime date) {
    // A simple way to get week number (might vary based on locale/start of week)
    // For consistency, let's use a fixed logic: week starts on Monday.
    // Calculate the week number within the year.
    // This is a basic implementation; for robust week numbers, consider a dedicated package.
    final startOfYear = DateTime(date.year, 1, 1);
    final daysSinceYearStart = date.difference(startOfYear).inDays;
    // Add 1 to daysSinceYearStart because day 1 is index 0.
    // Add startOfYear.weekday (1 for Monday, 7 for Sunday) to align with week start.
    // Divide by 7 and take floor to get week number.
    // Add 1 to week number because it's 1-indexed.
    int weekNumber =
        ((daysSinceYearStart + startOfYear.weekday) / 7).floor() + 1;
    return '${date.year}-${weekNumber.toString().padLeft(2, '0')}';
  }

  List<PieChartSectionData> _buildPieSections() {
    if (_totalSpentForMonth == 0) return [];
    return _categoryTotalsForMonth.entries.map((entry) {
      final percentage = (entry.value / _totalSpentForMonth) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 80,
        color: _getColorForCategory(entry.key),
        titleStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        borderSide: BorderSide(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    if (_categoryTotalsForMonth.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children:
            _categoryTotalsForMonth.keys
                .map((category) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorForCategory(category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                })
                .toList()
                .animate(interval: 50.ms)
                .fadeIn(duration: 200.ms)
                .slideX(),
      ),
    );
  }

  // Bar chart showing total spending per category for the selected month
  Widget _buildCategorySpendingBarChart() {
    if (_categoryTotalsForMonth.isEmpty)
      return const Center(child: Text("No data for selected month."));
    final barGroups =
        _categoryTotalsForMonth.entries.toList().asMap().entries.map((
          entryMap,
        ) {
          final index = entryMap.key;
          final categoryEntry = entryMap.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: categoryEntry.value,
                color: _getColorForCategory(categoryEntry.key),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList();

    return SizedBox(
      width: max(300, _categoryTotalsForMonth.length * 50.0), // Dynamic width
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          alignment: BarChartAlignment.spaceAround,
          maxY:
              _categoryTotalsForMonth.values.fold(
                0.0,
                (max, v) => v > max ? v : max,
              ) *
              1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _categoryTotalsForMonth.length) {
                    final categoryName = _categoryTotalsForMonth.keys.elementAt(
                      index,
                    );
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        categoryName.length > 10
                            ? '${categoryName.substring(0, 8)}...'
                            : categoryName,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: defaultGetTitle,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                _categoryTotalsForMonth.values.fold(
                  0.0,
                  (max, v) => v > max ? v : max,
                ) /
                5,
            getDrawingHorizontalLine:
                (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String categoryName = _categoryTotalsForMonth.keys.elementAt(
                  group.x,
                );
                return BarTooltipItem(
                  '$categoryName\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: NumberFormat.currency(
                        symbol: 'MYR',
                      ).format(rod.toY), // Changed symbol
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Line chart showing total spending over the last few months
  Widget _buildOverallMonthlyTrendChart() {
    if (_monthlyTotals.isEmpty)
      return const Center(child: Text("Not enough data for monthly trend."));

    final sortedEntries =
        _monthlyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    List<FlSpot> spots =
        sortedEntries.asMap().entries.map((entryMap) {
          return FlSpot(entryMap.key.toDouble(), entryMap.value.value);
        }).toList();

    if (spots.length < 2)
      return const Center(
        child: Text("Need at least 2 months for a trend line."),
      );

    return SizedBox(
      width: max(300, sortedEntries.length * 60.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval:
                _monthlyTotals.values.fold(0.0, (max, v) => v > max ? v : max) /
                5,
            getDrawingHorizontalLine:
                (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedEntries.length) {
                    final monthKey = sortedEntries[index].key;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        DateFormat(
                          'MMM',
                        ).format(DateFormat('yyyy-MM').parse(monthKey)),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: defaultGetTitle,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.primary.withOpacity(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final monthKey = sortedEntries[spot.spotIndex].key;
                  final monthName = DateFormat(
                    'MMM yyyy',
                  ).format(DateFormat('yyyy-MM').parse(monthKey));
                  return LineTooltipItem(
                    '$monthName\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: NumberFormat.currency(
                          symbol: 'MYR',
                        ).format(spot.y), // Changed symbol
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // Line chart showing trend for specific categories over the last few months
  Widget _buildCategoryMonthlyTrendChart() {
    if (_categoryMonthlyTrends.isEmpty)
      return const Center(
        child: Text("Not enough data to show category trends."),
      );

    List<LineChartBarData> lineBarsData = [];
    _categoryMonthlyTrends.forEach((category, dataPoints) {
      final List<FlSpot> spots =
          dataPoints
              .asMap()
              .entries
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.amount))
              .toList();

      if (spots.length < 2) return;

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _getColorForCategory(category),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      );
    });

    if (lineBarsData.isEmpty)
      return const Center(
        child: Text("Not enough data to show category trends."),
      );

    double maxY = 0;
    _categoryMonthlyTrends.values.forEach((points) {
      for (var point in points) {
        if (point.amount > maxY) {
          maxY = point.amount;
        }
      }
    });
    maxY *= 1.2;

    Set<String> uniqueMonths = {};
    for (var transaction in _allTransactionsLast6Months) {
      uniqueMonths.add(DateFormat('yyyy-MM').format(transaction.date));
    }
    final double dynamicWidth = max(300, uniqueMonths.length * 60.0);

    return SizedBox(
      width: dynamicWidth,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine:
                (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < uniqueMonths.length) {
                    final sortedMonthKeys = uniqueMonths.toList()..sort();
                    final monthKey = sortedMonthKeys[index];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        DateFormat(
                          'MMM',
                        ).format(DateFormat('yyyy-MM').parse(monthKey)),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: defaultGetTitle,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: lineBarsData,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final category = _categoryMonthlyTrends.keys.elementAt(
                    spot.barIndex,
                  );
                  final monthKey = DateFormat('yyyy-MM').format(
                    _categoryMonthlyTrends[category]![spot.spotIndex].date,
                  );
                  final monthName = DateFormat(
                    'MMM yyyy',
                  ).format(DateFormat('yyyy-MM').parse(monthKey));

                  return LineTooltipItem(
                    '$category\n',
                    TextStyle(
                      color: _getColorForCategory(category),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: '$monthName: ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: NumberFormat.currency(
                          symbol: 'MYR',
                        ).format(spot.y), // Changed symbol
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          maxY: maxY,
        ),
      ),
    );
  }

  // New: Daily Spending Bar Chart
  Widget _buildDailySpendingBarChart() {
    if (_dailyTotals.isEmpty)
      return const Center(
        child: Text("No daily spending data for this month."),
      );

    final List<MapEntry<String, double>> sortedDailyEntries =
        _dailyTotals.entries.toList();

    final barGroups =
        sortedDailyEntries.asMap().entries.map((entryMap) {
          final index = entryMap.key;
          final dailyEntry = entryMap.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dailyEntry.value,
                color: Theme.of(context).colorScheme.secondary,
                width: 10,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList();

    return SizedBox(
      width: max(300, sortedDailyEntries.length * 25.0),
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          alignment: BarChartAlignment.spaceAround,
          maxY:
              sortedDailyEntries.fold(
                0.0,
                (max, e) => e.value > max ? e.value : max,
              ) *
              1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedDailyEntries.length) {
                    final dateKey = sortedDailyEntries[index].key;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        DateFormat(
                          'dd',
                        ).format(DateFormat('yyyy-MM-dd').parse(dateKey)),
                        style: const TextStyle(fontSize: 9),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: defaultGetTitle,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                sortedDailyEntries.fold(
                  0.0,
                  (max, e) => e.value > max ? e.value : max,
                ) /
                5,
            getDrawingHorizontalLine:
                (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String dateLabel = DateFormat('MMM dd').format(
                  DateFormat(
                    'yyyy-MM-dd',
                  ).parse(sortedDailyEntries[group.x].key),
                );
                return BarTooltipItem(
                  '$dateLabel\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: NumberFormat.currency(
                        symbol: 'MYR',
                      ).format(rod.toY), // Changed symbol
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // New: Weekly Spending Bar Chart
  Widget _buildWeeklySpendingBarChart() {
    if (_weeklyTotals.isEmpty)
      return const Center(
        child: Text("No weekly spending data for this month."),
      );

    final List<MapEntry<String, double>> sortedWeeklyEntries =
        _weeklyTotals.entries.toList();

    final barGroups =
        sortedWeeklyEntries.asMap().entries.map((entryMap) {
          final index = entryMap.key;
          final weeklyEntry = entryMap.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: weeklyEntry.value,
                color: Theme.of(context).colorScheme.tertiary,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
            ],
          );
        }).toList();

    return SizedBox(
      width: max(300, sortedWeeklyEntries.length * 40.0),
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          alignment: BarChartAlignment.spaceAround,
          maxY:
              sortedWeeklyEntries.fold(
                0.0,
                (max, e) => e.value > max ? e.value : max,
              ) *
              1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedWeeklyEntries.length) {
                    final weekKey = sortedWeeklyEntries[index].key;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        'Week ${weekKey.split('-').last}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: defaultGetTitle,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                sortedWeeklyEntries.fold(
                  0.0,
                  (max, e) => e.value > max ? e.value : max,
                ) /
                5,
            getDrawingHorizontalLine:
                (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String weekLabel = sortedWeeklyEntries[group.x].key;
                return BarTooltipItem(
                  '${weekLabel.replaceAll('-', ' Week ')}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: NumberFormat.currency(
                        symbol: 'MYR',
                      ).format(rod.toY), // Changed symbol
                      style: TextStyle(
                        color: Colors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Helper for default title for axis
  Widget defaultGetTitle(double value, TitleMeta meta) {
    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Stats and Insights',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Theme.of(context).colorScheme.primary,
                        onPrimary: Theme.of(context).colorScheme.onPrimary,
                        onSurface: Theme.of(context).colorScheme.onBackground,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _selectedMonth) {
                setState(() {
                  _selectedMonth = DateTime(picked.year, picked.month);
                });
                _fetchTransactionDataForPastMonths(6);
              }
            },
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => _fetchTransactionDataForPastMonths(6),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Spending for Selected Month
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Spending for ${DateFormat('MMMM yyyy').format(_selectedMonth)}",
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ).animate().fadeIn(delay: 100.ms),
                            Text(
                              NumberFormat.currency(
                                symbol: 'MYR',
                              ) // Changed symbol
                              .format(_totalSpentForMonth),
                              style: Theme.of(
                                context,
                              ).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ).animate().fadeIn(delay: 150.ms).slideX(),
                          ],
                        ),
                      ),
                      // Pie Chart Section
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChartSection(
                              title:
                                  "💸 Spending Breakdown (${DateFormat.MMMM().format(_selectedMonth)})", // Dynamic title with emoji
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.3), // Light shade for card
                              chartWidgets: [
                                if (_categoryTotalsForMonth.isEmpty)
                                  const SizedBox(
                                    width: 280,
                                    child: Center(
                                      child: Text("No data for pie chart. "),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: 280,
                                    height: 250,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        PieChart(
                                              PieChartData(
                                                sections: _buildPieSections(),
                                                centerSpaceRadius: 40,
                                                sectionsSpace: 2,
                                                pieTouchData: PieTouchData(
                                                  touchCallback:
                                                      (
                                                        FlTouchEvent event,
                                                        pieTouchResponse,
                                                      ) {},
                                                ),
                                              ),
                                            )
                                            .animate()
                                            .fadeIn(delay: 300.ms)
                                            .scale(),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Total",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.copyWith(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onBackground,
                                              ),
                                            ),
                                            Text(
                                              NumberFormat.currency(
                                                symbol: 'MYR', // Changed symbol
                                              ).format(_totalSpentForMonth),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onBackground,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),

                            // Bar Chart Section
                            ChartSection(
                              title:
                                  "📊 Category Spending (Current Month)", // Dynamic title with emoji
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceVariant
                                  .withOpacity(0.3), // Light shade for card
                              chartWidgets: [
                                _buildCategorySpendingBarChart()
                                    .animate()
                                    .fadeIn(delay: 400.ms)
                                    .slideX(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLegend(),
                      const SizedBox(height: 10),
                      // Filter for spending charts (Daily, Weekly, Monthly)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Spending Over Time",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child:
                            SegmentedButton<ChartFilter>(
                              segments: const <ButtonSegment<ChartFilter>>[
                                ButtonSegment<ChartFilter>(
                                  value: ChartFilter.daily,
                                  label: Text('Daily'),
                                  icon: Icon(Icons.calendar_view_day),
                                ),
                                ButtonSegment<ChartFilter>(
                                  value: ChartFilter.weekly,
                                  label: Text('Weekly'),
                                  icon: Icon(Icons.calendar_view_week),
                                ),
                                ButtonSegment<ChartFilter>(
                                  value: ChartFilter.monthly,
                                  label: Text('Monthly'),
                                  icon: Icon(Icons.calendar_view_month),
                                ),
                              ],
                              selected: <ChartFilter>{_selectedFilter},
                              onSelectionChanged: (
                                Set<ChartFilter> newSelection,
                              ) {
                                setState(() {
                                  _selectedFilter = newSelection.first;
                                });
                              },
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                selectedForegroundColor:
                                    Theme.of(context).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.5),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ).animate().fadeIn(delay: 100.ms).slideY(),
                      ),
                      const SizedBox(height: 20),

                      // Dynamic Chart based on filter
                      ChartSection(
                        title:
                            _selectedFilter == ChartFilter.daily
                                ? "🗓️ Daily Spending (${DateFormat.MMMMd().format(_selectedMonth)})" // Dynamic title with emoji
                                : _selectedFilter == ChartFilter.weekly
                                ? "📅 Weekly Spending (${DateFormat('MMM d').format(DateTime(_selectedMonth.year, _selectedMonth.month, 1))} - ${DateFormat('MMM d').format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0))})" // Dynamic title with emoji
                                : "📈 Overall Spending Trend (Last 6 Months)", // Dynamic title with emoji
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.3), // Light shade for card
                        chartWidgets: [
                          if (_selectedFilter == ChartFilter.daily)
                            _buildDailySpendingBarChart()
                                .animate()
                                .fadeIn(delay: 500.ms)
                                .slideX()
                          else if (_selectedFilter == ChartFilter.weekly)
                            _buildWeeklySpendingBarChart()
                                .animate()
                                .fadeIn(delay: 500.ms)
                                .slideX()
                          else // Monthly filter
                            _buildOverallMonthlyTrendChart()
                                .animate()
                                .fadeIn(delay: 500.ms)
                                .slideX(),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Category Monthly Trend Line Chart (Always available for monthly trends)
                      ChartSection(
                        title:
                            "📈 Spending by Category (Last 6 Months)", // Dynamic title with emoji
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.3), // Light shade for card
                        chartWidgets: [
                          _buildCategoryMonthlyTrendChart()
                              .animate()
                              .fadeIn(delay: 600.ms)
                              .slideX(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            WormLineChart(
                              title:
                                  "Daily Spending Trend (${DateFormat.MMMM().format(_selectedMonth)})",
                              dataPoints: _getDailySpendingSpots(),
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .primary, // Use your theme's primary color
                            ),

                            // Add the Worm Line Chart for Weekly Spending Trend
                            WormLineChart(
                              title: "Weekly Spending Trend (Last 6 Months)",
                              dataPoints: _getWeeklySpendingSpots(),
                              color:
                                  Theme.of(context)
                                      .colorScheme
                                      .tertiary, // Use another theme color
                            ),
                            CategoryScatterChart(
                              title:
                                  "Category Spending Distribution (${DateFormat.MMMM().format(_selectedMonth)})",
                              points: _getCategorySpendingScatterSpots(),
                              minX: 0, // X-axis starts from day 1
                              maxX:
                                  DateUtils.getDaysInMonth(
                                    _selectedMonth.year,
                                    _selectedMonth.month,
                                  ).toDouble() +
                                  1, // Max day in month + padding
                              minY: 0,
                              maxY:
                                  _scatterChartMaxY, // Use the dynamically calculated max Y
                            ),
                          ],
                        ),
                      ),

                      // Add the Category Scatter Chart

                      // Smart Insights Section
                      // The section to be modified starts here
                      // Replace your existing code block for "Smart Insights" with this:
                      Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ), // Consistent margin with charts
                        color: Theme.of(context).colorScheme.surfaceVariant
                            .withOpacity(0.3), // Shaded background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ), // Rounded corners
                        elevation: 2, // Slight shadow
                        child: Padding(
                          padding: const EdgeInsets.all(
                            16.0,
                          ), // Internal padding for content
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start, // Align content to the start
                            children: [
                              Text(
                                " 💡 Smart Insights",
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                height: 12,
                              ), // Add some space after the title
                              if (_insights.isEmpty)
                                const Text(
                                  "No insights available for this month.",
                                ) // This text is now correctly padded by the Card's padding
                              else
                                // Insights map will still spread its children directly into the Column
                                ..._insights.map(
                                  (insight) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ), // Maintain individual insight spacing
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.lightbulb_outline,
                                        color: Colors.amber,
                                      ),
                                      title: Text(insight),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // The section ends here
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}

class TransactionDataPoint {
  final String categoryName;
  final double amount;
  final DateTime date;

  TransactionDataPoint({
    required this.categoryName,
    required this.amount,
    required this.date,
  });
}
