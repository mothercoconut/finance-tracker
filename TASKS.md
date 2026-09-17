# Task list — Personal Finance Tracker

Graded deliverable. Status verified against the repository on 2026-09-17; the
evidence column says how, so any line here can be re-checked rather than
trusted.

Owners follow the task document: **Vathana Sovann** (`Thava1206`) database
layer, **Allen** (`mothercoconut`) core UI, input screens and the build,
**TrentonH3** reports, transaction history and theme.

Due: **Friday 2026-09-18, 17:00.**

---

## Done

| Task | Owner | Evidence |
|---|---|---|
| Repository created, collaborators added | Allen | `mothercoconut/finance-tracker`, 3 collaborators |
| Database layer — models, DAOs, schema, seeding | Vathana | `lib/database/`, `lib/models/`, 7 tests in `test/database/` |
| Automated build (CI): analyze, test, Android package on every change | Allen | `.github/workflows/ci.yml`, merged as PR #1 |
| Dashboard / home screen — balance, recent transactions, quick-add | Vathana | `lib/screens/home_screen.dart`, smoke test in `test/widget_test.dart` |
| Add expense screen | TrentonH3, reworked by Vathana | `lib/screens/add_expense_screen.dart` |
| Add income screen | TrentonH3, reworked by Vathana | `lib/screens/add_income_screen.dart` |
| Spending trends / graphs screen | Vathana | `lib/screens/graphs_screen.dart` |
| Work record for the demo and the kata | Allen | `NOTES.md` |

## In progress

| Task | Owner | State |
|---|---|---|
| Categories management — create, edit, delete, refuse delete while in use | Allen | Branch `feat/categories`. Screen and tests written; being rebuilt after a machine crash corrupted the screen file. Not yet merged. |

## Not started

| Task | Owner | Note |
|---|---|---|
| Reports screen — totals by category, necessary vs discretionary | TrentonH3 | `ReportsDao` already provides `getTotalsByCategory`, `getNecessaryVsDiscretionary`, `getMonthlyTotals`. No screen calls them. |
| Transaction history screen — full list, filtering | TrentonH3 | The home screen shows recent transactions only. |
| Theme | TrentonH3 | App uses the default Material theme. |
| Starting balance / first-run setup | unassigned | `SettingsDao` exists with `completeOnboarding`, `getStartingBalance`, `getMonthlyIncome`. No screen calls it, so `monthly_income` is stored and never read. |
| Demo video | Allen | Script at `docs/demo-script.md`. |

## Blocked

| Task | Owner | Blocker |
|---|---|---|
| Branch protection on `main` — require a pull request and a passing check | Allen | Needs a repository-settings change; see `NOTES.md` for why it matters. Four direct pushes to `main` on 09-16 broke the build for everyone and stranded an open pull request. |
| Pull request #3 (`feat/screens`) | Allen | Targets the `finance_tracker/` directory, which no longer exists. Superseded by work already on `main` plus `feat/categories`. To be closed with a note, not merged. |

---

## Known issues, reported and not fixed

These were found while building against the database layer and belong to its
owner. They are recorded rather than changed, because the work agreement is
that teammates' code gets reported, not edited.

- **`monthly_income` is write-only.** `SettingsDao.completeOnboarding` stores
  it and `getMonthlyIncome` reads it back, but nothing in the app calls
  either, so the value cannot affect anything a user sees.
- **`getRecentExpenses` returns no category name**, only `category_id`, so a
  caller that wants to label a row has to fetch every category separately.
- **Money is stored as `double`.** Repeated addition of values like 0.10 and
  0.20 drifts, so a balance can end in a fraction of a cent. Integer cents, or
  a decimal type, avoids it. Changing it now would require a schema migration.
- **Fixed on 09-16:** `DatabaseHelper` hard-coded its database file name, so
  concurrently running test files shared one file and contaminated each
  other's data. The file name is now an overridable static.
