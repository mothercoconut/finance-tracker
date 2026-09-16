# PROJECT

Project number / name: Project 3 — Personal Finance Tracker
Stack and target platform: Flutter 3.47.2 / Dart 3.13.2, SQLite via sqflite, Android (Java 21). The real app is in `finance_tracker/`. See the trap below about the second project at the repo root.
Solo or team; my assigned area: Team of 3. Mine (mothercoconut/Allen) is GitHub + design + core UI and input screens (Dashboard, Add Expense, Add Income, Categories). Thava1206 (Vathana Sovann): database layer. TrentonH3: reports, transaction history, theme — per the task document, never confirmed by him.
Trunk branch name: main
Task board, and where my cards live: Trello — NOT CONFIRMED to exist. No URL has been produced. Graded deliverable.
Build command: flutter build apk --debug          (run from finance_tracker/)
Test command: flutter test                        (run from finance_tracker/)
Analyze / lint command: flutter analyze           (run from finance_tracker/)
CI configured (yes/no) and workflow path: yes — .github/workflows/ci.yml at the repo root, `working-directory: finance_tracker`. Triggers ONLY on push to main and PRs into main. **main is currently RED.**
Deliverables required for this project: git repo, demo video, task list, automated build
Constraints (professor's requirements, must-differ-from-previous-app, etc.): teams of 3; app must differ from Paranoia Meter and flappymiata
Repo: https://github.com/mothercoconut/finance-tracker (public)
Due: Friday 2026-09-18 17:00
Emulator AVD: csc4330 — start headless: /c/Android/Sdk/emulator/emulator.exe -avd csc4330 -no-window -no-boot-anim
JDK: C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot  (user JAVA_HOME points here since 2026-09-16)
Last updated: 2026-09-16 07:52

---

# HANDOFF — 2026-09-16 07:52 — main is red, screens are done and blocked on it

**Read order:** this file, then PR #3's description (the three database-layer findings), then `.github/workflows/ci.yml`.

## Right now

`main` is red because TrentonH3 pushed four commits straight to it. The five core screens are complete in **PR #3** and pass locally, but PR #3's CI cannot go green while `main` is broken, because a pull-request build checks out the PR merged onto `main`. **Three decisions are waiting on the owner and nothing can usefully move until he makes them.** Nothing is running in the background.

## VERIFIED — all readings 2026-09-16 07:52 unless marked

- `main` is at `b5d6e41` and its latest CI is `failure` — *source: `git rev-parse origin/main`; `gh run list --branch main --limit 1`*
- TrentonH3 pushed 4 commits directly to `main`, none through a pull request, 2026-09-15 21:48–22:02: `3fce490`, `f3b702d` (merge), `4338725`, `b5d6e41` — *source: `git log --format='%h parents=%p %an %s' 2053dc3..origin/main`*
- `main` now holds **two Flutter projects**: the real one in `finance_tracker/`, and a complete duplicate at the repo root with its own `pubspec.yaml`, `android/`, `ios/`, `lib/`, `web/`, `windows/` — *source: `git ls-tree --name-only origin/main`, and `git ls-tree -r --name-only origin/main | grep pubspec.yaml` returns two paths*
- TrentonH3's `add_expense_screen.dart` and `add_income_screen.dart` fail to compile. The import `../models/expense.dart`, from `finance_tracker/lib/expense/income_screen/`, resolves to `finance_tracker/lib/expense/models/`, which does not exist; `../../models/expense.dart` resolves to a file that does — *source: `git cat-file -e` on both paths against origin/main*
- Branch protection is NOT enabled on `main` — *source: `gh api repos/mothercoconut/finance-tracker/branches/main/protection` returns HTTP 404 "Branch not protected"*
- PR #3 (`feat/screens`) is open and its check `Analyze, test and build` fails — *source: `gh pr checks 3 -R mothercoconut/finance-tracker`*
- PR #3's failure is entirely TrentonH3's files: all 11 analyzer errors are in `finance_tracker/lib/expense/income_screen/`, a directory not present on `feat/screens` — *source: `gh run view 35052214027 -R mothercoconut/finance-tracker --log-failed`*
- On `feat/screens` itself: `flutter analyze` clean, `flutter test` 19 passing (the 7 database tests plus 12 new), database layer / models / pubspec untouched — *source: those commands run 2026-09-15 ~22:00 against the branch, which has not changed since*
- The JDK was removed by the Windows 11 23H2 → 24H2 upgrade. Reinstalled as Microsoft OpenJDK 21.0.12.1; user `JAVA_HOME` repointed; a stale PATH entry for the old `jdk-21.0.3.9` removed — *source: `java -version` on the new path; `[Environment]::GetEnvironmentVariable('JAVA_HOME','User')`*
- Local `flutter build apk --debug` succeeds with the new JDK — *source: exit 0, 2026-09-16 ~07:30*
- Emulator up, one device attached — *source: `adb devices`*

## INFERRED

- PR #3 goes green once `main` is fixed — *settle with: fix `main`, then `gh run rerun` the PR #3 check. Not certain, because a revert of TrentonH3's commits could still conflict with PR #3's rewrite of `lib/main.dart`.*
- TrentonH3 has not started reports, transaction history or theme — *settle with: `git -C /c/repo/finance-tracker log origin/main --author=TrentonH3 --name-only`. As of 07:52 his commits contain the two expense/income screens (in both projects) plus the root duplicate's scaffold — which includes root-level COPIES of the existing `lib/database/`, `lib/models/`, `lib/main.dart`, `pubspec.yaml` and tests. None of it is reports, history or theme. An earlier draft of this line said his commits touched nothing outside `lib/expense/`; running this command showed that was wrong.*

## Blocked on the owner — three decisions, asked 2026-09-16 ~07:45, unanswered

1. **Who fixes `main`?** TrentonH3 fixes his own push, or the owner authorises a revert of his four commits. A revert is a new commit, not a history rewrite.
2. **Which Add Expense / Add Income to keep?** Recommended: PR #3's — they compile, are wired to the real DAOs, and have mutation-checked tests.
3. **Enable branch protection on `main`** — require a PR and passing CI. Recommended first, so this cannot recur.

Recommended order: 3, then revert, then merge PR #3, then point TrentonH3 at reports and history on a branch. I offered to draft the message to him.

## Owed / open

- Decisions 1–3 above — the owner
- Reports, transaction history, theme — TrentonH3; unstarted
- Demo video — the owner
- Trello board — nobody has produced one
- `DatabaseHelper` is a singleton with a hard-coded filename, so concurrent test files share one database — Vathana; reported in PR #3's description, not fixed
- `monthly_income` is stored and read back but nothing consumes it — Vathana; reported, not fixed

## Details captured this session

- **Scope call awaiting the owner:** `test/widget_test.dart` was the `flutter create` counter test, in neither the in-scope nor the do-not-touch list, and it stopped compiling once `main.dart` became the real app. It was **rewritten** into the production-wiring test rather than deleted. The owner may prefer it deleted.
- `getRecentExpenses` returns rows with only `category_id`; the dashboard does an extra `getAllCategories()` lookup per load. Minor.
- `Expense.copyWith(note: ...)` cannot clear a note back to null. Not on any current path.
- Owner question, verbatim: *"powershell is broken?"* — answered: the harness PowerShell tool returned "Access is denied" for about ten minutes after the 24H2 reboot, while PowerShell run from Bash worked. It recovered on its own.
- Owner question, verbatim: *"why did the background agent die when i sent that message? thats strange."* — answered: it was a FOREGROUND agent, which is part of the turn, and a message interrupts the turn. It was cancelled twice this way before being backgrounded.

## Superseded by this handoff

The handoff written 2026-09-15 21:47 is retired. Specifically:

- It said **`main` is at `2053dc3` and contains the database layer and CI.** Retired: `main` is at `b5d6e41` and is red. The database layer and CI are still on `main`; what changed is what was pushed on top of them.
- It said **"no open PRs."** Retired: PR #3 is open.
- It said, marked VERIFIED, **"TrentonH3 has made no commits and pushed no branches."** Retired: he made four, all to `main`. That reading was correct at 21:47 and his first commit landed at 21:48. A VERIFIED claim is a reading with a timestamp, not a standing fact.
- It said **a screens agent was running.** Retired: it finished, and the result is PR #3.
- It gave the JDK path as `jdk-21.0.3.9-hotspot`. Retired: that directory no longer exists; the JDK is at `jdk-21.0.12.101-hotspot`.

Still binding from it: build against the teammate's API and never change it; the app lives in `finance_tracker/`; background any agent that must survive a conversation; start the emulator headless.

## Not done

- **Blocked, not unaffordable:** fixing `main`. It is a small change — a revert, or a one-segment path fix in two imports — but it is a teammate's code and a push to trunk, and both need the owner's authorisation.
- **Unaffordable:** reports, history and theme; the demo video; the Trello board.
- **Uninformative — do not revisit:** design questions 1, 2, 3, 5 and 9 from the original plan. The database schema answers all five in code.

## Traps for the successor

- **Two `pubspec.yaml` files now exist.** Any `flutter` command run from the repo root runs against the DUPLICATE project, not the real one. Always `cd finance_tracker` first.
- **Deleting the root duplicate alone will NOT make PR #3 green.** The files CI actually analyzes are `finance_tracker/lib/expense/income_screen/*.dart`, because CI runs with `working-directory: finance_tracker`. Those two files must be removed or fixed as well.
- **A red `main` poisons every pull request**, because a PR build checks out the PR merged onto `main`.
- **CI does not run on a plain branch push** — only on push to `main` and PRs into `main`. To get CI on a branch, open a PR.
- **Processes started before the JDK fix still carry the old `JAVA_HOME`**, which points at a directory that no longer exists. Export the new path in any such shell.
- **Writing multi-line files through a Bash heredoc has failed twice this session** on quoting, once writing nothing at all. The Write tool avoids shell parsing and is safer for long documents.
- The PowerShell tool may return "Access is denied" after a reboot. Bash works.
- A foreground subagent is cancelled by any incoming owner message.
