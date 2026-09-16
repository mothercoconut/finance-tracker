import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:finance_tracker/database/database_helper.dart';

// Shared bootstrap for the screen tests. Not a test file itself — the runner
// only executes `*_test.dart`, so this is imported, never run.

/// Points sqflite at a desktop SQLite engine, in a directory of this test
/// file's own, and returns nothing once both are in place.
///
/// Two separate problems are solved here.
///
/// The factory is the *no-isolate* one, unlike the database layer's own test,
/// because a reply that has to cross an isolate port can never arrive inside a
/// widget test — see [settleWithDatabase].
///
/// The databases path is per-file because `flutter test` runs test files
/// concurrently, in separate processes, and `DatabaseHelper` hard-codes a
/// single file name with no way to override it. Left on the default path, five
/// test files (plus the database layer's own) all open, write and delete the
/// same `finance_tracker.db` at the same time: rows appear from other files'
/// fixtures and some runs simply hang on the file lock. [isolationName] must
/// therefore be unique per test file.
Future<void> initScreenTestDatabase(String isolationName) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  final directory =
      await Directory.systemTemp.createTemp('finance_tracker_$isolationName');
  await databaseFactory.setDatabasesPath(directory.path);
}

/// Gives the next test a freshly created database.
///
/// `DatabaseHelper` is a singleton with a private constructor and a hard-coded
/// file name, so a test cannot hand the DAOs a separate in-memory database —
/// `CategoryDao(helper: ...)` can only ever be passed the one instance that
/// exists. The nearest equivalent, and what the database layer's own test
/// does, is to close the cached handle and delete the file, so the next call
/// re-runs onCreate and re-seeds the eight default categories.
///
/// Safe to call from `setUp`, which runs outside the fake-async zone.
Future<void> resetDatabase() async {
  await DatabaseHelper.instance.close();
  final path = join(await databaseFactory.getDatabasesPath(), 'finance_tracker.db');
  await databaseFactory.deleteDatabase(path);
}

/// Pumps until the screen's database work has finished.
///
/// A widget test body runs inside flutter_test's fake-async zone, which does
/// not turn the real event loop. sqflite's futures complete on the real loop,
/// so inside a plain `pumpAndSettle` they never complete at all: the screen
/// sits on its CircularProgressIndicator, that spinner keeps scheduling
/// frames, and pumpAndSettle spins until it times out. `runAsync` turns the
/// real loop for one cycle; the `pump` afterwards flushes the continuations
/// that completion scheduled back in the fake zone. Each `await` in a DAO
/// chain costs roughly one cycle, hence the loop rather than a single turn.
///
/// The explicit timeout on the final settle keeps a genuinely stuck screen
/// failing in seconds instead of after the default ten minutes.
Future<void> settleWithDatabase(WidgetTester tester, {int turns = 40}) async {
  for (var i = 0; i < turns; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

/// Runs a DAO call from inside a widget test body.
///
/// Same reason as [settleWithDatabase]: awaiting a database future directly in
/// a test body would hang, because the fake-async zone never lets it complete.
Future<T> readFromDatabase<T>(WidgetTester tester, Future<T> Function() query) async {
  final result = await tester.runAsync(query);
  return result as T;
}
