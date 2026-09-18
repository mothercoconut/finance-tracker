import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/expense_dao.dart';
import '../database/income_dao.dart';
import '../models/income.dart';

class SpendingGraphScreen extends StatefulWidget {
  const SpendingGraphScreen({super.key});

  @override
  State<SpendingGraphScreen> createState() => SpendingGraphScreenState();
}

class SpendingGraphScreenState extends State<SpendingGraphScreen> {
  final ExpenseDao _expenseDao = ExpenseDao();
  final IncomeDao _incomeDao = IncomeDao();
  bool _isLoading = true;
  List<ExpenseWithCategory> _expenseItems = [];
  List<Income> _incomeItems = [];
  double _necessaryTotal = 0.0;
  double _unnecessaryTotal = 0.0;
  double _totalIncome = 0.0;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final items = await _expenseDao.getExpensesWithCategoryInRange(
        startOfMonth,
        endOfMonth,
      );

      final monthlyIncomeList = await _incomeDao.getIncomeInRange(
        startOfMonth,
        endOfMonth,
      );

      final double totalInc = monthlyIncomeList.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );

      double necessary = 0.0;
      double unnecessary = 0.0;

      for (var item in items) {
        final catName = item.categoryName.toLowerCase();
        if (catName.contains('necessary') && !catName.contains('un')) {
          necessary += item.expense.amount;
        } else {
          unnecessary += item.expense.amount;
        }
      }

      if (mounted) {
        setState(() {
          _expenseItems = items;
          _incomeItems = monthlyIncomeList;
          _necessaryTotal = necessary;
          _unnecessaryTotal = unnecessary;
          _totalIncome = totalInc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteExpense(int expenseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to remove this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _expenseDao.deleteExpense(expenseId);
      await refreshData();
    }
  }

  Future<void> _confirmDeleteIncome(int incomeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text('Are you sure you want to remove this income entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _incomeDao.deleteIncome(incomeId);
      await refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSpending = _necessaryTotal + _unnecessaryTotal;
    final netBalance = _totalIncome - totalSpending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Overview'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: refreshData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Income', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('\$${_totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Spent', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('\$${totalSpending.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Balance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('\$${netBalance.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: netBalance >= 0 ? Colors.blue : Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: totalSpending == 0
                      ? const Center(child: Text('No expenses recorded this month!', style: TextStyle(color: Colors.grey)))
                      : PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            sections: [
                              PieChartSectionData(
                                color: Colors.blueAccent,
                                value: _necessaryTotal,
                                title: '\$${_necessaryTotal.toStringAsFixed(2)}',
                                radius: _touchedIndex == 0 ? 55 : 45,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: Colors.orangeAccent,
                                value: _unnecessaryTotal,
                                title: '\$${_unnecessaryTotal.toStringAsFixed(2)}',
                                radius: _touchedIndex == 1 ? 55 : 45,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      if (_incomeItems.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text('Income', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                        ..._incomeItems.map((inc) => ListTile(
                              title: Text(inc.source, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${inc.date.month}/${inc.date.day}/${inc.date.year}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+\$${inc.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () {
                                      if (inc.id != null) {
                                        _confirmDeleteIncome(inc.id!);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ),
                      if (_expenseItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No expense history', style: TextStyle(color: Colors.grey))),
                        )
                      else
                        ..._expenseItems.map((item) {
                          final displayName = item.expense.title.isNotEmpty 
                              ? item.expense.title 
                              : item.categoryName;

                          return ListTile(
                            title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${item.expense.date.month}/${item.expense.date.day}/${item.expense.date.year}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '-\$${item.expense.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    if (item.expense.id != null) {
                                      _confirmDeleteExpense(item.expense.id!);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}