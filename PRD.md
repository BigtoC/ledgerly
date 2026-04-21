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
- Multiple manual accounts with user-extensible account types (Cash, Investment seeded; users can add more)
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

Ledgerly uses a strict 3-layer architecture: a **Data** layer (SSOT), an optional **Domain** layer (Phase 2 only, for orchestration across repositories), and a **UI** layer organized feature-first. Each layer may only communicate with the layer directly adjacent to it.

### Core Principles

- **Separation of Concerns** — UI rendering, business logic, and data access live in distinct layers
- **Single Source of Truth** — Repositories own all data; no other layer may mutate it
- **Unidirectional Data Flow** — State flows down (Data → UI), events flow up (UI → Data)
- **UI as a Function of State** — Every screen renders from an immutable state object; widgets never hold business state

### Layer Boundaries (Forbidden Imports)

| Layer                                        | May import                                                 | Must not import                                     |
|----------------------------------------------|------------------------------------------------------------|-----------------------------------------------------|
| Widgets (`features/*/*_screen.dart`)         | Own controller + UI primitives                             | Repositories, services, `AppDatabase`, Drift tables |
| Controllers (`features/*/*_controller.dart`) | Repositories, use cases, domain models                     | `AppDatabase`, services, Drift tables, DAOs         |
| Use Cases (`domain/*.dart`) — Phase 2        | Repositories, services, domain models                      | Controllers, widgets                                |
| Repositories (`data/repositories/*.dart`)    | Services, `AppDatabase`, DAOs, domain models               | Controllers, widgets, use cases                     |
| Services (`data/services/*.dart`)            | External SDKs only (Drift, Dio, flutter_secure_storage, …) | Upstream layers                                     |

These rules are enforced via `custom_lint` / `import_lint` entries in `analysis_options.yaml`.

### SSOT Rule

Only repositories write to the database or to external stores. Controllers and use cases invoke repository methods; they never construct `Insertable` rows, call `.insert()` on DAOs, or write to `flutter_secure_storage` directly.

### Controller Contract

Every controller exposes two surfaces:

- **State** — an immutable Freezed sealed union (e.g., `HomeState.loading | .empty | .data(...) | .error`)
- **Commands** — typed methods for user actions (`saveTransaction(...)`, `deleteTransaction(id)`, `duplicateTransaction(id)`)

Widgets read state and invoke commands. Widgets never mutate state directly and never perform data-layer work (grouping, formatting, aggregation) in `build()`.

### Controller Responsibilities

Controllers transform domain models into presentation-friendly state. For example, `HomeController` consumes `Stream<List<Transaction>>` from `TransactionRepository` and emits `HomeState.data(daysGroupedByDate, summariesByCurrency, pendingBadgeCount)` — the widget renders this without any further transformation.

### Domain Models vs Drift Data Classes

Drift generates data classes from each table definition; these stay **inside repositories only**. Repositories map Drift rows into Freezed domain models in `data/models/` and return those to controllers. This isolates the UI and domain layers from schema changes.

### Reactive Data Flow

