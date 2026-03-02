import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../services/milk_production_service.dart';
import '../../widgets/app_drawer.dart';
import 'milk_production_screen.dart';

class MilkAnalyticsScreen extends StatefulWidget {
  const MilkAnalyticsScreen({super.key});

  @override
  State<MilkAnalyticsScreen> createState() => _MilkAnalyticsScreenState();
}

class _MilkAnalyticsScreenState extends State<MilkAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MilkProductionService _milkService = MilkProductionService();
  bool _isLoading = true;
  Map<String, dynamic> _data = {};
  String _currentTimeframe = 'week';
  
  // Selection state
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchData();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    String newTimeframe = 'week';
    if (_tabController.index == 1) newTimeframe = 'month';
    if (_tabController.index == 2) newTimeframe = 'year';
    
    if (newTimeframe != _currentTimeframe) {
      setState(() {
        _currentTimeframe = newTimeframe;
        _isLoading = true;
      });
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    try {
      final data = await _milkService.getAnalytics(
        _currentTimeframe,
        year: (_currentTimeframe == 'month' || _currentTimeframe == 'year') ? _selectedYear : null,
        month: (_currentTimeframe == 'month') ? _selectedMonth : null,
      );
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectPeriod() async {
    if (_currentTimeframe == 'week') return;

    if (_currentTimeframe == 'year') {
      // Show year picker
      final int? year = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              selectedDate: DateTime(_selectedYear),
              onChanged: (DateTime dateTime) {
                Navigator.pop(context, dateTime.year);
              },
            ),
          ),
        ),
      );
      if (year != null && year != _selectedYear) {
        setState(() {
          _selectedYear = year;
          _isLoading = true;
        });
        _fetchData();
      }
    } else if (_currentTimeframe == 'month') {
      // Show month/year picker (Simple version)
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime(_selectedYear, _selectedMonth),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDatePickerMode: DatePickerMode.year,
        helpText: 'Select Month',
      );
      if (picked != null) {
        setState(() {
          _selectedYear = picked.year;
          _selectedMonth = picked.month;
          _isLoading = true;
        });
        _fetchData();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Milk Analytics',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildTimeframeTabs(),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.mistBlue))
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  if (_currentTimeframe != 'week') ...[
                    GestureDetector(
                      onTap: _selectPeriod,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 18, color: AppColors.mistBlue),
                            const SizedBox(width: 8),
                            Text(
                              _data['periodName'] ?? (_currentTimeframe == 'year' ? '$_selectedYear' : 'Select Period'),
                              style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_currentTimeframe == 'week') _buildWeeklyProductionSection(),
                  if (_currentTimeframe == 'month' || _currentTimeframe == 'year') ...[
                    _buildTrendSection(),
                    const SizedBox(height: 24),
                    _buildPerformanceGrid(),
                  ],
                  const SizedBox(height: 24),
                  _buildHerdSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MilkProductionScreen()),
          );
          _fetchData(); // Fix: Reload data when returning
        },
        backgroundColor: AppColors.mistBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Record Milk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTimeframeTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.mistBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.mistBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'This Week'),
          Tab(text: 'This Month'),
          Tab(text: 'This Year'),
        ],
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  Widget _buildSummaryCard() {
    final double total = (_data['totalLiters'] ?? 0).toDouble();
    final double trend = (_data['trend'] ?? 0).toDouble();
    final double compareLiters = (_data['compareLiters'] ?? 0).toDouble();
    final formatter = NumberFormat('#,###');
    final String periodLabel = _data['periodName'] ?? (_currentTimeframe == 'week' ? 'This Week' : _currentTimeframe == 'month' ? 'This Month' : 'This Year');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Liters in $periodLabel',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatter.format(total),
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              const Text('Liters', style: TextStyle(color: Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mistBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(trend >= 0 ? Icons.trending_up : Icons.trending_down, color: AppColors.mistBlue, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                      style: const TextStyle(color: AppColors.mistBlue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'vs last ${_currentTimeframe == 'week' ? 'week' : _currentTimeframe == 'month' ? 'month' : 'year'}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProductionSection() {
    final List<dynamic> rawTrend = _data['dailyTrend'] ?? [];
    final double avg = (_data['avgDailyYield'] ?? 0).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Production', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('Mon - Sun Average', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
              Text('${NumberFormat('#,###').format(avg)} L/day', style: const TextStyle(color: AppColors.mistBlue, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 180,
            child: LineChart(_buildWeeklyLineData(rawTrend)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((d) => Text(d, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold))).toList(),
          ),
        ],
      ),
    );
  }

  LineChartData _buildWeeklyLineData(List<dynamic> rawTrend) {
    // Map dates to 0-6 (MON-SUN) or just showing last 7 entries correctly
    // Since backend returns last 7 days from now, we'll just show them in order
    // But to match Labels MON-SUN, we need to know which date is which day
    
    List<FlSpot> spots = [];
    final now = DateTime.now();
    // Monday of current week
    final mon = now.subtract(Duration(days: now.weekday - 1));
    
    for (int i = 0; i < 7; i++) {
        final dateToCheck = DateTime(mon.year, mon.month, mon.day).add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(dateToCheck);
        
        final match = rawTrend.firstWhere(
            (e) => e['date'] == dateStr,
            orElse: () => null,
        );
        
        double val = 0;
        if (match != null) val = (match['value'] ?? 0).toDouble();
        spots.add(FlSpot(i.toDouble(), val));
    }

    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.mistBlue,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
                // Find local maxima for styling
                return FlDotCirclePainter(
                    color: Colors.white,
                    radius: 3,
                    strokeWidth: 2,
                    strokeColor: AppColors.mistBlue,
                );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [AppColors.mistBlue.withValues(alpha: 0.1), Colors.transparent],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendSection() {
    final List<dynamic> trend = _data['dailyTrend'] ?? [];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.mistBlue, size: 20),
              const SizedBox(width: 8),
              Text('Production Trend (${_currentTimeframe == 'year' ? 'Yearly' : 'Monthly'})', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(_buildYearlyBarData(trend)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: (trend.isNotEmpty ? trend : List.filled(12, {'date': ''}))
                .map((e) => Text(e['date'].toString(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold))).toList(),
          ),
        ],
      ),
    );
  }

  BarChartData _buildYearlyBarData(List<dynamic> trend) {
    double maxVal = trend.fold(0.0, (m, e) => (e['value'] ?? 0) > m ? (e['value'] ?? 0).toDouble() : m);
    if (maxVal == 0) maxVal = 100;

    return BarChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: trend.asMap().entries.map((e) {
        bool isHighest = e.value['value'] == maxVal && maxVal > 0;
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: (e.value['value'] ?? 0).toDouble(),
              color: isHighest ? AppColors.mistBlue : AppColors.mistBlue.withValues(alpha: 0.15),
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true, toY: maxVal * 1.1, color: const Color(0xFFF1F5F9),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Yearly Performance', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Avg Daily Yield', '${NumberFormat('#,###').format(_data['avgDailyYield'] ?? 0)} L', Icons.water_drop, AppColors.mistBlue)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Active Cattle', '${_data['activeCattle'] ?? 0} Head', Icons.pets, AppColors.mistBlue)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildHerdSection() {
    final List<dynamic> herd = _data['herdDetails'] ?? [];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_currentTimeframe == 'week' ? 'Weekly Herd Breakdown' : 'Top Producing Cows', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w800)),
            TextButton(onPressed: () {}, child: Row(children: [const Text('View All', style: TextStyle(color: AppColors.mistBlue, fontWeight: FontWeight.bold)), const SizedBox(width: 4), const Icon(Icons.arrow_forward, size: 14, color: AppColors.mistBlue)])),
          ],
        ),
        const SizedBox(height: 12),
        ...herd.take(4).map((animal) => _buildAnimalRow(animal)),
      ],
    );
  }

  Widget _buildAnimalRow(Map<String, dynamic> animal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: animal['profileImage'] != null ? NetworkImage(animal['profileImage']) : null,
            backgroundColor: const Color(0xFFF1F5F9),
            child: animal['profileImage'] == null ? const Icon(Icons.pets, color: AppColors.mistBlue) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animal['name'], style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Tag ID: #${animal['nodeId']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${animal['totalL']} L', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800)),
              Text('TOTAL / ${_currentTimeframe == 'week' ? 'WK' : 'YR'}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
