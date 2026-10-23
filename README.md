# Ledgerly

Local-first Flutter expense tracker. Android-first, iOS supported. No bank
sync, no sign-in, no cloud required — all data lives on the device.

The authoritative spec is **[`PRD.md`](PRD.md)**. When this file and the
PRD disagree, the PRD wins. The milestone sequencing lives in
[`docs/plans/implementation-plan.md`](docs/plans/implementation-plan.md).

[![Check](https://github.com/BigtoC/ledgerly/actions/workflows/check.yml/badge.svg)](https://github.com/BigtoC/ledgerly/actions/workflows/check.yml)
[![Android release](https://github.com/BigtoC/ledgerly/actions/workflows/android-release.yml/badge.svg)](https://github.com/BigtoC/ledgerly/actions/workflows/android-release.yml)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/BigtoC/ledgerly)

## Status

**MVP complete.** All six feature slices (Splash, Home, Transactions,
Categories, Analysis, Settings) are on `main`, and several Phase 2 slices
have shipped on top of the MVP: recurring transactions + pending approval,
transaction search, extended multi-currency conversion with cached
exchange rates, charts (pie + daily bar with animations and interactive
selection), chart slice drill-down with per-slice item lists, and a
splash display-text redesign where the start date renders inline with
a rainbow gradient. The default template is now `On {date} start using
Ledgerly`, with multi-line display-text input in Settings and an
auto-prepend guarantee so the date is always visible on the splash even
if the user removes `{date}` from their template.

Drift schema is at **v5** (`exchange_rates` added in v5;
`recurring_rules` + `pending_transactions` added in v4). Snapshots are
committed under `drift_schemas/`.

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
- A customizable display text appears below the day count. The default is
  `On {date} start using Ledgerly`, where `{date}` renders inline with a
  rainbow gradient (the day count number, the rainbow date, and the rest
  of the text share one block). You can also use `{days}` to embed the
  current day count in your text.
- The display text supports multiple lines — press return inside the
  Settings field to break across lines.
- If you delete `{date}` from your custom template, Ledgerly automatically
  shows the date in front of your text so the start date is never hidden.
- Tap the enter button on the splash screen to continue to `Home`.
- You can turn the splash screen off if you prefer opening directly to `Home`.

#### Home

`Home` is your day-by-day overview.

- See the currently selected day's transactions.
- Review quick summary information for that day.
- Move backward or forward between days.
- Start adding a new transaction from the main flow.
- A pending-approval section appears when recurring rules have generated
  upcoming entries waiting for you to confirm or skip.
- A search affordance lets you find historical transactions by memo,
  category, or amount across the full history.

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

#### Analysis

`Analysis` visualizes how you spend.

- A pie chart breaks down expenses by category for the selected period.
- A daily bar chart shows day-over-day totals with smooth animations.
- Tap a pie slice or a legend row to drill into that category: the bar
  chart refilters and a per-slice list of matching transactions appears
  below the charts. Each row supports tap-to-edit and swipe-to-delete
  with a 4-second undo window.
- Multi-currency totals are converted using cached exchange rates; the
  app notifies you when it falls back to the last known rates older than
  about an hour.

#### Recurring transactions

`Settings > Recurring` lets you set up rules that pre-fill upcoming
transactions on a cadence (daily, weekly, monthly, etc.). Generated
entries land in the pending section on `Home` for approval — nothing is
written to your books until you accept. Skipping an occurrence rejects
that single date with a 4-second undo window; the parent rule keeps
running.

#### Shopping list

Quick-capture flow for groceries and errands. Add items as drafts in a
dedicated list, then convert each draft into a real transaction with the
amount and category locked in. Useful when you record purchases away
from the till and want to settle the books later.

#### Manage Accounts

Use `Settings > Manage Accounts` to organize where money is stored.

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
- Manage categories and accounts (with archive-instead-of-delete for
  history-backed records).
- Manage recurring transaction rules.
- Enable or disable the splash screen.
- Configure the splash day counter start date, the multi-line display
  text template (using `{date}` and `{days}` placeholders), and the
  enter button label.

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

### What Ledgerly does not do today

Ledgerly intentionally stays focused. The shipped product does **not**
include:

- bank sync
- sign-in or cloud backup
- budget planning
- crypto wallet sync (the `pending_transactions` table supports
  blockchain-source rows, but the sync flow and wallet management UI
  are not implemented)
- CSV import/export
- account transfers or credit-card payoff flows
- automatic categorization or AI memo suggestions

Charts, recurring transactions, and multi-currency conversion, which
were Phase 2 stretch goals, have now shipped. The app stays fast,
understandable, and centered on manual logging.

## Prerequisites

- Flutter 3.47+ (stable channel, Dart 3.13). `flutter --version` must run
  cleanly.
- For Android builds: JDK 17 or newer (CI uses Temurin 21) + Android SDK.
  The Gradle wrapper fetches Gradle 9.7.0; AGP 9.3.1 and Kotlin 2.4.21 are
  pinned in `android/settings.gradle.kts`. See
  [`docs/architecture/dependencies.md`](docs/architecture/dependencies.md#android-build-toolchain).
- For iOS builds: Xcode 15+ and CocoaPods.

## Common commands

```bash
flutter pub get                                     # resolve packages
flutter run                                         # device/emulator
dart analyze --fatal-infos                          # analyzer + flutter_lints + riverpod_lint (what CI runs)
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

## Website

```bash
corepack enable
yarn --cwd site install
yarn --cwd site dev
yarn --cwd site test
yarn --cwd site check
yarn --cwd site build
```

GitHub Pages deploys from `.github/workflows/github-pages.yml`. The public APK
download button on the site resolves the latest GitHub Release at Astro build
time and falls back to the Releases page when release metadata is unavailable.

## Project layout

```text
lib/
  app/        # bootstrap, router, MaterialApp, providers
  core/       # theme, utils (money_formatter, icon_registry, color_palette, date_helpers)
  data/       # database + tables, DAOs, services, repositories, Freezed models, use_cases
  features/
    splash/         # sun-themed splash with day count + inline rainbow {date}
    home/           # day-at-a-time list with summary strip, search, pending section
    transactions/   # add/edit form with calculator keypad
    categories/     # category list + form sheet with icon/color pickers
    analysis/       # charts (pie + bar with drill-down) + memo search
      charts/       # ChartsSection, pie/bar/legend/period/dimension/toggle widgets
      search/       # SearchBar-based transaction search + category detail
    accounts/       # account list + form (currency/type pickers; opened from Settings)
    recurring/      # recurring-rule list/form; generates pending approvals on Home
    shopping_list/  # draft-capture list that converts items into transactions
    settings/       # language, theme, defaults, splash + recurring entry points, about
l10n/         # Source ARB files (app_en, app_zh, app_zh_CN, app_zh_TW)
test/
  unit/       # services / repositories / controllers / utils
  widget/     # widget + golden tests (organized by feature)
  integration/
  support/    # shared in-memory DB + ProviderContainer fixtures
drift_schemas/ # Committed schema snapshots per schemaVersion (v1 – v5)
assets/
  splash/     # Sun-themed splash background image (shipped)
```

Cross-repository orchestration lives in `lib/data/use_cases/` (e.g.
`RecurringGenerationUseCase`). PRD reserves a dedicated `lib/domain/`
layer for further Phase 2/3 work; until then, use cases sit inside the
data layer alongside repositories.

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

`analysis_options.yaml` wires `flutter_lints` and the `riverpod_lint`
analysis-server plugin. CI enforces both with `dart analyze --fatal-infos`,
which waits for the plugin; `flutter analyze` does not wait and reports
riverpod_lint warnings only some of the time. The pinned
`import_lint ^0.1.6` reads its layer-boundary rules from
`import_analysis_options.yaml` at the repo root (separate file because
that version uses a regex schema, not the 2.x globs). CI runs it, but
0.1.6 does not currently enforce the rules: it matches them against
absolute paths, so no `^lib/...` rule fires, and it always exits 0.
Review is what keeps the layer boundaries today.

## Contributing

PRs must be green on `.github/workflows/check.yml` (analysis, lint,
codegen, tests, Android debug build). The iOS debug build in
`.github/workflows/ios-nightly.yml` runs on PRs that change `pubspec.yaml`,
`pubspec.lock` or `ios/`, and on demand. It is not scheduled. The website has its own
`.github/workflows/site-check.yml`; release artifacts ship through
`.github/workflows/android-release.yml`.

## Reference:
- Color codes: https://m3.material.io/styles/color/static/baseline#c9263303-f4ef-4a33-ad57-7d91dc736b6b
