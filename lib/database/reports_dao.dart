import '../models/category.dart';
import '../models/category_total.dart';
import 'database_helper.dart';
import 'expense_dao.dart';
import 'income_dao.dart';
import 'settings_dao.dart';

class ReportsDao {
  final ExpenseDao _expenseDao;
  final IncomeDao _incomeDao;
  final SettingsDao _settingsDao;

  ReportsDao({
    ExpenseDao? expenseDao,
    IncomeDao? incomeDao,
    SettingsDao? settingsDao,
  })  : _expenseDao = expenseDao ?? ExpenseDao(),
        _incomeDao = incomeDao ?? IncomeDao(),
        _settingsDao = settingsDao ?? SettingsDao();

  Future<double> getCurrentBalance() async {
    final starting = await _settingsDao.getStartingBalance();
    final income = await _incomeDao.getTotalIncome();
    final expenses = await _expenseDao.getTotalExpenses();
    return starting + income - expenses;
  }

  Future<List<CategoryTotal>> getTotalsByCategory() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        c.id AS category_id,
        c.name AS category_name,
        c.type AS category_type,
        COALESCE(SUM(e.amount), 0) AS total
      FROM categories c
      LEFT JOIN expenses e ON e.category_id = c.id
      GROUP BY c.id, c.name, c.type
      ORDER BY c.id ASC
    ''');

    return rows.map((row) {
      final type = CategoryType.values.firstWhere(
        (value) => value.name == row['category_type']?.toString(),
        orElse: () => CategoryType.expense,
      );
      return CategoryTotal(
        categoryId: (row['category_id'] as num).toInt(),
        categoryName: row['category_name']?.toString() ?? '',
        categoryType: type,
        total: (row['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<SpendingBreakdown> getNecessaryVsDiscretionary() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT c.type AS category_type, COALESCE(SUM(e.amount), 0) AS total
      FROM categories c
      LEFT JOIN expenses e ON e.category_id = c.id
      GROUP BY c.type
    ''');

    double necessary = 0.0;
    double discretionary = 0.0;

    for (final row in rows) {
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (row['category_type'] == CategoryType.necessary.name) {
        necessary += total;
      } else if (row['category_type'] == CategoryType.discretionary.name) {
        discretionary += total;
      }
    }

    return SpendingBreakdown(
      necessary: necessary,
      discretionary: discretionary,
    );
  }
}
