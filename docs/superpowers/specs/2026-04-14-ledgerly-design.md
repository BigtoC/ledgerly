# Ledgerly — Expense Tracker App Design Spec

## Overview

Ledgerly is a local-first mobile expense tracker built with Flutter. It is aimed at people who want a private, non-gamified replacement for Fortune City-style manual logging without bank sync or setup-heavy finance workflows. The product promise for v1 is simple: log an expense or income in a few taps, review recent activity quickly, and keep the app understandable.

- **Platforms:** Android-first, iOS supported
- **Framework:** Flutter (latest stable)
- **Design system:** Material Design 3 with custom theming
- **Languages:** English, Traditional Chinese (zh-TW), Simplified Chinese (zh-CN)
- **Target user:** People who prefer manual expense tracking over automation-heavy finance apps
- **Product wedge:** Fast local-first entry with seeded defaults and no sign-in requirement
- **MVP non-goals:** Bank sync, recurring automation, credit-card payoff flows, account transfers, multi-currency, charts, budgets, cloud sync

---

## Phased Roadmap

### MVP
- Fast manual expense/income recording
- Seeded categories
- Optional custom categories
- Multiple manual accounts (cash, bank, other)
- Transaction memos
- Quick repeat / duplicate existing transaction
- Light/dark/system theme
- English, Traditional Chinese, Simplified Chinese UI

### Phase 2
- Recurring transactions
- Credit card accounts
- Account transfers / payoff flows
- Basic charts (pie, bar)
- Fortune City CSV import
- Transaction search
- Multi-currency support

### Phase 3
- Detailed monthly summary
- Budget management (weekly/monthly/yearly)
- Data export (CSV)
- Cloud backup & sync

### Future (Good to Have)
- App lock / password protection
- Home screen widgets

---

## Architecture

Use a simple feature-first Flutter architecture for MVP. Start from a standard `flutter create` scaffold and add only the layers required by the current app. Avoid repository interfaces and one-use-case-per-action abstractions until a second data source or sync backend exists.

```text
lib/
  app/
    app.dart                 # MaterialApp, routing, app bootstrap
    router.dart              # go_router configuration
    bootstrap.dart           # Database, providers, localization init
  core/
    l10n/
    theme/
      app_theme.dart
      color_schemes.dart
    storage/
      app_database.dart      # Drift database
      tables/
    utils/                   # Formatters, validators, date helpers
    preferences/
      app_preferences.dart   # Theme, locale, default account/currency
  features/
    home/
      home_screen.dart
      home_controller.dart
    transactions/
      transaction_form_screen.dart
      transaction_form_controller.dart
      transaction_queries.dart
    categories/
      categories_screen.dart
      categories_controller.dart
    accounts/
      accounts_screen.dart
      accounts_controller.dart
    settings/
      settings_screen.dart
test/
  unit/
    controllers/
    queries/
    utils/
  widget/
    screens/
    widgets/
  integration/
    flows/
l10n/
  app_en.arb
  app_zh_TW.arb
  app_zh_CN.arb
```

### Technology Stack

| Concern           | Technology                               |
|-------------------|------------------------------------------|
| App shell / state | Riverpod                                 |
| Local database    | Drift + drift_flutter                    |
| Navigation        | go_router                                |
| Data models       | Freezed + json_annotation                |
| i18n              | flutter_localizations + intl             |
| Code generation   | build_runner, drift_dev                  |
| UI components     | flutter_slidable, material_symbols_icons |
| Testing           | mocktail, Drift in-memory DB             |

---

## Database Schema

### MVP Currency Policy

MVP uses one app-wide currency stored in `user_preferences.default_currency`. All accounts and transactions use that single currency. Phase 2 multi-currency support will add per-account and per-transaction currency fields plus aggregation rules.

### transactions

