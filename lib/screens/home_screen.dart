import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/category_dao.dart';
import '../database/expense_dao.dart';
import '../database/income_dao.dart';
import '../database/reports_dao.dart';
import '../models/category.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'categories_screen.dart';
import 'graphs_screen.dart';

class _Transaction {
  final DateTime date;
  final double amount;
  final String label;
  final bool isIncome;
  final bool necessary;

  const _Transaction({
    required this.date,
    required this.amount,
    required this.label,
    required this.isIncome,
    this.necessary = true,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  double _balance = 0.0;
  final List<_Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final balance = await ReportsDao().getCurrentBalance();

    final incomes = await IncomeDao().getAllIncome();

    final expenses =
        await ExpenseDao().getExpensesWithCategoryInRange(
      DateTime(2000, 1, 1),
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );

    final transactions = <_Transaction>[
      for (final income in incomes)
        _Transaction(
          date: income.date,
          amount: income.amount,
          label: income.source,
          isIncome: true,
        ),
      for (final entry in expenses)
        _Transaction(
          date: entry.expense.date,
          amount: entry.expense.amount,
          label: (entry.expense.note?.isNotEmpty ?? false)
              ? entry.expense.note!
              : entry.categoryName,
          isIncome: false,
          necessary:
              entry.categoryType == CategoryType.necessary,
        ),
    ]..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    if (!mounted) return;

    setState(() {
      _balance = balance;

      _transactions
        ..clear()
        ..addAll(transactions);

      _isLoading = false;
    });
  }

  Future<void> _openAddIncome() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddIncomeScreen(),
      ),
    );

    if (saved == true) {
      _loadData();
    }
  }

  Future<void> _openAddExpense() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddExpenseScreen(),
      ),
    );

    if (saved == true) {
      _loadData();
    }
  }

  Future<void> _openCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoriesScreen(
          categoryDao: CategoryDao(),
          reportsDao: ReportsDao(),
        ),
      ),
    );

    _loadData();
  }

  void _openGraphs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GraphsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text('Finance Tracker'),
        actions: [
          IconButton(
            onPressed: _openCategories,
            icon: const Icon(Icons.label_outline),
            tooltip: 'Categories',
          ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGraphs,
        icon: const Icon(Icons.bar_chart),
        label: const Text('Trends'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  96,
                ),
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 32,
                      ),
                      child: Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedTransactions(),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1F1C2C),
            Color(0xFF4A3AFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          _actionButton(
            label: 'Income',
            icon: Icons.arrow_downward,
            color: Colors.green,
            onTap: _openAddIncome,
          ),
          _actionButton(
            label: 'Expense',
            icon: Icons.arrow_upward,
            color: Colors.redAccent,
            onTap: _openAddExpense,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 150,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedTransactions() {
    final widgets = <Widget>[];

    DateTime? lastDay;

    for (final tx in _transactions) {
      final day = DateTime(
        tx.date.year,
        tx.date.month,
        tx.date.day,
      );

      if (lastDay == null || day != lastDay) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 8,
            ),
            child: Text(
              _formatDayLabel(day),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        );

        lastDay = day;
      }

      widgets.add(_buildTransactionTile(tx));
    }

    return widgets;
  }

  String _formatDayLabel(DateTime day) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final yesterday =
        today.subtract(const Duration(days: 1));

    if (day == today) return 'Today';

    if (day == yesterday) return 'Yesterday';

    return DateFormat(
      'MMM d, yyyy',
    ).format(day);
  }

  Widget _buildTransactionTile(_Transaction tx) {
    final color = tx.isIncome
        ? Colors.green
        : (tx.necessary
            ? Colors.blueGrey
            : Colors.redAccent);

    final sign = tx.isIncome ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              tx.isIncome
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  tx.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!tx.isIncome)
                  Text(
                    tx.necessary
                        ? 'Necessary'
                        : 'Unnecessary',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '$sign\$${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}