import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/database/category_dao.dart';
import 'package:finance_tracker/database/expense_dao.dart';
import 'package:finance_tracker/database/income_dao.dart';
import 'package:finance_tracker/database/reports_dao.dart';
import 'package:finance_tracker/database/settings_dao.dart';
import 'package:finance_tracker/screens/startup_gate.dart';
import 'package:finance_tracker/widgets/money.dart';

import 'test_support.dart';

void main() {
  setUpAll(() => initScreenTestDatabase('onboarding'));
  setUp(resetDatabase);

  Widget gate({Key? key}) {
    return MaterialApp(
      home: StartupGate(
        key: key,
        settingsDao: SettingsDao(),
        categoryDao: CategoryDao(),
        expenseDao: ExpenseDao(),
        incomeDao: IncomeDao(),
        reportsDao: ReportsDao(),
      ),
    );
  }

  testWidgets('onboarding persists what was entered and does not come back',
      (tester) async {
    final settingsDao = SettingsDao();

    await tester.pumpWidget(gate());
    await settleWithDatabase(tester);

    // Positive control for the "does not come back" assertion further down: on
    // a database where onboarding has not run, the gate must show onboarding.
    // Without this, a screen that never rendered at all would satisfy the
    // later findsNothing just as well as one that was correctly skipped.
    expect(find.text('Get started'), findsOneWidget);
    expect(
      await readFromDatabase(tester, () => settingsDao.isOnboardingComplete()),
      isFalse,
    );

    await tester.enterText(
      find.widgetWithText(AmountField, 'Starting balance'),
      '500',
    );
    await tester.enterText(
      find.widgetWithText(AmountField, 'Expected monthly income'),
      '3000',
    );
    await tester.tap(find.text('Get started'));
    await settleWithDatabase(tester);

    // Persisted, read back from the database rather than from the widget.
    expect(
      await readFromDatabase(tester, () => settingsDao.isOnboardingComplete()),
      isTrue,
    );
    expect(
      await readFromDatabase(tester, () => settingsDao.getStartingBalance()),
      500,
    );
    expect(
      await readFromDatabase(tester, () => settingsDao.getMonthlyIncome()),
      3000,
    );

    // The gate moved on in the same session.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);

    // And a relaunch does not show it again. The key forces a brand-new
    // StartupGate state, so the answer has to come from the database and not
    // from a future the old state was still holding.
    await tester.pumpWidget(gate(key: const ValueKey('relaunch')));
    await settleWithDatabase(tester);

    expect(find.text('Get started'), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    // The starting balance from onboarding is what the dashboard opens on.
    expect(find.text(r'$500.00'), findsOneWidget);
  });

  testWidgets('onboarding refuses to save until both amounts are valid',
      (tester) async {
    final settingsDao = SettingsDao();

    await tester.pumpWidget(gate());
    await settleWithDatabase(tester);

    // Nothing typed at all.
    await tester.tap(find.text('Get started'));
    await settleWithDatabase(tester);

    expect(find.text('Enter an amount'), findsNWidgets(2));
    expect(find.text('Get started'), findsOneWidget);
    expect(
      await readFromDatabase(tester, () => settingsDao.isOnboardingComplete()),
      isFalse,
    );

    // One valid, one still junk — must still refuse, so the check cannot be
    // passing merely because the form was completely empty.
    await tester.enterText(
      find.widgetWithText(AmountField, 'Starting balance'),
      '500',
    );
    await tester.enterText(
      find.widgetWithText(AmountField, 'Expected monthly income'),
      'not a number',
    );
    await tester.tap(find.text('Get started'));
    await settleWithDatabase(tester);

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(
      await readFromDatabase(tester, () => settingsDao.isOnboardingComplete()),
      isFalse,
    );
  });
}
