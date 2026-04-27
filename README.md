# Ledgerly

Local-first Flutter expense tracker. Android-first, iOS supported. No bank
sync, no sign-in, no cloud required for the MVP.

The authoritative spec is **[`PRD.md`](PRD.md)**. When this file and the
PRD disagree, the PRD wins. The milestone sequencing lives in
[`docs/plans/implementation-plan.md`](docs/plans/implementation-plan.md).

## Status

M5 complete — all six feature slices (Splash, Home, Transactions, Categories,
Accounts, Settings) plus Wave 4 integration are on `main`. M6 (integration
polish, a11y, release prep) is next.

## User handbook

### What Ledgerly is

Ledgerly is a private, local-first expense tracker for people who want fast
manual bookkeeping without bank sync, sign-in, or cloud setup. The app is built
for quick daily logging: open it, record an expense or income in a few taps,
and review what happened today.

Ledgerly is a good fit if you want to:

- track personal spending manually
- separate money across multiple accounts
- log both expenses and income
- keep data on-device for the MVP
- use a lightweight app instead of a finance platform

### Core ideas

- **Local-first:** your data lives on the device in the MVP.
- **Fast entry:** categories, currencies, and a default cash account are seeded
  on first run so you can start immediately.
- **Simple structure:** transactions belong to an account, a category, and a
  currency.
- **Manual control:** nothing is imported automatically; you decide what gets
  recorded.

### First-time setup

On first launch, Ledgerly prepares the app with sensible defaults:

- a default account such as `Cash`
- seeded categories for common expense and income use cases
- a default currency based on the device locale
- your saved theme, language, and splash preferences when available

After setup, you can start recording transactions right away and adjust the
defaults later in `Settings`.

### Main screens

#### Splash screen and day counter

On launch, Ledgerly can show a standalone day counter before entering the main
app. This feature is independent of expense tracking: it counts the days since
a meaningful start date you choose, then displays the count in a sun-themed
visual layout.

- Use it to track a personal milestone, habit, relationship date, or any other
  date that matters to you.
- If the splash screen is enabled but no start date is set yet, Ledgerly asks
  you to choose one.
- Tap the enter button on the splash screen to continue to `Home`.
- You can turn the splash screen off if you prefer opening directly to `Home`.

#### Home

`Home` is your day-by-day overview.

- See the currently selected day's transactions.
- Review quick summary information for that day.
- Move backward or forward between days.
- Start adding a new transaction from the main flow.

#### Add / Edit Transaction

Use the transaction form to record money movement.

Typical flow:

1. Choose whether the entry is an expense or income.
2. Enter the amount.
3. Pick an account.
4. Pick a category.
5. Optionally add a memo.
6. Save the transaction.

You can also open an existing transaction to edit it or duplicate it for quick
repeat entry.

#### Accounts

Use `Accounts` to organize where money is stored.

- Create additional accounts beyond the default cash account.
- Assign an account type and currency.
- Keep historical integrity: accounts that already have transactions are kept
  for record history instead of being casually removed.

#### Categories

Use `Categories` to control how spending and income are classified.

- Start with seeded categories.
- Add your own custom categories.
- Rename categories to match your preferences.
- Archive used categories instead of deleting history-backed records.

#### Settings

Use `Settings` to personalize the app.

- Change theme mode.
- Change app language.
- Choose the default currency.
- Choose the default account.
- Enable or disable the splash screen.
- Configure the splash day counter start date, display text, and enter button
  label.

### Daily usage example

If you buy lunch with cash, a common flow looks like this:

1. Open Ledgerly.
2. Tap to add a transaction.
3. Enter the amount you spent.
4. Select your `Cash` account.
5. Choose a category such as food or dining.
6. Optionally type a memo like `Lunch`.
7. Save.

The entry then appears on `Home` for that day.

### What Ledgerly does not do in the MVP

Ledgerly intentionally stays focused. The MVP does **not** include:

- bank sync
- sign-in or cloud backup
- budget planning
- charts and analytics-heavy reporting
- recurring automation
- crypto wallet sync

That keeps the app fast, understandable, and centered on manual logging.

## Prerequisites

- Flutter (stable channel), Dart SDK `^3.11.5`. `flutter --version` must run
  cleanly.
- For Android builds: JDK 17 + Android SDK.
- For iOS builds: Xcode 15+ and CocoaPods.

## Common commands

```bash
flutter pub get                                     # resolve packages
flutter run                                         # device/emulator
flutter analyze                                     # custom_lint + riverpod_lint
dart run import_lint                                # enforce layer boundaries
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs
dart run drift_dev schema dump \
  lib/data/database/app_database.dart drift_schemas/
flutter test                                        # all tests
flutter test test/widget/smoke_test.dart            # single file
flutter test --name 'M0 smoke'                      # single group
dart format .
```

Regenerate code whenever a `@freezed`, `@riverpod`, or Drift
`@DriftDatabase` / `@DataClassName` annotation changes — the build fails
loudly if generated files are stale.

## Project layout

```text
lib/
  app/        # bootstrap, router, MaterialApp, providers
  core/       # theme, utils (money_formatter, icon_registry, color_palette, date_helpers)
  data/       # database + tables, DAOs, services, repositories, Freezed models
  features/
    splash/         # animated sun splash with day-count display
    home/           # day-at-a-time transaction list with summary strip
    transactions/   # add/edit form with calculator keypad
    categories/     # category list + form sheet with icon/color pickers
    accounts/       # account list + form with currency/type pickers
    settings/       # language, theme, default currency/account, splash toggle
l10n/         # Source ARB files (app_en, app_zh, app_zh_CN, app_zh_TW)
test/
  unit/       # services / repositories / controllers / utils
  widget/     # widget + golden tests
  integration/
drift_schemas/ # Committed schema snapshots per schemaVersion (v1, v2)
assets/
  splash/     # Splash assets (sun-themed asset lands in M6)
```

MVP has no `lib/domain/`; that directory is Phase 2 only, for use-case
orchestration across repositories.

## Architecture guardrails

Enforced combinations of lint + review + tests keep the layers honest. See
PRD → Architecture for the full table. Headlines:

- Only `data/repositories/*` write to Drift or `flutter_secure_storage`.
- Drift data classes stay inside repositories; they never escape into
  controllers or widgets.
- Controllers expose immutable Freezed state + typed commands. Widgets
  never call DAOs, never construct Drift `Insertable` rows, and never
  transform data inside `build()`.
- Money is stored as integer minor units end-to-end. `double` is only
  allowed inside `core/utils/money_formatter.dart`.

`analysis_options.yaml` wires `flutter_lints`, `custom_lint`,
`riverpod_lint`, and `import_lint`; CI fails any PR that violates the
layer-boundary rules.

## Contributing

PRs must be green on the CI workflow at `.github/workflows/ci.yml`
(analysis, lint, codegen, tests, Android debug build). iOS runs nightly
via `.github/workflows/ios-nightly.yml`.

## Reference:
- Color codes: https://m3.material.io/styles/color/static/baseline#c9263303-f4ef-4a33-ad57-7d91dc736b6b
