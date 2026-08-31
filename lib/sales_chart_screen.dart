import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_theme.dart';
import 'sales_analytics.dart';

// ==========================================
// FEATURE SCREEN: GRAFIK PENJUALAN (ADMIN)
// Menampilkan grafik batang omzet per hari
// dalam satu bulan, dan daftar menu terlaris.
// ==========================================
class SalesChartScreen extends StatefulWidget {
  const SalesChartScreen({super.key});

  @override
  State<SalesChartScreen> createState() => _SalesChartScreenState();
}

class _SalesChartScreenState extends State<SalesChartScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  static const List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    final years = availableYears();
    _selectedYear = years.isNotEmpty ? years.last : DateTime.now().year;
    _selectedMonth = DateTime.now().month;
  }

  String _shortCurrency(num value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}rb';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final years = availableYears();
    final revenue = dailyRevenue(_selectedYear, _selectedMonth);
    final maxRevenue = revenue.values.isEmpty
        ? 0
        : revenue.values.reduce((a, b) => a > b ? a : b);
    final daysInMonth = revenue.length;
    final topMenu = topSellingMenu(year: _selectedYear, month: _selectedMonth, topN: 5);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grafik Penjualan Harian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    DropdownButton<int>(
                      value: _selectedMonth,
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_monthLabels[m - 1]),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                      },
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: years
                          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
           Container(
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
  ),
  height: 260,
  child: maxRevenue == 0
      ? const Center(
          child: Text(
            'Belum ada data penjualan di bulan ini.',
            style: TextStyle(color: Colors.grey),
          ),
        )
      : LayoutBuilder(
          builder: (context, constraints) {
            // Lebar tiap bar+jarak, cukup lega agar tidak dempet
            const double widthPerDay = 32;
            final chartWidth = daysInMonth * widthPerDay;
            final needsScroll = chartWidth > constraints.maxWidth;

            final chart = SizedBox(
              width: needsScroll ? chartWidth : constraints.maxWidth,
              height: 230,
              child: BarChart(
                BarChartData(
                  maxY: maxRevenue * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Tgl ${group.x}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'Rp ${rod.toY.toInt()}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 11),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 1 || idx > daysInMonth) return const SizedBox();
                          // Tampilkan setiap tanggal karena sudah ada ruang lebar per bar
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('$idx', style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(_shortCurrency(value), style: const TextStyle(fontSize: 9));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  barGroups: List.generate(daysInMonth, (i) {
                    final day = i + 1;
                    final value = (revenue[day] ?? 0).toDouble();
                    return BarChartGroupData(x: day, barRods: [
                      BarChartRodData(
                        toY: value,
                        color: AppColors.primary,
                        width: 14,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ]);
                  }),
                ),
              ),
            );

            if (!needsScroll) return chart;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: chart,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '← Geser untuk lihat tanggal lainnya',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            );
          },
        ),
),
            const SizedBox(height: 28),
            const Text(
              'Menu Terlaris',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${_monthLabels[_selectedMonth - 1]} $_selectedYear',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (topMenu.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada data penjualan menu di bulan ini.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...topMenu.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final data = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank == 1 ? AppColors.primary : Colors.grey.shade300,
                      foregroundColor: rank == 1 ? Colors.white : Colors.black87,
                      child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(data.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      '${data.value} terjual',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}