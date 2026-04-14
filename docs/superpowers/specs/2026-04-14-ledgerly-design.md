# Ledgerly — Expense Tracker App Design Spec

## Overview

Ledgerly is a mobile expense tracking app built with Flutter, inspired by Fortune City's core financial features (excluding gamification). The primary function is manual expense/income recording with a focus on speed, clarity, and extensibility.

- **Platforms:** Android-first, iOS supported
- **Framework:** Flutter (latest stable)
- **Design system:** Material Design 3 with custom theming
- **Languages:** English, Traditional Chinese (zh-TW), Simplified Chinese (zh-CN)

---

## Phased Roadmap

### MVP
- Expense/income recording
- Categories with subcategories
- Multiple accounts (cash, credit card, bank, other)
- Recurring expenses (pending confirmation flow)
- Transaction memos
- Light/dark/system theme

### Phase 2
- Basic charts (pie, bar)
- Fortune City CSV import
- Transaction search
- Multi-currency support

### Phase 3
- Basic monthly summary
- Budget management (weekly/monthly/yearly)
- Data export (CSV)
- Cloud backup & sync
- Wants vs. needs classification
- Blockchain transaction support

### Future (Good to Have)
- App lock / password protection
- Home screen widgets
- Smart Note (location-based suggestions)

---

## Architecture

Clean architecture with three layers:

```
lib/
  core/                    # Shared utilities, constants, extensions
    theme/
      app_theme.dart         # Light & dark ThemeData from seed color
      color_schemes.dart     # Custom ColorScheme definitions
    l10n/                    # Localization config
    utils/                   # Formatters (currency, date), validators
    constants/
    preferences/
      theme_preference.dart  # Persisted light/dark/system setting
  data/                    # Data layer
    database/              # Drift database, tables, DAOs
    repositories/          # Repository implementations
    models/                # Data models / DTOs
  domain/                  # Domain layer
    entities/              # Business objects (Transaction, Account, Category)
    repositories/          # Repository interfaces (abstract classes)
    usecases/              # Business logic (AddTransaction, GetRecurring, etc.)
  presentation/            # UI layer
    screens/               # Full screens (home, add_transaction, accounts, etc.)
    widgets/               # Reusable UI components
    providers/             # Riverpod providers
  app.dart                 # MaterialApp, routing, theme
  main.dart                # Entry point, initialization
test/
  unit/
    usecases/              # One test file per use case
    repositories/          # Repository tests with in-memory DB
    utils/                 # Formatter, validator tests
  widget/
    screens/               # Screen-level widget tests
    widgets/               # Reusable component tests
  integration/
    flows/                 # End-to-end user flows
l10n/
  app_en.arb
  app_zh_TW.arb
  app_zh_CN.arb
```

### Technology Stack

| Layer | Technology |
|-------|-----------|
| State management | Riverpod |
| Local database | Drift + drift_flutter |
| Navigation | go_router |
| Entities | Freezed + json_annotation |
| i18n | flutter_localizations + intl |
| Code generation | build_runner, drift_dev |
| UI components | flutter_slidable, material_symbols_icons |
| Testing | mocktail, Drift in-memory DB |

---

## Database Schema

### transactions

| Column | Type | Constraints |
|--------|------|------------|
| id | INTEGER | PRIMARY KEY AUTO |
| amount | REAL | NOT NULL |
| currency | TEXT | NOT NULL |
| category_id | INTEGER | REFERENCES categories |
| account_id | INTEGER | REFERENCES accounts |
| memo | TEXT | |
| date | DATETIME | NOT NULL |
| recurring_id | INTEGER | REFERENCES recurring_rules, nullable |
| created_at | DATETIME | |
| updated_at | DATETIME | |

Note: Transaction type (expense/income) is derived from the linked category's `type` field. No duplicate `type` column.

### categories

