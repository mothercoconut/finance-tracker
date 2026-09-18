import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/expense_dao.dart';
import '../database/income_dao.dart';
import '../models/category.dart';
import '../models/expense_with_category.dart';
import '../models/income.dart';

class SpendingGraphScreen extends StatefulWidget {
  const SpendingGraphScreen({super.key});

  @override
  State<SpendingGraphScreen> createState() => SpendingGraphScreenState();
}

class SpendingGraphScreenState extends State<SpendingGraphScreen> {
  final _expenseDao = ExpenseDao();
  final _incomeDao = IncomeDao();

  bool _loading = true;
  List<ExpenseWithCategory> _expenses = [];
  List<Income> _income = [];
  double _necessary = 0;
  double _discretionary = 0;
  double _incomeTotal = 0;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final expenses = await _expenseDao.getExpensesWithCategoryInRange(start, end);
      final income = await _incomeDao.getIncomeInRange(start, end);

      double necessary = 0;
      double discretionary = 0;
      for (final item in expenses) {
        if (item.categoryType == CategoryType.necessary) {
          necessary += item.expense.amount;
        } else if (item.categoryType == CategoryType.discretionary) {
          discretionary += item.expense.amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _income = income;
        _necessary = necessary;
        _discretionary = discretionary;
        _incomeTotal = income.fold(0.0, (sum, item) => sum + item.amount);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteExpense(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to remove this expense?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _expenseDao.deleteExpense(id);
      await refreshData();
    }
  }

  Future<void> _deleteIncome(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text('Are you sure you want to remove this income entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _incomeDao.deleteIncome(id);
      await refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spent = _necessary + _discretionary;
    final balance = _incomeTotal - spent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Overview'),
        actions: [
          IconButton(onPressed: refreshData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('Income', _incomeTotal),
                        _stat('Spent', spent),
                        _stat('Balance', balance),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: spent == 0
                      ? CustomPaint(
                          painter: _EmptyChartPainter(),
                          child: const Center(
                            child: Text('No expenses recorded this month!'),
                          ),
                        )
                      : PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            sections: [
                              PieChartSectionData(
                                value: _necessary,
                                title: '\$${_necessary.toStringAsFixed(0)}',
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: _discretionary,
                                title: '\$${_discretionary.toStringAsFixed(0)}',
                                radius: 50,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                const Text('Income', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_income.isEmpty)
                  const ListTile(title: Text('No income this month.'))
                else
                  ..._income.map((item) => ListTile(
                        title: Text(item.source),
                        subtitle: Text('${item.date.month}/${item.date.day}/${item.date.year}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('+\$${item.amount.toStringAsFixed(2)}'),
                            if (item.id != null)
                              IconButton(
                                onPressed: () => _deleteIncome(item.id!),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      )),
                const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_expenses.isEmpty)
                  const ListTile(title: Text('No expense history.'))
                else
                  ..._expenses.map((item) => ListTile(
                        title: Text(
                          item.expense.title.isNotEmpty
                              ? item.expense.title
                              : item.categoryName,
                        ),
                        subtitle: Text(item.categoryName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('-\$${item.expense.amount.toStringAsFixed(2)}'),
                            if (item.expense.id != null)
                              IconButton(
                                onPressed: () => _deleteExpense(item.expense.id!),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      )),
              ],
            ),
    );
  }

  Widget _stat(String label, double value) => Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text('\$${value.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
}

class _EmptyChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(size.center(Offset.zero), 55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
