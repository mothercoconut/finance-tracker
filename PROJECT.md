# PROJECT

Project number / name: Project 3 — Personal Finance Tracker
Stack and target platform: Flutter 3.47.2 / Dart 3.13.2, SQLite via sqflite, Android (Java 21). The repo also carries web/windows/linux/macos directories from `flutter create`; only Android is exercised.
Solo or team; my assigned area: Team of 3. Mine (mothercoconut/Allen) is GitHub + design + the core UI and input screens. Thava1206 (Vathana Sovann) wrote the database layer. TrentonH3 is the third member.
Trunk branch name: main
Task board, and where my cards live: Trello — NOT CONFIRMED to exist. Nobody has produced a board URL. This is a graded deliverable for project 3.
Build command: flutter build apk --debug          (run from finance_tracker/, NOT the repo root)
Test command: flutter test                        (run from finance_tracker/)
Analyze / lint command: flutter analyze           (run from finance_tracker/)
CI configured (yes/no) and workflow path: yes — .github/workflows/ci.yml at the REPO ROOT, with `defaults.run.working-directory: finance_tracker`
Deliverables required for this project: git repo, demo video, task list, automated build
Constraints (professor's requirements, must-differ-from-previous-app, etc.): teams of 3, "no repeats" (unresolved whether that bars a repeat teammate); app must differ from Paranoia Meter and flappymiata
Repo: https://github.com/mothercoconut/finance-tracker (public)
Due: Friday 2026-09-18 17:00
Emulator AVD: csc4330 — start headless or it sits on the owner's screen:
  /c/Android/Sdk/emulator/emulator.exe -avd csc4330 -no-window -no-boot-anim
Last updated: 2026-09-15

---

# HANDOFF — 2026-09-15 21:47 — project 3 mid-build, screens agent running

**Read order:** this file, then `finance_tracker/lib/database/` and
`finance_tracker/lib/models/` (the teammate's API, which is the contract),
then `.github/workflows/ci.yml`.

## Right now

A background subagent is building five screens (Onboarding, Dashboard, Add
Expense, Add Income, Categories) on branch `feat/screens`, against the
teammate's DAOs. It had been launched twice in the foreground and cancelled
both times by an incoming user message; it is backgrounded now specifically so
that cannot happen again. Working tree was clean at 21:47, so it was still
reading rather than writing.

## VERIFIED

- `main` is at `2053dc3` and contains both the database layer (PR #2) and CI
  (PR #1) — *source: `git log --oneline origin/main`, 21:47*
- PR #1 and PR #2 are both MERGED; no open PRs — *source:
  `gh pr list -R mothercoconut/finance-tracker --state all`, 21:47*
- Both collaborators have accepted: Thava1206 and TrentonH3 — *source:
  `gh api repos/mothercoconut/finance-tracker/collaborators`, 21:47*
- CI passed on the CI branch before merge — *source: `gh run list`, check
  "Analyze, test and build" = SUCCESS*
- `feat/screens` is 0 commits ahead of `origin/main`, tree clean — *source:
  `git rev-list --count origin/main..HEAD` and `git status --porcelain`, 21:47*
- Emulator `csc4330` running headless, one device attached — *source:
  `adb devices` and `Get-Process qemu-system-x86_64-headless` (pid 10828,
  420s CPU), 21:47*
- `pubspec.yaml` already declares sqflite, path, intl, and sqflite_common_ffi
  (dev) — *source: read of `finance_tracker/pubspec.yaml`*
- The teammate's tests bootstrap `sqfliteFfiInit(); databaseFactory =
  databaseFactoryFfi;`, so they run on a test VM with no emulator — *source:
  read of `finance_tracker/test/database/database_helper_test.dart`*
- `SettingsDao.completeOnboarding({required double startingBalance, required
  double monthlyIncome})` — *source: `settings_dao.dart:45`*
- `Income.recurring` is a stored label that nothing acts on. The only
  occurrences are the schema column, the model's own field, and its
  copyWith/toMap/fromMap/toString — no query, no posting logic — *source:
  `grep -rn "recurring" /c/repo/finance-tracker/finance_tracker/lib/`, 8 hits,
  21:52*
- TrentonH3 has made no commits and pushed no branches; the only authors in
  the repository are Allen and Vathana, and `main` is the only remote branch —
  *source: `git log --all --format='%an' | sort -u` and `git branch -r`, 21:52*
- Trello is not referenced anywhere in the repository — *source:
  `grep -rin "trello" . --include=*.md`, no hits outside this file, 21:52*

## INFERRED

- The screens agent is still running — *settle with: the completion
  notification. Do NOT read its output file; it is the full JSONL transcript
  and will overflow context.*
- TrentonH3 owns reports, transaction history and theme — this was my reading
  of the task document, never confirmed by anyone — *settle with: ask*
- The PowerShell tool's "Access is denied" was the 24H2 upgrade settling — it
  failed for roughly ten minutes after the reboot and then worked — *settle
  with: if it recurs after the next reboot, it is not transient*

## Owed / open

- Five screens — the running agent; nothing else blocks on it
- Reports, transaction history, theme — TrentonH3; zero commits from them so
  far (verified above). With the deadline 2d19h out this is the single largest
  unstarted piece of the project.
- Demo video — Allen; not started
- Task list (Trello) — nobody has confirmed a board exists. Graded deliverable.
- Whether "no repeats" bars a repeat teammate — asked, never answered

## Details captured this session

- Thava1206 = Vathana Sovann, wrote `lib/database/` and `lib/models/`
- TrentonH3 — GitHub account has no display name set
- Owner ruling, verbatim: *"can we just kinda infer everything and shoot for
  it anyways"* — proceed on reasonable inference rather than asking
- Owner ruling, verbatim: *"add him to the github. we'll get the second person
  later"*, then later *"TrentonH3 is the other github user"*
- Money is stored as `double` in `Expense.amount` and `Income.amount`.
  Reported to the owner as a correctness risk, NOT fixed — it is the
  teammate's code and the working agreement forbids changing it.
- Do not touch `pubspec.yaml`: shared, and teammates are actively editing it

## Superseded by this handoff

- My earlier plan proposed designing a `FinanceRepository` contract plus an
  in-memory fake before anyone built screens. **That is retired.** Vathana's
  DAOs are the contract, they are merged to `main`, and they already answer
  the design questions the plan was going to settle. Still binding from that
  plan: build against the teammate's API, never change it.
- An earlier statement that the database layer lives on `origin/feat/database`
  is **no longer true** — that branch was deleted when PR #2 merged. The code
  is on `main`.

## Not done

- **Unaffordable:** the five screens (agent running), reports/history/theme
  (another person's lane), the demo video, the Trello board.
- **Uninformative — do not revisit:** design questions 1, 2, 3, 5 and 9 from
  the original plan (necessity on category vs expense, category picker
  required, where starting balance lives, delete-in-use behaviour, seeded
  default categories). The teammate's schema answers all five in code. Asking
  again would produce the same answers at the cost of a round trip.

## Traps for the successor

- **The Flutter app is in `finance_tracker/`, not the repo root.** Every
  flutter command must run from there or it fails looking for a pubspec. CI
  sets `defaults.run.working-directory` for exactly this reason.
- **A foreground subagent dies when the owner sends a message.** It becomes
  part of the turn, and a message interrupts the turn. Background anything
  that must survive a conversation.
- **Start the emulator headless.** With a window it sits on the owner's screen
  and he closes it, which looks like a crash from here.
- The owner's machine took a Windows 11 23H2 → 24H2 upgrade on 2026-09-12 and
  rebooted 2026-09-15 21:34. The PowerShell tool returned "Access is denied"
  for every command for about ten minutes afterwards, including `Get-Date`,
  while PowerShell invoked from Bash worked normally. It recovered on its own.
