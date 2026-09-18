import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SettingsDao {
  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<void> completeOnboarding({
    required double startingBalance,
    required double monthlyIncome,
  }) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': 'onboarding_complete', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'settings',
      {'key': 'starting_balance', 'value': startingBalance.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'settings',
      {'key': 'monthly_income', 'value': monthlyIncome.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isOnboardingComplete() async {
    final db = await _db;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['onboarding_complete'],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['value'] == 'true';
  }

  Future<double> getStartingBalance() async {
    final db = await _db;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['starting_balance'],
      limit: 1,
    );
    if (rows.isEmpty) return 0.0;
    return double.tryParse(rows.first['value'].toString()) ?? 0.0;
  }

  Future<double> getMonthlyIncome() async {
    final db = await _db;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['monthly_income'],
      limit: 1,
    );
    if (rows.isEmpty) return 0.0;
    return double.tryParse(rows.first['value'].toString()) ?? 0.0;
  }
}
