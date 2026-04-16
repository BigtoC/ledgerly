# Ledgerly — Expense Tracker App PRD

## Overview

Ledgerly is a local-first mobile expense tracker built with Flutter. It is aimed at people who want a private, non-gamified replacement for Fortune City-style manual logging without bank sync or setup-heavy finance workflows. The product promise for v1 is simple: log an expense or income in a few taps, review recent activity quickly, and keep the app understandable.

- **Platforms:** Android-first, iOS supported
- **Framework:** Flutter (latest stable)
- **Design system:** Material Design 3 with custom theming
- **Languages:** English, Traditional Chinese (zh-TW), Simplified Chinese (zh-CN)
- **Target user:** People who prefer manual expense tracking over automation-heavy finance apps
- **Product wedge:** Fast local-first entry with seeded defaults and no sign-in requirement
- **MVP non-goals:** Bank sync, recurring automation, credit-card payoff flows, account transfers, automatic FX price fetching / auto-conversion, charts, budgets, cloud sync, wallet transaction sync

---

## Phased Roadmap

### MVP
- Fast manual expense/income recording
- Seeded categories with subcategories
- Optional custom categories and subcategories
- Multiple manual accounts (cash, bank, other)
- Base multi-currency support with configurable default currency
- Transaction memos
- Quick repeat / duplicate existing transaction
- Light/dark/system theme
- English, Traditional Chinese, Simplified Chinese UI
- **Splash screen with configurable day counter** — standalone feature, hnotes-style visual design

### Phase 2
- Recurring transactions (auto-generate pending transactions for user approval)
- Credit card accounts
- Account transfers / payoff flows
- Basic charts (pie, bar)
- Fortune City CSV import
- Transaction search
- Extended multi-currency — fetch currency prices and auto-convert balances, summaries, and charts to the user's default currency
- **Wallet transaction sync** — EVM wallet addresses linked to accounts, Ankr API integration, pending transaction review/approve/reject flow
- **Pending transaction management screen**

### Phase 3
- Detailed monthly summary
- Budget management (weekly/monthly/yearly)
- Data export (CSV)
- Cloud backup & sync

### Future (Good to Have)
- App lock / password protection
- Home screen widgets
- Background periodic wallet sync
- Address-level ignore rules for spam token transfers

---

## Architecture

Use a simple feature-first Flutter architecture for MVP. Start from a standard `flutter create` scaffold and add only the layers required by the current app. Avoid repository interfaces and one-use-case-per-action abstractions until a second data source or sync backend exists. Phase 2 adds small integration services for wallet sync and exchange-rate fetching without changing the overall feature-first structure.

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
    splash/
      splash_screen.dart
      splash_controller.dart
    home/
      home_screen.dart
      home_controller.dart
    transactions/
      transaction_form_screen.dart
      transaction_form_controller.dart
      transaction_queries.dart
    pending_transactions/        # Phase 2
      pending_transactions_screen.dart
      pending_transactions_controller.dart
    categories/
      categories_screen.dart
      categories_controller.dart
    accounts/
      accounts_screen.dart
      accounts_controller.dart
    wallets/                     # Phase 2
      wallets_screen.dart
      wallets_controller.dart
      ankr_service.dart
    exchange_rates/              # Phase 2
      exchange_rate_service.dart
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
| Native splash     | flutter_native_splash                    |
| Testing           | mocktail, Drift in-memory DB             |

---

## Database Schema

### MVP Currency Policy

MVP supports multi-currency accounts and transactions. `user_preferences.default_currency` is configurable and used as the default for new accounts, the first seeded account, and preferred display currency in Settings. MVP stores original amounts and currencies without auto-conversion; mixed-currency summaries are grouped by currency. Phase 2 fetches currency prices and auto-converts balances, summaries, and charts into the user's default currency while preserving original amounts.

### transactions

| Column      | Type     | Constraints                    |
|-------------|----------|--------------------------------|
| id          | INTEGER  | PRIMARY KEY AUTO               |
| amount      | REAL     | NOT NULL                       |
| currency    | TEXT     | NOT NULL                       |
| category_id | INTEGER  | NOT NULL REFERENCES categories |
| account_id  | INTEGER  | NOT NULL REFERENCES accounts   |
| memo        | TEXT     |                                |
| date        | DATETIME | NOT NULL                       |
| created_at  | DATETIME |                                |
| updated_at  | DATETIME |                                |

