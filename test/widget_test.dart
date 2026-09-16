// Smoke test for the app's actual home screen (the dashboard), run against
// a real, empty SQLite database via sqflite_common_ffi so it exercises the
// same DAOs the app uses at runtime.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:finance_tracker/database/database_helper.dart';
import 'package:finance_tracker/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.dbName = 'widget_test.db';
  });

  setUp(() async {
    await DatabaseHelper.instance.close();
    final path = join(await databaseFactory.getDatabasesPath(), DatabaseHelper.dbName);
    await databaseFactory.deleteDatabase(path);
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  testWidgets('Home screen starts at a zero balance with no transactions', (tester) async {
    await tester.pumpWidget(const MyApp());

    // sqflite_common_ffi does real file/isolate I/O for the initial load,
    // which needs the real event loop — tester.pump() alone only drains
    // Flutter's fake-async frame queue, so the loading spinner never
    // resolves without runAsync.
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }

    expect(find.text('Finance Tracker'), findsOneWidget);
    expect(find.text('Available Balance'), findsOneWidget);
    expect(find.text('\$0.00'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Trends'), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
  });
}
