# M1 — Stream B: Freezed domain models + `LocaleService` stub

**Owner:** Agent B (Models)
**Milestone:** M1 — Data foundations (`docs/plans/implementation-plan.md` §5, M1)
**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md)
- Architecture → *Domain Models vs Drift Data Classes*: lines **96–98**
- Database Schema (for field shapes): `currencies` **259–273**, `transactions` **275–291**, `categories` **293–314**, `accounts` **315–334**
- *Money Storage Policy*: lines **249–253**
- *Bootstrap Sequence* (where `LocaleService` is called): lines **219–229**

**Sibling contract:** `docs/plans/m1-data-foundations/stream-c-field-name-contract.md` is the field-name contract for the Drift ↔ Freezed boundary. Stream A §9.1 records the Drift-side commitments that feed that contract.

**Stack:** `freezed ^3.1.0`, `freezed_annotation ^3.0.0`, `build_runner ^2.5.4`. Dart `^3.11.5`, Flutter `>=3.41.6`.

---

## 1. Scope & non-goals

### In scope (Stream B builds)
- `lib/data/models/transaction.dart` — Freezed `Transaction` domain model.
- `lib/data/models/category.dart` — Freezed `Category` domain model + `CategoryType` enum.
- `lib/data/models/account.dart` — Freezed `Account` domain model.
- `lib/data/models/account_type.dart` — Freezed `AccountType` domain model.
- `lib/data/models/currency.dart` — Freezed `Currency` domain model.
- `lib/data/services/locale_service.dart` — minimal `Platform.localeName` wrapper for the bootstrap seed path.
- Generated files (`*.freezed.dart`) committed alongside the hand-written sources.

### Out of scope (Stream B does NOT build)
- **Drift tables, DAOs, `AppDatabase`, `drift_schemas/drift_schema_v1.json`.** Those are Stream A's territory (§ stream-a-drift-schema.md §2–§5). Stream B must not import `package:drift/*` anywhere under `lib/data/models/`.
- **Repositories** (`lib/data/repositories/*`) → **M3**. Stream B does not write Drift → Freezed mappers; that is the repository's job (`PRD.md` lines 96–98: "Repositories map Drift rows into Freezed domain models in `data/models/` and return those to controllers").
- **Phase 2 models** (`pending_transaction.dart`, `wallet_address.dart`, `exchange_rate.dart`). Not declared, not imported.
- **`UserPreferences` Freezed model.** The preferences table is a generic KV store (`key`, `value` JSON); typed accessors live on `UserPreferencesRepository` at M3, not on a Freezed model (matches Stream A §3.6 and §9.1 last row).
- **Seed data.** Stream B exposes the types; M3 seeds rows through repositories.
- **`pubspec.yaml` edits.** All needed Freezed deps are already present from M0.

---

## 2. Domain-model design principles

