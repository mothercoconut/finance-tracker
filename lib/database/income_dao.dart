import '../models/income.dart';
import 'database_helper.dart';

class IncomeDao {
  Future<int> insertIncome(Income income) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('income', income.toMap());
  }

  Future<List<Income>> getAllIncome() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('income');
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  Future<List<Income>> getIncomeInRange(DateTime start, DateTime end) async {
    final allIncome = await getAllIncome();
    return allIncome.where((inc) {
      return inc.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
             inc.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Future<int> deleteIncome(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('income', where: 'id = ?', whereArgs: [id]);
  }
}