Repositories expose `Stream<T>` for list queries (backed by Drift's `.watch()`). Controllers use `StreamNotifier` / `AsyncNotifier` from Riverpod so the UI reactively updates on insert/delete/edit without manual refresh.

### Folder Structure

```text
lib/
  app/
    app.dart                 # MaterialApp, root ProviderScope
    router.dart              # go_router configuration
    bootstrap.dart           # Async init sequence, provider overrides
  core/
    l10n/
    theme/
      app_theme.dart
      color_schemes.dart
    utils/
      money_formatter.dart
      icon_registry.dart
      color_palette.dart
      date_helpers.dart
  data/
    database/
      app_database.dart      # Drift database, schemaVersion, migrations
      tables/
        transactions_table.dart
        categories_table.dart
        account_types_table.dart
        accounts_table.dart
        currencies_table.dart
        user_preferences_table.dart
        pending_transactions_table.dart    # Phase 2
        wallet_addresses_table.dart        # Phase 2
        exchange_rates_table.dart          # Phase 2
      daos/
        transaction_dao.dart
        category_dao.dart
        account_type_dao.dart
        account_dao.dart
        currency_dao.dart
        user_preferences_dao.dart
        pending_transaction_dao.dart       # Phase 2
        wallet_address_dao.dart            # Phase 2
        exchange_rate_dao.dart             # Phase 2
    services/
      locale_service.dart
      ankr_service.dart                    # Phase 2
      exchange_rate_service.dart           # Phase 2
      secure_storage_service.dart          # Phase 2
    repositories/
      transaction_repository.dart
      category_repository.dart
      account_type_repository.dart
      account_repository.dart
      currency_repository.dart
      user_preferences_repository.dart
      pending_transaction_repository.dart  # Phase 2
      wallet_address_repository.dart       # Phase 2
      exchange_rate_repository.dart        # Phase 2
      api_key_repository.dart              # Phase 2
    models/                                # Freezed domain models
      transaction.dart
      category.dart
      account_type.dart
      account.dart
      currency.dart
      pending_transaction.dart             # Phase 2
      wallet_address.dart                  # Phase 2
      exchange_rate.dart                   # Phase 2
  domain/                                  # Phase 2 — use cases
    wallet_sync_use_case.dart
    approve_pending_transaction_use_case.dart
    reject_pending_transaction_use_case.dart
  features/
    splash/
      splash_screen.dart
      splash_controller.dart
      splash_state.dart
    home/
      home_screen.dart
      home_controller.dart
      home_state.dart
    transactions/
      transaction_form_screen.dart
      transaction_form_controller.dart
      transaction_form_state.dart
    pending_transactions/                  # Phase 2
      pending_transactions_screen.dart
      pending_transactions_controller.dart
      pending_transactions_state.dart
    categories/
      categories_screen.dart
      categories_controller.dart
      categories_state.dart
    accounts/
      accounts_screen.dart
      accounts_controller.dart
      accounts_state.dart
    wallets/                               # Phase 2
      wallets_screen.dart
      wallets_controller.dart
      wallets_state.dart
    settings/
      settings_screen.dart
      settings_controller.dart
      settings_state.dart
test/
  unit/
    services/
    repositories/
    use_cases/                             # Phase 2
    controllers/
    utils/
  widget/
  integration/
l10n/
  app_en.arb
  app_zh.arb            # Base Chinese fallback (required by flutter_localizations)
  app_zh_TW.arb
  app_zh_CN.arb
```

### Bootstrap Sequence

`app/bootstrap.dart` defines the ordered async init before `runApp`:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Open `AppDatabase` (async) — runs migrations if `schemaVersion` changed
3. Initialize `LocaleService`, resolve device locale for default-currency fallback
4. Read `user_preferences` table
5. First-run seed (if empty DB): seed `currencies`, default categories, default account types (Cash, Investment), one `Cash` account (of type `accountType.cash`), `default_currency` from device locale
6. Configure `ProviderScope` with overrides injecting the opened `AppDatabase` into `appDatabaseProvider`
7. `runApp(ProviderScope(overrides: [...], child: App()))`

### Technology Stack

| Concern           | Technology                                  |
|-------------------|---------------------------------------------|
| App shell / state | Riverpod + `riverpod_generator`             |
| Local database    | Drift + drift_flutter (per-entity DAOs)     |
| Navigation        | go_router (`StatefulShellRoute`)            |
| Domain models     | Freezed + json_annotation                   |
| i18n              | flutter_localizations + intl                |
| Code generation   | build_runner, drift_dev, riverpod_generator |
| UI components     | flutter_slidable, material_symbols_icons    |
| Native splash     | flutter_native_splash                       |
| Testing           | mocktail, Drift in-memory DB                |

---

## Database Schema

### Money Storage Policy

All monetary amounts are stored as **integer minor units** — the smallest indivisible unit of the currency: cents for USD (`2` decimals), yen for JPY (`0` decimals), wei for ETH (`18` decimals), and so on. Floating-point types are never used for money. This eliminates rounding drift across sums, monthly summaries, and long-lived balances, and gives Phase 2 tokens exact representation at 18 decimals.

Formatting to a decimal string happens only at the UI boundary via `core/utils/money_formatter.dart`, which divides by `10^currencies.decimals` and applies locale-aware grouping via `intl`'s `NumberFormat.currency`.

### MVP Currency Policy

MVP supports multi-currency accounts and transactions. `user_preferences.default_currency` is configurable and used as the default for new accounts, the first seeded account, and preferred display currency in Settings. MVP stores original amounts in the transaction's native currency without auto-conversion; mixed-currency summaries are grouped by currency. Phase 2 fetches currency prices and auto-converts balances, summaries, and charts into the user's default currency while preserving original amounts.

### currencies

| Column        | Type    | Constraints                                          |
|---------------|---------|------------------------------------------------------|
| code          | TEXT    | PRIMARY KEY — ISO 4217 for fiat, symbol for tokens   |
| decimals      | INTEGER | NOT NULL — 2 for USD, 0 for JPY, 18 for ETH/ERC-20   |
| symbol        | TEXT    | display symbol (`$`, `¥`, `NT$`, …)                  |
| name_l10n_key | TEXT    | optional, localized currency name key                |
| is_token      | BOOL    | DEFAULT false — flags Phase 2 crypto tokens          |
| sort_order    | INTEGER |                                                      |

Notes:
- Seeded at first launch with common fiat codes (USD, EUR, JPY, TWD, CNY, HKD, GBP). Phase 2 seeds token entries (ETH, USDC, USDT, …).
- `transactions.currency`, `accounts.currency`, and `pending_transactions.currency` are foreign keys to `currencies.code`.
- Single source of truth for how many minor units a currency has. Never duplicate `decimals` onto transaction rows.

### transactions

| Column             | Type     | Constraints                                 |
|--------------------|----------|---------------------------------------------|
| id                 | INTEGER  | PRIMARY KEY AUTO                            |
| amount_minor_units | INTEGER  | NOT NULL — see Money Storage Policy         |
| currency           | TEXT     | NOT NULL REFERENCES currencies(code)        |
| category_id        | INTEGER  | NOT NULL REFERENCES categories              |
| account_id         | INTEGER  | NOT NULL REFERENCES accounts                |
| memo               | TEXT     |                                             |
| date               | DATETIME | NOT NULL                                    |
| created_at         | DATETIME | NOT NULL — set by repository on insert      |
| updated_at         | DATETIME | NOT NULL — set by repository on insert and every update |

Notes:
- Transaction type (expense/income) is derived from the linked category's `type` field. A category's `type` becomes immutable after the first transaction uses it, so historical transaction meaning cannot be changed later by editing the category.
- **No third `type` value exists or will be added.** Phase 2 account transfers and wallet sync model direction as expense/income from the tracked account's (or wallet address's) perspective: inflow **into** the tracked account = **income**; outflow **out of** the tracked account = **expense**. An account-to-account transfer produces two transactions (expense on the source, income on the destination) linked by shared memo / timestamp — not a single `'transfer'` type.
- `currency` stores the original transaction currency. Phase 2 conversion never overwrites the original `amount_minor_units` or `currency`.
- `created_at` and `updated_at` are populated by `TransactionRepository`, not by the database. On insert, both are set to `DateTime.now()`. On every update, `updated_at` is refreshed to `DateTime.now()` and `created_at` is left unchanged.

### categories

