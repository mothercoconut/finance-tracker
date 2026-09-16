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
  setUpAll(() => initScreenTestDatabase('add_expense'));

  setUp(() async {
    await resetDatabase();
    // A known starting balance, so every balance assertion below is against a
    // number this test put there.
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

  testWidgets('adding an expense with a category moves the dashboard balance down',
      (tester) async {
    await tester.pumpWidget(dashboard());
    await settleWithDatabase(tester);

    // Baseline first: without it, the post-save assertion would also pass on a
    // screen that had been showing $960.00 all along.
    expect(find.text(r'$1,000.00'), findsOneWidget);
    expect(find.text('No expenses recorded yet.'), findsOneWidget);

    await tester.tap(find.text('Add Expense'));
    await settleWithDatabase(tester);

    await tester.enterText(find.widgetWithText(AmountField, 'Amount'), '40');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    // `.last` is the item in the opened menu overlay; the same text also sits
    // in the closed button underneath it.
    await tester.tap(find.text('Groceries').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Note (optional)'),
      'Weekly shop',
    );

    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await settleWithDatabase(tester);

    // Back on the dashboard, re-read from the database: 1000 - 40.
    expect(find.text(r'$1,000.00'), findsNothing);
    expect(find.text(r'$960.00'), findsOneWidget);

    // And the expense itself is on the recent list, with its category.
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text(r'-$40.00'), findsOneWidget);
    expect(find.textContaining('Weekly shop'), findsOneWidget);

    // The balance on screen came from getCurrentBalance, not from arithmetic
    // in the widget — so it must agree with the DAO asked directly.
    expect(
      await readFromDatabase(tester, () => ReportsDao().getCurrentBalance()),
      960,
    );
  });

  testWidgets('an expense with no category is refused and nothing is written',
      (tester) async {
    await tester.pumpWidget(dashboard());
    await settleWithDatabase(tester);

    await tester.tap(find.text('Add Expense'));
    await settleWithDatabase(tester);

    // Amount is valid, so the category picker is the only thing that can
    // refuse this save.
    await tester.enterText(find.widgetWithText(AmountField, 'Amount'), '40');
    await tester.ensureVisible(find.text('Save expense'));
    await tester.tap(find.text('Save expense'));
    await settleWithDatabase(tester);

    expect(find.text('Choose a category'), findsOneWidget);
    // Still on the add screen, and the database is untouched.
    expect(find.text('Save expense'), findsOneWidget);
    expect(
      await readFromDatabase(tester, () => ExpenseDao().getTotalExpenses()),
      0,
    );
    expect(
      await readFromDatabase(tester, () => ReportsDao().getCurrentBalance()),
      1000,
    );
  });
}