| Column | Type | Constraints |
|--------|------|------------|
| id | INTEGER | PRIMARY KEY AUTO |
| name | TEXT | NOT NULL |
| icon | TEXT | NOT NULL |
| color | INTEGER | NOT NULL |
| type | TEXT | NOT NULL — 'expense' or 'income' |
| parent_id | INTEGER | REFERENCES categories, nullable |
| sort_order | INTEGER | |
| is_default | BOOL | |

### accounts

| Column | Type | Constraints |
|--------|------|------------|
| id | INTEGER | PRIMARY KEY AUTO |
| name | TEXT | NOT NULL |
| type | TEXT | NOT NULL — 'cash', 'credit_card', 'bank', 'other' |
| balance | REAL | DEFAULT 0 |
| currency | TEXT | DEFAULT 'USD' |
| icon | TEXT | |
| color | INTEGER | |
| sort_order | INTEGER | |
| is_archived | BOOL | DEFAULT false |

Note: Future account types include 'crypto_wallet' for Phase 3 blockchain support.

### recurring_rules

| Column | Type | Constraints |
|--------|------|------------|
| id | INTEGER | PRIMARY KEY AUTO |
| amount | REAL | NOT NULL |
| currency | TEXT | NOT NULL |
| category_id | INTEGER | REFERENCES categories |
| account_id | INTEGER | REFERENCES accounts |
| memo | TEXT | |
| frequency | TEXT | NOT NULL — 'daily', 'weekly', 'monthly', 'yearly' |
| day_of_week | INTEGER | 1-7 for weekly rules |
| day_of_month | INTEGER | 1-31 for monthly rules |
| month_of_year | INTEGER | 1-12 for yearly rules |
| next_due_date | DATETIME | NOT NULL |
| is_active | BOOL | DEFAULT true |

No start/end dates. Rules are active until paused or deleted. Scheduling fields are frequency-specific:
- Daily: no additional fields
- Weekly: `day_of_week` (1=Monday to 7=Sunday)
- Monthly: `day_of_month` (handles short months gracefully)
- Yearly: `month_of_year` + `day_of_month`

### user_preferences

| Column | Type | Constraints |
|--------|------|------------|
| key | TEXT | PRIMARY KEY |
| value | TEXT | JSON-encoded |

Stores theme preference (light/dark/system), default account, default currency, locale, etc.

---

## Default Categories

### Expense Categories

| Category | Subcategories |
|----------|--------------|
| Food | Groceries, Restaurants |
| Drinks | Coffee, Alcohol, Beverages |
| Transportation | Gas, Public Transit, Taxi/Ride, Parking |
| Shopping | Clothing, Household |
| Housing | Rent, Utilities, Maintenance |
| Entertainment | Movies, Games, Subscriptions |
| Medical | Doctor, Pharmacy, Insurance |
| Education | Tuition, Books, Courses |
| Personal | Haircut, Gym, Gifts |
| Travel | Flights, Hotels, Activities |
| 3C | Phone, Computer, Gadgets |
| Miscellaneous | — |
| Other | — |

### Income Categories

| Category | Subcategories |
|----------|--------------|
| Salary | — |
| Freelance | — |
| Investment | — |
| Gift | — |
| Other Income | — |

All default categories are editable and deletable. Users can create custom categories and subcategories. Category names are localized for EN, zh-TW, zh-CN.

---

## MVP Screens & User Flow

### Screens

1. **Home Screen** — Daily transaction list grouped by date, total expense/income summary at top, FAB to add transaction, pending recurring items with distinct visual treatment
2. **Add/Edit Transaction** — Calculator-style keypad for amount, category picker (icon grid), account selector, date picker, memo field, save/delete
3. **Categories Screen** — List all categories grouped by expense/income, add/edit/reorder/delete, subcategory management
4. **Accounts Screen** — List all accounts with balances, add/edit/archive accounts
5. **Recurring Rules Screen** — List active/inactive rules, add/edit/delete, shows next due date
6. **Settings Screen** — Theme toggle (light/dark/system), language selector, default account, default currency

### Primary User Flow (Recording an Expense)

