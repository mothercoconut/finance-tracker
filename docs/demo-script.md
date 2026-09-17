# Demo video — script and shot list

For the Project 3 demo. Written against what the app actually does on `main`
as of 2026-09-17, not against what it was planned to do. If a screen changes
before recording, fix this file first.

Target length: 3–4 minutes. Nothing here needs a second take; if a step
fails, say what failed and move on — a demo that shows a real app is worth
more than a demo that shows a rehearsed one.

---

## Before recording

```bash
cd /c/repo/finance-tracker
flutter test
flutter run
```

The emulator should already be running (`adb devices` shows
`emulator-5554  device`). Start it headed for the recording, not with
`-no-window`:

```bash
/c/Android/Sdk/emulator/emulator.exe -avd csc4330
```

Delete the app's data first so the demo starts from an empty balance —
long-press the app icon, App info, Storage, Clear storage. A demo that opens
on leftover test data is hard to follow.

Have these open in tabs, ready to show: the GitHub repository, the Actions
tab with a green run, and `NOTES.md`.

---

## Shot 1 — What it is (20s)

*On the home screen, app freshly opened.*

> This is a personal finance tracker, built by three of us in Flutter with a
> SQLite database on the device. It answers one question: where did my money
> go. The home screen shows the available balance, the recent transactions,
> and the three things you can do — add income, add an expense, see the
> trends.

Point out the balance reads $0.00 and the list says no transactions yet.

## Shot 2 — Add income (30s)

*Tap Income.*

> Income is an amount, a source, and a date.

Enter **2400**, source **Paycheck**, leave today's date.

> When you save, it asks whether this is recurring or one-time, because a
> monthly paycheck and a birthday cheque are not the same thing.

Tap **Recurring**. Land back on the home screen and point at the balance —
it now reads $2,400.00, and the transaction appears in the list.

## Shot 3 — Add an expense (40s)

*Tap Expense.*

> An expense has an amount, a category, and a date — and one extra question.

Enter **85.40**, pick category **Groceries**, tap **Necessary**.

> Every expense is tagged necessary or unnecessary. That's the distinction
> the reports are built on: not just what you spent, but how much of it you
> had to spend.

Save. Back on the home screen: balance drops to $2,314.60, and both
transactions are listed.

Add a second expense quickly — **60.00**, category **Entertainment**, marked
**Unnecessary** — so the graph in the next shot has something to show.

## Shot 4 — Trends (30s)

*Tap Trends.*

> The trends screen reads the same database and charts income against
> spending over time.

Let the chart render, point out the two series and the legend.

## Shot 5 — Categories (30s) — only if `feat/categories` has merged

*Open the categories screen.*

> Categories are editable. You can add one, rename one, and delete one —
> except a category that transactions are already filed under. That delete is
> refused, and it tells you why, because silently deleting it would orphan
> every expense pointing at it.

Demonstrate: create **Textbooks**, rename it, then try to delete
**Groceries** and show the refusal.

## Shot 6 — How it's built (45s)

*Switch to the browser.*

> Everything is in one GitHub repository. Three of us work in it: the
> database layer, the screens, and the reports.

Show the repository, then the Actions tab.

> Every change runs the same three checks automatically before it can be
> trusted: the analyzer, the test suite, and a real Android build. If any of
> them fails, the run goes red and we know before it reaches anyone's phone.

Open the most recent green run and show the steps.

> That's the automated build requirement, and it's the reason a broken push
> got caught in minutes instead of at submission time.

## Shot 7 — Close (15s)

*Back to the app, home screen.*

> Flutter, SQLite on the device, no server. A balance, transactions in and
> out, categories, and trends. Repository and build history are linked in the
> submission.

---

## If asked what you'd do next

Honest answers, all of them true of the current code:

- Store money as integer cents; `double` drifts by fractions of a cent.
- Full transaction history with filtering — the home screen shows recent
  entries only.
- The reports the database already supports: totals by category, necessary
  versus discretionary spending, month over month.
