import '../models/category.dart';
import 'database_helper.dart';
import 'income_dao.dart';
import 'expense_dao.dart';
import 'settings_dao.dart';

/// Total spent in one category over a period — one bar in the reports
/// bar graph.
class CategoryTotal {
  final int categoryId;
  final String categoryName;
  final CategoryType categoryType;
  final double total;

  const CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.total,
  });
}

/// Necessary vs. discretionary spend over a period — the reports screen's
/// pie/bar breakdown.
class NecessaryVsDiscretionary {
  final double necessary;
  final double discretionary;

  const NecessaryVsDiscretionary({
    required this.necessary,
    required this.discretionary,
  });

  double get total => necessary + discretionary;
}

/// Total expenses for one calendar month — one point in a month-over-month
/// spending trend.
class MonthlyTotal {
  /// First day of the month this total covers.
  final DateTime month;
  final double total;

  const MonthlyTotal({required this.month, required this.total});
}

/// Read-only queries that combine income/expense/category/settings data for
/// the dashboard and reports screens. Individual CRUD lives in the
/// per-table Dao classes; this is where cross-table reporting SQL lives so
/// it isn't duplicated across UI screens.
class ReportsDao {
  final DatabaseHelper _helper;
  final IncomeDao _incomeDao;
  final ExpenseDao _expenseDao;
  final SettingsDao _settingsDao;

  ReportsDao({
    DatabaseHelper? helper,
    IncomeDao? incomeDao,
    ExpenseDao? expenseDao,
    SettingsDao? settingsDao,
  })  : _helper = helper ?? DatabaseHelper.instance,
        _incomeDao = incomeDao ?? IncomeDao(helper: helper),
        _expenseDao = expenseDao ?? ExpenseDao(helper: helper),
        _settingsDao = settingsDao ?? SettingsDao(helper: helper);

  /// Starting balance (from onboarding) + all income - all expenses,
  /// recorded to date. This is what the dashboard shows as "current
  /// balance".
  Future<double> getCurrentBalance() async {
    final starting = await _settingsDao.getStartingBalance();
    final income = await _incomeDao.getTotalIncome();
    final expenses = await _expenseDao.getTotalExpenses();
    return starting + income - expenses;
  }

  /// Total spent per category, most-spent first. Pass [start]/[end] to
  /// scope to a period (e.g. the current month); omit both for all-time.
  Future<List<CategoryTotal>> getTotalsByCategory({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await _helper.database;

    final where = <String>[];
    final args = <Object?>[];
    if (start != null) {
      where.add('e.date >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('e.date <= ?');
      args.add(end.toIso8601String());
    }
    final joinFilter = where.isEmpty ? '' : 'AND ${where.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT c.id AS category_id, c.name AS category_name, c.type AS category_type,
             COALESCE(SUM(e.amount), 0) AS total
      FROM $tableCategory c
      LEFT JOIN $tableExpense e ON e.category_id = c.id $joinFilter
      GROUP BY c.id, c.name, c.type
      ORDER BY total DESC, c.name COLLATE NOCASE ASC
    ''', args);

    return rows
        .map((row) => CategoryTotal(
              categoryId: row['category_id'] as int,
              categoryName: row['category_name'] as String,
              categoryType: CategoryType.fromValue(row['category_type'] as String),
              total: (row['total'] as num).toDouble(),
            ))
        .toList();
  }

  /// Necessary vs. discretionary totals over a period ([start]/[end]
  /// optional, defaults to all-time).
  Future<NecessaryVsDiscretionary> getNecessaryVsDiscretionary({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await _helper.database;

    final where = <String>[];
    final args = <Object?>[];
    if (start != null) {
      where.add('e.date >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('e.date <= ?');
      args.add(end.toIso8601String());
    }
    final whereClause = where.isEmpty ? '' : 'AND ${where.join(' AND ')}';

    final rows = await db.rawQuery('''
      SELECT c.type AS category_type, COALESCE(SUM(e.amount), 0) AS total
      FROM $tableExpense e
      JOIN $tableCategory c ON c.id = e.category_id
      WHERE 1 = 1 $whereClause
      GROUP BY c.type
    ''', args);

    double necessary = 0;
    double discretionary = 0;
    for (final row in rows) {
      final total = (row['total'] as num).toDouble();
      if (row['category_type'] == CategoryType.necessary.value) {
        necessary = total;
      } else {
        discretionary = total;
      }
    }
    return NecessaryVsDiscretionary(necessary: necessary, discretionary: discretionary);
  }

  /// Total expenses for each of the past [months] calendar months (oldest
  /// first, including months with no spending), for a month-over-month
  /// trend line/comparison.
  Future<List<MonthlyTotal>> getMonthlyTotals({int months = 6}) async {
    final db = await _helper.database;
    final now = DateTime.now();
    final results = <MonthlyTotal>[];

    for (var i = months - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 1)
          .subtract(const Duration(milliseconds: 1));

      final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM $tableExpense '
        'WHERE date >= ? AND date <= ?',
        [monthStart.toIso8601String(), monthEnd.toIso8601String()],
      );

      results.add(MonthlyTotal(
        month: monthStart,
        total: (rows.first['total'] as num).toDouble(),
      ));
    }

    return results;
  }

  /// Total spent in a single category during the given month — used to
  /// drive a per-category budget progress bar (spent / cap).
  Future<double> getCategoryTotalForMonth(int categoryId, DateTime month) async {
    final db = await _helper.database;
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd =
        DateTime(month.year, month.month + 1, 1).subtract(const Duration(milliseconds: 1));

    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM $tableExpense '
      'WHERE category_id = ? AND date >= ? AND date <= ?',
      [categoryId, monthStart.toIso8601String(), monthEnd.toIso8601String()],
    );
    return (rows.first['total'] as num).toDouble();
  }
}