```
Home → tap FAB → Add Transaction screen
  → enter amount on calculator keypad
  → select category from icon grid
  → account auto-selected (default), tap to change
  → date defaults to today, tap to change
  → optional: add memo
  → tap Save → returns to Home with new entry visible
```

### Recurring Expense Flow

```
Recurring Rules → tap Add
  → same fields as Add Transaction
  → plus: frequency picker, day/date selection
  → Save → rule is active

On app open:
  → background check scans rules where next_due_date <= today
  → generates pending transactions (in memory, NOT in DB)
  → pending items shown on Home with distinct style
  → user taps Confirm → written to DB
  → user taps Dismiss → skipped, not recorded
  → user taps Edit → adjust fields, then confirm
  → next_due_date advances to next occurrence
```

### UX Decisions

- Calculator-style keypad for amount entry — faster than keyboard, standard in finance apps
- Category picker as icon grid — visual, quick selection
- Home screen sorted newest-first by default
- Swipe-to-delete on transactions with undo snackbar
- Pending recurring transactions have a distinct background/badge to differentiate from confirmed entries

---

## Internationalization

Using Flutter's `intl` package with ARB files:

```
l10n/
  app_en.arb            # English
  app_zh_TW.arb         # Traditional Chinese
  app_zh_CN.arb         # Simplified Chinese
```

Localized elements:
- All UI labels, buttons, messages
- Default category names
- Date formats (locale-aware)
- Number/currency formats (locale-aware)

---

## Theme

Material Design 3 with `ColorScheme.fromSeed()` for both light and dark variants.

- `core/theme/app_theme.dart` — defines `lightTheme` and `darkTheme` ThemeData
- `core/theme/color_schemes.dart` — custom ColorScheme definitions
- `core/preferences/theme_preference.dart` — persists user choice (light/dark/system)
- Theme preference stored in `user_preferences` table
- Riverpod provider watches preference and rebuilds MaterialApp on change

---

## Testing Strategy

### Unit Tests (Core Focus)
- **Use cases** — each use case tested independently with mocked repositories
- **Repositories** — tested against in-memory Drift database (no SQL mocking needed)
- **Recurring logic** — generation, scheduling, edge cases (month-end, leap year, short months)
- **Formatters/utils** — currency formatting, date helpers

### Widget Tests
- **Add Transaction screen** — keypad input, category selection, validation
- **Home screen** — transaction list rendering, pending recurring items
- **Category/Account screens** — CRUD flows

### Integration Tests
- Full flow: add transaction → appears on home → verify in DB
- Recurring flow: create rule → app open → pending shown → confirm → written to DB

### Key Testing Decisions
- Drift's in-memory database makes repository tests fast
- Riverpod's ProviderContainer overrides enable clean dependency injection in tests
- High coverage on use cases and recurring logic, lighter coverage on straightforward UI
- `mocktail` for mocking repository interfaces in use case tests

---

## Dependencies

### Core

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `drift` | Database ORM |
| `drift_flutter` | Flutter SQLite integration |
| `path_provider` | DB file path location |
| `go_router` | Navigation/routing |
| `freezed_annotation` | Immutable entity annotations |
| `json_annotation` | JSON serialization annotations |
| `flutter_localizations` | i18n framework |
| `intl` | Localization utilities |
| `flutter_slidable` | Swipe actions on list items |
| `material_symbols_icons` | MD3 icon set |

### Dev Dependencies

| Package | Purpose |
|---------|---------|
| `build_runner` | Code generation runner |
| `drift_dev` | Drift code generation |
| `freezed` | Freezed code generation |
| `json_serializable` | JSON code generation |
| `mocktail` | Mocking for tests |
| `flutter_lints` | Static analysis |

### Deferred (Not in MVP)

| Package | Phase | Purpose |
|---------|-------|---------|
| `fl_chart` | Phase 2 | Pie/bar charts |
| `csv` | Phase 2 | Fortune City CSV import |
| Firebase/Supabase | Phase 3 | Cloud backup |
| `local_auth` | Future | App lock |
| `geolocator` | Future | Smart Note |
