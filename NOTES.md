# NOTES

Work record for this repository, newest last. One entry per completed task:
what changed, which files, which commands built and tested it, what broke and
how it was fixed. Written as a record of what actually happened.

Entries cover this workstation's work (mothercoconut / Allen). Teammates'
commits are noted only where they changed something this work depended on.

---

## 2026-09-14 — Repository and collaborators

Created `mothercoconut/finance-tracker` (public) and invited the two
teammates; both accepted. Vathana Sovann (`Thava1206`) took the database
layer, `TrentonH3` took reports, transaction history and theme, and this
workstation took the core UI and input screens.

Vathana created the Flutter project inside a `finance_tracker/` subdirectory
rather than at the repository root. That detail caused most of the friction
recorded below, and was undone on 09-16.

---

## 2026-09-15 — Automated build (CI)

**Task.** The project requires an automated build. Prove on every change that
the code analyzes, the tests pass, and the app still compiles for Android.

**Changed.** `.github/workflows/ci.yml` (new), `.gitattributes` (new).

The workflow pins Flutter 3.47.2 and Java 21, then runs, in order:
`flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk
--debug`. It triggers on pushes to `main` and on pull requests into `main`,
and carries a 20-minute timeout so a hung job cannot burn quota up to
GitHub's six-hour ceiling. At the time it also set `working-directory:
finance_tracker`, because the app was not at the repository root.

`.gitattributes` pins `gradlew` and `*.sh` to LF. Without it, a checkout on a
Windows machine rewrites those files with CRLF line endings and the Linux
build machine cannot execute them.

**Commands.** `flutter analyze`, `flutter test`, `flutter build apk --debug`
locally; then the workflow's own run on the pull request.

**Result.** Merged as pull request #1 (`ci/automated-build`), commit
`2053dc3`. CI green.

---

## 2026-09-15 — Core UI and input screens

**Task.** Build this workstation's assigned screens against the database
layer's public API, without changing that API.

**Changed.** New: `lib/screens/onboarding_screen.dart`,
`dashboard_screen.dart`, `add_expense_screen.dart`, `add_income_screen.dart`,
`categories_screen.dart`, `startup_gate.dart`, `lib/widgets/money.dart`.
Rewritten: `lib/main.dart` (builds the five DAOs and hands them to the
startup gate). Tests: `test/screens/test_support.dart` plus one test file per
screen; `test/widget_test.dart` rewritten from the `flutter create` counter
template into a test of the real production wiring.

The screens take their DAOs by constructor injection, defaulting to real
ones, so a test can supply its own. Deleting a category is guarded by
`isCategoryInUse`, with a `DatabaseException` caught as a backstop in case
the check and the delete race.

**Commands.** `flutter analyze` → `No issues found!`; `flutter test` →
`00:02 +19: All tests passed!` (the database layer's 7 plus 12 new);
`flutter build apk --debug` → exit 0.

Each test was also checked by deliberately breaking the code it covers and
confirming the test went red — including the delete-refusal path, which is
the one most likely to pass vacuously.

**Problems and fixes.**

- The implementing agent was first briefed against the wrong branch: the
  working tree held the CI branch, not the database branch, so the described
  API did not exist in it. The agent refused to invent the API rather than
  guessing, which was the correct outcome. Fixed by re-branching off the
  database branch and re-briefing against the verified tree.
- `DatabaseHelper` is a singleton with a hard-coded database file name, and
  `flutter test` runs test files concurrently, so every test file opened,
  wrote and deleted the same file. Symptoms were rows appearing from another
  file's fixtures, and runs hanging on the file lock. Worked around by giving
  each test file its own databases directory. Reported to the database
  layer's owner; fixed properly by them on 09-16 by making the file name an
  overridable static.
- sqflite's futures complete on the real event loop, but a widget test body
  runs inside flutter_test's fake-async zone, so a plain `pumpAndSettle`
  never sees them complete and spins until it times out. Fixed with a helper
  that turns the real loop and then flushes the continuations back into the
  fake zone.

**Result.** Pull request #3 opened from `feat/screens`, carrying three
findings for the database layer's owner in its description. Never merged —
see below.

---

## 2026-09-15 to 09-16 — Development environment repair

Not a repository change, but it stopped all work and is worth recording.

Windows 11 upgraded itself from 23H2 to 24H2 and removed the Java
development kit the Android build depends on. `flutter build apk --debug`
failed with `ERROR: JAVA_HOME is set to an invalid directory`. Fixed by
installing Microsoft OpenJDK 21 (`winget install --id Microsoft.OpenJDK.21`),
repointing the user `JAVA_HOME` at the new path, and removing the stale entry
for the old one from `PATH`. The build then succeeded.

The same reboot killed the Android emulator and the debug bridge; the
emulator was restarted headless with
`emulator.exe -avd csc4330 -no-window -no-boot-anim`.

---

## 2026-09-16 — `main` broken, then restructured (teammates)

Recorded because it changed what this workstation could build on, not
because anything here was changed by this workstation.

`TrentonH3` pushed four commits straight to `main`, with no pull request and
therefore no CI gate before the fact. They added a second, complete copy of
the Flutter project at the repository root and two screens whose imports did
not resolve. `main` went red with 11 analyzer errors, and because a
pull-request build checks out the pull request merged onto `main`, every open
pull request went red with it — including #3, which had nothing to do with
the breakage.

Later the same day the two teammates repaired it: `TrentonH3` fixed the
imports and added a spending graph, then Vathana deleted the
`finance_tracker/` directory outright — making the root copy the real app —
rewrote `lib/main.dart`, added their own home and graphs screens, and removed
`working-directory` from the CI workflow to match the new layout. `main` went
green at `0206961`: no analyzer issues, 8 tests passing, Android build
succeeding.

The cost fell on pull request #3, which targets a directory that no longer
exists and conflicts with `main` on two files. The work in it was not lost,
but it cannot be merged as it stands.

**Prevention, since put in place:** branch protection on `main`, requiring a
pull request and a passing check. See the 09-17 entry. Every problem in this
entry was a direct push to an unprotected trunk.

---

## 2026-09-17 — Categories management screen

**Task.** `main` had no way to create, rename or delete a spending category.
Port that screen from the stranded branch onto the current layout, wire it up,
and merge it through a pull request.

**Changed.** New: `lib/screens/categories_screen.dart`,
`lib/widgets/money.dart`, `test/screens/test_support.dart`,
`test/screens/categories_screen_test.dart`. Modified:
`lib/screens/home_screen.dart`, +25 lines, no deletions. Documentation:
`NOTES.md`, `TASKS.md`, `PROJECT.md`, `docs/demo-script.md`.

The screen file needed no edits at all — it is byte-identical to the version
written on 09-15, because its relative imports resolve the same way at the
repository root. The test bootstrap did change: it now sets
`DatabaseHelper.dbName` per test file, replacing the per-file temp-directory
workaround, since the database layer made that name overridable on 09-16.

The entry point is an app bar action on the home screen rather than a fourth
button — the existing buttons all record or review activity, and an icon adds
no text, so the home screen's exact-text test still holds.

**Commands.** `flutter analyze` → `No issues found!`; `flutter test` →
`00:03 +13: All tests passed!` (8 existing, 5 new). CI green on all three
commits of pull request #4. Merged as `2f712b4`.

Also run on the device, not just compiled: `flutter run -d emulator-5554`,
driven with `adb input`, confirming the icon opens the screen and that
renaming a category updates the home screen's activity list.

**Problems and fixes.**

- **A machine crash corrupted a source file in a way that looks like garbage,
  not like damage.** `categories_screen.dart` came back with its size
  recorded — 9,628 bytes — and every byte a NUL, because the metadata was
  flushed and the contents were not. The analyzer reported 9,629 errors in one
  file, all `Illegal character`. Fixed by rewriting the file from the blob
  still in git; the restored file hashes identical to the one that had already
  passed, so nothing was reconstructed by guesswork.
- **A green test suite that proved nothing.** Deliberately removing the
  `DatabaseException` backstop from the delete path left every test passing:
  the ported tests covered the pre-check twice and the backstop never. A test
  that defeats only the pre-check now covers it, so the two guards are tested
  separately.
- **A copied pattern that would have failed silently.** The obvious way to
  wire the screen was the existing `Navigator.push<bool>` plus
  `if (saved == true) _loadData()`. The categories screen exits by the back
  button and never pops a result, so that guard is always false: it would have
  compiled, analyzed clean, passed the suite, and shown stale category names.
  The reload is unconditional for that reason, and the device run is what
  proved it matters.

**Result.** Pull request #4 merged. Pull request #3 closed with a comment
recording what replaced it. Branch protection enabled on `main`: a pull
request and the `Analyze, test and build` check are now required, force
pushes and deletions are off, and administrator bypass is left on so the
owner keeps an override before the deadline.
