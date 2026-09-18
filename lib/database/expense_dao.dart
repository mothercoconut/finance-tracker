import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/expense_with_category.dart';
import 'database_helper.dart';

class ExpenseDao {
  final Database? _providedDb;

  ExpenseDao([this._providedDb]);

  Future<Database> get _db async =>
      _providedDb ?? await DatabaseHelper.instance.database;

  Future<int> insertExpense(Expense expense) async {
    final db = await _db;
    final data = expense.toMap()..remove('id');
    return db.insert('expenses', data);
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Expense.fromMap(rows.first);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await _db;
    final rows = await db.query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<Expense>> getExpensesInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final rows = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<List<ExpenseWithCategory>> getExpensesWithCategoryInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        e.id AS expense_id,
        e.title AS expense_title,
        e.amount AS expense_amount,
        e.category_id AS expense_category_id,
        e.date AS expense_date,
        e.note AS expense_note,
        c.id AS category_id,
        c.name AS category_name,
        c.type AS category_type
      FROM expenses e
      INNER JOIN categories c ON c.id = e.category_id
      WHERE e.date >= ? AND e.date <= ?
      ORDER BY e.date DESC, e.id DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return rows.map((row) {
      final expense = Expense(
        id: (row['expense_id'] as num).toInt(),
        title: row['expense_title']?.toString() ?? '',
        amount: (row['expense_amount'] as num).toDouble(),
        categoryId: (row['expense_category_id'] as num).toInt(),
        date: DateTime.parse(row['expense_date'].toString()),
        note: row['expense_note']?.toString(),
      );
      final category = Category(
        id: (row['category_id'] as num).toInt(),
        name: row['category_name']?.toString() ?? '',
        type: CategoryType.values.firstWhere(
          (type) => type.name == row['category_type']?.toString(),
          orElse: () => CategoryType.expense,
        ),
      );
      return ExpenseWithCategory(expense: expense, category: category);
    }).toList();
  }

  Future<double> getTotalExpenses() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COALESCE(SUM(amount), 0) AS total FROM expenses');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> deleteExpense(int id) async {
    final db = await _db;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
