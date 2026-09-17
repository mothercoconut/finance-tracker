import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:finance_tracker/database/database_helper.dart';

// Shared bootstrap for the screen tests. Not a test file itself — the runner
// only executes `*_test.dart`, so this is imported, never run.

/// Points sqflite at a desktop SQLite engine and gives this test file its own
/// database file.
///
/// The factory is the *no-isolate* one, unlike the database layer's own test,
/// because a reply that has to cross an isolate port can never arrive inside a
/// widget test — see [settleWithDatabase].
///
/// The database file name is per-test-file because `flutter test` runs test
/// files concurrently: sharing one name across files means rows appear from
/// another file's fixtures, and some runs simply hang on the file lock.
/// [isolationName] must therefore be unique per test file.
///
/// `DatabaseHelper.dbName` is writable precisely so a test can do this, so the
/// name is overridden directly rather than working around a fixed name by
/// pointing each file at a temporary databases *directory*.
Future<void> initScreenTestDatabase(String isolationName) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  DatabaseHelper.dbName = '${isolationName}_screen_test.db';
}

/// Gives the next test a freshly created database.
///
/// `DatabaseHelper` is a singleton, so a test cannot hand the DAOs a separate
/// in-memory database — `CategoryDao(helper: ...)` can only ever be passed the
/// one instance that exists. The nearest equivalent, and what the database
/// layer's own test does, is to close the cached handle and delete the file,
/// so the next call re-runs onCreate and re-seeds the eight default
/// categories.
///
/// The path is computed from [DatabaseHelper.dbName] rather than a literal: a
/// literal here would silently stop matching the file the helper actually
/// opens the moment either side changed, and the symptom would be state
/// leaking between tests, not an error.
///
/// Safe to call from `setUp`, which runs outside the fake-async zone.
Future<void> resetDatabase() async {
  await DatabaseHelper.instance.close();
  final path =
      join(await databaseFactory.getDatabasesPath(), DatabaseHelper.dbName);
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