Note: Transaction type (expense/income) is derived from the linked category's `type` field. A category's `type` becomes immutable after the first transaction uses it, so historical transaction meaning cannot be changed later by editing the category.

Additional note: `currency` stores the original transaction currency. Phase 2 conversion never overwrites the original `amount` or `currency`.

### categories

| Column      | Type    | Constraints                            |
|-------------|---------|----------------------------------------|
| id          | INTEGER | PRIMARY KEY AUTO                       |
| l10n_key    | TEXT    | UNIQUE, nullable for custom categories |
| custom_name | TEXT    | nullable user override                 |
| icon        | TEXT    | NOT NULL                               |
| color       | INTEGER | NOT NULL                               |
| type        | TEXT    | NOT NULL — 'expense' or 'income'       |
| parent_id   | INTEGER | REFERENCES categories, nullable        |
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
| currency        | TEXT    | NOT NULL                           |
| opening_balance | REAL    | DEFAULT 0                          |
| icon            | TEXT    |                                    |
| color           | INTEGER |                                    |
| sort_order      | INTEGER |                                    |
| is_archived     | BOOL    | DEFAULT false                      |

Notes:
- New accounts default to `user_preferences.default_currency` but can be changed on creation.
- Tracked balance is derived in the account's native currency from transactions assigned to that account.
- MVP Home and Accounts surfaces group totals by original currency. Phase 2 can also show auto-converted totals in `default_currency`.
- Accounts with existing transactions can be archived but not hard-deleted.
- Transfers, reconciliation, and credit-card payoff flows are deferred to Phase 2.

### exchange_rates (Phase 2)

| Column         | Type     | Constraints         |
|----------------|----------|---------------------|
| id             | INTEGER  | PRIMARY KEY AUTO    |
| base_currency  | TEXT     | NOT NULL            |
| quote_currency | TEXT     | NOT NULL            |
| rate           | REAL     | NOT NULL            |
| fetched_at     | DATETIME | NOT NULL            |
| provider       | TEXT     | NOT NULL            |

Notes:
- Stores fetched currency prices / exchange rates used to auto-convert balances and summaries into `user_preferences.default_currency`.
- Original transaction and account amounts remain unchanged; conversion is additive display data.

### pending_transactions (Phase 2)

| Column            | Type     | Constraints                                |
|-------------------|----------|--------------------------------------------|
| id                | INTEGER  | PRIMARY KEY AUTO                           |
| source            | TEXT     | NOT NULL — 'blockchain', 'recurring'       |
| amount            | REAL     | NOT NULL                                   |
| currency          | TEXT     | NOT NULL                                   |
| category_id       | INTEGER  | REFERENCES categories, nullable            |
| account_id        | INTEGER  | NOT NULL REFERENCES accounts               |
| memo              | TEXT     | nullable                                   |
| date              | DATETIME | NOT NULL                                   |
| fetched_at        | DATETIME | NOT NULL                                   |
| token_name        | TEXT     | nullable, blockchain-specific              |
| token_symbol      | TEXT     | nullable, blockchain-specific              |
| token_decimals    | INTEGER  | nullable, blockchain-specific              |
| contract_address  | TEXT     | nullable, blockchain-specific              |
| from_address      | TEXT     | nullable, blockchain-specific              |
| to_address        | TEXT     | nullable, blockchain-specific              |
| tx_hash           | TEXT     | UNIQUE, nullable, blockchain-specific      |
| blockchain        | TEXT     | nullable, blockchain-specific              |
| recurring_rule_id | INTEGER  | REFERENCES recurring_rules, nullable       |

Note: `recurring_rules` table schema will be defined when recurring transactions are designed in Phase 2.