1. **Framework-agnostic.** Files under `lib/data/models/` import `package:freezed_annotation/freezed_annotation.dart` plus sibling model files when needed for typed fields such as `Currency`. Forbidden imports: `package:drift/*`, `package:flutter/*`, `dart:ui`, `dart:io`. This keeps the models portable while still allowing domain-model composition. `import_lint` (M0) enforces the package-layer boundary at `data/models/**`.
2. **Money is `int` minor units, always.** Every `amountMinorUnits` / `openingBalanceMinorUnits` field is a plain `int`. The scaling factor is `Currency.decimals`; formatting happens in M2's `money_formatter` at the UI boundary. Dartdoc on each money field references `PRD.md` → *Money Storage Policy*.
3. **Enums are Dart `enum`s, never string literals in model code.** One enum ships in M1: `CategoryType { expense, income }`. Each value carries an explicit `@JsonValue('expense')`-style annotation so the JSON wire format matches the SQL wire format M3 writes to Drift `TEXT` columns. Stream A stores the raw string at the Drift layer (see Stream A §2.3); repositories call `CategoryType.values.byName(...)` / enhanced-enum helpers in M3. `AccountType` is **not** an enum — it is a first-class Freezed domain model backed by the `account_types` table (Stream A), mirroring the `Category` pattern (indirect icon string key + palette-index color, seeded rows identified by `l10n_key`, user-extensible).
4. **IDs are `int`.** Matches Drift autoincrement PKs (Stream A §2.2, §2.3, §2.4). `Currency` is the only exception — its PK is `code` (`String`), per Stream A §2.1 and §9.1.
5. **Relationships stay scalar unless the model needs an already-defined value object.** `Transaction.categoryId`, `Transaction.accountId`, and `Account.accountTypeId` remain scalar FKs. `Transaction.currency`, `Account.currency`, and `AccountType.defaultCurrency` are allowed to use nested `Currency` because `Currency` is itself an M1 domain model and M2 utilities need `symbol` plus `decimals` together. M1 fixes the domain-model field names and types; repository API details belong to M3.
6. **Immutability via Freezed.** All fields are `final`, generated via Freezed factory constructors. `copyWith`, `==`, `hashCode`, and `toString` are free.
7. **Nullability matches the Drift column.** Non-null Drift columns (PRD pk/NOT NULL) are non-null Freezed fields; nullable Drift columns are nullable Freezed fields. No defensive `''` / `-1` sentinels — an absent `memo` is `null`.
8. **Freezed 3.x syntax.** We use `@freezed abstract class X with _$X { factory X({...}) = _X; ... }` for plain data classes (no unions in M1). `sealed class` is reserved for controller state unions in M5; using `sealed` here is wrong because these models have exactly one shape each. See `~/.pub-cache/hosted/pub.dev/freezed-3.1.0/CHANGELOG.md` lines 39–200 for the 3.x model.

---

## 3. Per-model spec

Stream B's field names mirror Stream A §9.1 exactly. Type decisions per field are justified below each block.

### 3.1 `Currency` — `lib/data/models/currency.dart`

**PRD:** lines 259–273. **Stream A row class:** `Currency` (unprefixed — Stream A §2.1 note 2).
```dart
// lib/data/models/currency.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency.freezed.dart';

/// Currency descriptor. Mirrors `currencies` row (PRD.md 259–273).
/// `decimals` is the SSOT for minor-unit scaling (PRD.md Money Storage Policy).
@freezed
abstract class Currency with _$Currency {
  const factory Currency({
    required String code,          // PK. ISO 4217 for fiat, symbol for tokens.
    required int decimals,         // 2 for USD, 0 for JPY, 18 for ETH/ERC-20.
    String? symbol,                // '$', '¥', 'NT$', …
    String? nameL10nKey,           // sql: name_l10n_key
    @Default(false) bool isToken,  // Phase 2 token flag.
    int? sortOrder,
  }) = _Currency;

}
```

Notes:
- `code` is the domain identity — equality is driven by Freezed's value semantics, so two `Currency` values with the same `code` but different `sortOrder` are not equal. That is fine because the repository always hands out a single canonical row per code.
- `decimals` is `int`, not an enum. Ranges from 0 (JPY) to 18 (ETH); nothing else is valid, but the enforcement lives in `CurrencyRepository` at M3.
- **No `Currency` enum.** Keep the `String code` primitive: Phase 2 adds arbitrary token symbols and an enum would require a migration.

### 3.2 `Category` — `lib/data/models/category.dart`