| Column      | Type     | Constraints                    |
|-------------|----------|--------------------------------|
| id          | INTEGER  | PRIMARY KEY AUTO               |
| amount      | REAL     | NOT NULL                       |
| category_id | INTEGER  | NOT NULL REFERENCES categories |
| account_id  | INTEGER  | NOT NULL REFERENCES accounts   |
| memo        | TEXT     |                                |
| date        | DATETIME | NOT NULL                       |
| created_at  | DATETIME |                                |
| updated_at  | DATETIME |                                |

Note: Transaction type (expense/income) is derived from the linked category's `type` field. A category's `type` becomes immutable after the first transaction uses it, so historical transaction meaning cannot be changed later by editing the category.

### categories

| Column      | Type    | Constraints                            |
|-------------|---------|----------------------------------------|
| id          | INTEGER | PRIMARY KEY AUTO                       |
| l10n_key    | TEXT    | UNIQUE, nullable for custom categories |
| custom_name | TEXT    | nullable user override                 |
| icon        | TEXT    | NOT NULL                               |
| color       | INTEGER | NOT NULL                               |
| type        | TEXT    | NOT NULL — 'expense' or 'income'       |
| sort_order  | INTEGER |                                        |
| is_archived | BOOL    | DEFAULT false                          |

Notes:
- Seeded categories use `l10n_key` for stable identity and localized display.
- Renaming a seeded category writes `custom_name` but keeps `l10n_key`, so locale changes do not duplicate or orphan categories.
- Categories with existing transactions can be archived but not hard-deleted.
- Unused custom categories may be deleted.

### accounts

| Column          | Type    | Constraints                        |
|-----------------|---------|------------------------------------|
| id              | INTEGER | PRIMARY KEY AUTO                   |
| name            | TEXT    | NOT NULL                           |
| type            | TEXT    | NOT NULL — 'cash', 'bank', 'other' |
| opening_balance | REAL    | DEFAULT 0                          |
| icon            | TEXT    |                                    |
| color           | INTEGER |                                    |
| sort_order      | INTEGER |                                    |
| is_archived     | BOOL    | DEFAULT false                      |

Notes:
- Tracked balance is derived in queries: `opening_balance + income - expense` for transactions assigned to that account.
- Accounts with existing transactions can be archived but not hard-deleted.
- Transfers, reconciliation, and credit-card payoff flows are deferred to Phase 2.

### user_preferences

| Column | Type | Constraints  |
|--------|------|--------------|
| key    | TEXT | PRIMARY KEY  |
| value  | TEXT | JSON-encoded |

Stores theme preference (light/dark/system), default account, default currency, locale, and first-run state.

---

## Default Categories

### Expense Categories

| Category       | Subcategories                           |
|----------------|-----------------------------------------|
| Food           | Groceries, Restaurants                  |
| Drinks         | Coffee, Alcohol, Beverages              |
| Transportation | Gas, Public Transit, Taxi/Ride, Parking |
| Shopping       | Clothing, Household                     |
| Housing        | Rent, Utilities, Maintenance            |
| Entertainment  | Movies, Games, Subscriptions            |
| Medical        | Doctor, Pharmacy, Insurance             |
| Education      | Tuition, Books, Courses                 |
| Personal       | Haircut, Gym, Gifts                     |
| Travel         | Flights, Hotels, Activities             |
| 3C             | Phone, Computer, Gadgets                |
| Miscellaneous  | —                                       |
| Other          | —                                       |

### Income Categories

| Category     | Subcategories |
|--------------|---------------|
| Salary       | —             |
| Freelance    | —             |
| Investment   | —             |
| Gift         | —             |
| Other Income | —             |

Seeded categories use stable `l10n_key` values so locale changes do not create duplicate categories or break references. Users can rename any seeded category, create custom categories, archive seeded categories they do not use, and delete only unused custom categories.

---

## MVP Screens & User Flow

### Navigation

- Bottom navigation: Home, Accounts, Settings
- Home FAB opens Add Transaction
- Categories is a secondary management screen opened from Add/Edit Transaction or Settings > Manage Categories

