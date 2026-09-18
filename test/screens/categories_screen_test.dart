import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/database/category_dao.dart';
import 'package:finance_tracker/database/expense_dao.dart';
import 'package:finance_tracker/database/reports_dao.dart';
import 'package:finance_tracker/models/expense.dart';
import 'package:finance_tracker/screens/categories_screen.dart';

import '../test_support.dart';

void main() {
  setUpAll(() => initScreenTestDatabase('categories'));

  late CategoryDao categoryDao;

  setUp(() async {
    await resetDatabase();

    categoryDao = CategoryDao();

    final categories = await categoryDao.getAllCategories();

    final rent =
        categories.firstWhere((category) => category.name == 'Rent');

    await ExpenseDao().insertExpense(
      Expense(
        title: 'Rent Payment',
        amount: 1200,
        date: DateTime(2026, 1, 1),
        categoryId: rent.id!,
      ),
    );
  });

  Widget categories() {
    return MaterialApp(
      home: CategoriesScreen(
        categoryDao: categoryDao,
        reportsDao: ReportsDao(),
      ),
    );
  }

  Finder deleteButtonFor(String name) {
    return find.descendant(
      of: find.widgetWithText(ListTile, name),
      matching: find.byIcon(Icons.delete_outline),
    );
  }

  testWidgets('used category cannot be deleted', (tester) async {
    await tester.pumpWidget(categories());
    await settleWithDatabase(tester);

    expect(find.text('Rent'), findsOneWidget);
    expect(find.text(r'$1200.00'), findsOneWidget);

    await tester.tap(deleteButtonFor('Rent'));
    await settleWithDatabase(tester);

    expect(find.text('Delete "Rent"?'), findsNothing);
    expect(
      find.textContaining('still has expenses'),
      findsOneWidget,
    );
  });

  testWidgets('unused category can be deleted', (tester) async {
    await tester.pumpWidget(categories());
    await settleWithDatabase(tester);

    await tester.tap(deleteButtonFor('Dining Out'));
    await settleWithDatabase(tester);

    expect(
      find.text('Delete "Dining Out"?'),
      findsOneWidget,
    );

    await tester.tap(
      find.widgetWithText(TextButton, 'Delete'),
    );

    await settleWithDatabase(tester);

    expect(find.text('Dining Out'), findsNothing);
  });

  testWidgets('category can be created and edited', (tester) async {
    await tester.pumpWidget(categories());
    await settleWithDatabase(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settleWithDatabase(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Pets',
    );

    await tester.tap(
      find.widgetWithText(TextButton, 'Save'),
    );

    await settleWithDatabase(tester);

    expect(find.text('Pets'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Pets'),
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );

    await settleWithDatabase(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Pet Care',
    );

    await tester.tap(
      find.widgetWithText(TextButton, 'Save'),
    );

    await settleWithDatabase(tester);

    expect(find.text('Pets'), findsNothing);
    expect(find.text('Pet Care'), findsOneWidget);
  });

  testWidgets('duplicate category name is rejected', (tester) async {
    await tester.pumpWidget(categories());
    await settleWithDatabase(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settleWithDatabase(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Rent',
    );

    await tester.tap(
      find.widgetWithText(TextButton, 'Save'),
    );

    await settleWithDatabase(tester);

    expect(
      find.textContaining('already a category called'),
      findsOneWidget,
    );
  });

  testWidgets(
    'database foreign key is still the final delete backstop',
    (tester) async {
      final blind = _BlindCategoryDao();

      await tester.pumpWidget(
        MaterialApp(
          home: CategoriesScreen(
            categoryDao: blind,
            reportsDao: ReportsDao(),
          ),
        ),
      );

      await settleWithDatabase(tester);

      await tester.tap(deleteButtonFor('Rent'));
      await settleWithDatabase(tester);

      expect(
        find.text('Delete "Rent"?'),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(TextButton, 'Delete'),
      );

      await settleWithDatabase(tester);

      expect(
        find.textContaining('while this screen was open'),
        findsOneWidget,
      );

      expect(find.text('Rent'), findsOneWidget);
    },
  );
}

class _BlindCategoryDao extends CategoryDao {
  @override
  Future<bool> isCategoryInUse(int categoryId) async {
    return false;
  }
}