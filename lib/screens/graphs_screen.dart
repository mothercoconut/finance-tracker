import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/expense_dao.dart';
import '../database/income_dao.dart';

class _DailyTotals {
  double income = 0;
  double totalExpense = 0;
  double necessaryExpense = 0;
}

class GraphsScreen extends StatefulWidget {
  const GraphsScreen({super.key});

  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

class _GraphsScreenState extends State<GraphsScreen> {
  bool _isLoading = true;
  List<DateTime> _days = [];

  /// Running balance if only necessary expenses are counted: income - necessary.
  List<double> _balanceNecessaryOnly = [];

  /// Running balance with every expense counted: income - necessary - unnecessary.
  List<double> _balanceActual = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final incomes = await IncomeDao().getAllIncome();
    final expenses = await ExpenseDao().getExpensesWithCategoryInRange(
      DateTime(2000, 1, 1),
      DateTime.now().add(const Duration(days: 1)),
    );

    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

    final byDay = <DateTime, _DailyTotals>{};
    for (final income in incomes) {
      byDay.putIfAbsent(dayOf(income.date), () => _DailyTotals()).income +=
          income.amount;
    }
    for (final entry in expenses) {
      final totals =
          byDay.putIfAbsent(dayOf(entry.expense.date), () => _DailyTotals());
      totals.totalExpense += entry.expense.amount;
      if (entry.categoryType == 'necessary') {
        totals.necessaryExpense += entry.expense.amount;
      }
    }

    final sortedDays = byDay.keys.toList()..sort();

    final days = <DateTime>[];
    final balanceNecessaryOnly = <double>[];
    final balanceActual = <double>[];

    var runningIncome = 0.0;
    var runningExpense = 0.0;
    var runningNecessary = 0.0;

    for (final day in sortedDays) {
      final totals = byDay[day]!;
      runningIncome += totals.income;
      runningExpense += totals.totalExpense;
      runningNecessary += totals.necessaryExpense;

      days.add(day);
      balanceNecessaryOnly.add(runningIncome - runningNecessary);
      balanceActual.add(runningIncome - runningExpense);
    }

    if (!mounted) return;
    setState(() {
      _days = days;
      _balanceNecessaryOnly = balanceNecessaryOnly;
      _balanceActual = balanceActual;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _days.length < 2
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Add a few transactions on different days to see your trends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Balance Over Time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'The gap between the two bars is what you could have saved '
                      'by skipping non-essential purchases.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _buildLegend(const [
                      _LegendItem('Balance (necessary only)', Colors.blueAccent),
                      _LegendItem('Balance (all expenses)', Colors.redAccent),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 260,
                      child: _buildBarChart(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildBarChart() {
    final step = (_days.length / 5).ceil().clamp(1, _days.length);
    final allValues = [..._balanceNecessaryOnly, ..._balanceActual];
    final maxY = allValues.fold<double>(0, (m, v) => v > m ? v : m);
    final minY = allValues.fold<double>(0, (m, v) => v < m ? v : m);

    return LayoutBuilder(
      builder: (context, constraints) {
        final perGroup = constraints.maxWidth / _days.length;
        final barWidth = (perGroup * 0.28).clamp(3.0, 22.0);

        return BarChart(
          BarChartData(
            maxY: maxY == 0 ? 1 : maxY * 1.15,
            minY: minY == 0 ? 0 : minY * 1.15,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final day = _days[group.x.toInt()];
                  const labels = ['Necessary only', 'All expenses'];
                  return BarTooltipItem(
                    '${DateFormat('MMM d').format(day)}\n'
                    '${labels[rodIndex]}: \$${rod.toY.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) => Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: step.toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= _days.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('M/d').format(_days[index]),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < _days.length; i++)
                BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(
                      toY: _balanceNecessaryOnly[i],
                      color: Colors.blueAccent,
                      width: barWidth,
                    ),
                    BarChartRodData(
                      toY: _balanceActual[i],
                      color: Colors.redAccent,
                      width: barWidth,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(List<_LegendItem> items) {
    return Wrap(
      spacing: 16,
      children: [
        for (final item in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, color: item.color),
              const SizedBox(width: 6),
              Text(item.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
}