### First-run Defaults

- On first launch, seed one `Cash` account with `opening_balance = 0` and all default categories
- `default_currency` starts from device locale and can be changed in Settings
- Home opens in an empty state with primary CTA `Log first transaction`
- Users can complete their first transaction without visiting Accounts, Categories, or Settings

### Screens

1. **Home Screen** — Compact summary strip (`Today expense`, `Today income`, `Month net`), daily transaction list grouped by date, newest first, empty-state CTA, FAB to add transaction
2. **Add/Edit Transaction** — Expense/Income segmented control, calculator-style keypad for amount, category picker (icon grid), account selector, date picker, memo field, save; delete only in edit mode
3. **Accounts Screen** — List accounts with tracked balances, add account, set default account, archive account
4. **Categories Screen** — List categories grouped by expense/income, add/edit/reorder/archive
5. **Settings Screen** — Theme toggle (light/dark/system), language selector, default account, default currency, manage categories

### Add/Edit Interaction Rules

- Expense is the default selection when opening from Home; users can switch to Income via a segmented control at the top
- Category picker shows all visible categories for the selected type in a single icon grid
- Default account uses the user's configured default account, otherwise the last used active account
- Date defaults to today
- Save stays disabled until amount is greater than zero and both category and account are selected
- Leaving with unsaved changes shows a confirm-discard dialog
- Save failure keeps the form open and shows an error snackbar; successful save returns to Home and places the new transaction at the top of the list

### Screen States

- **Home:** skeleton rows on cold start, `No transactions yet` empty state on first run, undo snackbar after delete
- **Add/Edit Transaction:** inline validation for missing amount/category/account, confirm-discard dialog, save-error snackbar
- **Accounts:** if no active account exists, show `Create account` CTA and block transaction save until one exists
- **Categories:** if a type has no visible categories, show `Create category` CTA; used categories can be archived but not deleted

### Primary User Flow (Recording an Expense)

```text
Home → tap FAB → Add Transaction screen
  → Expense selected by default
  → enter amount on calculator keypad
  → select category from icon grid
  → default account preselected, change if needed
  → date defaults to today, tap to change
  → optional: add memo
  → tap Save → returns to Home with new entry visible at the top
```

### Quick Repeat Flow

```text
Home → swipe or open overflow on an existing transaction → Duplicate
  → Add Transaction screen opens with copied type/category/account/memo/amount
  → user adjusts amount or date if needed
  → tap Save → returns to Home with the duplicate visible at the top
```

### Management Rules

- Used categories keep their current type forever; if a user needs a category under the opposite type, they create a new category instead
- Archived accounts and categories are hidden from pickers but remain visible in management screens and historical records
- MVP does not include pending recurring items, account transfers, or credit-card payoff flows

### UX Decisions

- Calculator-style keypad for amount entry — faster than keyboard, standard in finance apps
- Category picker as icon grid — visual, quick selection
- Home screen sorted newest-first by default
- Home summary stays a single compact strip, not a dashboard of generic metric cards
- Swipe-to-delete on transactions with undo snackbar

---

## Internationalization

Using Flutter's `intl` package with ARB files:

```text
l10n/
  app_en.arb            # English
  app_zh_TW.arb         # Traditional Chinese
  app_zh_CN.arb         # Simplified Chinese
```

Localized elements:
- All UI labels, buttons, messages
- Seeded category labels via `l10n_key`
- Date formats (locale-aware)
- Number/currency formats (locale-aware, using the single MVP default currency)

User-renamed categories are not auto-translated after rename; they display the user's chosen label in every locale.

---

## Theme

Material Design 3 with `ColorScheme.fromSeed()` for both light and dark variants.

