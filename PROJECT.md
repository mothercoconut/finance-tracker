# PROJECT

Project number / name: Project 3 — Personal Finance Tracker
Stack and target platform: Flutter 3.47.2 / Dart 3.13.2, SQLite via sqflite, fl_chart, Android (Java 21). The app is at the **repository root** — `lib/`, `test/`, `pubspec.yaml` are top level. It lived in `finance_tracker/` until 2026-09-16; anything that still says otherwise is stale.
Solo or team; my assigned area: Team of 3. Mine (mothercoconut / Allen): GitHub, design, core UI and input screens, and the automated build. Thava1206 (Vathana Sovann): database layer, and in practice the home, add and graphs screens. TrentonH3: reports, transaction history, theme.
Trunk branch name: main
Task board, and where my cards live: `TASKS.md` at the repository root. No Trello board exists.
Build command: flutter build apk --debug
Test command: flutter test
Analyze / lint command: flutter analyze
CI configured (yes/no) and workflow path: yes — `.github/workflows/ci.yml`. Runs `pub get`, `analyze`, `test`, `build apk --debug`. Triggers only on push to `main` and pull requests into `main`, so a plain branch push gets no CI — open a pull request to get a run.
Deliverables required for this project: git repo, demo video, task list, automated build
Constraints: teams of 3; the app must differ from Paranoia Meter and flappymiata
Repo: https://github.com/mothercoconut/finance-tracker (public)
Due: **Friday 2026-09-18 17:00**
Emulator AVD: csc4330 — headless: `/c/Android/Sdk/emulator/emulator.exe -avd csc4330 -no-window -no-boot-anim`; headed for recording: same without the flags
JDK: C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot
Last updated: 2026-09-17 18:5x

---

# HANDOFF — 2026-09-17 evening

**Read order:** this file, then `NOTES.md` (what happened, per task), then `TASKS.md` (who owes what).

## Right now

Pull request #4 (`feat/categories`) holds the categories management screen, its entry point in the home screen, and three documentation files. CI was green on the first commit; a second run is in flight for the wiring commit. **Merging it needs the owner**, and so do two other GitHub writes — see "Blocked" below.

## VERIFIED — readings 2026-09-17 ~18:00–18:55

- `main` is at `0206961`, green — *source: `gh run list --branch main --limit 1`*
- `feat/categories` is at `4c2f64f`, three commits ahead of `main` — *source: `git log`, `git push`*
- On that branch: `flutter analyze` → `No issues found!`; `flutter test` → `00:03 +13: All tests passed!` — *source: both commands run by the director, not reported by an agent*
- The categories screen file is byte-identical to the version that passed on `feat/screens` — *source: `git hash-object` vs `git rev-parse origin/feat/screens:...`, both `dfcb05c7`*
- `home_screen.dart` changed by 25 insertions and 0 deletions — *source: `git diff --stat`*
- The wiring was exercised on `emulator-5554`: the app bar icon opens the screen, and a renamed category re-renders in the home screen's activity list — *source: agent ran `flutter run` and drove it with `adb input`, with screenshots checksummed to catch a screenshot that raced the transition*
- Branch protection is still NOT enabled — *source: the `PUT .../branches/main/protection` call refused by the permission classifier; never applied*
- Pull request #3 carries a closing comment but is still OPEN — *source: `gh pr close 3` refused by the classifier*

## INFERRED

- PR #4's second CI run passes — *settle with `gh pr checks 4`. The same tree was green on run one, and the only change since is additive and locally verified.*

## Blocked — needs the owner's hands, not a decision

The permission classifier refuses GitHub writes from this session (`[External System Writes]`, `[Modify Shared Resources]`). The owner has authorised all three; the harness, not the owner, is the blocker.

1. Merge PR #4 into `main`.
2. `gh pr close 3` — the explanatory comment is already posted.
3. Branch protection on `main`: require a pull request and the check `Analyze, test and build`, `enforce_admins: false` so the owner can still force something through before the deadline. Every problem in `NOTES.md`'s 09-16 entry came from a direct push to an unprotected trunk.

## Owed / open

- Demo video — the owner. Script at `docs/demo-script.md`; clear the emulator first with `adb shell pm clear com.example.finance_tracker`, because an agent left a $12.34 expense and a category renamed to "Groceries Renamed" on it.
- Reports screen, transaction history, theme — TrentonH3, unstarted.
- Starting-balance / first-run screen — unassigned, unstarted. `SettingsDao` exists and nothing calls it.
- Four findings in `home_screen.dart`, reported to the owner and recorded here, **not fixed** because the file is a teammate's: negative balance renders as `$-12.34` while the rows below render `-$12.34`; money formatted inline although `lib/widgets/money.dart` exports `formatMoney`; `_loadData()` clears its loading flag only on the success path, so a database error leaves the spinner up forever; the expense query's lower bound is hardcoded to `DateTime(2000, 1, 1)`.
- Database-layer findings, reported and recorded in `TASKS.md`: `monthly_income` is write-only; `getRecentExpenses` returns no category name; money is stored as `double`.

## Traps for the successor

- **A crash can leave a file the right size and entirely NUL.** That is what happened to `categories_screen.dart` on 09-17: `wc -c` said 9,628, every byte was `\0`, and the analyzer reported 9,629 issues in one file. If a file's errors are all `Illegal character`, check for this before reading the code.
- **Copying the `Navigator.push<bool>` + `if (saved == true)` pattern is wrong for any screen that exits by the back button** — the result is always null, the reload never fires, and nothing fails. It compiles, analyzes and tests green.
- A screenshot taken immediately after a tap can race the transition and come back byte-identical to the one before it, which reads exactly like "the button does nothing". Checksum consecutive screenshots.
- `flutter test` runs test files concurrently. Every test file must set its own `DatabaseHelper.dbName` or they share one database file.
- CI does not run on a plain branch push. Open a pull request.
- Foreground subagents are cancelled by any incoming owner message; background them.
