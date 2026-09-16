import 'package:flutter/material.dart';

import '../database/category_dao.dart';
import '../database/expense_dao.dart';
import '../database/income_dao.dart';
import '../database/reports_dao.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../widgets/money.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'categories_screen.dart';

/// Everything one dashboard render needs, fetched together so the screen
/// paints once instead of flickering through four separate loading states.
class _DashboardData {
  const _DashboardData({
    required this.balance,
    required this.recentExpenses,
    required this.recentIncome,
    required this.categoryNames,
  });

  final double balance;
  final List<Expense> recentExpenses;
  final List<Income> recentIncome;

  /// category id -> name, so the recent-expense rows can show a name.
  final Map<int, String> categoryNames;
}

/// The home screen: current balance, the two things you came here to do, and
/// what you recorded most recently.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.categoryDao,
    required this.expenseDao,
    required this.incomeDao,
    required this.reportsDao,
  });

  final CategoryDao categoryDao;
  final ExpenseDao expenseDao;
  final IncomeDao incomeDao;
  final ReportsDao reportsDao;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _data = _load();

  Future<_DashboardData> _load() async {
    // The balance is READ, never computed here. ReportsDao.getCurrentBalance()
    // is starting balance + all income - all expenses; recomputing it in the
    // UI from the "recent" lists would quietly give a different (wrong) answer
    // as soon as there were more than five of either.
    final balance = await widget.reportsDao.getCurrentBalance();
    final recentExpenses = await widget.expenseDao.getRecentExpenses();
    final recentIncome = await widget.incomeDao.getRecentIncome();

    // getRecentExpenses returns raw rows carrying only category_id, so names
    // are resolved once here rather than with a lookup per row.
    final categories = await widget.categoryDao.getAllCategories();

    return _DashboardData(
      balance: balance,
      recentExpenses: recentExpenses,
      recentIncome: recentIncome,
      categoryNames: {
        for (final category in categories)
          if (category.id != null) category.id!: category.name,
      },
    );
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  /// Pushes [screen] and reloads if it reported that it changed the data.
  Future<void> _openAndRefresh(Widget screen) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (context) => screen),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      _reload();
    }
  }

  Future<void> _openCategories() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => CategoriesScreen(
          categoryDao: widget.categoryDao,
          reportsDao: widget.reportsDao,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    // Categories can be renamed while that screen is open, and the recent
    // expense rows show category names, so always reload on the way back.
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Categories',
            onPressed: _openCategories,
          ),
        ],
      ),
      body: FutureBuilder<_DashboardData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Could not load your data: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceCard(balance: data.balance),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.remove),
                      label: const Text('Add Expense'),
                      onPressed: () => _openAndRefresh(
                        AddExpenseScreen(
                          expenseDao: widget.expenseDao,
                          categoryDao: widget.categoryDao,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Income'),
                      onPressed: () => _openAndRefresh(
                        AddIncomeScreen(incomeDao: widget.incomeDao),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionHeading('Recent expenses'),
              if (data.recentExpenses.isEmpty)
                const _EmptyRow('No expenses recorded yet.')
              else
                for (final expense in data.recentExpenses)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.arrow_downward),
                    title: Text(data.categoryNames[expense.categoryId] ?? 'Unknown category'),
                    subtitle: Text(
                      expense.note == null || expense.note!.isEmpty
                          ? formatDate(expense.date)
                          : '${formatDate(expense.date)} — ${expense.note}',
                    ),
                    trailing: Text('-${formatMoney(expense.amount)}'),
                  ),
              const SizedBox(height: 16),
              const _SectionHeading('Recent income'),
              if (data.recentIncome.isEmpty)
                const _EmptyRow('No income recorded yet.')
              else
                for (final income in data.recentIncome)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.arrow_upward),
                    title: Text(income.source),
                    subtitle: Text(
                      income.recurring
                          ? '${formatDate(income.date)} — recurring'
                          : formatDate(income.date),
                    ),
                    trailing: Text('+${formatMoney(income.amount)}'),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Current balance'),
            const SizedBox(height: 8),
            Text(
              formatMoney(balance),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text),
    );
  }
}