| Column      | Type    | Constraints                            |
|-------------|---------|----------------------------------------|
| id          | INTEGER | PRIMARY KEY AUTO                       |
| l10n_key    | TEXT    | UNIQUE, nullable for custom categories |
| custom_name | TEXT    | nullable user override                 |
| icon        | TEXT    | NOT NULL — icon-registry string key    |
| color       | INTEGER | NOT NULL — index into `color_palette`  |
| type        | TEXT    | NOT NULL — 'expense' or 'income'       |
| parent_id   | INTEGER | REFERENCES categories, nullable        |
| sort_order  | INTEGER |                                        |
| is_archived | BOOL    | DEFAULT false                          |

Notes:
- Seeded categories use `l10n_key` for stable identity and localized display.
- Renaming a seeded category writes `custom_name` but keeps `l10n_key`, so locale changes do not duplicate or orphan categories.
- Categories with existing transactions can be archived but not hard-deleted.
- Unused custom categories may be deleted.
- `icon` is a string key resolved at render time via `core/utils/icon_registry.dart`; unknown keys fall back to a default icon.
- `color` is a fixed index into `core/utils/color_palette.dart`; indices are append-only across app versions.

### account_types

| Column           | Type    | Constraints                                      |
|------------------|---------|--------------------------------------------------|
| id               | INTEGER | PRIMARY KEY AUTO                                 |
| l10n_key         | TEXT    | UNIQUE, nullable for custom account types        |
| custom_name      | TEXT    | nullable user override                           |
| default_currency | TEXT    | nullable REFERENCES currencies(code)             |
| icon             | TEXT    | NOT NULL — icon-registry string key              |
| color            | INTEGER | NOT NULL — index into `color_palette`            |
| sort_order       | INTEGER |                                                  |
| is_archived      | BOOL    | DEFAULT false                                    |

Notes:
- Seeded account types use `l10n_key` for stable identity and localized display; custom account types set `custom_name` and leave `l10n_key` NULL.
- Renaming a seeded account type writes `custom_name` but keeps `l10n_key`, so locale changes do not duplicate or orphan types. Same pattern as `categories`.
- `default_currency` is used to pre-fill the currency when the user creates a new account of this type; falls back to `user_preferences.default_currency` when NULL. Users can still change the currency on any individual account.
- Account types with existing accounts can be archived but not hard-deleted. Unused custom account types may be deleted.
- `icon` and `color` follow the same indirection rules as `categories` — string key resolved via `icon_registry.dart`, integer index into the append-only `color_palette.dart`. Never raw `IconData` or ARGB.

### accounts

| Column                      | Type    | Constraints                           |
|-----------------------------|---------|---------------------------------------|
| id                          | INTEGER | PRIMARY KEY AUTO                      |
| name                        | TEXT    | NOT NULL                              |
| account_type_id             | INTEGER | NOT NULL REFERENCES account_types(id) |
| currency                    | TEXT    | NOT NULL REFERENCES currencies(code)  |
| opening_balance_minor_units | INTEGER | DEFAULT 0 — see Money Storage Policy  |
| icon                        | TEXT    |                                       |
| color                       | INTEGER |                                       |
| sort_order                  | INTEGER |                                       |
| is_archived                 | BOOL    | DEFAULT false                         |

Notes:
- New accounts default currency from `account_types.default_currency`; if NULL, fall back to `user_preferences.default_currency`. User can override on creation.
- `account_type_id` is required; archiving an account type does not cascade-archive accounts, but new-account creation hides archived types from the picker.
- Tracked balance is derived in the account's native currency from transactions assigned to that account.
- MVP Home and Accounts surfaces group totals by original currency. Phase 2 can also show auto-converted totals in `default_currency`.
- Accounts with existing transactions can be archived but not hard-deleted.
- Transfers, reconciliation, and credit-card payoff flows are deferred to Phase 2.

### exchange_rates (Phase 2)

| Column           | Type     | Constraints                          |
|------------------|----------|--------------------------------------|
| id               | INTEGER  | PRIMARY KEY AUTO                     |
| base_currency    | TEXT     | NOT NULL REFERENCES currencies(code) |
| quote_currency   | TEXT     | NOT NULL REFERENCES currencies(code) |
| rate_numerator   | INTEGER  | NOT NULL                             |
| rate_denominator | INTEGER  | NOT NULL                             |
| fetched_at       | DATETIME | NOT NULL                             |
| provider         | TEXT     | NOT NULL                             |

Notes:
- Rate is stored as an integer fraction (`numerator / denominator`) to preserve precision when applied to integer minor-unit amounts. Provider-native rate strings parse cleanly into this form.
- Original transaction and account amounts remain unchanged; conversion is additive display data.

### pending_transactions (Phase 2)

| Column             | Type     | Constraints                                                                         |
|--------------------|----------|-------------------------------------------------------------------------------------|
| id                 | INTEGER  | PRIMARY KEY AUTO                                                                    |
| source             | TEXT     | NOT NULL — 'blockchain', 'recurring'                                                |
| amount_minor_units | INTEGER  | NOT NULL — see Money Storage Policy                                                 |
| currency           | TEXT     | NOT NULL REFERENCES currencies(code)                                                |
| category_id        | INTEGER  | REFERENCES categories, nullable                                                     |
| account_id         | INTEGER  | NOT NULL REFERENCES accounts                                                        |
| memo               | TEXT     | nullable                                                                            |
| date               | DATETIME | NOT NULL                                                                            |
| fetched_at         | DATETIME | NOT NULL                                                                            |
| token_name         | TEXT     | nullable, blockchain-specific                                                       |
| token_symbol       | TEXT     | nullable, blockchain-specific                                                       |
| token_decimals     | INTEGER  | nullable, blockchain-specific (used before the token is registered in `currencies`) |
| contract_address   | TEXT     | nullable, blockchain-specific                                                       |
| from_address       | TEXT     | nullable, blockchain-specific                                                       |
| to_address         | TEXT     | nullable, blockchain-specific                                                       |
| tx_hash            | TEXT     | UNIQUE, nullable, blockchain-specific                                               |
| blockchain         | TEXT     | nullable, blockchain-specific                                                       |
| recurring_rule_id  | INTEGER  | REFERENCES recurring_rules, nullable                                                |