- `core/theme/app_theme.dart` — defines `lightTheme` and `darkTheme` ThemeData
- `core/theme/color_schemes.dart` — custom ColorScheme definitions
- `core/preferences/app_preferences.dart` — persists user choice (light/dark/system)
- Theme preference stored in `user_preferences` table
- Riverpod provider watches preference and rebuilds MaterialApp on change

---

## Security & Privacy

- MVP is local-first and does not require sign-in or cloud services
- Sensitive data includes transactions, memos, account names, balances, and category names
- The Drift database lives inside the app sandbox. Before release, validate platform file-protection settings on both iOS and Android and do not write financial data to logs
- MVP stores no remote tokens. When future features introduce credentials or secrets, store them in secure storage rather than `user_preferences`
- App lock remains future work. MVP baseline relies on OS device security plus sandbox/file-protection settings rather than an in-app passcode
- Future CSV import/export must be explicit user actions with schema validation, size limits, malformed-row handling, formula escaping, and clear warnings that exported CSV files are portable unencrypted data
- Future cloud backup must define provider choice, authentication, encryption expectations, token storage, sync scope, and delete/restore behavior before implementation

---

## Testing Strategy

### Unit Tests (Core Focus)
- **Controllers/queries** — add/edit transaction validation, account balance derivation from `opening_balance`, Home summary calculations
- **Category rules** — archive/delete constraints, type immutability after first use, localized display label resolution from `l10n_key` + `custom_name`
- **Formatters/utils** — currency formatting using `default_currency`, locale-aware date helpers

### Widget Tests
- **Home screen** — first-run empty state, summary strip, transaction list rendering, delete undo snackbar
- **Add Transaction screen** — keypad input, expense/income toggle, category selection, validation, duplicate flow
- **Category/Account screens** — create, archive, reorder, empty-state CTAs
- **Settings screen** — theme, locale, and default-currency updates

### Integration Tests
- Full flow: first launch seeds defaults → add transaction → appears on Home → verify in DB
- Duplicate flow: duplicate existing transaction → edit amount/date → save → verify second row in DB
- Management flow: archive used category/account → hidden from pickers but still visible in history/management screens

### Key Testing Decisions
- Drift's in-memory database makes query and rules tests fast
- Riverpod's ProviderContainer overrides enable clean dependency injection in tests
- High coverage on the manual-entry loop, first-run flow, and archive/type rules; recurring, transfers, and multi-currency get dedicated coverage only when they enter scope in Phase 2
- `mocktail` for isolated controller tests where a full DB setup is unnecessary

---

## Dependencies

### Core

| Package                  | Purpose                          |
|--------------------------|----------------------------------|
| `flutter_riverpod`       | State management                 |
| `drift`                  | Database ORM                     |
| `drift_flutter`          | Flutter SQLite integration       |
| `path_provider`          | DB file path location            |
| `go_router`              | Navigation/routing               |
| `freezed_annotation`     | Immutable data model annotations |
| `json_annotation`        | JSON serialization annotations   |
| `flutter_localizations`  | i18n framework                   |
| `intl`                   | Localization utilities           |
| `flutter_slidable`       | Swipe actions on list items      |
| `material_symbols_icons` | MD3 icon set                     |

### Dev Dependencies

| Package             | Purpose                 |
|---------------------|-------------------------|
| `build_runner`      | Code generation runner  |
| `drift_dev`         | Drift code generation   |
| `freezed`           | Freezed code generation |
| `json_serializable` | JSON code generation    |
| `mocktail`          | Mocking for tests       |
| `flutter_lints`     | Static analysis         |

### Deferred (Not in MVP)

| Package                  | Phase            | Purpose                           |
|--------------------------|------------------|-----------------------------------|
| `fl_chart`               | Phase 2          | Charts and trend views            |
| `csv`                    | Phase 2 / 3      | CSV import and export             |
| Firebase/Supabase        | Phase 3          | Cloud backup & sync               |
| `flutter_secure_storage` | Phase 3 / Future | Sync credentials or other secrets |
| `local_auth`             | Future           | App lock                          |
