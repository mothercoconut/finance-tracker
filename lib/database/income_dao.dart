import 'package:sqflite/sqflite.dart';
import '../models/income.dart';
import 'database_helper.dart';

class IncomeDao {
  final Database? _providedDb;

  IncomeDao([this._providedDb]);

  Future<Database> get _db async =>
      _providedDb ?? await DatabaseHelper.instance.database;

  Future<int> insertIncome(Income income) async {
    final db = await _db;
    final data = income.toMap()..remove('id');
    return db.insert('income', data);
  }

  Future<List<Income>> getAllIncome() async {
    final db = await _db;
    final rows = await db.query('income', orderBy: 'date DESC, id DESC');
    return rows.map(Income.fromMap).toList();
  }

  Future<List<Income>> getIncomeInRange(DateTime start, DateTime end) async {
    final db = await _db;
    final rows = await db.query(
      'income',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC, id ASC',
    );
    return rows.map(Income.fromMap).toList();
  }

  Future<double> getTotalIncome() async {
    final db = await _db;
    final result =
        await db.rawQuery('SELECT COALESCE(SUM(amount), 0) AS total FROM income');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> deleteIncome(int id) async {
    final db = await _db;
    return db.delete('income', where: 'id = ?', whereArgs: [id]);
  }
}
