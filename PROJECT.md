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
Last updated: 2026-09-17 19:10

---

# HANDOFF — 2026-09-17 evening

**Read order:** this file, then `NOTES.md` (what happened, per task), then `TASKS.md` (who owes what).

## Right now

The categories screen, its entry point in the home screen and four documentation files are merged to `main`, which is green. `main` is now protected: a pull request and a passing check are required. Nothing of this workstation's is outstanding. What remains for the deadline is the demo video, which is the owner's, and three unstarted features belonging to TrentonH3.

## VERIFIED — readings 2026-09-17 ~19:10

- `main` is at `2f712b4` ("Add categories management screen (#4)") and its CI is `success` — *source: `git log origin/main`; `gh run list --branch main --limit 1`*
- Branch protection is ON: required check `Analyze, test and build`, pull request required with 0 approvals, force pushes and deletions disabled, `enforce_admins` false so the owner keeps an override — *source: `gh api repos/mothercoconut/finance-tracker/branches/main/protection`, read back after the owner applied it*
- Pull request #4 is MERGED; #3 is CLOSED with a comment explaining what replaced it — *source: `gh pr list --state all`*
- `lib/screens/categories_screen.dart`, `lib/widgets/money.dart`, `test/screens/`, `NOTES.md`, `TASKS.md`, `PROJECT.md` and `docs/demo-script.md` are all on `main` — *source: `git ls-tree -r --name-only origin/main`*

## VERIFIED — readings 2026-09-17 ~18:00–18:55

- `main` is at `0206961`, green — *source: `gh run list --branch main --limit 1`*
- `feat/categories` is at `4c2f64f`, three commits ahead of `main` — *source: `git log`, `git push`*
- On that branch: `flutter analyze` → `No issues found!`; `flutter test` → `00:03 +13: All tests passed!` — *source: both commands run by the director, not reported by an agent*
- The categories screen file is byte-identical to the version that passed on `feat/screens` — *source: `git hash-object` vs `git rev-parse origin/feat/screens:...`, both `dfcb05c7`*
- `home_screen.dart` changed by 25 insertions and 0 deletions — *source: `git diff --stat`*
- The wiring was exercised on `emulator-5554`: the app bar icon opens the screen, and a renamed category re-renders in the home screen's activity list — *source: agent ran `flutter run` and drove it with `adb input`, with screenshots checksummed to catch a screenshot that raced the transition*
## Retired from the earlier part of this handoff

Three items were listed as blocked at 18:55 — merging #4, closing #3, and enabling branch protection. All three are done; the readings above supersede them.

## The harness blocks GitHub writes from this session

Every write to GitHub — merging a pull request, closing one, changing repository settings — is refused by the permission classifier (`[Merge Without Review]`, `[External System Writes]`, `[Modify Shared Resources]`), whatever the owner has authorised in conversation. Reads, branch pushes, pull-request creation and pull-request comments all work.

So the shape of the work is: do everything up to the merge, then hand the owner the exact command. **Write commands for the owner in PowerShell**, not POSIX shell — their terminal is Windows PowerShell 5.1, where `&&` is a parse error and `printf` and `/tmp` do not exist. A bash heredoc pasted there fails silently enough to look like it worked. A permission rule for `gh` in the owner's settings would remove this friction permanently; offered, not yet set up.

## Owed / open

- Demo video — the owner, and the last deliverable still outstanding. Script at `docs/demo-script.md`; clear the emulator first with `adb shell pm clear com.example.finance_tracker`, because an agent left a $12.34 expense and a category renamed to "Groceries Renamed" on it.
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