**PRD:** lines 293–314. **Stream A row class:** `CategoryRow`.
```dart
// lib/data/models/category.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// Expense vs income. Wire values match `categories.type` TEXT column
/// (Stream A §2.3) — do not rename without a schema migration.
enum CategoryType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

/// User-facing category. Mirrors `categories` row (PRD.md 293–314).
/// Display name resolution: `customName ?? l10nKey` — handled at the UI
/// boundary, not here (PRD.md 308–309, CLAUDE.md → Data-Model Invariants).
@freezed
abstract class Category with _$Category {
  const factory Category({
    required int id,
    required String icon,         // Icon-registry string key. Never IconData.
    required int color,           // Index into core/utils/color_palette.dart.
    required CategoryType type,   // Immutable after first referencing tx (M3).
    String? l10nKey,              // Stable identity for seeded rows.
    String? customName,           // User override of the localized name.
    int? sortOrder,
    @Default(false) bool isArchived,
  }) = _Category;

}
```

Notes:
- `icon` is `String` (icon-registry key). `color` is `int` (palette index). Enforced by CLAUDE.md → Data-Model Invariants; never a `IconData` / `Color` / `int ARGB`.
- `type` is `CategoryType`, not `String`. Repository (M3) converts `row.type` (`String`) → enum via `CategoryType.values.byName(row.type)`. An unknown string from a corrupt DB throws; catching is M3's business.
- `l10nKey` + `customName` nullability exactly mirrors PRD 293–310: seeded rows have `l10nKey` set; custom rows have `customName` set; renamed seeded rows have both. **Do not** collapse them into one `String name` field — that destroys the rename semantics.
- **NOT a Drift row.** Do not import `CategoryRow` here. Repositories (M3) convert `CategoryRow` → `Category`.

### 3.3 `Account` — `lib/data/models/account.dart`

**PRD:** lines 315–334. **Stream A row class:** `AccountRow`.
```dart
// lib/data/models/account.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'currency.dart';

part 'account.freezed.dart';

/// User-facing account. Mirrors `accounts` row (PRD.md 315–334).
/// Current balance is DERIVED (PRD.md 331) — never a field on this model.
@freezed
abstract class Account with _$Account {
  const factory Account({
    required int id,
    required String name,
    required int accountTypeId,            // FK: account_types.id.
    /// Native currency value object on the read side.
    required Currency currency,
    /// Integer minor units. Scaling factor is `Currency.decimals`. Never
    /// a double. See PRD.md → Money Storage Policy.
    @Default(0) int openingBalanceMinorUnits,
    String? icon,
    int? color,
    int? sortOrder,
    @Default(false) bool isArchived,
  }) = _Account;

}
```

Notes:
- `accountTypeId` is an `int` FK into `account_types`. No nested `AccountType` model — controllers look it up from `AccountTypeRepository` (a cheap `.watchAll()` cached map).
- `currency` is typed as `Currency` in the domain model so downstream code can consume both `symbol` and `decimals` together.
- `openingBalanceMinorUnits` is `int`. Dartdoc on the field explicitly references the Money Storage Policy so the guardrail grep (G4, §7) only fires on accidental `double`s.
- **No `currentBalance` field.** Derived by the repository / controller from transactions (PRD 331). Adding one here creates two sources of truth.

### 3.3a `AccountType` — `lib/data/models/account_type.dart`

**PRD:** `account_types` table (first-class, mirrors `categories`). **Stream A row class:** `AccountTypeRow`.
```dart
// lib/data/models/account_type.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'currency.dart';

part 'account_type.freezed.dart';

/// User-facing account type (e.g. "Cash", "Investment"). Mirrors the
/// `account_types` row. Seeded rows (`accountType.cash`, `accountType.investment`)
/// are identified by `l10nKey`; users can rename (sets `customName`) or
/// add custom types. Display name resolution: `customName ?? l10nKey` —
/// handled at the UI boundary, not here.
@freezed
abstract class AccountType with _$AccountType {
  const factory AccountType({
    required int id,
    String? l10nKey,               // Stable identity for seeded rows.
    String? customName,            // User override of the localized name.
    /// Optional default-currency hint.
    /// Null = no preference; account-creation form falls back to
    /// `user_preferences.default_currency`, then `'USD'`.
    Currency? defaultCurrency,
    required String icon,          // Icon-registry string key. Never IconData.
    required int color,            // Index into core/utils/color_palette.dart.
    @Default(0) int sortOrder,
    @Default(false) bool isArchived,
  }) = _AccountType;

}
```

