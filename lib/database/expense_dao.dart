import '../models/expense.dart';
import 'database_helper.dart';

class ExpenseWithCategory {
  final Expense expense;
  final String categoryName;

  ExpenseWithCategory({
    required this.expense,
    required this.categoryName,
  });
}

class ExpenseDao {
  Future<int> insertExpense(Expense expense) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('expense', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('expense');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<ExpenseWithCategory>> getExpensesWithCategoryInRange(
      DateTime start, DateTime end) async {
    final db = await DatabaseHelper.instance.database;
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        e.id, 
        e.amount, 
        e.category_id, 
        e.date, 
        c.name as category_name 
      FROM expense e
      LEFT JOIN category c ON e.category_id = c.id
      WHERE e.date >= ? AND e.date <= ?
      ORDER BY e.date DESC
    ''', [startIso, endIso]);

    return result.map((row) {
      return ExpenseWithCategory(
        expense: Expense.fromMap(row),
        categoryName: (row['category_name'] as String?) ?? 'Uncategorized',
      );
    }).toList();
  }

  Future<int> deleteExpense(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'expense',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}