Notes:
- Universal staging table for auto-generated transactions from any source.
- Shared fields (`amount`, `currency`, `category_id`, `account_id`, `memo`, `date`) are common to all sources.
- Blockchain fields populated only when `source = 'blockchain'`; `currency` usually comes from the token symbol / reviewed asset code, and `category_id` is nullable since user assigns it during review.
- Recurring fields populated when `source = 'recurring'`; `category_id` and `currency` are pre-filled from the recurring rule.
- `tx_hash` UNIQUE constraint prevents blockchain duplicates.
- Approve: validate required fields, insert into `transactions` with original `currency`, delete from `pending_transactions`.
- Reject: delete from `pending_transactions`.

### wallet_addresses (Phase 2)

| Column               | Type     | Constraints                       |
|----------------------|----------|-----------------------------------|
| id                   | INTEGER  | PRIMARY KEY AUTO                  |
| address              | TEXT     | NOT NULL                          |
| label                | TEXT     | nullable (user-friendly name)     |
| account_id           | INTEGER  | NOT NULL REFERENCES accounts      |
| last_sync_timestamp  | INTEGER  | nullable (UNIX timestamp)         |
| created_at           | DATETIME | NOT NULL                          |

Notes:
- Each wallet is mapped to a specific Ledgerly account.
- `last_sync_timestamp` used as `fromTimestamp` in Ankr API calls to only fetch new transfers since last sync.

### user_preferences

| Column | Type | Constraints  |
|--------|------|--------------|
| key    | TEXT | PRIMARY KEY  |
| value  | TEXT | JSON-encoded |

Stores theme preference (light/dark/system), default account, default currency, locale, first-run state, and splash screen settings.

**Splash screen keys:**
- `splash_enabled` — bool, default true
- `splash_start_date` — ISO date string, nullable
- `splash_display_text` — string, default uses l10n template
- `splash_button_label` — string, default uses l10n "Enter"

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

Seeded categories use stable `l10n_key` values so locale changes do not create duplicate categories or break references. Users can rename any seeded category, create custom categories/subcategories, archive seeded categories they do not use, and delete only unused custom categories.

---

## Splash Screen (MVP)

### Overview

