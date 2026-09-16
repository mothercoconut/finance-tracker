import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/database/category_dao.dart';
import 'package:finance_tracker/database/expense_dao.dart';
import 'package:finance_tracker/database/income_dao.dart';
import 'package:finance_tracker/database/reports_dao.dart';
import 'package:finance_tracker/database/settings_dao.dart';
import 'package:finance_tracker/screens/dashboard_screen.dart';
import 'package:finance_tracker/widgets/money.dart';

import 'test_support.dart';

void main() {
  setUpAll(() => initScreenTestDatabase('add_income'));

  setUp(() async {
    await resetDatabase();
    await SettingsDao().completeOnboarding(startingBalance: 1000, monthlyIncome: 0);
  });

  Widget dashboard() {
    return MaterialApp(
      home: DashboardScreen(
        categoryDao: CategoryDao(),
        expenseDao: ExpenseDao(),
        incomeDao: IncomeDao(),
        reportsDao: ReportsDao(),
      ),
    );
  }

  testWidgets('adding income moves the dashboard balance the other way',
      (tester) async {
    await tester.pumpWidget(dashboard());
    await settleWithDatabase(tester);

    expect(find.text(r'$1,000.00'), findsOneWidget);
    expect(find.text('No income recorded yet.'), findsOneWidget);

    await tester.tap(find.text('Add Income'));
    await settleWithDatabase(tester);

    await tester.enterText(find.widgetWithText(AmountField, 'Amount'), '250');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Source'),
      'Paycheck',
    );
    // Recurring is the one field with a non-text control; flip it so the
    // stored value is not just the column default.
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save income'));
    await tester.tap(find.text('Save income'));
    await settleWithDatabase(tester);

    // 1000 + 250, up rather than down.
    expect(find.text(r'$1,000.00'), findsNothing);
    expect(find.text(r'$1,250.00'), findsOneWidget);

    expect(find.text('Paycheck'), findsOneWidget);
    expect(find.text(r'+$250.00'), findsOneWidget);
    expect(find.textContaining('recurring'), findsOneWidget);

    final stored = await readFromDatabase(tester, () => IncomeDao().getAllIncome());
    expect(stored.single.amount, 250);
    expect(stored.single.source, 'Paycheck');
    expect(stored.single.recurring, isTrue);
  });

  testWidgets('income with no source is refused and nothing is written',
      (tester) async {
    await tester.pumpWidget(dashboard());
    await settleWithDatabase(tester);

    await tester.tap(find.text('Add Income'));
    await settleWithDatabase(tester);

    // Amount is valid, so only the missing source can refuse this save.
    await tester.enterText(find.widgetWithText(AmountField, 'Amount'), '250');
    await tester.ensureVisible(find.text('Save income'));
    await tester.tap(find.text('Save income'));
    await settleWithDatabase(tester);

    expect(find.text('Enter where it came from'), findsOneWidget);
    expect(await readFromDatabase(tester, () => IncomeDao().getTotalIncome()), 0);
    expect(
      await readFromDatabase(tester, () => ReportsDao().getCurrentBalance()),
      1000,
    );
  });
}