Note: `recurring_rules` table schema will be defined when recurring transactions are designed in Phase 2.

Notes:
- Universal staging table for auto-generated transactions from any source.
- Shared fields (`amount_minor_units`, `currency`, `category_id`, `account_id`, `memo`, `date`) are common to all sources.
- Blockchain fields populated only when `source = 'blockchain'`; `currency` usually comes from the token symbol / reviewed asset code, and `category_id` is nullable since user assigns it during review. If the token isn't yet in `currencies`, `token_decimals` carries the scaling factor until the token is registered.
- Recurring fields populated when `source = 'recurring'`; `category_id` and `currency` are pre-filled from the recurring rule.
- `tx_hash` UNIQUE constraint prevents blockchain duplicates.
- Approve: validate required fields, insert into `transactions` with original `currency` and `amount_minor_units`, delete from `pending_transactions`.
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

### Migration Strategy

- MVP ships with `schemaVersion = 1`. All MVP tables (`currencies`, `transactions`, `categories`, `accounts`, `user_preferences`) exist at v1.
- Phase 2 additions (`pending_transactions`, `wallet_addresses`, `exchange_rates`, plus token rows seeded into `currencies`) bump to `schemaVersion = 2` via `MigrationStrategy.onUpgrade`.
- Each schema version has a committed snapshot in `drift_schemas/` (generated via `drift_dev schema dump`).
- Migrations are tested by generating every historical schema and running the upgrade path on both an empty DB and a seeded DB (see Testing Strategy → Repository Tests).
- Breaking schema changes (column type swaps, table splits) require a new version + a documented data-transform step — never rewrite existing migrations in place.

---

## Default Categories

### Color Source — MD3 Baseline