Notes:
- **Indirect icon/color, same as `Category`.** `icon` is a string key resolved via `core/utils/icon_registry.dart` (M2); `color` is an index into the append-only `core/utils/color_palette.dart`. Never store raw `IconData` or ARGB ints — both break across Flutter updates and across backup/restore (CLAUDE.md → Data-Model Invariants).
- `l10nKey` + `customName` nullability mirrors `Category`: seeded rows have `l10nKey` set; custom rows have `customName` set; renamed seeded rows have both. Do **not** collapse into one `String name` field.
- `defaultCurrency` is an optional currency hint. Nullable — a user-created type may not prefer any particular currency.
- **Archive-instead-of-delete** when referenced by at least one `Account`. Enforced in `AccountTypeRepository` (M3), not here.
- **NOT a Drift row.** Do not import `AccountTypeRow` here. Repositories (M3) convert `AccountTypeRow` → `AccountType`.

### 3.4 `Transaction` — `lib/data/models/transaction.dart`

**PRD:** lines 275–291. **Stream A row class:** `TransactionRow`.
```dart
// lib/data/models/transaction.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'currency.dart';

part 'transaction.freezed.dart';

/// User transaction. Mirrors `transactions` row (PRD.md 275–291).
/// `currency` stores the original transaction currency — Phase 2 price
/// conversion never overwrites it (PRD.md 291).
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required int id,
    /// Integer minor units. Scaling factor is `Currency.decimals`. Never a
    /// double, not even for display. See PRD.md → Money Storage Policy.
    required int amountMinorUnits,
    /// Original-transaction currency value object on the read side.
    required Currency currency,
    required int categoryId,        // FK: categories.id. Type derives from category.
    required int accountId,         // FK: accounts.id.
    required DateTime date,
    String? memo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

}
```

Notes:
- **No `type` field.** Expense/income is derived from the linked `Category.type` (PRD 290). A `type` on `Transaction` would double-source that truth and can desync after a category type-lock violation attempt.
- `currency` is typed as `Currency` in the domain model while the other transaction relationships remain scalar ids.
- **`createdAt` / `updatedAt` are NOT NULL.** `TransactionRepository` sets both to `DateTime.now()` on insert and refreshes `updatedAt` on every update (PRD §275–291 notes, Stream A §10 Q4 RESOLVED).
- `categoryId` remains the scalar relationship field; `CategoryType` enum value only lives on the separately-fetched `Category`.

### 3.5 Why `UserPreferences` is absent

PRD lines 401–414 describe `user_preferences` as a generic `(key, value)` KV store with JSON-encoded `value`. Stream A §2.5 models it exactly that way. There is no natural Freezed shape for an open-ended KV bag; the typed accessors (`themeMode`, `defaultCurrency`, `splashEnabled`, …) live on `UserPreferencesRepository` at M3, each with its own parser. **Do not pre-build a `UserPreference` model here** — it would either be a pointless wrapper around `(String, String)` or require choosing the repository-level typed shape before M3 has designed it.

---

## 4. `LocaleService` stub — `lib/data/services/locale_service.dart`

### 4.1 API

```dart
// lib/data/services/locale_service.dart
import 'dart:io' show Platform;

/// Thin wrapper around the device locale. M1 stub.
///
/// Consumed by the M3 first-run seed / M4 bootstrap path to expose the
/// raw device locale string. The locale-to-currency lookup policy lives
/// alongside seeding once the seeded currency set is available.
/// Swapped for a fake in tests via Riverpod override (M4 smoke-test
/// template, §5.5 of implementation-plan.md).
class LocaleService {
  const LocaleService();

  /// BCP 47-ish locale string as reported by the platform
  /// (e.g. `en_US`, `zh_TW`, `ja_JP`). Returns `'en_US'` if `Platform`
  /// lookup throws (test environments, headless Linux without LANG set).
  String get deviceLocale {
    try {
      return Platform.localeName;
    } catch (_) {
      return 'en_US';
    }
  }

}
```

