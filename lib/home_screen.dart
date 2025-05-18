import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double _balance = 5320.75;
  final String username = "Adnan";
  final String profileUrl = "https://i.pravatar.cc/300";
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, '/transaction');
        break;
      case 2:
        Navigator.pushNamed(context, '/stats');
        break;
      case 3:
        Navigator.pushNamed(context, '/scan');
        break;
      case 4:
        Navigator.pushNamed(context, '/goals');
        break;
      case 5:
        Navigator.pushNamed(context, '/budgets');
        break;
      case 6:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  void _updateBalance(bool add) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: Color(0xFF1E1E1E),
          title: Text(
            add ? "Add Balance" : "Deduct Balance",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: Colors.white30),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                double value = double.tryParse(controller.text) ?? 0;
                setState(() {
                  _balance = add ? _balance + value : _balance - value;
                });
                Navigator.of(context).pop();
              },
              child: Text(
                "Confirm",
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavBarIcon(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.tealAccent : Colors.blueGrey,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.tealAccent : Colors.blueGrey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          'ExpenSense',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(),
            SizedBox(height: 20),
            _buildBalanceCard(),
            SizedBox(height: 20),
            _buildInfoCardsRow(),
            SizedBox(height: 20),

            SizedBox(height: 20),
            Text(
              'Spending Trends',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            _buildSpendingChart(),
            SizedBox(height: 20),
            Text(
              'Income vs Expenses',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    margin: EdgeInsets.only(right: 16),
                    child: _buildLineChartCard(),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: _buildLineChartCard2(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            Text(
              'Expense Breakdown',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            _buildDoughnutChart(),
            SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
        onPressed: () => _onTabTapped(3),
        child: Icon(Icons.qr_code_scanner, color: Colors.black),
        shape: CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF1E1E1E),
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavBarIcon(Icons.home, "Home", 0),
                    _buildNavBarIcon(Icons.swap_horiz, "Transactions", 1),
                    _buildNavBarIcon(Icons.bar_chart, "Stats", 2),
                  ],
                ),
              ),
              SizedBox(width: 60),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavBarIcon(Icons.flag, "Goals", 4),
                    _buildNavBarIcon(
                      Icons.account_balance_wallet,
                      "Budgets",
                      5,
                    ),
                    _buildNavBarIcon(Icons.person, "Profile", 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(
            'https://i.pravatar.cc/150?img=3', // You can replace with Firebase user's profile photo URL later
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
            ),
            Text(
              'Adnan 👋',
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
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 10),
            Text(
              '\$${_balance.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _updateBalance(true),
                  icon: Icon(Icons.add, color: Colors.black),
                  label: Text("Add"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _updateBalance(false),
                  icon: Icon(Icons.remove, color: Colors.black),
                  label: Text("Deduct"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
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
          child: Card(
            color: Colors.teal[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Income',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '\$6,200',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Card(
            color: Colors.deepOrange[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Expenses',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '\$3,800',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
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

  Widget _buildSpendingChart() {
    return Card(
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      const days = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      return Text(
                        days[value.toInt()],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      );
                    },
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              barGroups: List.generate(7, (index) {
                final data = [8, 10, 14, 15, 13, 10, 7];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data[index].toDouble(),
                      color: Colors.tealAccent,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChartCard2() {
    return Card(
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Income vs Expense",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1.6,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 2),
                        FlSpot(1, 4),
                        FlSpot(2, 3),
                        FlSpot(3, 5),
                      ],
                      isCurved: true,
                      color: Colors.tealAccent,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 1),
                        FlSpot(1, 2),
                        FlSpot(2, 4),
                        FlSpot(3, 3),
                      ],
                      isCurved: true,
                      color: Colors.pinkAccent,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard() {
    return Card(
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AspectRatio(
          aspectRatio: 1.6,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1000,
                    getTitlesWidget:
                        (value, _) => Text(
                          '\$${value.toInt()}',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                      return Text(
                        months[value.toInt()],
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Colors.tealAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  spots: [
                    FlSpot(0, 3200),
                    FlSpot(1, 3800),
                    FlSpot(2, 4200),
                    FlSpot(3, 4700),
                    FlSpot(4, 5000),
                  ],
                ),
                LineChartBarData(
                  isCurved: true,
                  color: Colors.deepOrangeAccent,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  spots: [
                    FlSpot(0, 1200),
                    FlSpot(1, 1500),
                    FlSpot(2, 1800),
                    FlSpot(3, 1900),
                    FlSpot(4, 2100),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoughnutChart() {
    return Card(
      color: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.tealAccent,
                      value: 40,
                      title: '',
                    ),
                    PieChartSectionData(
                      color: Colors.orangeAccent,
                      value: 30,
                      title: '',
                    ),
                    PieChartSectionData(
                      color: Colors.purpleAccent,
                      value: 30,
                      title: '',
                    ),
                  ],
                  sectionsSpace: 4,
                  centerSpaceRadius: 45,
                ),
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend('Food', Colors.tealAccent),
                _buildLegend('Transport', Colors.orangeAccent),
                _buildLegend('Utilities', Colors.purpleAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 10, height: 10, color: color),
          SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