All seeded colors (categories and account types) are picked from the **Material Design 3 baseline palettes** (https://m3.material.io/styles/color/static/baseline). The `core/utils/color_palette.dart` registry stores these as an append-only ordered `List<Color>`; `categories.color` and `account_types.color` are integer indices into that registry. New seeded categories or account types added later must also pick from the MD3 baseline — custom colors invented per-feature break the visual coherence of the app.

### Expense Categories

| Category       | Subcategories                           | Color (MD3 baseline)                                               |
|----------------|-----------------------------------------|--------------------------------------------------------------------|
| Food           | Groceries, Restaurants                  | Red 60 — `#B3251E`                                                 |
| Drinks         | Coffee, Alcohol, Beverages              | Green 40 — `#006C35`                                               |
| Transportation | Gas, Public Transit, Taxi/Ride, Parking | Cyan 70 — `#00BBDF`                                                |
| Shopping       | Clothing, Household                     | Purple 30 — `#5629A4`                                              |
| Housing        | Rent, Utilities, Maintenance            | Green 80 — `#80DA88`                                               |
| Entertainment  | Movies, Games, Subscriptions            | Orange 70 — `#FF8D41`                                              |
| Medical        | Doctor, Pharmacy, Insurance             | Red 50 — `#DB372D`                                                 |
| Education      | Tuition, Books, Courses                 | Purple 30 — `#5629A4`                                              |
| Personal       | Haircut, Gym, Gifts                     | Green 80 — `#80DA88`                                               |
| Travel         | Flights, Hotels, Activities             | Cyan 70 — `#00BBDF`                                                |
| 3C             | Phone, Computer, Gadgets                | Blue 30 — `#04409F`                                                |
| Miscellaneous  | —                                       | Neutral Variant 50 — `#79747E`                                     |
| Other          | —                                       | Neutral Variant 50 — `#79747E`                                     |

**Color reuse is intentional.** Transportation + Travel share Cyan 70; Shopping + Education share Purple 30; Housing + Personal share Green 80; Other + Miscellaneous share Neutral Variant 50. The `color_palette.dart` registry de-duplicates: each unique color occupies one index, and multiple `categories` rows can reference the same index.

### Income Categories

All seeded income categories share **Yellow 80 — `#FCBD00`**.

| Category     | Subcategories | Color (MD3 baseline)  |
|--------------|---------------|-----------------------|
| Salary       | —             | Yellow 80 — `#FCBD00` |
| Freelance    | —             | Yellow 80 — `#FCBD00` |
| Investment   | —             | Yellow 80 — `#FCBD00` |
| Gift         | —             | Yellow 80 — `#FCBD00` |
| Other Income | —             | Yellow 80 — `#FCBD00` |

Income vs expense is also disambiguated by the `+` / `-` amount sign in lists — color is a secondary cue.

Seeded categories use stable `l10n_key` values so locale changes do not create duplicate categories or break references. Users can rename any seeded category, create custom categories/subcategories, archive seeded categories they do not use, and delete only unused custom categories.

### Default Account Types

| Account Type | `l10n_key`               | Icon key        | Color (MD3 baseline)           | Default Currency                                 |
|--------------|--------------------------|-----------------|--------------------------------|--------------------------------------------------|
| Cash         | `accountType.cash`       | `'wallet'`      | Neutral Variant 70 — `#AEA9B4` | `user_preferences.default_currency` at seed time |
| Investment   | `accountType.investment` | `'trending_up'` | Neutral Variant 70 — `#AEA9B4` | `user_preferences.default_currency` at seed time |

Account type tiles deliberately use a shared neutral tint — account types are visually distinguished by their **icon**, not by color. Users creating custom account types can pick any other palette color if they want color-coded account types. Icon keys (`'wallet'`, `'trending_up'`) resolve via `core/utils/icon_registry.dart` at render time to `Symbols.wallet` and `Symbols.trending_up` from `material_symbols_icons`.

Seeded account types follow the same identity rules as seeded categories: `l10n_key` stays stable across renames; user renames write `custom_name` only. Users can add custom account types from the Accounts screen (name + icon + color + default currency). Archiving / deletion rules match categories: archive when referenced, hard-delete only when unused.

Phase 2 token wallets will be another account type (seeded when the wallet sync milestone lands) — the table shape above is forward-compatible.

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

The sync flow is implemented as `domain/wallet_sync_use_case.dart`, which orchestrates `AnkrService`, `WalletAddressRepository`, `TransactionRepository`, `PendingTransactionRepository`, and `CurrencyRepository` (to register unknown tokens on first sight). The `WalletsController` exposes a `sync()` command that invokes the use case and manages loading/error state only.

### Supported Chains

All chains supported by Ankr's `ankr_getTokenTransfers` endpoint: Arbitrum, Avalanche, Base, BSC, Ethereum, Fantom, Flare, Gnosis, Linea, Optimism, Polygon, Scroll, Stellar, Story, Syscoin, Taiko, Telos, Xai, X Layer, and associated testnets.

### Architecture

Direct API calls from the app to Ankr's JSON-RPC endpoint. No backend proxy. This preserves Ledgerly's local-first, no-sign-in philosophy. The Ankr API key is treated as a secret, wrapped by `SecureStorageService`, and accessed only through `ApiKeyRepository`.

### Wallet Management (Settings > Wallets)

- Add wallet: enter EVM address + optional label + select linked Ledgerly account
- List wallets with label, truncated address, linked account name
- Edit/delete wallets
- Each wallet shows last sync time

### Sync Flow

```text
App open (or manual refresh tap) → WalletsController.sync() → WalletSyncUseCase.execute()
  → for each wallet_address:
    → call AnkrService.getTokenTransfers(
        address: wallet.address,
        fromTimestamp: wallet.last_sync_timestamp ?? wallet.created_at,
        toTimestamp: now
      )
    → for each transfer:
      → skip if tx_hash already exists in pending_transactions or transactions
      → if token unknown, register it in `currencies` (is_token = true)
      → determine direction: `from_address = wallet` → expense (outflow); `to_address = wallet` → income (inflow). There is no `'transfer'` category type — the direction relative to the monitored wallet fully determines the transaction type.
      → insert into pending_transactions with source='blockchain', account_id from wallet, amount stored as integer minor units using token decimals
    → update wallet.last_sync_timestamp = now
```

**Trigger:** Auto-fetch on app open + manual refresh button. No background sync in Phase 2.

### Pending Transaction Review

- List all pending transactions, grouped by source
- Each row shows: amount, token symbol, chain, date, linked account
- User taps a pending transaction to: assign category + optional memo, then approve
- Swipe to reject (delete from pending)
- Bulk approve available for items that already have categories assigned

**Approve flow** — `ApprovePendingTransactionUseCase`: validate required fields (amount, category, account) → insert into `transactions` table (memo auto-generated from token/chain info if not provided) → delete from `pending_transactions`.

**Reject flow** — `RejectPendingTransactionUseCase`: delete from `pending_transactions`.

### API Key Management (Settings > Ankr API Key)

- Input field for Ankr API key
- Stored via `ApiKeyRepository` → `SecureStorageService` → `flutter_secure_storage`
- Wallet sync features disabled until key is provided
- Key is validated on save (test call to Ankr)

### Error Handling

- Network failure: show error snackbar, retain last successful sync timestamp
- Invalid API key: prompt user to re-enter
- Rate limit hit (30 req/min free tier): queue remaining wallets, retry after cooldown; retry logic lives in `WalletSyncUseCase`

---

## Routing Structure

Navigation uses `go_router` with a `StatefulShellRoute` for the bottom navigation, so Home / Accounts / Settings preserve independent state when switching tabs.

```text
/                           redirect → /splash if splash_enabled else /home
/splash                     Day counter screen
ShellRoute (bottom nav)
  /home                     Home tab
    /home/add               Add Transaction (modal push)
    /home/edit/:id          Edit Transaction (modal push)
    /home/pending           Pending Transactions (Phase 2)
  /accounts                 Accounts tab
    /accounts/new           New Account
    /accounts/:id           Edit Account
  /settings                 Settings tab
    /settings/categories    Manage Categories
    /settings/wallets       Wallet Management (Phase 2)
    /settings/ankr-key      Ankr API Key (Phase 2)
```

- Add/Edit Transaction is a full-screen modal push (`MaterialPage` / `CupertinoPage`) so the calculator keypad has full vertical space.
- Splash → Home transition uses a fade `CustomTransitionPage` to preserve the hnotes-style reveal.
- Root `redirect:` reads `splash_enabled` from `user_preferences`; no splash route is visited when disabled.

---

## MVP Screens & User Flow

### Navigation

- Bottom navigation on phone: Home, Accounts, Settings (switches to `NavigationRail` on ≥600dp — see Adaptive Layouts)
- Home FAB opens Add Transaction
- Categories is a secondary management screen opened from Add/Edit Transaction or Settings > Manage Categories
- Splash screen is the initial route when enabled (before bottom navigation)

### First-run Defaults

- On first launch, seed common fiat entries into `currencies`, all default account types (Cash, Investment), one `Cash` account (type = `accountType.cash`) with `opening_balance_minor_units = 0`, and all default categories
- `default_currency` starts from device locale (resolved via `LocaleService`), can be changed in Settings, and is used for new account defaults
- `splash_enabled = true` by default; first launch redirects to date picker before showing splash
- After splash, Home opens in an empty state with primary CTA `Log first transaction`
- Users can complete their first transaction without visiting Accounts, Categories, or Settings

### Screens

1. **Splash Screen** — Day counter with hnotes-style visual design, tap to enter Home
2. **Home Screen** — Compact summary strip grouped by currency in MVP (`Today expense`, `Today income`, `Month net` per currency); Phase 2 can also show auto-converted totals in `default_currency`, daily transaction list grouped by date, newest first, empty-state CTA, FAB to add transaction, pending transaction badge (Phase 2)
3. **Add/Edit Transaction** — Expense/Income segmented control, calculator-style keypad for amount, category picker (icon grid), account selector with currency indicator, date picker, memo field, save; delete only in edit mode
4. **Accounts Screen** — List accounts with tracked balances in native currency, add account (pick from existing account types or create a new type inline with name + icon + color + default currency), manage account types, set default account, archive account
5. **Categories Screen** — List categories grouped by expense/income, add/edit/reorder/archive, subcategory management
6. **Settings Screen** — Theme toggle (light/dark/system), language selector, default account, default currency, manage categories, splash screen settings
7. **Pending Transactions Screen** (Phase 2) — Review/approve/reject auto-generated transactions, accessible from Home badge and Settings
8. **Wallet Management Screen** (Phase 2) — Add/edit/delete wallet addresses, linked accounts
9. **Ankr API Key Screen** (Phase 2) — Enter/update API key stored via `ApiKeyRepository`

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
App open → WalletsController.sync() → auto-fetch transfers for all configured wallets
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

## Adaptive Layouts

Ledgerly is phone-first but must not break on larger form factors. A single breakpoint at **600dp** switches between compact and expanded layouts using `LayoutBuilder` at the shell level.

| Region               | <600dp (phone)        | ≥600dp (tablet/foldable)                       |
|----------------------|-----------------------|------------------------------------------------|
| Primary navigation   | `BottomNavigationBar` | `NavigationRail` (left)                        |
| Home                 | Single-pane list      | Two-pane: list left, selected-day detail right |
| Add/Edit Transaction | Full-screen modal     | Constrained dialog (max 560dp wide)            |
| Category picker      | Modal bottom sheet    | Side sheet                                     |

Orientation policy:
- Phone: portrait-primary; landscape allowed but not optimized (calculator keypad reflows)
- Tablet: both orientations supported via the adaptive breakpoint above

iOS safe-area and Android gesture insets are handled at the `Scaffold` level; no widget computes insets manually.

---

## Layout Primitives

The following screens have known unbounded-constraint or keyboard-interaction hazards. The PRD specifies the required widget structure to avoid them.

### Home screen

Use `CustomScrollView` with slivers to combine the summary strip and the infinite daily list without nesting a `ListView` inside a `Column`:

```text
CustomScrollView
  ├─ SliverToBoxAdapter  — currency-grouped summary strip
  ├─ SliverList          — day headers + transaction rows
  └─ SliverPadding       — bottom FAB clearance
```

### Add/Edit Transaction

Fixed calculator keypad pinned to the bottom, scrollable form above, keyboard does not cover the keypad:

```text
Scaffold(resizeToAvoidBottomInset: false)
  └─ SafeArea
      └─ Column
          ├─ Expanded → SingleChildScrollView (type toggle, amount display, category, account, date, memo)
          └─ CalculatorKeypad (fixed height)
```

### Category picker

Icon grid inside a modal bottom sheet; uses `SliverGrid` to lazily render with proper constraints:

```text
ModalBottomSheet
  └─ CustomScrollView
      ├─ SliverGrid      — top-level categories
      └─ SliverList      — subcategory expansion
```

### Constraint rule

All scrollable regions must survive a 2× text scale (`MediaQuery.textScalerOf`). Fixed-height widgets (keypad, day counter) declare a max-scale clamp or reflow into multiple lines.

---

## Icon & Color Registry

Categories store `icon` as a string key and `color` as a palette index. The actual `IconData` and `Color` values are resolved at render time from compile-time registries in `core/utils/`:

- `core/utils/icon_registry.dart` — `Map<String, IconData>` mapping string keys to `Symbols.*` from `material_symbols_icons`. Unknown keys fall back to `Symbols.category`.
- `core/utils/color_palette.dart` — ordered `List<Color>` of MD3-compatible category colors. `categories.color` is the index into this list. Palette additions append; existing indices never change.

This avoids storing raw `IconData` symbols or ARGB ints in the DB (both fragile across Flutter / Material updates) while keeping categories portable across future backup/restore.

---

## Error Handling Pattern

Errors propagate through the layers with typed boundaries:

- **Services** throw typed exceptions (`AnkrApiException`, `RateLimitException`, `DatabaseException`). No swallowing.
- **Repositories** either re-throw or wrap lower-layer exceptions; they never catch-and-return-null.
- **Use cases (Phase 2)** catch and translate to domain-level errors (`WalletSyncFailure.rateLimited`, `.network`, `.invalidKey`).
- **Controllers** use Riverpod's `AsyncValue<State>` at the boundary; errors become `AsyncError(error, stack)` which the widget renders as an error state.
- **Widgets** render three states (loading / data / error); errors surface via snackbar for recoverable actions (save failed) or a full-screen error state for unrecoverable reads.

No `try/catch` in widgets. No unhandled `Future` anywhere.

---

## Accessibility

- WCAG AA contrast for all text, including rainbow-gradient splash text and category tiles
- Minimum 48×48dp tap targets for FAB, swipe actions, category tiles, keypad keys
- `Semantics` labels on icon-only buttons (FAB, duplicate, delete, undo snackbar action)
- Dynamic text scaling respected up to 2×; splash day counter uses `AutoSizeText` or clamps at 1.5× to preserve layout
- `MediaQuery.boldText` respected in list rendering
- Screen reader order verified on Home and Add Transaction screens

---

## Pagination

MVP supports up to **10,000 transactions** rendered via Drift streams + `ListView.builder` (or slivers, per Layout Primitives). Beyond that, perceived scroll performance degrades because the full list is held in memory even though widgets render lazily.

- MVP: document the 10k cap; no pagination
- Phase 2: introduce cursor-based pagination in `TransactionRepository.watchPage(cursor, limit)` before the user-visible threshold is reached
- Phase 3: archive-to-cold-storage strategy tied to CSV export / cloud backup availability

This is an explicit decision; don't premature-optimize, but don't pretend the limit doesn't exist.

---

## Internationalization

Using Flutter's `intl` package with ARB files:

```text
l10n/
  app_en.arb            # English (template)
  app_zh.arb            # Base Chinese fallback — required because zh_CN / zh_TW
                        # include a country code; flutter_localizations demands a
                        # bare `zh` fallback or codegen fails.
  app_zh_TW.arb         # Traditional Chinese
  app_zh_CN.arb         # Simplified Chinese
```

Localized elements:
- All UI labels, buttons, messages
- Seeded category labels via `l10n_key`
- Date formats (locale-aware)
- Number/currency formats (locale-aware, using each transaction/account currency in MVP and default-currency conversion labels in Phase 2). All formatting funnels through `core/utils/money_formatter.dart`.
- Splash screen default display text and button label
- Pending transaction labels and review UI (Phase 2)
- Wallet management labels (Phase 2)

User-renamed categories are not auto-translated after rename; they display the user's chosen label in every locale. Custom splash display text and button labels are not auto-translated.

---

## Theme

Material Design 3 with `ColorScheme.fromSeed()` for both light and dark variants.

- `core/theme/app_theme.dart` — defines `lightTheme` and `darkTheme` ThemeData
- `core/theme/color_schemes.dart` — custom ColorScheme definitions
- Theme preference stored in `user_preferences` via `UserPreferencesRepository`
- A Riverpod provider watches the preference and rebuilds MaterialApp on change
- Splash screen respects current theme for native splash; day counter screen uses its own visual style (sun background, rainbow gradient) independent of theme

---

## Security & Privacy

- MVP is local-first and does not require sign-in or cloud services
- Sensitive data includes transactions, memos, account names, balances, category names, and wallet addresses (Phase 2)
- The Drift database lives inside the app sandbox. Before release, validate platform file-protection settings on both iOS and Android and do not write financial data to logs
- Phase 2 secret management:
  - `flutter_secure_storage` is wrapped by `SecureStorageService` in `data/services/`.
  - `ApiKeyRepository` is the only component that reads or writes the Ankr API key.
  - Controllers request the key via the repository; they never touch secure storage directly.
- Wallet addresses are stored in the local database only; no server-side storage
- MVP stores no remote tokens. Phase 2 introduces the Ankr API key as the first secret requiring secure storage.
- Phase 2 currency-price requests send currency pairs and conversion metadata only; they must not include user memos, categories, or other transaction text
- App lock remains future work. MVP baseline relies on OS device security plus sandbox/file-protection settings rather than an in-app passcode
- Future CSV import/export must be explicit user actions with schema validation, size limits, malformed-row handling, formula escaping, and clear warnings that exported CSV files are portable unencrypted data
- Future cloud backup must define provider choice, authentication, encryption expectations, token storage, sync scope, and delete/restore behavior before implementation

---

## Testing Strategy

Tests are organized by **architectural layer**, not by feature. This mirrors the implementation workflow and makes layer coverage gaps obvious.

### Service Tests (`test/unit/services/`)

- Primarily Phase 2: `AnkrService` response parsing, `ExchangeRateService` fetch + error shapes
- Mock `Dio` / HTTP client; assert raw JSON → typed return values
- `SecureStorageService` uses an in-memory fake implementation
- `AppDatabase` is not unit-tested directly; repositories exercise it via the in-memory Drift constructor

### Repository Tests (`test/unit/repositories/`)

- Use Drift's in-memory database
- Assert domain-model transformation (Drift row → Freezed model)
- Assert business rules: category type locking after first use, archive-instead-of-delete when referenced, currency FK integrity, integer minor-unit arithmetic
- Assert reactive streams emit on insert/update/delete
- Migration tests: run `MigrationStrategy.onUpgrade` from v1 → v2 on a seeded DB; assert data is intact and new columns have defaults

### Use Case Tests (`test/unit/use_cases/`) — Phase 2

- Mock repositories and services
- `WalletSyncUseCase`: happy path, duplicate tx_hash dedupe, partial failure (1 of N wallets fails), rate-limit retry, timestamp window correctness, auto-registration of unknown tokens
- `ApprovePendingTransactionUseCase`: insert-then-delete atomicity, missing-category rejection

### Controller Tests (`test/unit/controllers/`)

- Mock repositories (or use cases in Phase 2) via Riverpod `ProviderContainer` overrides
- Assert state transitions: loading → data, loading → error, command → new state
- Assert presentation transformation: grouping, summary aggregation, badge-count derivation

### Utility Tests (`test/unit/utils/`)

- `money_formatter` — correct minor-unit → display conversion per currency (USD cents, JPY zero-decimal, ETH wei), locale grouping
- `date_helpers` — day boundary math, locale-aware formatting
- Splash day count calculation, template variable substitution (`{days}`, `{date}`)

### Widget Tests (`test/widget/`)

- Override controller provider with a test double; assert rendering per state variant
- Golden tests for the splash screen (visual design is a product requirement)
- Home: first-run empty state, grouped-by-currency summary strip, delete-undo snackbar
- Add Transaction: keypad input, expense/income toggle, validation, duplicate flow
- Category/Account: create, archive, reorder, empty-state CTAs
- Settings: theme, locale, default-currency updates, splash settings
- Phase 2: pending badge, pending list approve/reject actions, wallet add/edit/delete

### Integration Tests (`test/integration/`)

- Full stack with in-memory Drift
- First launch → seed defaults → splash date picker → splash → Home → add transaction → verify DB row
- Subsequent launch with splash enabled: splash → Home
- Subsequent launch with splash disabled: straight to Home
- Duplicate flow: duplicate existing transaction → edit amount/date → save → verify second row in DB
- Multi-currency flow: create second account with different currency → add transactions → verify Home groups totals by currency
- Archive flow: archive used category/account → hidden from pickers but visible in management screens
- Phase 2: add wallet → sync → pending appears → approve → visible in Home
- Phase 2: reject pending → removed from pending, absent from transactions

### Key Testing Decisions

- Drift's in-memory database makes repository and rule tests fast
- Riverpod's `ProviderContainer` overrides provide clean DI at every layer
- `mocktail` for controller and use case tests where a full DB setup is unnecessary
- Ankr API calls mocked in all tests; no live API calls in the test suite
- Migration tests run against every committed schema snapshot in `drift_schemas/`

---

## Dependencies

Versions below are the tested resolvable set under Flutter **3.41.7** (Dart 3.11.5). Keep `pubspec.yaml` in sync with this table — any version bump needs to round-trip `flutter pub get` and `dart run build_runner build` before landing here.

### Core (MVP)

| Package                  | Version     | Purpose                                                                  |
|--------------------------|-------------|--------------------------------------------------------------------------|
| `flutter_riverpod`       | `^2.6.1`    | State management                                                         |
| `riverpod_annotation`    | `^2.6.1`    | Provider code-gen annotations                                            |
| `drift`                  | `^2.28.0`   | Database ORM                                                             |
| `drift_flutter`          | `^0.2.7`    | Flutter SQLite integration                                               |
| `path_provider`          | `^2.1.5`    | DB file path location                                                    |
| `go_router`              | `^17.2.1`   | Navigation/routing (`StatefulShellRoute`)                                |
| `freezed_annotation`     | `^3.0.0`    | Immutable data model annotations                                         |
| `json_annotation`        | `^4.9.0`    | JSON serialization annotations                                           |
| `flutter_localizations`  | sdk         | i18n framework                                                           |
| `intl`                   | `^0.20.2`   | Localization utilities + `NumberFormat`                                  |
| `flutter_slidable`       | `^4.0.3`    | Swipe actions on list items                                              |
| `material_symbols_icons` | `^4.2803.0` | MD3 icon set                                                             |
| `flutter_native_splash`  | `^2.4.4`    | Native pre-Flutter splash screen (dev-only import; see Dev Dependencies) |

### Phase 2 Additions

| Package                  | Version  | Purpose                                                       |
|--------------------------|----------|---------------------------------------------------------------|
| `flutter_secure_storage` | TBD      | Wrapped by `SecureStorageService` for Ankr API key            |
| `dio`                    | TBD      | HTTP client (wrapped by `AnkrService`, `ExchangeRateService`) |

Phase 2 versions are pinned when the milestone lands; do not pre-add to `pubspec.yaml`.

### Dev Dependencies

| Package                 | Version   | Purpose                                                                                                                                                               |
|-------------------------|-----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `build_runner`          | `^2.5.4`  | Code generation runner                                                                                                                                                |
| `drift_dev`             | `^2.28.0` | Drift code generation + schema dump                                                                                                                                   |
| `freezed`               | `^3.1.0`  | Freezed code generation                                                                                                                                               |
| `json_serializable`     | `^6.9.0`  | JSON code generation                                                                                                                                                  |
| `riverpod_generator`    | `^2.6.3`  | Riverpod code generation                                                                                                                                              |
| `custom_lint`           | `^0.7.6`  | Riverpod lint support                                                                                                                                                 |
| `riverpod_lint`         | `^2.6.5`  | Riverpod-specific lints                                                                                                                                               |
| `import_lint`           | `^0.1.6`  | Enforce layer-boundary rules — pinned to the 0.1.x line; see note                                                                                                     |
| `mocktail`              | `^1.0.4`  | Mocking for tests                                                                                                                                                     |
| `flutter_lints`         | `^6.0.0`  | Static analysis                                                                                                                                                       |
| `flutter_native_splash` | `^2.4.4`  | Splash asset codegen CLI (`dart run flutter_native_splash:create`); never imported at runtime, so it lives in dev deps even though it's listed under Core (MVP) above |

**`import_lint` version note.** `import_lint >=2.0.0` pulls `analyzer ^12.1.0`, which requires `meta ^1.18.0`. Flutter 3.41.7 pins `meta` to `1.17.0`, so 2.x is unresolvable. The 0.9.x–1.0.x line requires `analyzer ^5.2.0`, which conflicts with `freezed >=2.5.3`. Only `^0.1.6` resolves — it has no `analyzer` constraint. Revisit this pin when Flutter ships `meta 1.18+`; at that point pin `import_lint ^2.x` for the full layer-boundary rule set.

### Deferred (Not in MVP)

| Package           | Phase   | Purpose                           |
|-------------------|---------|-----------------------------------|
| `fl_chart`        | Phase 2 | Charts and trend views            |
| `csv`             | Phase 3 | CSV import and export             |
| Firebase/Supabase | Phase 3 | Cloud backup & sync               |
| `local_auth`      | Future  | App lock                          |