### 4.2 Shape justification

- `deviceLocale` is a getter (not a `Future`) because `Platform.localeName` is synchronous. A `Future` would force `bootstrap.dart` into an unnecessary `await`.
- **No default-currency policy in M1.** The M1 service only exposes the raw locale. M3's seed / M4 bootstrap decides how `deviceLocale` maps onto the seeded currencies once that table exists.
- **No `LocaleService.fromTest(...)` constructor.** Riverpod override in the test's `ProviderContainer` is the mocking seam; keeping the class instantiable with a single `const LocaleService()` keeps the production wiring trivial.

### 4.3 Import constraint (flag)

`dart:io`'s `Platform` is fine inside `data/services/*` — services may import external SDKs (PRD.md 75). But `Platform` **must not** leak into `data/models/*` (principle §2.1) or into `features/**`: the only accepted path is `service → bootstrap → ProviderScope override → controller`. Any widget that reads `Platform` directly fails the `import_lint` rule at `features/**` (M0). Flag this during M4 review when bootstrap wiring lands.

### 4.4 Testing (M4+)

- M1 itself ships no tests for `LocaleService` (per implementation-plan.md §7 — "None" at M1).
- M4 smoke test overrides `localeServiceProvider` with a `FakeLocaleService` returning a deterministic `'en_US'` so bootstrap is reproducible on CI Linux runners. Stream B does not write this test; Stream B writes the class shape that makes the override trivial.

---

## 5. Code-gen workflow

Generated files:

| Source                                  | Generated                                           |
|-----------------------------------------|-----------------------------------------------------|
| `lib/data/models/currency.dart`         | `currency.freezed.dart`                             |
| `lib/data/models/category.dart`         | `category.freezed.dart`                             |
| `lib/data/models/account.dart`          | `account.freezed.dart`                              |
| `lib/data/models/account_type.dart`     | `account_type.freezed.dart`                         |
| `lib/data/models/transaction.dart`      | `transaction.freezed.dart`                          |

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Rules:
- All five generated `*.freezed.dart` files are **committed**.
- Use `dart run build_runner watch --delete-conflicting-outputs` during active development.
- If `flutter analyze` reports missing `_$Category`, etc., codegen is stale. Re-run build_runner; never hand-write these symbols.
- Stream B's codegen is independent of Stream A's — no `part of` crossover, no shared generated file — so the two streams can run `build_runner` in isolation without waiting on each other.

---

## 6. Testing in M1

Per `implementation-plan.md` §7, M1 ships **no behavioural tests**. Stream B deliverable boils down to "compiles cleanly, `flutter test` green (trivially, because there is nothing to exercise)".

Optional (not required, not part of exit criteria):
- A single `test/unit/models/transaction_copy_with_test.dart` verifying `Transaction(...).copyWith(memo: 'x').memo == 'x'`. Costs ~10 LOC per model. Useful as a smoke test that `build_runner` ran. **Skip unless a sibling model's `copyWith` is about to be relied on by M3 repository tests** — Freezed's copyWith is heavily tested upstream.
- An enum round-trip test: `CategoryType.values.byName('expense') == CategoryType.expense`. Better written once in M3's repository test for the mapping itself.

Do **not** add golden tests, widget tests, or service tests at M1. `LocaleService` tests land in M4 (Riverpod override path) or M6 (BCP 47 parsing hardening).

---

## 7. Exit criteria (from M1 plan)

Stream B is done when **all** of the following hold:

