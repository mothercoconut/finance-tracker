import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/database/category_dao.dart';
import 'package:finance_tracker/database/expense_dao.dart';
import 'package:finance_tracker/database/reports_dao.dart';
import 'package:finance_tracker/models/expense.dart';
import 'package:finance_tracker/screens/categories_screen.dart';

import 'test_support.dart';

void main() {
  setUpAll(() => initScreenTestDatabase('categories'));

  late CategoryDao categoryDao;

  setUp(() async {
    await resetDatabase();
    categoryDao = CategoryDao();

    // Put one expense behind "Rent" so exactly one of the eight seeded
    // categories is in use. "Dining Out" stays unused and is the control.
    final rent =
        (await categoryDao.getAllCategories()).firstWhere((c) => c.name == 'Rent');
    await ExpenseDao().insertExpense(
      Expense(amount: 1200, date: DateTime(2026, 1, 1), categoryId: rent.id!),
    );
  });

  Widget categories() {
    return MaterialApp(
      home: CategoriesScreen(categoryDao: categoryDao, reportsDao: ReportsDao()),
    );
  }

  Finder deleteButtonFor(String name) {
    return find.descendant(
      of: find.widgetWithText(ListTile, name),
      matching: find.byIcon(Icons.delete_outline),
    );
  }

  testWidgets('deleting a category that has expenses is refused, with a reason',
      (tester) async {
    await tester.pumpWidget(categories());
    await settleWithDatabase(tester);

    expect(find.text('Rent'), findsOneWidget);
    expect(find.text(r'$1,200.00'), findsOneWidget);

    await tester.tap(deleteButtonFor('Rent'));
    await settleWithDatabase(tester);

    // No confirmation dialog: the refusal happens before the user is even
    // offered the choice.
    expect(find.text('Delete "Rent"?'), findsNothing);
    expect(find.textContaining('still has expenses'), findsOneWidget);

    // The category, and therefore the spending history behind it, survives.
    expect(find.text('Rent'), findsOneWidget);
    final names = await readFromDatabase(
      tester,
      () async => (await categoryDao.getAllCategories()).map((c) => c.name).toList(),
    );
    expect(names, contains('Rent'));
    expect(
      await readFromDatabase(tester, () => ExpenseDao().getTotalExpenses()),
      1200,
    );

    // Let the SnackBar's own timer expire so the test does not end with one
    // pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('deleting a category with no expenses succeeds', (tester) async {
    // Positive control for the test above. Without it, a delete path that was
    // broken outright — or a button wired to nothing — would look exactly like
    // a working refusal.
    await tester.pumpWidget(categories());
    await settleWithDatabase(tester);

    expect(find.text('Dining Out'), findsOneWidget);

    await tester.tap(deleteButtonFor('Dining Out'));
    await settleWithDatabase(tester);

    expect(find.text('Delete "Dining Out"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settleWithDatabase(tester);

    expect(find.text('Dining Out'), findsNothing);
    final names = await readFromDatabase(
      tester,
      () async => (await categoryDao.getAllCategories()).map((c) => c.name).toList(),
    );
    expect(names, isNot(contains('Dining Out')));
    expect(names, contains('Rent'));
  });

  testWidgets('categories can be created and edited', (tester) async {
    await tester.pumpWidget(categories());
    await settleWithDatabase(tester);

    expect(find.text('Pets'), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await settleWithDatabase(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Pets');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await settleWithDatabase(tester);

    expect(find.text('Pets'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Pets'),
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );
    await settleWithDatabase(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Pet Care');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await settleWithDatabase(tester);

    expect(find.text('Pets'), findsNothing);
    expect(find.text('Pet Care'), findsOneWidget);

    // Renamed in place rather than added as a second row: still nine
    // categories, not ten.
    final names = await readFromDatabase(
      tester,
      () async => (await categoryDao.getAllCategories()).map((c) => c.name).toList(),
    );
    expect(names.length, 9);
    expect(names, contains('Pet Care'));
  });

  testWidgets('a duplicate category name is rejected', (tester) async {
    await tester.pumpWidget(categories());
    await settleWithDatabase(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settleWithDatabase(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Rent');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await settleWithDatabase(tester);

    expect(find.textContaining('already a category called'), findsOneWidget);
    final names = await readFromDatabase(
      tester,
      () async => (await categoryDao.getAllCategories()).map((c) => c.name).toList(),
    );
    expect(names.length, 8);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
