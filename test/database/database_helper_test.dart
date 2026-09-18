import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:finance_tracker/database/database_helper.dart';
import 'package:finance_tracker/database/category_dao.dart';
import 'package:finance_tracker/database/expense_dao.dart';
import 'package:finance_tracker/database/income_dao.dart';
import 'package:finance_tracker/database/reports_dao.dart';
import 'package:finance_tracker/database/settings_dao.dart';
import 'package:finance_tracker/models/category.dart';
import 'package:finance_tracker/models/expense.dart';
import 'package:finance_tracker/models/income.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.dbName = 'database_helper_test.db';
  });

  setUp(() async {
    await DatabaseHelper.instance.close();

    final path = join(
      await databaseFactory.getDatabasesPath(),
      DatabaseHelper.dbName,
    );

    await databaseFactory.deleteDatabase(path);
  });

  tearDownAll(
    () async => DatabaseHelper.instance.close(),
  );

  test('database seeds eight default categories', () async {
    final categories =
        await CategoryDao().getAllCategories();

    expect(categories.length, 8);

    expect(
      categories.any(
        (c) =>
            c.name == 'Rent' &&
            c.type == CategoryType.necessary,
      ),
      isTrue,
    );

    expect(
      categories.any(
        (c) =>
            c.name == 'Entertainment' &&
            c.type == CategoryType.discretionary,
      ),
      isTrue,
    );
  });

  test('category CRUD works', () async {
    final dao = CategoryDao();

    final id = await dao.insertCategory(
      const Category(
        name: 'Pets',
        type: CategoryType.discretionary,
      ),
    );

    final fetched =
        await dao.getCategoryById(id);

    expect(fetched?.name, 'Pets');

    await dao.updateCategory(
      fetched!.copyWith(
        name: 'Pet Care',
      ),
    );

    expect(
      (await dao.getCategoryById(id))?.name,
      'Pet Care',
    );

    await dao.deleteCategory(id);

    expect(
      await dao.getCategoryById(id),
      isNull,
    );
  });

  test(
    'category with expenses cannot be deleted',
    () async {
      final category =
          (await CategoryDao().getAllCategories())
              .firstWhere(
        (c) => c.name == 'Rent',
      );

      await ExpenseDao().insertExpense(
        Expense(
          amount: 1200,
          date: DateTime(2026, 1, 1),
          categoryId: category.id!,
        ),
      );

      expect(
        await CategoryDao().isCategoryInUse(
          category.id!,
        ),
        isTrue,
      );

      expect(
        CategoryDao().deleteCategory(
          category.id!,
        ),
        throwsA(
          isA<DatabaseException>(),
        ),
      );
    },
  );

  test(
    'starting balance and transactions calculate current balance',
    () async {
      await SettingsDao().completeOnboarding(
        startingBalance: 500,
        monthlyIncome: 3000,
      );

      expect(
        await SettingsDao().isOnboardingComplete(),
        isTrue,
      );

      expect(
        await SettingsDao().getStartingBalance(),
        500,
      );

      await IncomeDao().insertIncome(
        Income(
          amount: 3000,
          date: DateTime(2026, 1, 1),
          source: 'Paycheck',
          recurring: true,
        ),
      );

      final rent =
          (await CategoryDao().getAllCategories())
              .firstWhere(
        (c) => c.name == 'Rent',
      );

      await ExpenseDao().insertExpense(
        Expense(
          amount: 1200,
          date: DateTime(2026, 1, 2),
          categoryId: rent.id!,
        ),
      );

      expect(
        await ReportsDao().getCurrentBalance(),
        2300,
      );
    },
  );

  test(
    'category totals and spending breakdown work',
    () async {
      final categories =
          await CategoryDao().getAllCategories();

      final rent = categories.firstWhere(
        (c) => c.name == 'Rent',
      );

      final fun = categories.firstWhere(
        (c) => c.name == 'Entertainment',
      );

      await ExpenseDao().insertExpense(
        Expense(
          amount: 1200,
          date: DateTime(2026, 1, 5),
          categoryId: rent.id!,
        ),
      );

      await ExpenseDao().insertExpense(
        Expense(
          amount: 80,
          date: DateTime(2026, 1, 6),
          categoryId: fun.id!,
          note: 'Movies',
        ),
      );

      final totals =
          await ReportsDao().getTotalsByCategory();

      expect(
        totals
            .firstWhere(
              (t) => t.categoryName == 'Rent',
            )
            .total,
        1200,
      );

      expect(
        totals
            .firstWhere(
              (t) =>
                  t.categoryName == 'Entertainment',
            )
            .total,
        80,
      );

      final breakdown =
          await ReportsDao().getNecessaryVsDiscretionary();

      expect(
        breakdown.necessary,
        1200,
      );

      expect(
        breakdown.discretionary,
        80,
      );
    },
  );

  test(
    'expenses can be filtered by date range',
    () async {
      final rent =
          (await CategoryDao().getAllCategories())
              .firstWhere(
        (c) => c.name == 'Rent',
      );

      await ExpenseDao().insertExpense(
        Expense(
          amount: 100,
          date: DateTime(2026, 1, 15),
          categoryId: rent.id!,
        ),
      );

      await ExpenseDao().insertExpense(
        Expense(
          amount: 200,
          date: DateTime(2026, 2, 15),
          categoryId: rent.id!,
        ),
      );

      final january =
          await ExpenseDao().getExpensesInRange(
        DateTime(2026, 1, 1),
        DateTime(
          2026,
          1,
          31,
          23,
          59,
          59,
        ),
      );

      expect(
        january.length,
        1,
      );

      expect(
        january.first.amount,
        100,
      );
    },
  );

  test(
    'data survives closing and reopening the database',
    () async {
      await SettingsDao().completeOnboarding(
        startingBalance: 100,
        monthlyIncome: 1000,
      );

      await IncomeDao().insertIncome(
        Income(
          amount: 1000,
          date: DateTime(2026, 1, 1),
          source: 'Job',
        ),
      );

      await DatabaseHelper.instance.close();

      expect(
        await SettingsDao().isOnboardingComplete(),
        isTrue,
      );

      expect(
        await IncomeDao().getTotalIncome(),
        1000,
      );
    },
  );
}