1. `flutter analyze` — clean (no errors, no lints) on `lib/data/models/**` and `lib/data/services/locale_service.dart`.
2. `flutter test` compiles the tree (implementation-plan.md §5 M1 exit criterion). No behavioural tests required.
3. `dart run build_runner build --delete-conflicting-outputs` — succeeds and is idempotent (second run produces no diff). All five generated `*.freezed.dart` files are committed.
4. **`drift_dev` round-trips.** Shared with Stream A: Stream A owns `drift_dev schema dump`, but the schema only round-trips if Stream B's enum wire values and field-name contract (§8) match Stream A's Drift definitions. **This is a shared failure mode** — both streams block on it.
5. **Money grep** (`implementation-plan.md` §5, M1 exit): from repo root, `grep -rnE 'double\s+\w*(amount|balance|rate|price)' lib/` returns **zero hits**. Stream B's only money fields (`amountMinorUnits`, `openingBalanceMinorUnits`) are `int`; the grep's false-positive surface for Stream B is zero.
6. No `package:drift/*`, `package:flutter/*`, or `dart:ui` import exists anywhere under `lib/data/models/`. Verifiable with `grep -rn "package:drift\|package:flutter\|dart:ui" lib/data/models/` returning zero hits. (Not a formal M1 exit criterion from the plan, but a Stream B self-guardrail that makes principle §2.1 auditable.)

---

## 8. Cross-stream hand-offs

### 8.1 Field-name alignment — link, don't duplicate

The single source of truth for the Drift ↔ Freezed field-name contract is `docs/plans/m1-data-foundations/stream-c-field-name-contract.md`. Stream B commits to every corresponding Freezed field named there, grounded by Stream A's Drift-side commitments in §9.1. The per-model code blocks in §3 above were written to match row-by-row; if Stream A changes a Dart property name, update Stream C and Stream B in the same merge window.

### 8.2 Model-side choices that constrain Stream A

These are contracts Stream B imposes back on Stream A; flagged so Stream A's reviewers see them.

1. **`CategoryType` wire values are the exact strings `'expense'` and `'income'`.** Stream A stores these raw in `categories.type` (`TEXT`). Once seeded rows land at M3, changing these strings is a data migration, not a refactor. (`@JsonValue('expense')` in §3.2 is binding.)
2. **`AccountType` is a first-class table, not an enum.** `accounts.account_type_id` is an `int` FK into `account_types.id`; there are no wire-value strings like `'cash'`/`'bank'`/`'other'` to agree on. The `account_types` field matrix is owned by Stream A's contract table (see Stream A §3 / §9 for the `account_types` row); Stream B mirrors those field names 1:1 on the `AccountType` Freezed model (§3.3a). Seeded rows are identified by `l10n_key` (e.g. `accountType.cash`, `accountType.investment`), not by a fixed enum casing.
3. **Freezed model class names are unprefixed** (`Transaction`, `Category`, `Account`, `AccountType`, `Currency`). Stream A must keep the `…Row` suffix on conflicting Drift data classes (`TransactionRow`, `CategoryRow`, `AccountRow`, `AccountTypeRow`); `Currency` is shared — the two never meet in the same file, so the collision is harmless (repositories live in `data/repositories/` and are the only files importing both).
4. **`Transaction.currency` / `Account.currency` / `AccountType.defaultCurrency` use `Currency` / `Currency?` on the domain-model side.** Stream A is unchanged — it still stores `TEXT` FKs.
5. **No enum on `Currency.code`.** Phase 2 adds arbitrary token symbols (`ETH`, `USDC`, …); an enum would be a migration. Matches Stream A §2.1 "natural PK".
6. **No `Currency.isToken`-driven Freezed union.** Stream B keeps `Currency` a single flat data class; fiat vs token is a bool flag, not a sealed variant. Simpler M2 `money_formatter` signature.

### 8.3 Constraints imposed on M3 (repositories)

For the record, not for M1 sign-off:

