import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

const String settingStartingBalance = 'starting_balance';
const String settingMonthlyIncome = 'monthly_income';
const String settingOnboardingComplete = 'onboarding_complete';

/// Key/value app settings — currently just what the onboarding screen
/// collects (starting balance + expected monthly income) and whether
/// onboarding has run, so `main.dart` knows whether to show it again on
/// relaunch.
class SettingsDao {
  final DatabaseHelper _helper;

  SettingsDao({DatabaseHelper? helper}) : _helper = helper ?? DatabaseHelper.instance;

  Future<void> setValue(String key, String value) async {
    final db = await _helper.database;
    await db.insert(
      tableSettings,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getValue(String key) async {
    final db = await _helper.database;
    final rows = await db.query(
      tableSettings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<bool> isOnboardingComplete() async {
    final value = await getValue(settingOnboardingComplete);
    return value == 'true';
  }

  /// Persists the onboarding answers and marks onboarding as done.
  Future<void> completeOnboarding({
    required double startingBalance,
    required double monthlyIncome,
  }) async {
    final db = await _helper.database;
    final batch = db.batch();
    batch.insert(
      tableSettings,
      {'key': settingStartingBalance, 'value': startingBalance.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      tableSettings,
      {'key': settingMonthlyIncome, 'value': monthlyIncome.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      tableSettings,
      {'key': settingOnboardingComplete, 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await batch.commit(noResult: true);
  }

  Future<double> getStartingBalance() async {
    final value = await getValue(settingStartingBalance);
    return double.tryParse(value ?? '') ?? 0;
  }

  Future<double> getMonthlyIncome() async {
    final value = await getValue(settingMonthlyIncome);
    return double.tryParse(value ?? '') ?? 0;
  }
}
