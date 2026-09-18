import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:finance_tracker/database/database_helper.dart';

void initScreenTestDatabase(String name) {
  DatabaseHelper.dbName = 'finance_tracker_test_$name.db';
}

Future<void> resetDatabase() async {
  await DatabaseHelper.instance.close();

  final databasesPath = await getDatabasesPath();
  final path = '$databasesPath/${DatabaseHelper.dbName}';

  await deleteDatabase(path);

  await DatabaseHelper.instance.database;
}

Future<void> settleWithDatabase(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}