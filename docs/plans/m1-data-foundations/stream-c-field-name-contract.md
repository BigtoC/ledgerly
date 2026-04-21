# M1 — Field-Name Sync Contract (Drift ↔ Freezed)

**Owner:** Agent C (Contracts)
**Milestone:** M1 — Data foundations (`docs/plans/implementation-plan.md` §5, M1)
**Sibling specs:**
- Stream A: [`stream-a-drift-schema.md`](stream-a-drift-schema.md) — Drift tables, DAOs, `AppDatabase`.
- Stream B: [`stream-b-freezed-models.md`](stream-b-freezed-models.md) — Freezed domain models, enums, `LocaleService`.

**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md) — *Database Schema* lines **247–423** (column shapes); *Domain Models vs Drift Data Classes* lines **96–98** (why they're separate); *Money Storage Policy* lines **249–253**.

---

## 1. Purpose

This contract binds **three identifier spaces** that otherwise drift independently across a two-stream milestone:

1. Drift **SQL column names** (snake_case, persisted to disk and captured in `drift_schemas/drift_schema_v1.json`).
2. Drift **Dart getter names** on the generated data classes (`Currency`, `TransactionRow`, `CategoryRow`, `AccountRow`, `UserPreferenceRow`).
3. Freezed **domain-model field names** on `Currency`, `Transaction`, `Category`, `Account`.

Plus the **enum wire values** (`'expense'`, `'income'`) stored as `TEXT` in the DB.

Why it matters: `implementation-plan.md` §5 M1 — *"Agree field names between Drift tables and Freezed models on day 1. Without that, regeneration churn cascades into M2 formatters and M3 seeds."* A Dart-property rename in Stream A without a matching Freezed rename in Stream B breaks every M3 repository mapper; a seed-string rename breaks every round-trip of enum values through the DB.

**Change control.** This document, `stream-a-drift-schema.md`, `stream-b-freezed-models.md`, the affected Drift table, the affected Freezed model, and any M3 seed/repo/test code that references the renamed field **all change in one PR**. Unilateral renames are forbidden.

---

## 2. Naming conventions

| Layer                                                      | Rule                                                                                                                                                                                                                                                |
|------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Drift **Dart getter**                                      | `camelCase` (Drift default). Example: `amountMinorUnits`.                                                                                                                                                                                           |
| Drift **SQL column**                                       | `snake_case`. Drift derives this automatically from the getter, or we override with `.named('snake_case_name')` when the PRD pins the SQL spelling (see Stream A §2.2). Example: `amount_minor_units`.                                              |
| Freezed **field name**                                     | `camelCase`. **MUST byte-for-byte match the Drift getter** (so M3 repository mappers can use the same identifier on both sides of the `=`).                                                                                                         |
| Freezed **JSON key** (when `@JsonSerializable` is applied) | `camelCase` (the Dart field name). No `fieldRename` override. Backup/restore in Phase 3 consumes this; MVP has no JSON boundary that needs to match the SQL snake_case.                                                                             |
| **Enum wire value** (DB `TEXT`)                            | lowercase string, exact match to what M3 writes into the `TEXT` column. Declared on every Dart enum case via `@JsonValue('…')`. Example: `@JsonValue('expense') expense`.                                                                           |
| **Foreign-key fields**                                     | Freezed/Drift getter uses `…Id` suffix (`categoryId`, `accountId`, `parentId`). SQL column uses `…_id` (`category_id`, …). Drift `.references(Table, #id)` emits the SQL `REFERENCES` constraint.                                                   |
| **Currency FK — domain-model shape**                       | On the Freezed side, `Transaction.currency`, `Account.currency`, and `AccountType.defaultCurrency` use `Currency` / `Currency?` so render-time utilities have `symbol` and `decimals` together. Drift columns stay `TEXT` FKs regardless. See §9.1. |
| **Boolean columns**                                        | Named `is…` (`isToken`, `isArchived`). Drift default `false` where the PRD says `DEFAULT false`.                                                                                                                                                    |

**Drift `@DataClassName` convention** (Stream A §2 header): Drift data classes use the `…Row` suffix — `TransactionRow`, `CategoryRow`, `AccountRow`, `UserPreferenceRow` — to leave the unsuffixed names (`Transaction`, `Category`, `Account`) free for the Freezed domain models. `Currency` is shared unprefixed because the two classes never appear in the same file (only M3 repositories cross both sides, and they alias as needed).

---

## 3. Field-name matrix (MVP entities only)

Phase 2 columns (`exchange_rates.*`, `pending_transactions.*`, `wallet_addresses.*`, Phase 2 seed tokens) are **not in scope** for M1 and are deliberately omitted below. Each subsection quotes the PRD line range it mirrors.

### 3.1 `currencies` — PRD 259–273

| DB column (PRD) | Drift getter / Freezed field | Type (domain)              | Notes                                                                                     |
|-----------------|------------------------------|----------------------------|-------------------------------------------------------------------------------------------|
| `code`          | `code`                       | `String`                   | PRIMARY KEY. ISO 4217 for fiat; token symbol in Phase 2. No enum.                         |
| `decimals`      | `decimals`                   | `int`                      | SSOT for minor-unit scaling (2 USD / 0 JPY / 18 ETH). Never duplicated onto transactions. |
| `symbol`        | `symbol`                     | `String?`                  | Display symbol (`$`, `¥`, `NT$`, …).                                                      |
| `name_l10n_key` | `nameL10nKey`                | `String?`                  | Optional localized-name key.                                                              |
| `is_token`      | `isToken`                    | `bool` (`@Default(false)`) | DB default `false`. MVP never sets true.                                                  |
| `sort_order`    | `sortOrder`                  | `int?`                     | Order in pickers.                                                                         |

### 3.2 `transactions` — PRD 275–291

| DB column (PRD)      | Drift getter / Freezed field | Type (domain) | Notes                                                                                                                            |
|----------------------|------------------------------|---------------|----------------------------------------------------------------------------------------------------------------------------------|
| `id`                 | `id`                         | `int`         | PRIMARY KEY AUTOINCREMENT.                                                                                                       |
| `amount_minor_units` | `amountMinorUnits`           | `int`         | **Money**. Integer minor units — never `double`. SQL name pinned via `.named('amount_minor_units')`.                             |
| `currency`           | `currency`                   | `Currency`    | FK → `currencies.code`. Original transaction currency; Phase 2 conversion never overwrites. Drift column stays `TEXT`. See §9.1. |
| `category_id`        | `categoryId`                 | `int`         | FK → `categories.id`. Transaction type (expense/income) is derived from linked category.                                         |
| `account_id`         | `accountId`                  | `int`         | FK → `accounts.id`.                                                                                                              |
| `memo`               | `memo`                       | `String?`     | Optional free text.                                                                                                              |
| `date`               | `date`                       | `DateTime`    | User-supplied transaction date. See §5.                                                                                          |
| `created_at`         | `createdAt`                  | `DateTime`    | **NOT NULL.** Repository-populated at insert (M3). See §5 and §9.3.                                                              |
| `updated_at`         | `updatedAt`                  | `DateTime`    | **NOT NULL.** Repository-populated at insert; refreshed on every update (M3). See §5 and §9.3.                                   |

No `type` column — derived from `categories.type` (PRD 290).

### 3.3 `categories` — PRD 293–314

| DB column (PRD) | Drift getter / Freezed field | Type (domain)              | Notes                                                                                                                                         |
|-----------------|------------------------------|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `id`            | `id`                         | `int`                      | PRIMARY KEY AUTOINCREMENT.                                                                                                                    |
| `l10n_key`      | `l10nKey`                    | `String?`                  | UNIQUE (nullable). Stable identity for seeded rows.                                                                                           |
| `custom_name`   | `customName`                 | `String?`                  | User override. Renamed seeded row keeps `l10nKey`, writes `customName`.                                                                       |
| `icon`          | `icon`                       | `String`                   | Icon-registry key (`core/utils/icon_registry.dart`). Never `IconData`.                                                                        |
| `color`         | `color`                      | `int`                      | Index into `core/utils/color_palette.dart`. Never ARGB. Append-only.                                                                          |
| `type`          | `type`                       | `CategoryType` (domain)    | Freezed side holds enum; Drift side holds `String`. Wire values: §4. **Immutable after first referencing transaction** (repository rule, M3). |
| `parent_id`     | `parentId`                   | `int?`                     | Self-FK (nullable root). `REFERENCES categories(id)`.                                                                                         |
| `sort_order`    | `sortOrder`                  | `int?`                     |                                                                                                                                               |
| `is_archived`   | `isArchived`                 | `bool` (`@Default(false)`) | DB default `false`.                                                                                                                           |

### 3.4 `account_types` — PRD (new table, mirrors `categories` shape)

First-class table seeded with `accountType.cash` and `accountType.investment` by `l10n_key`; users may add custom rows. Same identity rules as `categories` (see §7).

| DB column (PRD)    | Drift getter / Freezed field | Type (domain)              | Notes                                                                                                                                                               |
|--------------------|------------------------------|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`               | `id`                         | `int`                      | PRIMARY KEY AUTOINCREMENT.                                                                                                                                          |
| `l10n_key`         | `l10nKey`                    | `String?`                  | UNIQUE (nullable). Stable identity for seeded rows. Seeded: `accountType.cash`, `accountType.investment`.                                                           |
| `custom_name`      | `customName`                 | `String?`                  | User override. Renamed seeded row keeps `l10nKey`, writes `customName`. No auto-translation after rename.                                                           |
| `default_currency` | `defaultCurrency`            | `Currency?`                | FK → `currencies.code`, nullable. Drift column stays `TEXT?`. Null = no preference — form falls back to `user_preferences.default_currency` then `'USD'`. See §9.1. |
| `icon`             | `icon`                       | `String`                   | Icon-registry key (`core/utils/icon_registry.dart`). NOT NULL. Never `IconData`.                                                                                    |
| `color`            | `color`                      | `int`                      | Index into `core/utils/color_palette.dart`. NOT NULL. Never ARGB. Append-only.                                                                                      |
| `sort_order`       | `sortOrder`                  | `int?`                     | Order in pickers.                                                                                                                                                   |
| `is_archived`      | `isArchived`                 | `bool` (`@Default(false)`) | DB default `false`. Archive-instead-of-delete when the row has linked accounts.                                                                                     |

### 3.5 `accounts` — PRD 315–334

| DB column (PRD)               | Drift getter / Freezed field | Type (domain)              | Notes                                                                                                                                                   |
|-------------------------------|------------------------------|----------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                          | `id`                         | `int`                      | PRIMARY KEY AUTOINCREMENT.                                                                                                                              |
| `name`                        | `name`                       | `String`                   | User-visible account name.                                                                                                                              |
| `account_type_id`             | `accountTypeId`              | `int`                      | **FK** → `account_types.id`, NOT NULL. Replaces the removed `accounts.type TEXT` column.                                                                |
| `currency`                    | `currency`                   | `Currency`                 | FK → `currencies.code`. New-account default currency chain: `account_types.default_currency` → `user_preferences.default_currency` → `'USD'`. See §9.1. |
| `opening_balance_minor_units` | `openingBalanceMinorUnits`   | `int` (`@Default(0)`)      | **Money**. Integer minor units — never `double`. SQL name pinned.                                                                                       |
| `icon`                        | `icon`                       | `String?`                  | Icon-registry key or null.                                                                                                                              |
| `color`                       | `color`                      | `int?`                     | Palette index or null.                                                                                                                                  |
| `sort_order`                  | `sortOrder`                  | `int?`                     |                                                                                                                                                         |
| `is_archived`                 | `isArchived`                 | `bool` (`@Default(false)`) | DB default `false`.                                                                                                                                     |

No `current_balance` / `tracked_balance` — derived from transactions (PRD 331). No `type` column — replaced by `account_type_id` FK to `account_types`.

### 3.6 `user_preferences` — PRD 401–414

| DB column (PRD) | Drift getter / Freezed field                       | Type (domain) | Notes                                                                                                                                                                                                                  |
|-----------------|----------------------------------------------------|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `key`           | Drift getter `key`. **No Freezed domain model.**   | `String`      | PRIMARY KEY. Known keys: `theme_mode`, `default_account_id`, `default_currency`, `locale`, `first_run_completed`, `splash_enabled`, `splash_start_date`, `splash_display_text`, `splash_button_label` (Stream A §2.5). |
| `value`         | Drift getter `value`. **No Freezed domain model.** | `String`      | **Always JSON-encoded, including scalars** (§9.4 RESOLVED). `true` stored as `"true"`, `"light"` stored as `"\"light\""`. Parsed by `UserPreferencesRepository` at M3 with a single `jsonDecode` path.                 |

Stream B deliberately omits a Freezed `UserPreference` model (Stream B §3.5). Typed accessors live on the M3 repository; this contract has nothing to bind on that table beyond the two raw column names.

### 3.7 Phase-2 tables — SKIP

Do **not** declare field names for these in M1. When Phase 2 lands, add them in a new contract document alongside the v2 schema bump.

| Table                   | Status           |
|-------------------------|------------------|
| `exchange_rates`        | SKIP — Phase 2   |
| `pending_transactions`  | SKIP — Phase 2   |
| `wallet_addresses`      | SKIP — Phase 2   |

---

## 4. Enum wire values

Enum cases are declared on the Freezed side (`lib/data/models/category.dart` — see Stream B §3.2). Drift stores the raw `String`. M3 repositories are the ONLY place that calls `CategoryType.values.byName(…)` / `@JsonValue` round-trips; a mismatch between the Dart-side `@JsonValue` and the string M3 writes is a silent bug that survives `flutter analyze`.

`AccountType` is **no longer a Dart enum** — account type is a first-class `account_types` row referenced by `accounts.account_type_id` (see §3.4). No enum wire values apply. `CategoryType` remains the only enum in this contract.

### 4.1 `CategoryType` — mirrors `categories.type` (`TEXT NOT NULL`)

| Dart case              | `@JsonValue(...)`       | DB-stored `TEXT` |
|------------------------|-------------------------|------------------|
| `CategoryType.expense` | `@JsonValue('expense')` | `'expense'`      |
| `CategoryType.income`  | `@JsonValue('income')`  | `'income'`       |

**Casing rule:** lowercase only. SCREAMING_SNAKE / PascalCase / hyphenated variants are forbidden (Stream B §9 open question 3). Once seeded rows exist (M3), these strings are **migration-locked** — a rename requires a schema version bump with a data-transform step, not a refactor.

---

## 5. Timestamps

Applies to: `transactions.created_at`, `transactions.updated_at`, `transactions.date`, and (Phase 2 only) `exchange_rates.fetched_at`, `wallet_addresses.created_at`, `wallet_addresses.last_sync_timestamp`. MVP contract is `transactions` only.

| Field       | Drift column type | SQL storage                        | Freezed type | Nullability (MVP) | Populated by                                                          |
|-------------|-------------------|------------------------------------|--------------|-------------------|-----------------------------------------------------------------------|
| `date`      | `DateTimeColumn`  | Drift default (Unix ms, `INTEGER`) | `DateTime`   | NOT NULL          | UI → controller → repository (user picks).                            |
| `createdAt` | `DateTimeColumn`  | Drift default (Unix ms, `INTEGER`) | `DateTime`   | **NOT NULL**      | **`TransactionRepository` at insert (M3).** Immutable across updates. |
| `updatedAt` | `DateTimeColumn`  | Drift default (Unix ms, `INTEGER`) | `DateTime`   | **NOT NULL**      | **`TransactionRepository` at insert and every update (M3).**          |

**Decision — storage mode:** use Drift's **default `INTEGER` (Unix millisecond)** encoding for `DateTimeColumn`. Rationale:
- Cheaper comparisons on the `transactions_date_idx` (Stream A §2.2) than `TEXT` ISO-8601.
- Drift 2.x default — no opt-in flag needed.
- Keeps persisted ordering/comparison cheap while leaving future export/backup format decisions outside M1.

**Decision — who writes `created_at` / `updated_at`:** the **repository**, not the DB. Resolves Stream A §10 Q4 and Stream B §9 Q7. Using Drift's `.clientDefault(() => DateTime.now())` was considered and rejected because:
- `clientDefault` does not fire on `UPDATE`, so `updatedAt` would go stale.
- Repository-level `DateTime.now()` is mockable via a `Clock`-style override in M3 tests; a DB-level default is not.

Consequence: Drift columns are **NOT NULL** (no `.nullable()`). Freezed fields are **required DateTime** (non-nullable). M3 tests assert: (a) both fields set on insert; (b) `updatedAt > createdAt` after any update; (c) `createdAt` is immutable across updates.

---

## 6. Money fields

Every monetary quantity in the MVP schema. Rule: **never rename to anything shorter.** Keeping `_minor_units` in the column name and `MinorUnits` in the Dart field is the *deliberate friction* that makes an accidental `double` jump out in code review and in the guardrail grep (`implementation-plan.md` §6 G4).

| Table / DB column                         | Drift getter / Freezed field | Type  | Status         |
|-------------------------------------------|------------------------------|-------|----------------|
| `transactions.amount_minor_units`         | `amountMinorUnits`           | `int` | MVP            |
| `accounts.opening_balance_minor_units`    | `openingBalanceMinorUnits`   | `int` | MVP            |
| `pending_transactions.amount_minor_units` | `amountMinorUnits`           | `int` | SKIP — Phase 2 |
| `exchange_rates.rate_numerator`           | `rateNumerator`              | `int` | SKIP — Phase 2 |
| `exchange_rates.rate_denominator`         | `rateDenominator`            | `int` | SKIP — Phase 2 |

**Non-negotiables:**
- `IntColumn` on the Drift side, `int` on the Freezed side. No `RealColumn`, no `double`, no `num`.
- SQL column names are pinned explicitly via `.named('amount_minor_units')` / `.named('opening_balance_minor_units')` (Stream A §2.2, §2.4) — migration tests compare SQL snapshots, so the snake_case spelling is part of the contract.
- Formatting (minor units → localized string) is the **exclusive** responsibility of `core/utils/money_formatter.dart` (M2). No widget, controller, or repository divides or multiplies by `10^decimals`. Dartdoc on each money field must cite `PRD.md` → *Money Storage Policy*.

---

## 7. Change-control protocol

Any column/field rename during implementation must ship as a **single PR** that updates **every** item in the list below. Partial PRs are not mergeable.

Required updates (all in one commit/PR):

1. **Drift table** (`lib/data/database/tables/<table>.dart`) — getter name and/or `.named(...)` SQL override.
2. **Freezed model** (`lib/data/models/<model>.dart`) — field name.
3. **This contract** (`docs/plans/m1-data-foundations/stream-c-field-name-contract.md`) — row in §3.
4. **Stream A spec** (`stream-a-drift-schema.md`) — §9.1 table.
5. **Stream B spec** (`stream-b-freezed-models.md`) — §3.x code block.
6. **M3 seed code** (when M3 exists) — seed SQL / Drift companions that construct the row.
7. **M3 repository** — mapper between `…Row` and Freezed model.
8. **Tests** — any test referencing the old name.
9. **`drift_schemas/drift_schema_v1.json`** — regenerated via `drift_dev schema dump` **only** if pre-merge to main. After merge, SQL column renames require a new `schemaVersion` and a new snapshot, never a rewrite.

**Identity rules for seeded rows.** The `account_types` table follows the same identity rules as `categories`: user renames write `custom_name` only, `l10n_key` is stable across locale changes, and seeded rows are resolved by `l10n_key` (not display name). Auto-translation is not applied after a rename.

**Forbidden operations:**

- **Drift rename without Freezed counterpart in the same commit.** Breaks the M3 mapper's identifier match and poisons `drift_schemas/` history if the snapshot is regenerated in isolation.
- **Wire-value rename after first seed.** Once M3 seeds currencies / categories, the enum wire strings (`'expense'`, `'income'`) are **migration-locked** — change only via `schemaVersion` bump + data transform.
- **`categories.type` rename after first referencing transaction exists in production.** PRD's category type-lock rule (lines 290–291, CLAUDE.md → Data-Model Invariants) makes this a data-integrity violation, not just a schema churn. Enforced in `CategoryRepository` at M3, but also forbidden at the contract level.
- **Adding a Freezed JSON `fieldRename`** (e.g. `@JsonKey(name: 'amount_minor_units')`). Breaks the rule in §2 that Freezed JSON key == Dart field name, and creates a second source of truth.

---

## 8. Drift-side constraints Stream B must honour

Copied / distilled from Stream A §2 and §9. Freezed nullability in Stream B's per-model code blocks must match the columns below.

### 8.1 NOT NULL columns (Freezed field MUST be non-nullable)

| Table              | Column               | Freezed field                                     |
|--------------------|----------------------|---------------------------------------------------|
| `currencies`       | `code`               | `Currency.code`                                   |
| `currencies`       | `decimals`           | `Currency.decimals`                               |
| `transactions`     | `amount_minor_units` | `Transaction.amountMinorUnits`                    |
| `transactions`     | `currency`           | `Transaction.currency`                            |
| `transactions`     | `category_id`        | `Transaction.categoryId`                          |
| `transactions`     | `account_id`         | `Transaction.accountId`                           |
| `transactions`     | `date`               | `Transaction.date`                                |
| `transactions`     | `created_at`         | `Transaction.createdAt`                           |
| `transactions`     | `updated_at`         | `Transaction.updatedAt`                           |
| `categories`       | `icon`               | `Category.icon`                                   |
| `categories`       | `color`              | `Category.color`                                  |
| `categories`       | `type`               | `Category.type` (enum `CategoryType`)             |
| `account_types`    | `icon`               | `AccountType.icon`                                |
| `account_types`    | `color`              | `AccountType.color`                               |
| `accounts`         | `name`               | `Account.name`                                    |
| `accounts`         | `account_type_id`    | `Account.accountTypeId` (FK → `account_types.id`) |
| `accounts`         | `currency`           | `Account.currency`                                |
| `user_preferences` | `key`, `value`       | N/A — repository-layer accessors                  |

### 8.2 Nullable columns (Freezed field MUST be nullable)

| Table           | Column                                                      | Freezed field                                                          |
|-----------------|-------------------------------------------------------------|------------------------------------------------------------------------|
| `currencies`    | `symbol`, `name_l10n_key`, `sort_order`                     | `Currency.symbol`, `.nameL10nKey`, `.sortOrder`                        |
| `transactions`  | `memo`                                                      | `Transaction.memo`                                                     |
| `categories`    | `l10n_key`, `custom_name`, `parent_id`, `sort_order`        | `Category.l10nKey`, `.customName`, `.parentId`, `.sortOrder`           |
| `account_types` | `l10n_key`, `custom_name`, `default_currency`, `sort_order` | `AccountType.l10nKey`, `.customName`, `.defaultCurrency`, `.sortOrder` |
| `accounts`      | `icon`, `color`, `sort_order`                               | `Account.icon`, `.color`, `.sortOrder`                                 |

### 8.3 Columns with defaults (Freezed uses `@Default(...)`)

| Table           | Column                        | Default | Freezed declaration                        |
|-----------------|-------------------------------|---------|--------------------------------------------|
| `currencies`    | `is_token`                    | `false` | `@Default(false) bool isToken`             |
| `categories`    | `is_archived`                 | `false` | `@Default(false) bool isArchived`          |
| `account_types` | `is_archived`                 | `false` | `@Default(false) bool isArchived`          |
| `accounts`      | `opening_balance_minor_units` | `0`     | `@Default(0) int openingBalanceMinorUnits` |
| `accounts`      | `is_archived`                 | `false` | `@Default(false) bool isArchived`          |

### 8.4 Unique / foreign-key constraints

| Constraint                        | Table.column                                                                              | Enforcement notes                                                                                                                                                    |
|-----------------------------------|-------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| PRIMARY KEY                       | `currencies.code`                                                                         | Natural PK. Drift `@override primaryKey => {code}` (Stream A §2.1).                                                                                                  |
| UNIQUE (nullable)                 | `categories.l10n_key`                                                                     | SQLite treats multiple NULLs as distinct → custom categories with `l10nKey = null` coexist. Freezed mirrors as `String?` (Stream A §2.3).                            |
| UNIQUE (nullable)                 | `account_types.l10n_key`                                                                  | Same NULL-distinct semantics as `categories.l10n_key`. Freezed mirrors as `String?`.                                                                                 |
| FK `REFERENCES currencies(code)`  | `transactions.currency`, `accounts.currency`, `account_types.default_currency` (nullable) | Fires only with `PRAGMA foreign_keys = ON` (set in `beforeOpen`). M3 repositories must handle FK-violation exceptions. `account_types.default_currency` is nullable. |
| FK `REFERENCES categories(id)`    | `transactions.category_id`, `categories.parent_id` (self-FK)                              | Self-FK allows nullable root (`parentId == null`).                                                                                                                   |
| FK `REFERENCES accounts(id)`      | `transactions.account_id`                                                                 |                                                                                                                                                                      |
| FK `REFERENCES account_types(id)` | `accounts.account_type_id`                                                                | NOT NULL. Every account must reference an `account_types` row (seeded or custom).                                                                                    |

### 8.5 Closed enum check in MVP

`categories.type` is a permanently closed two-value set in MVP, so Stream A v1 adds `CHECK(type IN ('expense','income'))` at the SQL level. Repositories still enforce the separate business rule that a category's type becomes immutable after first use. `accounts.type` was removed from the schema (replaced by the `accounts.account_type_id` FK), so its historical CHECK-constraint question no longer applies.

### 8.6 Indexes (informational, not binding on Stream B)

Listed for completeness — Stream B does not consume these, but M3 repository query shapes must not assume indexes other than these exist.

- `transactions_date_idx` on `date DESC`
- `transactions_account_idx` on `account_id`
- `transactions_category_idx` on `category_id`
- `accounts_account_type_idx` on `account_type_id`
- `categories_parent_idx` on `parent_id`
- Implicit index from `UNIQUE(l10n_key)` on `categories`

---

## 9. Open questions

Disagreements or ambiguities between Stream A and Stream B that required a human decision during authoring. The sibling specs reference the resolutions here.

### 9.1 `Transaction.currency` / `Account.currency` / `AccountType.defaultCurrency`

- **Stream A §10 Q1** originally raised the question.
- ✅ **RESOLVED — use `Currency` / `Currency?` on the domain-model side.** The M1 contract binds field names, nullability, and the fact that the DB columns remain `TEXT` FKs. Repository command signatures are outside this contract.

### 9.2 `categories.type` `CHECK` constraint

- **Stream A §10 Q3** asked whether to add a `CHECK (type IN ('expense','income'))`.
- **Stream B** keeps `CategoryType` as a closed two-case enum.
- ✅ **RESOLVED — add SQL `CHECK(type IN ('expense','income'))`, and `CategoryType` is locked to exactly `{expense, income}` forever.** Schema-level validation now matches the product-level invariant. `CategoryRepository` still enforces the separate type-lock-after-first-use rule. Phase 2 account transfers and wallet sync continue to model direction as expense/income from the tracked account/wallet's perspective: inflow = income, outflow = expense.

**RESOLVED — `accounts.type` CHECK constraint (obsolete).** Any prior open question from Stream A asking whether `accounts.type TEXT` should carry a `CHECK (type IN (...))` constraint is now moot: `accounts.type` was removed from the schema and replaced by the `accounts.account_type_id` FK into the first-class `account_types` table. Referential integrity is enforced by the FK, not a CHECK.

**RESOLVED — `AccountType` enum wire values (obsolete).** Any prior open question about `AccountType` Dart-enum wire values (`'cash'` / `'bank'` / `'other'` casing, set membership, third variant, etc.) is now moot: `AccountType` is a Freezed domain model mirroring the `account_types` table, not an enum. Identity for seeded rows is via `l10n_key` (§3.4, §7).

### 9.3 `transactions.created_at` / `updated_at` population

- **Stream A §10 Q4** asks whether Drift `.clientDefault` or the repository populates them.
- **Stream B §9 Q7** defers to the repository.
- ✅ **RESOLVED — repository populates; both columns are NOT NULL on both sides.** `TransactionRepository` sets `createdAt = updatedAt = DateTime.now()` on insert and refreshes only `updatedAt` on every update. Drift columns are **NOT NULL** (no `.nullable()`); Freezed fields are **required DateTime** (not nullable). PRD §275–291 updated to match. M3 tests assert: (a) both fields set on insert, (b) `updatedAt > createdAt` after any update, (c) `createdAt` immutable across updates.

### 9.4 `UserPreferences.value` encoding

- **Stream A §10 Q6** asks whether every value is JSON-encoded, even scalar bools/strings.
- **Stream B §3.5** defers typed accessors to M3 without specifying.
- ✅ **RESOLVED — (a) always JSON-encoded, including scalars.** Gives `UserPreferencesRepository` a single-code-path parser. `bool true` stored as `"true"`, `String "en_US"` stored as `"\"en_US\""` (JSON-quoted), `int 7` stored as `"7"`. Consequence: direct `sqlite3` inspection during debugging shows JSON-wrapped values — documented in the `user_preferences` table comment at M1 so a future maintainer opening `sqlite3` doesn't think it's a bug.

### 9.5 JSON serialization on the five Freezed models

- **Stream B §9 Q1** raised whether to include `fromJson` / `toJson` broadly in M1.
- **Stream A** takes no position because Drift has no JSON boundary here.
- ✅ **RESOLVED — defer JSON serialization.** M1 keeps the five models (`Currency`, `Transaction`, `Category`, `AccountType`, `Account`) as plain Freezed data classes. If backup/export lands later, that milestone can add `fromJson` / `toJson` with the then-current requirements instead of freezing a speculative JSON contract now.

### 9.6 Third `CategoryType` variant (`transfer`)

- **Stream B §9 Q2** says no — wait for Phase 2.
- **Stream A** only stores the raw string; silent on the enum shape.
- ✅ **RESOLVED — `CategoryType` is `{expense, income}` forever.** No `transfer` variant, now or ever. Phase 2 transfers and Phase 2 wallet sync model direction as expense/income from the tracked account/wallet's perspective (see §9.2 and PRD *transactions* notes). Exhaustive-switch sites across M5 widgets therefore handle exactly two cases, period.

### 9.7 Locale-based default currency owner

- **Stream B §9 Q5** originally proposed hard-coding `'USD'` in the stub.
- **Stream A** does not touch `LocaleService`.
- **Resolution (this contract):** **M1 exposes locale only.** `LocaleService` returns `deviceLocale`; the locale-to-currency lookup belongs to M3 seed / M4 bootstrap once the seeded currency list exists. This keeps M1 free of speculative default-currency policy.

### 9.8 Seeded `account_types` icon keys and palette indices

- The `account_types.icon` (NOT NULL `String`) and `account_types.color` (NOT NULL palette index) values for the two seeded rows (`accountType.cash`, `accountType.investment`) are **not fixed here**.
- **Open:** pick both in M2 when `core/utils/icon_registry.dart` and `core/utils/color_palette.dart` land, so the seeded icon keys are guaranteed to resolve and the palette indices point at real, appended entries.
- **Stream B and Stream C must not hard-code defaults** in the Freezed model, the Drift table, or this contract in the meantime. M3 seed code picks them up from the M2 registries.

### 9.9 Non-contradictions observed (for the record)

Stream A and Stream B **agree** on:

- Drift `@DataClassName` suffix convention: `…Row` on every Drift data class (`TransactionRow`, `CategoryRow`, `AccountTypeRow`, `AccountRow`, `UserPreferenceRow`) except `Currency`, which is unsuffixed because Stream B's Freezed `Currency` never coexists with it in the same file. Freezed-side names (`Transaction`, `Category`, `AccountType`, `Account`, `Currency`) are always unsuffixed. See Stream A §2 header and Stream B §8.2 item 3.
- Enum wire values `'expense'` / `'income'` — Stream A §9.2 vs. Stream B §3.2. (`AccountType` is no longer an enum; see §9.2 resolution.)
- Field-name matrix — Stream A §9.1 is the source of truth; Stream B §8.1 commits to it by reference.
- Money type (`int`) on both money columns — Stream A §7 vs. Stream B §2.2.
- No Freezed model for `user_preferences` — Stream A §3.5 & §9.1 last row vs. Stream B §3.5.
- No import of `package:drift/*` from `data/models/**` — implied by Stream A §3.6 return-type rule + `import_lint` from M0 vs. Stream B §2.1.
- `account_types` is first-class (new table), `accounts.type TEXT` is removed, `accounts.account_type_id` replaces it as a NOT NULL FK.

No **contradictions** were found between the two sibling docs; the open questions above are ambiguities or decisions deferred by one stream to the other, not disagreements. If a contradiction surfaces during implementation, update §9 with the specific file paths and line numbers so `/ce:review` can arbitrate.

---

*This contract's scope ends where M3's starts: once repository mappers ship, any field-level discrepancy between Drift and Freezed surfaces as a compile error inside the mapper — not in this document. Keep §3 and §4 current; everything else is commentary.*
