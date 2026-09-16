import '../models/expense.dart';
import 'database_helper.dart';

/// An expense joined with its category's name/type — what the transaction
/// history screen actually wants to render (no second lookup per row).
class ExpenseWithCategory {
  final Expense expense;
  final String categoryName;
  final String categoryType;

  const ExpenseWithCategory({
    required this.expense,
    required this.categoryName,
    required this.categoryType,
  });

  factory ExpenseWithCategory.fromMap(Map<String, Object?> map) {
    return ExpenseWithCategory(
      expense: Expense.fromMap(map),
      categoryName: map['category_name'] as String,
      categoryType: map['category_type'] as String,
    );
  }
}

class ExpenseDao {
  final DatabaseHelper _helper;

  ExpenseDao({DatabaseHelper? helper}) : _helper = helper ?? DatabaseHelper.instance;

  Future<int> insertExpense(Expense expense) async {
    final db = await _helper.database;
    return db.insert(tableExpense, expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Cannot update an expense without an id');
    }
    final db = await _helper.database;
    return db.update(
      tableExpense,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await _helper.database;
    return db.delete(tableExpense, where: 'id = ?', whereArgs: [id]);
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableExpense,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await _helper.database;
    final rows = await db.query(tableExpense, orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableExpense,
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.map(Expense.fromMap).toList();
  }

  /// Expenses with `date` in `[start, end]` (inclusive), for the
  /// transaction history screen's month filter.
  Future<List<Expense>> getExpensesInRange(DateTime start, DateTime end) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableExpense,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getExpensesByCategory(int categoryId) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableExpense,
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  /// Same as [getExpensesInRange] but joined with category name/type, most
  /// recent first — what the transaction history + filtered list screens
  /// should call directly.
  Future<List<ExpenseWithCategory>> getExpensesWithCategoryInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
      '''
      SELECT e.*, c.name AS category_name, c.type AS category_type
      FROM $tableExpense e
      JOIN $tableCategory c ON c.id = e.category_id
      WHERE e.date >= ? AND e.date <= ?
      ORDER BY e.date DESC, e.id DESC
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return rows.map(ExpenseWithCategory.fromMap).toList();
  }

  Future<double> getTotalExpenses() async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM $tableExpense',
    );
    return (result.first['total'] as num).toDouble();
  }
}
