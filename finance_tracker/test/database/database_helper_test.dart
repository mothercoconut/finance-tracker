// Exercises the whole database layer (schema, CRUD, reports) against a
// real SQLite engine via sqflite_common_ffi, so it runs on the desktop
// test VM without an Android/Chrome target.
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:finance_tracker/database/database_helper.dart';
import 'package:finance_tracker/database/category_dao.dart';
import 'package:finance_tracker/database/income_dao.dart';
import 'package:finance_tracker/database/expense_dao.dart';
import 'package:finance_tracker/database/reports_dao.dart';
import 'package:finance_tracker/database/settings_dao.dart';
import 'package:finance_tracker/models/category.dart';
import 'package:finance_tracker/models/expense.dart';
import 'package:finance_tracker/models/income.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late CategoryDao categoryDao;
  late IncomeDao incomeDao;
  late ExpenseDao expenseDao;
  late ReportsDao reportsDao;
  late SettingsDao settingsDao;

  setUp(() async {
    // Start every test from a clean database.
    await DatabaseHelper.instance.close();
    final path = join(await databaseFactory.getDatabasesPath(), 'finance_tracker.db');
    await databaseFactory.deleteDatabase(path);

    categoryDao = CategoryDao();
    incomeDao = IncomeDao();
    expenseDao = ExpenseDao();
    reportsDao = ReportsDao();
    settingsDao = SettingsDao();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  test('creating the database seeds default categories', () async {
    final categories = await categoryDao.getAllCategories();
    expect(categories.length, 8);
    expect(categories.any((c) => c.name == 'Rent' && c.type == CategoryType.necessary), isTrue);
    expect(
      categories.any((c) => c.name == 'Entertainment' && c.type == CategoryType.discretionary),
      isTrue,
    );
  });

  test('category CRUD round-trips', () async {
    final id = await categoryDao.insertCategory(
      const Category(name: 'Pets', type: CategoryType.discretionary),
    );

    final fetched = await categoryDao.getCategoryById(id);
    expect(fetched?.name, 'Pets');

    await categoryDao.updateCategory(fetched!.copyWith(name: 'Pet Care'));
    final updated = await categoryDao.getCategoryById(id);
    expect(updated?.name, 'Pet Care');

    await categoryDao.deleteCategory(id);
    expect(await categoryDao.getCategoryById(id), isNull);
  });

  test('deleting a category that has expenses is rejected', () async {
    final categories = await categoryDao.getAllCategories();
    final rent = categories.firstWhere((c) => c.name == 'Rent');

    await expenseDao.insertExpense(
      Expense(amount: 1200, date: DateTime(2026, 1, 1), categoryId: rent.id!),
    );

    expect(await categoryDao.isCategoryInUse(rent.id!), isTrue);
    expect(() => categoryDao.deleteCategory(rent.id!), throwsA(isA<DatabaseException>()));
  });

  test('onboarding settings and current balance calculation', () async {
    await settingsDao.completeOnboarding(startingBalance: 500, monthlyIncome: 3000);
    expect(await settingsDao.isOnboardingComplete(), isTrue);
    expect(await settingsDao.getStartingBalance(), 500);

    await incomeDao.insertIncome(
      Income(amount: 3000, date: DateTime(2026, 1, 1), source: 'Paycheck', recurring: true),
    );

    final categories = await categoryDao.getAllCategories();
    final rent = categories.firstWhere((c) => c.name == 'Rent');
    await expenseDao.insertExpense(
      Expense(amount: 1200, date: DateTime(2026, 1, 2), categoryId: rent.id!),
    );

    // 500 starting + 3000 income - 1200 expense.
    expect(await reportsDao.getCurrentBalance(), 2300);
  });

  test('totals by category and necessary vs discretionary breakdown', () async {
    final categories = await categoryDao.getAllCategories();
    final rent = categories.firstWhere((c) => c.name == 'Rent'); // necessary
    final fun = categories.firstWhere((c) => c.name == 'Entertainment'); // discretionary

    await expenseDao.insertExpense(
      Expense(amount: 1200, date: DateTime(2026, 1, 5), categoryId: rent.id!),
    );
    await expenseDao.insertExpense(
      Expense(amount: 80, date: DateTime(2026, 1, 6), categoryId: fun.id!, note: 'Movies'),
    );

    final totals = await reportsDao.getTotalsByCategory();
    final rentTotal = totals.firstWhere((t) => t.categoryName == 'Rent');
    final funTotal = totals.firstWhere((t) => t.categoryName == 'Entertainment');
    expect(rentTotal.total, 1200);
    expect(funTotal.total, 80);

    final breakdown = await reportsDao.getNecessaryVsDiscretionary();
    expect(breakdown.necessary, 1200);
    expect(breakdown.discretionary, 80);
  });

  test('expenses can be filtered by date range for transaction history', () async {
    final categories = await categoryDao.getAllCategories();
    final rent = categories.firstWhere((c) => c.name == 'Rent');

    await expenseDao.insertExpense(
      Expense(amount: 100, date: DateTime(2026, 1, 15), categoryId: rent.id!),
    );
    await expenseDao.insertExpense(
      Expense(amount: 200, date: DateTime(2026, 2, 15), categoryId: rent.id!),
    );

    final januaryExpenses = await expenseDao.getExpensesInRange(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 31, 23, 59, 59),
    );

    expect(januaryExpenses.length, 1);
    expect(januaryExpenses.first.amount, 100);
  });

  test('database survives being reopened (app relaunch)', () async {
    await settingsDao.completeOnboarding(startingBalance: 100, monthlyIncome: 1000);
    await incomeDao.insertIncome(
      Income(amount: 1000, date: DateTime(2026, 1, 1), source: 'Job'),
    );

    // Simulate an app relaunch: close and reopen the database handle.
    await DatabaseHelper.instance.close();

    final reopenedSettings = SettingsDao();
    final reopenedIncome = IncomeDao();
    expect(await reopenedSettings.isOnboardingComplete(), isTrue);
    expect(await reopenedIncome.getTotalIncome(), 1000);
  });
}
