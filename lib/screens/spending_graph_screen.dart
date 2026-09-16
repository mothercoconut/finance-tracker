import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/expense_dao.dart';
import '../models/expense.dart';

class SpendingGraphScreen extends StatefulWidget {
  const SpendingGraphScreen({super.key});

  @override
  State<SpendingGraphScreen> createState() => _SpendingGraphScreenState();
}

class _SpendingGraphScreenState extends State<SpendingGraphScreen> {
  bool _isLoading = true;
  double _necessaryTotal = 0.0;
  double _unnecessaryTotal = 0.0;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadSpendingData();
  }

  Future<void> _loadSpendingData() async {
    try {
      // Fetch all expenses from your database DAO
      List<Expense> expenses = await ExpenseDao().getAllExpenses();

      double necessary = 0.0;
      double unnecessary = 0.0;

      for (var expense in expenses) {
        // Assuming categoryId 1 or specific markers denote "Necessary" (e.g., bills, groceries)
        // Adjust this condition based on how your categories are structured!
        if (expense.categoryId == 1) {
          necessary += expense.amount;
        } else {
          unnecessary += expense.amount;
        }
      }

      setState(() {
        _necessaryTotal = necessary;
        _unnecessaryTotal = unnecessary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSpending = _necessaryTotal + _unnecessaryTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Spending Overview'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : totalSpending == 0
              ? const Center(
                  child: Text(
                    'No expenses recorded yet!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Necessary vs Unnecessary Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                color: Colors.blueAccent,
                                value: _necessaryTotal,
                                title: '\$${_necessaryTotal.toStringAsFixed(2)}',
                                radius: _touchedIndex == 0 ? 60 : 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                color: Colors.orangeAccent,
                                value: _unnecessaryTotal,
                                title: '\$${_unnecessaryTotal.toStringAsFixed(2)}',
                                radius: _touchedIndex == 1 ? 60 : 50,
                                titleStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendIndicator(Colors.blueAccent, 'Necessary'),
                          const SizedBox(width: 24),
                          _buildLegendIndicator(Colors.orangeAccent, 'Unnecessary'),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}