A standalone day counter feature inspired by [hnotes](https://github.com/BigtoC/hnotes), completely independent from expense tracking. Counts days since a user-configurable meaningful date and displays the count in an hnotes-style visual layout on app launch.

### Two-Stage Launch

1. **Native splash** (`flutter_native_splash`) — static themed screen shown while Flutter engine boots.
2. **Day counter screen** — dynamic Flutter screen shown after initialization, with the interactive day counter.

### Visual Design (hnotes style)

- Sun-themed background image
- Large day count number, prominent center (white, large font ~90)
- Rainbow-gradient text below showing the start date (locale-aware format)
- Customizable display text (default: localized "Since {date}" with `{date}` and `{days}` as template variables)
- Button at bottom to enter the app (default label: localized "Enter", customizable)
- Fade transition to Home on button tap

### Launch Flow

```text
App cold start
  → Native splash (flutter_native_splash) — static, shows during engine init
  → Flutter initializes
  → splash_enabled?
    → yes + date set → Day Counter screen → tap → Home
    → yes + no date → Date Picker → save → Day Counter screen → tap → Home
    → no → Home
```

### Settings

- "Show splash screen" toggle (default: on)
- "Start date" date picker (only visible when splash is enabled)
- "Display text" free text field (`{date}` and `{days}` as template variables)
- "Button label" free text field

### Localization

Day counter label, "Since {date}" default text, and "Enter" button label need entries in all three ARB files. Date formatted locale-aware using `intl`.

---

## Wallet Transaction Sync (Phase 2)

### Overview

Users add EVM wallet addresses, each linked to a Ledgerly account. The app fetches token transfers via [Ankr's Advanced Multichain API](https://www.ankr.com/docs/advanced-api/token-methods/#ankr_gettokentransfers) and creates pending transactions for user review.

### Supported Chains

All chains supported by Ankr's `ankr_getTokenTransfers` endpoint: Arbitrum, Avalanche, Base, BSC, Ethereum, Fantom, Flare, Gnosis, Linea, Optimism, Polygon, Scroll, Stellar, Story, Syscoin, Taiko, Telos, Xai, X Layer, and associated testnets.

### Architecture

Direct API calls from the app to Ankr's JSON-RPC endpoint. No backend proxy. This preserves Ledgerly's local-first, no-sign-in philosophy. The Ankr API key is treated as a secret and stored in `flutter_secure_storage`.

### Wallet Management (Settings > Wallets)

- Add wallet: enter EVM address + optional label + select linked Ledgerly account
- List wallets with label, truncated address, linked account name
- Edit/delete wallets
- Each wallet shows last sync time

### Sync Flow

```text
App open (or manual refresh tap)
  → for each wallet_address:
    → call ankr_getTokenTransfers(
        address: wallet.address,
        fromTimestamp: wallet.last_sync_timestamp ?? wallet.created_at,
        toTimestamp: now
      )
    → for each transfer:
      → skip if tx_hash already exists in pending_transactions or transactions
      → determine if expense (from_address = wallet) or income (to_address = wallet)
      → insert into pending_transactions with source='blockchain', account_id from wallet
    → update wallet.last_sync_timestamp = now
```

**Trigger:** Auto-fetch on app open + manual refresh button. No background sync in Phase 2.

### Pending Transaction Review

- List all pending transactions, grouped by source
- Each row shows: amount, token symbol, chain, date, linked account
- User taps a pending transaction to: assign category + optional memo, then approve
- Swipe to reject (delete from pending)
- Bulk approve available for items that already have categories assigned

**Approve flow:** Validate required fields (amount, category, account) → insert into `transactions` table (memo auto-generated from token/chain info if not provided) → delete from `pending_transactions`.

**Reject flow:** Delete from `pending_transactions`.

### API Key Management (Settings > Ankr API Key)

- Input field for Ankr API key
- Stored in `flutter_secure_storage`
- Wallet sync features disabled until key is provided
- Key is validated on save (test call to Ankr)

### Error Handling

- Network failure: show error snackbar, retain last successful sync timestamp
- Invalid API key: prompt user to re-enter
- Rate limit hit (30 req/min free tier): queue remaining wallets, retry after cooldown

---

## MVP Screens & User Flow

### Navigation

- Bottom navigation: Home, Accounts, Settings
- Home FAB opens Add Transaction
- Categories is a secondary management screen opened from Add/Edit Transaction or Settings > Manage Categories
- Splash screen is the initial route when enabled (before bottom navigation)

### First-run Defaults

- On first launch, seed one `Cash` account with `opening_balance = 0` and all default categories
- `default_currency` starts from device locale, can be changed in Settings, and is used for new account defaults
- `splash_enabled = true` by default; first launch redirects to date picker before showing splash
- After splash, Home opens in an empty state with primary CTA `Log first transaction`
- Users can complete their first transaction without visiting Accounts, Categories, or Settings

### Screens

1. **Splash Screen** — Day counter with hnotes-style visual design, tap to enter Home
2. **Home Screen** — Compact summary strip grouped by currency in MVP (`Today expense`, `Today income`, `Month net` per currency); Phase 2 can also show auto-converted totals in `default_currency`, daily transaction list grouped by date, newest first, empty-state CTA, FAB to add transaction, pending transaction badge (Phase 2)
3. **Add/Edit Transaction** — Expense/Income segmented control, calculator-style keypad for amount, category picker (icon grid), account selector with currency indicator, date picker, memo field, save; delete only in edit mode
4. **Accounts Screen** — List accounts with tracked balances in native currency, add account, set default account, archive account
5. **Categories Screen** — List categories grouped by expense/income, add/edit/reorder/archive, subcategory management
6. **Settings Screen** — Theme toggle (light/dark/system), language selector, default account, default currency, manage categories, splash screen settings
7. **Pending Transactions Screen** (Phase 2) — Review/approve/reject auto-generated transactions, accessible from Home badge and Settings
8. **Wallet Management Screen** (Phase 2) — Add/edit/delete wallet addresses, linked accounts
9. **Ankr API Key Screen** (Phase 2) — Enter/update API key stored in secure storage

### Add/Edit Interaction Rules

- Expense is the default selection when opening from Home; users can switch to Income via a segmented control at the top
- Category picker first shows top-level categories for the selected type; selecting a parent with children opens a subcategory sheet
- Default account uses the user's configured default account, otherwise the last used active account
- Transaction currency is inherited from the selected account and shown next to the amount; new accounts default to `default_currency`
- Date defaults to today
- Save stays disabled until amount is greater than zero and both category and account are selected
- Leaving with unsaved changes shows a confirm-discard dialog
- Save failure keeps the form open and shows an error snackbar; successful save returns to Home and places the new transaction at the top of the list

### Screen States

- **Splash:** shows day count when configured, date picker redirect when no start date set, skipped when disabled
- **Home:** skeleton rows on cold start, `No transactions yet` empty state on first run, grouped summary chips when multiple currencies are present, undo snackbar after delete, pending transaction badge (Phase 2)
- **Add/Edit Transaction:** inline validation for missing amount/category/account, confirm-discard dialog, save-error snackbar
- **Accounts:** if no active account exists, show `Create account` CTA and block transaction save until one exists
- **Categories:** if a type has no visible categories, show `Create category` CTA; used categories can be archived but not deleted
- **Pending Transactions (Phase 2):** list with approve/reject actions, empty state when no pending items, grouped by source

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

### Wallet Sync Flow (Phase 2)

```text
App open → auto-fetch transfers for all configured wallets
  → new transfers appear as pending transactions
  → user sees badge on Home → taps to open Pending Transactions screen
  → reviews each: assign category, optional memo → Approve
  → approved transaction appears in Home list under the linked account
  → unwanted transfers → swipe to Reject
```

### Management Rules

- Used categories keep their current type forever; if a user needs a category under the opposite type, they create a new category instead
- Archived accounts and categories are hidden from pickers but remain visible in management screens and historical records
- MVP does not include pending recurring items, account transfers, or credit-card payoff flows
- Wallet addresses can be deleted; associated pending transactions are also deleted, but approved transactions remain in the transactions table

### UX Decisions

- Calculator-style keypad for amount entry — faster than keyboard, standard in finance apps
- Category picker as icon grid — visual, quick selection
- Home screen sorted newest-first by default
- Home summary stays a single compact strip, not a dashboard of generic metric cards
- Swipe-to-delete on transactions with undo snackbar
- MVP summaries stay grouped by original currency; Phase 2 adds auto-converted totals in `default_currency` when rates are available
- Pending transactions as a separate review screen rather than inline with confirmed transactions — keeps the main transaction list clean

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
- Number/currency formats (locale-aware, using each transaction/account currency in MVP and default-currency conversion labels in Phase 2)
- Splash screen default display text and button label
- Pending transaction labels and review UI (Phase 2)
- Wallet management labels (Phase 2)

User-renamed categories are not auto-translated after rename; they display the user's chosen label in every locale. Custom splash display text and button labels are not auto-translated.

---

## Theme

Material Design 3 with `ColorScheme.fromSeed()` for both light and dark variants.

- `core/theme/app_theme.dart` — defines `lightTheme` and `darkTheme` ThemeData
- `core/theme/color_schemes.dart` — custom ColorScheme definitions
- `core/preferences/app_preferences.dart` — persists user choice (light/dark/system)
- Theme preference stored in `user_preferences` table
- Riverpod provider watches preference and rebuilds MaterialApp on change
- Splash screen respects current theme for native splash; day counter screen uses its own visual style (sun background, rainbow gradient) independent of theme

---

## Security & Privacy

- MVP is local-first and does not require sign-in or cloud services
- Sensitive data includes transactions, memos, account names, balances, category names, and wallet addresses (Phase 2)
- The Drift database lives inside the app sandbox. Before release, validate platform file-protection settings on both iOS and Android and do not write financial data to logs
- Ankr API key stored in `flutter_secure_storage`, never in `user_preferences` or logs (Phase 2)
- Wallet addresses are stored in the local database only; no server-side storage
- MVP stores no remote tokens. Phase 2 introduces the Ankr API key as the first secret requiring secure storage
- Phase 2 currency-price requests send currency pairs and conversion metadata only; they must not include user memos, categories, or other transaction text
- App lock remains future work. MVP baseline relies on OS device security plus sandbox/file-protection settings rather than an in-app passcode
- Future CSV import/export must be explicit user actions with schema validation, size limits, malformed-row handling, formula escaping, and clear warnings that exported CSV files are portable unencrypted data
- Future cloud backup must define provider choice, authentication, encryption expectations, token storage, sync scope, and delete/restore behavior before implementation

---

## Testing Strategy

### Unit Tests (Core Focus)
- **Controllers/queries** — add/edit transaction validation, account balance derivation in native currency, grouped Home summary calculations by currency, default-currency preference behavior
- **Category rules** — archive/delete constraints, type immutability after first use, localized display label resolution from `l10n_key` + `custom_name`
- **Formatters/utils** — currency formatting for account / transaction currencies, default-currency preference, locale-aware date helpers
- **Splash screen** — day count calculation from start date, preference read/write, template variable substitution (`{days}`, `{date}`)
- **FX conversion (Phase 2)** — exchange-rate fetch/caching, auto-conversion to `default_currency`, stale-rate fallback, grouped-vs-converted summary behavior
- **Wallet sync (Phase 2)** — Ankr response parsing, transfer-to-pending mapping, expense vs income detection (from/to address matching), timestamp window logic, duplicate tx_hash prevention
- **Pending transactions (Phase 2)** — approve flow (insert into transactions + delete from pending), reject flow, source-based grouping

### Widget Tests
- **Splash screen** — renders day count, respects enabled/disabled toggle, date picker flow on first config, fade transition
- **Home screen** — first-run empty state, grouped-by-currency summary strip in MVP, converted-summary state in Phase 2, transaction list rendering, delete undo snackbar, pending badge (Phase 2)
- **Add Transaction screen** — keypad input, expense/income toggle, category selection, validation, duplicate flow
- **Category/Account screens** — create, archive, reorder, empty-state CTAs
- **Settings screen** — theme, locale, default-currency updates, splash settings
- **Pending Transactions screen (Phase 2)** — list rendering, approve/reject actions, bulk approve, empty state
- **Wallet Management screen (Phase 2)** — add/edit/delete wallet, linked account display

### Integration Tests
- Full flow: first launch seeds defaults → date picker for splash → splash screen → add transaction → appears on Home → verify in DB
- Subsequent launch with splash enabled: splash → Home
- Subsequent launch with splash disabled: straight to Home
- Duplicate flow: duplicate existing transaction → edit amount/date → save → verify second row in DB
- Multi-currency flow: create second account with a different currency → add transactions in both accounts → verify Home groups totals by currency in MVP
- Management flow: archive used category/account → hidden from pickers but still visible in history/management screens
- **Phase 2:** add wallet → sync → pending transactions appear → approve → visible in Home transaction list
- **Phase 2:** reject pending transaction → removed from pending, not in transactions

### Key Testing Decisions
- Drift's in-memory database makes query and rules tests fast
- Riverpod's ProviderContainer overrides enable clean dependency injection in tests
- High coverage on the manual-entry loop, first-run flow, splash screen, and archive/type rules
- Wallet sync, pending transactions, recurring, transfers, and automatic FX conversion get dedicated coverage in Phase 2; base multi-currency coverage starts in MVP
- `mocktail` for isolated controller tests where a full DB setup is unnecessary
- Ankr API calls mocked in tests; no live API calls in test suite

---

## Dependencies

### Core (MVP)

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
| `flutter_native_splash`  | Native pre-Flutter splash screen |

### Phase 2 Additions

| Package                  | Purpose                                |
|--------------------------|----------------------------------------|
| `flutter_secure_storage` | Secure storage for Ankr API key        |
| `dio`                    | HTTP client for currency-price and Ankr API calls |

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

| Package           | Phase   | Purpose                           |
|-------------------|---------|-----------------------------------|
| `fl_chart`        | Phase 2 | Charts and trend views            |
| `csv`             | Phase 3 | CSV import and export             |
| Firebase/Supabase | Phase 3 | Cloud backup & sync               |
| `local_auth`      | Future  | App lock                          |
