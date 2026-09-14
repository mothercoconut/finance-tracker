import '../models/income.dart';
import 'database_helper.dart';

class IncomeDao {
  final DatabaseHelper _helper;

  IncomeDao({DatabaseHelper? helper}) : _helper = helper ?? DatabaseHelper.instance;

  Future<int> insertIncome(Income income) async {
    final db = await _helper.database;
    return db.insert(tableIncome, income.toMap());
  }

  Future<int> updateIncome(Income income) async {
    if (income.id == null) {
      throw ArgumentError('Cannot update income without an id');
    }
    final db = await _helper.database;
    return db.update(
      tableIncome,
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await _helper.database;
    return db.delete(tableIncome, where: 'id = ?', whereArgs: [id]);
  }

  Future<Income?> getIncomeById(int id) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableIncome,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Income.fromMap(rows.first);
  }

  Future<List<Income>> getAllIncome() async {
    final db = await _helper.database;
    final rows = await db.query(tableIncome, orderBy: 'date DESC, id DESC');
    return rows.map(Income.fromMap).toList();
  }

  Future<List<Income>> getRecentIncome({int limit = 5}) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableIncome,
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.map(Income.fromMap).toList();
  }

  /// Income entries with `date` in `[start, end]` (inclusive), for the
  /// transaction history screen's month filter.
  Future<List<Income>> getIncomeInRange(DateTime start, DateTime end) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableIncome,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Income.fromMap).toList();
  }

  Future<double> getTotalIncome() async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM $tableIncome',
    );
    return (result.first['total'] as num).toDouble();
  }
}
