import 'package:flutter/material.dart';

import '../database/category_dao.dart';
import '../database/expense_dao.dart';
import '../database/income_dao.dart';
import '../database/reports_dao.dart';
import '../database/settings_dao.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

/// Decides what the user sees on launch: onboarding, or the dashboard.
///
/// The answer is read from [SettingsDao.isOnboardingComplete] every time the
/// gate rebuilds its future, and is never cached anywhere else. That is what
/// makes onboarding a genuinely one-time screen across relaunches: the flag
/// lives in the database, not in the widget tree.
class StartupGate extends StatefulWidget {
  const StartupGate({
    super.key,
    required this.settingsDao,
    required this.categoryDao,
    required this.expenseDao,
    required this.incomeDao,
    required this.reportsDao,
  });

  final SettingsDao settingsDao;
  final CategoryDao categoryDao;
  final ExpenseDao expenseDao;
  final IncomeDao incomeDao;
  final ReportsDao reportsDao;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<bool> _onboardingComplete = widget.settingsDao.isOnboardingComplete();

  /// Re-asks the database rather than assuming onboarding succeeded, so a
  /// failed write can never be mistaken for a completed one.
  void _recheck() {
    setState(() {
      _onboardingComplete = widget.settingsDao.isOnboardingComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingComplete,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Could not open your data: ${snapshot.error}')),
          );
        }

        if (snapshot.data != true) {
          return OnboardingScreen(
            settingsDao: widget.settingsDao,
            onComplete: _recheck,
          );
        }

        return DashboardScreen(
          categoryDao: widget.categoryDao,
          expenseDao: widget.expenseDao,
          incomeDao: widget.incomeDao,
          reportsDao: widget.reportsDao,
        );
      },
    );
  }
}
