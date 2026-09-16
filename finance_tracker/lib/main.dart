import 'package:flutter/material.dart';

import 'database/category_dao.dart';
import 'database/expense_dao.dart';
import 'database/income_dao.dart';
import 'database/reports_dao.dart';
import 'database/settings_dao.dart';
import 'screens/startup_gate.dart';

void main() {
  // Needed because the first thing the app does is open SQLite through a
  // platform channel, which requires the binding to exist first.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceTrackerApp());
}

/// The app shell, and the one place the real DAOs are constructed.
///
/// Every screen takes its DAOs as constructor arguments so widget tests can
/// pass in ones backed by a throwaway test database. The cost of that is that
/// the *real* wiring below — DAOs built with no arguments, which makes each of
/// them fall back to the shared `DatabaseHelper.instance` — is the one code
/// path no screen test ever executes. `test/widget_test.dart` pumps this
/// widget itself for exactly that reason.
class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> {
  // Built once rather than in build(), so rebuilding the shell does not churn
  // DAO objects. They are cheap holders, but the database handle behind them
  // is shared and should be opened once.
  late final SettingsDao _settingsDao = SettingsDao();
  late final CategoryDao _categoryDao = CategoryDao();
  late final ExpenseDao _expenseDao = ExpenseDao();
  late final IncomeDao _incomeDao = IncomeDao();
  late final ReportsDao _reportsDao = ReportsDao();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: StartupGate(
        settingsDao: _settingsDao,
        categoryDao: _categoryDao,
        expenseDao: _expenseDao,
        incomeDao: _incomeDao,
        reportsDao: _reportsDao,
      ),
    );
  }
}