- Repositories map `CategoryRow.type` (`String`) → `CategoryType` via `CategoryType.values.byName(row.type)`. If the string is unknown, throw a typed exception (not covered in M1).
- Repositories map `TransactionRow` → `Transaction` field-by-field (all names identical per Stream A §9.1). No renames.
- Repositories hydrate `Currency` lookups at their own discretion; Stream B exposes only the flat `Currency` value object.

### 8.4 Constraints imposed on M2 (utilities)

- `money_formatter.format(int minorUnits, Currency currency)` is the expected signature. Pass the whole `Currency` so `decimals` and `symbol` are in one argument. Stream B's `Currency` shape (§3.1) supports this directly.

---

## 9. Decision Log

Questions raised during authoring and their current resolution:

1. **`fromJson`/`toJson` on the five models.** ✅ **RESOLVED — defer.** M1 has no JSON boundary. Keep the models as plain Freezed data classes for now and add JSON serialization only in the milestone that introduces backup/export or another real JSON contract.
2. **`CategoryType` third variant?** ✅ **RESOLVED — no third variant, ever.** PRD § transactions notes (updated) and `stream-a-drift-schema.md` §10 Q3 pin this: Phase 2 account transfers and wallet sync model direction as expense/income from the tracked account/wallet perspective. Outflow = expense, inflow = income. An account-to-account transfer creates two transactions (expense on source, income on destination). `CategoryType` stays two cases forever.
3. **`CategoryType` wire-value casing.** ✅ **RESOLVED — lowercase.** `'expense'` and `'income'`, exactly. `@JsonValue('expense')` / `@JsonValue('income')` on the Dart enum cases (§3.2) is binding; M3 seeds and writes the same lowercase strings into `categories.type`. Once seeded rows land, any case change is a data migration, not a refactor. Contract §4.1 locks the same rule. (Does not apply to `AccountType` — that's a table now; seed identity is the `l10n_key` string, owned by M3's seed list.)
3a. **Seeded `AccountType` icon keys + palette indices.** ✅ **RESOLVED.** Per PRD → *Default Account Types*: both seeded rows use icon key `'wallet'` (for `accountType.cash`) / `'trending_up'` (for `accountType.investment`) and share **Neutral Variant 70 `#AEA9B4`** as their palette color (account types are distinguished by icon, not color). M2's `icon_registry.dart` must register `'wallet'` → `Symbols.wallet` and `'trending_up'` → `Symbols.trending_up` from `material_symbols_icons`. M2's `color_palette.dart` must include Neutral Variant 70 `#AEA9B4` (shared with categories/account types that use it). M3 seed code writes the palette indices resolved at M2 time.
4. **`Transaction.currency` scalar vs. nested `Currency`.** ✅ **RESOLVED — use `Currency` / `Currency?` on the domain-model side.** Repository command signatures are not part of M1.
5. **Locale-based default currency owner.** ✅ **RESOLVED — M1 exposes locale only.** `LocaleService` provides `deviceLocale`; the locale-to-currency mapping belongs to M3 seed / M4 bootstrap once the seeded currency set is available.
6. **Generated-file commit policy.** `stream-a-drift-schema.md` §6 commits Drift-generated `*.g.dart`. Stream B commits only `*.freezed.dart` in M1 because JSON serialization is deferred.
7. **`Transaction.createdAt` / `updatedAt` — who writes them?** ✅ **RESOLVED — NOT NULL, repository writes.** `TransactionRepository` sets `createdAt = updatedAt = DateTime.now()` on insert and refreshes only `updatedAt` on every update. Freezed model fields are non-nullable (`required DateTime createdAt / updatedAt`) — see §3.4. PRD §275–291 updated to match.

---

*Stream B's contract with Stream A is §8 and (by reference) Stream A §9.1. Stream B's contract with M3 is §8.3. Anything beyond those seams is an over-reach and should be pushed back to M3 or later.*
