// Covers the production wiring path.
//
// Every screen takes its DAOs as constructor arguments so the screen tests can
// supply their own. That makes the real construction — the DAOs built with no
// arguments inside FinanceTrackerApp, each falling back to the shared
// DatabaseHelper.instance — the one path those tests never execute. This file
// pumps the real app widget so that path runs: if the wiring in main.dart were
// wrong (a screen handed the wrong DAO, the gate never reached), the screen
// tests would all still pass and only this one would go red.
//
// The one thing still substituted is the sqflite platform factory, which has
// to be: there is no Android platform channel on the test VM. That is the same
// substitution the database layer's own test makes.
//
// This file replaces the counter smoke test from `flutter create`, which
// referenced the scaffold's MyApp and no longer compiled once main.dart became
// the real app.
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/database/settings_dao.dart';
import 'package:finance_tracker/main.dart';

import 'screens/test_support.dart';

void main() {
  setUpAll(() => initScreenTestDatabase('app_wiring'));
  setUp(resetDatabase);

  testWidgets('the app builds its own DAOs and gates on the real database',
      (tester) async {
    await tester.pumpWidget(const FinanceTrackerApp());
    await settleWithDatabase(tester);

    // First launch: onboarding, chosen by a real SettingsDao reading a real
    // database it opened itself.
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('the app opens on the dashboard once onboarding has been done',
      (tester) async {
    // Written through a separately constructed DAO, so the app's own DAOs have
    // to find it in the shared database rather than in anything handed to
    // them. This is the arm that proves the test above is reporting the gate's
    // decision and not just "the app renders something".
    //
    // runAsync because this is a database call from inside the test body; see
    // readFromDatabase in screens/test_support.dart.
    await tester.runAsync(
      () => SettingsDao().completeOnboarding(startingBalance: 250, monthlyIncome: 0),
    );

    await tester.pumpWidget(const FinanceTrackerApp());
    await settleWithDatabase(tester);

    expect(find.text('Get started'), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text(r'$250.00'), findsOneWidget);
  });
}
