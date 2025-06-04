// lib/widgets/chart_widgets.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // For the max function in MiniLineChart maxY calculation

// (YOUR EXISTING WormLineChart AND CategoryScatterChart DEFINITIONS GO HERE)
/// 🪱 Worm Line Chart Widget
class WormLineChart extends StatelessWidget {
  final List<FlSpot> dataPoints;
  final Color color;
  final String title;
  final String bottomTitle; // New: Label for X-axis
  final String leftTitle; // New: Label for Y-axis
  final double? minX; // New: Explicit min X value
  final double? maxX; // New: Explicit max X value
  final double? minY; // New: Explicit min Y value
  final double? maxY; // New: Explicit max Y value

  const WormLineChart({
    required this.dataPoints,
    required this.color,
    required this.title,
    this.bottomTitle = '', // Default empty
    this.leftTitle = '', // Default empty
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
    super.key,
  });

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
              height: 160,
              width: 300,
              child: LineChart(
                LineChartData(
                  minX: minX, // Use explicit minX
                  maxX: maxX, // Use explicit maxX
                  minY: minY, // Use explicit minY
                  maxY: maxY, // Use explicit maxY
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval:
                        (maxY ?? 100) / 4, // Dynamic horizontal grid
                    verticalInterval: (maxX ?? 1) / 5, // Dynamic vertical grid
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
                          // Display actual values for X-axis (e.g., day number, week number)
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
                      ), // X-axis label
                      axisNameSize: 20,
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          // Display amounts for Y-axis
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
                      ), // Y-axis label
                      axisNameSize: 20,
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      color: color,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.3),
                      ),
                      barWidth: 4,
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<FlSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${bottomTitle.isNotEmpty ? '$bottomTitle: ${spot.x.toStringAsFixed(0)}\n' : ''}${leftTitle.isNotEmpty ? '$leftTitle: ' : ''}MYR${spot.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white, fontSize: 10),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Make sure they are the latest versions with dynamic axis ranges and labels.

/// Mini Line Chart Widget for Dashboard
class MiniLineChart extends StatelessWidget {
  final List<FlSpot> dataPoints;
  final String title;
  final Color color;

  const MiniLineChart({
    required this.dataPoints,
    required this.title,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8), // Small margin for dashboard tiles
      color: const Color(0xFF1E1E1E), // Consistent with your theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white, // Consistent with your theme
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: false,
                  ), // No grid lines for mini chart
                  titlesData: FlTitlesData(
                    show: false,
                  ), // No axis titles for mini chart
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minX: 0,
                  maxX:
                      dataPoints.isNotEmpty
                          ? (dataPoints.length - 1).toDouble()
                          : 1,
                  minY: 0,
                  maxY:
                      dataPoints.isNotEmpty
                          ? dataPoints
                                  .map((e) => e.y)
                                  .reduce((a, b) => max(a, b)) *
                              1.2
                          : 100, // Dynamically set maxY based on data
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini Pie Chart Widget for Dashboard
class MiniPieChart extends StatelessWidget {
  final List<PieChartSectionData> sections;
  final String title;

  const MiniPieChart({required this.sections, required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8), // Small margin for dashboard tiles
      color: const Color(0xFF1E1E1E), // Consistent with your theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white, // Consistent with your theme
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30, // Creates a donut chart
                  pieTouchData: PieTouchData(
                    enabled: true,
                  ), // Enable touch feedback
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
