# M3 — Stream C: `UserPreferencesRepository`, first-run seed, migration harness

> **For agentic workers.** Drive this plan through `superpowers:subagent-driven-development`
> and resume with `superpowers:executing-plans` if interrupted. Every task in §5 is
> bite-sized; run the §6 tests alongside, not at the end.

**Owner:** Agent C — Data / Shell boundary (`docs/plans/implementation-plan.md` §5 M3 row, stream C; §8 3-developer split → Dev A Data)
**Milestone:** M3 — Repositories + first-run seed (`docs/plans/implementation-plan.md` §5 M3; exit criteria in §7 M3 row).
**Sibling streams (M3, same merge window):**
- **Stream A** — `transaction_repository.dart`, `category_repository.dart` (`docs/plans/m3-repositories-seed/stream-a-transaction-category.md`). Freezes `CategoryRepository.save(...)` / `upsertSeeded(...)` plus the concrete `DriftTransactionRepository` / `DriftCategoryRepository` implementations this stream wires in tests.
- **Stream B** — `account_type_repository.dart`, `account_repository.dart`, `currency_repository.dart` (`docs/plans/m3-repositories-seed/stream-b-account-currency.md`). Freezes `CurrencyRepository.upsert(...)`, `AccountTypeRepository.upsertSeeded(...)`, `AccountRepository.save(...)` plus the concrete `Drift*Repository` implementations this stream wires in tests.

**Upstream dependencies (must be merged to `main` before this stream starts red/green):**
- M1 Stream A — Drift tables + DAOs + `AppDatabase` + `drift_schemas/drift_schema_v1.json`. **Merged.**
- M1 Stream B — Freezed domain models (`lib/data/models/*.dart`) + `LocaleService` stub. **Merged.**
- M2 Stream A — `money_formatter.dart`, `date_helpers.dart` (unused by this stream; listed for completeness).
- M2 Stream B — `icon_registry.dart`, `color_palette.dart` (used by this stream to pin seed palette indices).
- M2 Stream C — `app_en.arb` + `app_zh_TW.arb` + `app_zh_CN.arb` populated with every seeded-category / account-type `l10n_key` that this stream writes into the DB.

**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md)
- Bootstrap Sequence — lines **223–234** (seed is step 6; locale init is step 3).
- Database Schema → `user_preferences` — lines **429–442** (KV table, JSON-encoded value, splash keys).
- Database Schema → Migration Strategy — lines **444–450**.
- Default Categories — lines **454–494** (expense + income seed list).
- Default Account Types — lines **497–507** (`accountType.cash`, `accountType.investment`).
- Splash Screen (MVP) — lines **511–552** (settings list in 544–551).
- First-run Defaults — lines **662–668** (`default_currency` from device locale; seeded Cash account; `splash_enabled = true`).
- Internationalization → locale fallback policy — lines **864–892**.
- Testing Strategy → Repository Tests + migration tests — lines **938–950**.

**Tech stack:** Drift `^2.28.0` + `drift_dev ^2.28.0` (migration-snapshot codegen), `NativeDatabase.memory()` from `drift_flutter ^0.2.7` for tests, `intl ^0.20.2`. **No new dependencies.** `flutter_secure_storage` is not imported (Phase 2).

**One-sentence goal.** Ship the `UserPreferencesRepository` typed API, the idempotent transactional first-run seed that produces a launchable empty DB, and the migration test harness that keeps the v1 snapshot honest — so that M4's `bootstrap.dart` can wire steps 3–7 of the PRD bootstrap sequence with zero invention.

**Architecture paragraph.** `user_preferences` is a key/value Drift table whose `value` column stores JSON (M1 Stream A §2.6 fixes the shape). This stream exports an abstract `UserPreferencesRepository` interface plus a concrete `DriftUserPreferencesRepository` that owns both the scalar codec and the watch/read/write contract the UI + router consume. On top of that repository, a single module — `lib/data/seed/first_run_seed.dart` — composes the sibling repository interfaces (Currency, Category, AccountType, Account) in a single Drift transaction to produce the first-run DB state mandated by PRD §First-run Defaults. Because the seed takes its seven collaborators by argument rather than constructing them, it is fully unit-testable with `newTestAppDatabase()` + `TestRepoBundle` from §4 and wire-up at M4 is a one-liner. The migration harness completes the triangle: it freezes `drift_schemas/drift_schema_v1.json` as the committed shape, proves `MigrationStrategy.onUpgrade` is a no-op at v1, and leaves the v1→v2 slot pre-wired for Phase 2.

---

## 0. Current state of the files being replaced / created

### 0.1 `lib/data/repositories/user_preferences_repository.dart` (verbatim — 7-line TODO stub)

```dart
// TODO(M3): `UserPreferencesRepository` — SSOT for the `user_preferences`
// key/value table. Typed getters and setters for theme, locale, default
// account, default currency, first-run state, and splash settings.
//
// Also owns the first-run seed routine invoked from bootstrap when the DB
// is empty (currencies, default categories, one Cash account,
// `default_currency` resolved via LocaleService).
```

**Note.** The stub mentions the seed routine "also" lives in the repository. This plan overrides that: §2 pulls the seed into its own file (`lib/data/seed/first_run_seed.dart`) so the repository stays focused on the KV table and the seed stays testable without instantiating the entire dependency graph. The file header comment in the new repository should say "first-run seed lives in `lib/data/seed/first_run_seed.dart`" to prevent drift.

### 0.2 `lib/data/database/tables/user_preferences_table.dart` (M1 Stream A, frozen)

```dart
@DataClassName('UserPreferenceRow')
class UserPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
```

Header comment confirms the contract: `value` is **always JSON-encoded**, scalars included (`bool true` → `"true"`, `String "light"` → `"\"light\""`, `int 7` → `"7"`). The DAO is agnostic; the repository owns `jsonEncode` / `jsonDecode`.

### 0.3 `lib/data/database/daos/user_preferences_dao.dart` (M1 Stream A, frozen — verbatim shape)

- `Stream<String?> watch(String key)` — emits `null` when missing.
- `Stream<List<UserPreferenceRow>> watchAll()` — debug / bulk read.
- `Future<String?> read(String key)` — one-shot.
- `Future<void> write(String key, String value)` — upsert on primary key.
- `Future<int> deleteByKey(String key)` — named `deleteByKey` to avoid colliding with `DatabaseAccessor.delete<Table>(TableInfo)`.

Everything the repository needs is present. No DAO changes in Stream C.

### 0.4 `lib/data/database/app_database.dart` (M1 Stream A, frozen)

- `schemaVersion = 1`.
- `MigrationStrategy.onCreate = (m) => m.createAll()`.
- `MigrationStrategy.onUpgrade = (m, from, to) async { /* no-op at v1 */ }`.
- `beforeOpen` runs `PRAGMA foreign_keys = ON` — migration tests must keep this pragma on the upgraded DB, not only on a fresh open.

### 0.5 `lib/data/services/locale_service.dart` (M1 Stream B, stub)

```dart
class LocaleService {
  const LocaleService();
  String get deviceLocale {
    try { return Platform.localeName; } catch (_) { return 'en_US'; }
  }
}
```

Returns BCP 47-ish `language_REGION` strings. **Task C3** keeps the locale → default currency mapping as a private helper in `lib/data/seed/first_run_seed.dart`; it does not extend `LocaleService`.

### 0.6 `drift_schemas/drift_schema_v1.json` (M1 Stream A snapshot — entity summary)

Six tables, four indexes, one options block. Entities:

| id | Type  | Name                        | Notable shape                                                                    |
|----|-------|-----------------------------|----------------------------------------------------------------------------------|
| 0  | table | `currencies`                | PK `code`; `decimals` NOT NULL; `is_token` CHECK (0,1).                          |
| 1  | table | `categories`                | auto-PK `id`; `l10n_key` UNIQUE nullable; `type` CHECK `('expense','income')`.   |
| 2  | table | `account_types`             | auto-PK `id`; `l10n_key` UNIQUE nullable; `default_currency` FK → currencies.    |
| 3  | table | `accounts`                  | auto-PK `id`; `account_type_id` FK → account_types; `currency` FK → currencies.  |
| 4  | table | `transactions`              | auto-PK `id`; FKs to currencies, categories, accounts.                           |
| 5  | table | `user_preferences`          | PK `key`; `value` TEXT NOT NULL.                                                 |
| 6  | index | `transactions_date_idx`     | on `date`.                                                                       |
| 7  | index | `transactions_account_idx`  | on `account_id`.                                                                 |
| 8  | index | `transactions_category_idx` | on `category_id`.                                                                |
| 9  | index | `accounts_account_type_idx` | on `account_type_id`.                                                            |

**Phase 2 slot.** Entities `pending_transactions`, `wallet_addresses`, `exchange_rates` are absent by design (PRD 447). The migration harness must accept a v1-only corpus and still be non-trivial — see §3.

### 0.7 `drift_schemas/README.md` (M1 Stream A, frozen)

Rules: never rewrite an existing snapshot in place; file name convention `drift_schema_v<N>.json`; snapshot command is `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/`. **This stream does not generate a new snapshot** — v1 already lives on disk from M1. It generates the `SchemaV1` helper via `dart run drift_dev schema generate drift_schemas/ test/unit/repositories/_harness/generated/` (see §3).

### 0.8 `test/unit/repositories/migration_test.dart` (M0 skeleton — verbatim)

```dart
// Migration harness skeleton.
//
// M0 commits this file as a stub so Phase 2 inherits the harness without
// retrofitting. It is activated in M3 once `AppDatabase` and the v1 schema
// snapshot exist.
//
// Final shape (per PRD -> Migration Strategy and Testing Strategy):
//
//   test('v1 schema is stable', ...)
//   test('onUpgrade v1 -> v2 preserves data on empty DB', ...)
//   test('onUpgrade v1 -> v2 preserves data on seeded DB', ...)
//
// Each case boots `drift_dev`'s generated schema for a given version,
// applies the real `MigrationStrategy.onUpgrade`, and asserts row-level
// invariants. Snapshots live in /drift_schemas/.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('migrations', () {
    test(
      'TODO(M3): activate against drift_schemas/drift_schema_v1.json',
      () { /* intentionally empty */ },
      skip: 'Activated in M3 with the first repository tests.',
    );
  });
}
```

This stream **extends** — does not replace — that file. The `skip:` string is removed, the v1 cases land as real assertions, and a slot for v1→v2 is left as a `// TODO(phase-2):` comment block inside the same `group`.

### 0.9 `l10n/app_en.arb` — seeded-key cross-check (M2 Stream C)

All seeded DB `l10n_key` values this stream writes are backed by camelCase ARB getters in `app_en.arb`. Cross-checked line-by-line:

| DB `l10n_key` (written by seed) | ARB getter                 | EN string      | PRD line |
|---------------------------------|----------------------------|----------------|----------|
| `category.food`                 | `categoryFood`             | Food           | 464      |
| `category.drinks`               | `categoryDrinks`           | Drinks         | 465      |
| `category.transportation`       | `categoryTransportation`   | Transportation | 466      |
| `category.shopping`             | `categoryShopping`         | Shopping       | 467      |
| `category.housing`              | `categoryHousing`          | Housing        | 468      |
| `category.entertainment`        | `categoryEntertainment`    | Entertainment  | 469      |
| `category.medical`              | `categoryMedical`          | Medical        | 470      |
| `category.education`            | `categoryEducation`        | Education      | 471      |
| `category.personal`             | `categoryPersonal`         | Personal       | 472      |
| `category.travel`               | `categoryTravel`           | Travel         | 473      |
| `category.threeC`               | `categoryThreeC`           | 3C             | 474      |
| `category.miscellaneous`        | `categoryMiscellaneous`    | Miscellaneous  | 475      |
| `category.other`                | `categoryOther`            | Other          | 476      |
| `category.income.salary`        | `categoryIncomeSalary`     | Salary         | 486      |
| `category.income.freelance`     | `categoryIncomeFreelance`  | Freelance      | 487      |
| `category.income.investment`    | `categoryIncomeInvestment` | Investment     | 488      |
| `category.income.gift`          | `categoryIncomeGift`       | Gift           | 489      |
| `category.income.other`         | `categoryIncomeOther`      | Other Income   | 490      |
| `accountType.cash`              | `accountTypeCash`          | Cash           | 500      |
| `accountType.investment`        | `accountTypeInvestment`    | Investment     | 501      |

All 20 DB keys have live ARB entries (see `app_en.arb` lines 98–179). The seed writes the dotted DB form; M5 renders via the `localizedCategoryName` helper owned by M2 Stream C (§7.3 of the M2 plan). **If the cross-check ever goes red, the seed or the ARB drifted — do not add a new key here without also updating `app_zh_TW.arb` / `app_zh_CN.arb` in the same PR.**

### 0.10 `lib/core/utils/color_palette.dart` — seed index pins (M2 Stream B)

`CategoryPaletteIndex` constants this stream references in the seed (concrete values, not magic ints):

| Constant           | Ordinal | Color                 | Seeds it's used for                          |
|--------------------|---------|-----------------------|----------------------------------------------|
| `red60`            | 0       | Red 60 `#B3251E`      | `category.food`                              |
| `green40`          | 1       | Green 40 `#006C35`    | `category.drinks`                            |
| `cyan70`           | 2       | Cyan 70 `#00BBDF`     | `category.transportation`, `category.travel` |
| `purple30`         | 3       | Purple 30 `#5629A4`   | `category.shopping`, `category.education`    |
| `green80`          | 4       | Green 80 `#80DA88`    | `category.housing`, `category.personal`      |
| `orange70`         | 5       | Orange 70 `#FF8D41`   | `category.entertainment`                     |
| `red50`            | 6       | Red 50 `#DB372D`      | `category.medical`                           |
| `blue30`           | 7       | Blue 30 `#04409F`     | `category.threeC`                            |
| `neutralVariant50` | 8       | Neutral V50 `#79747E` | `category.miscellaneous`, `category.other`   |
| `yellow80`         | 9       | Yellow 80 `#FCBD00`   | All five seeded income categories            |
| `neutralVariant70` | 10      | Neutral V70 `#AEA9B4` | `accountType.cash`, `accountType.investment` |

Color reuse (Cyan 70, Purple 30, Green 80, Neutral V50) is intentional per PRD 478. The palette is append-only — seed code references constants, never bare ints.

---

## 1. Public API contract — `UserPreferencesRepository`

### 1.1 File header + dependencies

```dart
// lib/data/repositories/user_preferences_repository.dart
//
// SSOT for the `user_preferences` key/value table. Typed getters + setters
// + watchers over the JSON-encoded `value` column. The first-run seed
// lives in lib/data/seed/first_run_seed.dart and uses this repository's
// getFirstRunComplete / markFirstRunComplete as its idempotency gate.
```

Imports: `package:drift/drift.dart` (for errors only), `dart:async`, `dart:convert`, `package:flutter/material.dart` (for `ThemeMode`, `Locale`), `../database/daos/user_preferences_dao.dart`, `../database/app_database.dart`.

**Construction.**

```dart
abstract class UserPreferencesRepository {
  // method surface in §1.3
}

final class DriftUserPreferencesRepository
    implements UserPreferencesRepository {
  DriftUserPreferencesRepository(this._db) : _dao = _db.userPreferencesDao;
  final AppDatabase _db;
  final UserPreferencesDao _dao;
}
```

The concrete implementation takes the `AppDatabase` (not the DAO directly) so the seed module can call `_db.transaction(...)` on the same database instance. G1 still holds: only this repository reads and writes `user_preferences`; consumers import the repository interface, never the DAO.

### 1.2 Preference key registry

All keys are string constants declared inside the repository as `static const`. **The `key_` prefix does not leak into the DB column — these are Dart identifiers; the DB value is the string literal.** PRD §user_preferences (429–442) pins `splash_enabled`, `splash_start_date`, `splash_display_text`, `splash_button_label`. The remaining keys mirror PRD 436.

| Dart constant         | DB key                | Value shape (JSON-decoded)                      | PRD line |
|-----------------------|-----------------------|-------------------------------------------------|----------|
| `_kThemeMode`         | `theme_mode`          | `'light' \| 'dark' \| 'system'`                 | 436, 902 |
| `_kLocale`            | `locale`              | BCP-47 string or `null`                         | 436, 887 |
| `_kDefaultCurrency`   | `default_currency`    | ISO 4217 string (`'USD'`)                       | 436, 665 |
| `_kDefaultAccountId`  | `default_account_id`  | `int?`                                          | 436, 686 |
| `_kFirstRunCompleted` | `first_run_completed` | `bool`                                          | 436      |
| `_kSplashEnabled`     | `splash_enabled`      | `bool` (default `true`)                         | 439, 666 |
| `_kSplashStartDate`   | `splash_start_date`   | ISO-8601 date string or `null`                  | 440      |
| `_kSplashDisplayText` | `splash_display_text` | `String` (may contain `{date}`/`{days}` tokens) | 441      |
| `_kSplashButtonLabel` | `splash_button_label` | `String`                                        | 442      |

**Locked decision.** The nine DB key strings above are canonical. Any rename after M3 lands is a schema migration (G7 spirit — stable string identity).

### 1.3 Method surface

Typed getters / setters. Every watcher is a `Stream<T>` (or `Stream<T?>`) backed by `dao.watch(key)`; every setter is `Future<void>` and calls `dao.write`. Reads that the router / bootstrap need synchronously expose `Future<T>` one-shots that delegate to `dao.read`.

**Theme (PRD 902).**

```dart
Stream<ThemeMode> watchThemeMode();
Future<ThemeMode> getThemeMode();     // default ThemeMode.system
Future<void> setThemeMode(ThemeMode mode);
```

**Locale (PRD 887–892).**

```dart
Stream<Locale?> watchLocale();        // null = "follow device"
Future<Locale?> getLocale();
Future<void> setLocale(Locale? locale);
```

Encoded as `language_REGION` string (e.g. `zh_TW`) via `Locale.toLanguageTag()`'s inverse, or `null`. Chinese-locale resolution (PRD 889) is the shell's responsibility (M4), not the repository's — the repository stores what it's given.

**Default currency (PRD 665, 687).**

```dart
Stream<String> watchDefaultCurrency();   // ISO 4217
Future<String> getDefaultCurrency();     // defaults to 'USD' only if missing — but the seed guarantees it's present post-first-run
Future<void> setDefaultCurrency(String code);
```

Invariant: the repository does **not** validate that `code` exists in the `currencies` table. That is enforced at the FK level by `AccountRepository` / `TransactionRepository` when a row referencing it is written. The default-currency preference is a display hint, not a relational row.

**Default account (PRD 686).**

```dart
Stream<int?> watchDefaultAccountId();
Future<int?> getDefaultAccountId();
Future<void> setDefaultAccountId(int? id);
```

`null` means "use last-used active account" per PRD 686.

**First-run gate (bootstrap step 6).**

```dart
Future<bool> getFirstRunComplete();   // false when key missing
Future<void> markFirstRunComplete();  // writes `true`
```

This is the seed idempotency gate (§2). It is also exposed to M4 bootstrap for logging / telemetry — no write path other than `markFirstRunComplete` is allowed (no `resetFirstRun` in the MVP API).

**Splash (PRD 439–442, 544–547).**

```dart
Stream<bool> watchSplashEnabled();      // default true
Future<bool> getSplashEnabled();
Future<void> setSplashEnabled(bool enabled);

Future<DateTime?> getSplashStartDate();
Future<void> setSplashStartDate(DateTime? date);
Stream<DateTime?> watchSplashStartDate();

Stream<String> watchSplashDisplayText();  // falls back to seeded 'Since {date}' template
Future<String> getSplashDisplayText();
Future<void> setSplashDisplayText(String text);

Stream<String> watchSplashButtonLabel();  // falls back to seeded 'Enter'
Future<String> getSplashButtonLabel();
Future<void> setSplashButtonLabel(String label);
```

**`watchSplashEnabled` is the exact seam the M4 router `redirect:` consumes** (PRD 649; implementation-plan.md §9 risk 7; §8 guardrail G10). `SplashScreen` never subscribes to this stream. The repository deliberately exposes no widget-facing helper — it is a pure data source.

### 1.4 Internal JSON codec

```dart
Future<T> _readJson<T>(
  String key, {
  required T defaultValue,
  required T Function(dynamic) decode,
});

Future<void> _writeJson<T>(
  String key, {
  required T value,
  required dynamic Function(T) encode,
});

Stream<T> _watchJson<T>(
  String key, {
  required T defaultValue,
  required T Function(dynamic) decode,
});
```

**Contract.**
- `encode` returns a `dynamic` that must be `jsonEncode`-able (string, num, bool, null, list, map).
- `decode` receives the raw `jsonDecode` output and must return `T` or throw. The repository catches the throw and re-raises as `PreferenceDecodeException`.
- Missing key (`dao.read` returns `null`) resolves to `defaultValue`. Only actively corrupted JSON fires the exception.
- Scalars still round-trip as JSON: `true` → `"true"`, `'light'` → `"\"light\""`, `42` → `"42"`. This matches M1 Stream A §2.6's stated contract (quoted above in §0.2 — JSON-encoded including scalars). No special-case for "it's just a string."

### 1.5 Error types

```dart
import 'repository_exceptions.dart';

class PreferenceDecodeException extends RepositoryException {
  PreferenceDecodeException(this.key, this.rawValue, Object cause)
      : super('user_preferences[$key] corrupted: $cause');
  final String key;
  final String rawValue;
}
```

`RepositoryException` is the shared repository-layer base from Stream B's `lib/data/repositories/repository_exceptions.dart`. This stream subclasses it for preference-codec failures; it does not declare a duplicate base type.

### 1.6 What the repository deliberately does NOT do

- **Does not validate business rules on the stored values.** `ThemeMode.values.byName(...)` decoding is strict (throws `ArgumentError` → `PreferenceDecodeException`), but no semantic check like "theme must match a seeded palette."
- **Does not expose `jsonDecode` output.** Every public method returns a typed value.
- **Does not write on every watch.** `watchX()` streams share the DAO's `.watchSingleOrNull()` subscription; they do not write a default on first subscribe. Callers handle missing keys via the `defaultValue` return.
- **Does not call `LocaleService`.** Locale → currency mapping lives in the seed, not the repository.
- **Does not touch `flutter_secure_storage`.** That is Phase 2's `ApiKeyRepository`.

---

## 2. First-run seed routine — `lib/data/seed/first_run_seed.dart`

### 2.1 Location + shape decision

**Decision: free-standing top-level async function in a new file `lib/data/seed/first_run_seed.dart`.**

Justification (weighed against the alternative of a static method on `UserPreferencesRepository`):

1. **Testability.** The seed's unit tests (§6) inject real repositories backed by in-memory Drift. A top-level function with explicit named dependencies exposes exactly the set the test needs to construct — no "fake UserPreferencesRepository.runFirstRunSeed" indirection.
2. **Single responsibility.** `UserPreferencesRepository` owns a KV table. Making it also own a cross-table orchestration would double the surface area and conflate two concerns (one watcher-heavy, one write-heavy).
3. **No import-lint violation.** `lib/data/seed/` sits inside `lib/data/` but not inside `lib/data/repositories/`. G1 bans writes to the DB outside `data/repositories/`, but the seed performs those writes **through** the sibling repositories — it never touches DAOs directly. Layer-boundary-wise, the seed is a data-layer orchestrator; compare the Phase 2 `domain/wallet_sync_use_case.dart` that orchestrates without owning state. The `import_lint` rules in `import_analysis_options.yaml` must allow `lib/data/seed/**` to import `lib/data/repositories/**` and `lib/data/services/locale_service.dart`. If the current rules are tighter, §5 C0 opens a one-line amendment PR to the rule file (Agent A reviews per `docs/plans/implementation-plan.md` §8 cross-cutting ownership).
4. **M4 call site stays tiny.** `bootstrap.dart` step 6 imports the function by name: `await runFirstRunSeed(db: appDb, currencies: currencyRepo, ...)`. No receiver needed.

### 2.2 Signature

```dart
// lib/data/seed/first_run_seed.dart
Future<void> runFirstRunSeed({
  required AppDatabase db,
  required CurrencyRepository currencies,
  required CategoryRepository categories,
  required AccountTypeRepository accountTypes,
  required AccountRepository accounts,
  required UserPreferencesRepository preferences,
  required LocaleService localeService,
});
```

All seven arguments are required. No defaults, no implicit globals. `db` is accepted explicitly because the seed wraps its work in `db.transaction(() async { ... })` (§2.4) — the repositories do not individually expose a "run inside this transaction" API. Drift's `transaction` hook makes every repository call on the same zone use the transactional executor; this is the standard Drift pattern for cross-repo atomicity.

### 2.3 Step-by-step algorithm

**Step 0 — Idempotency gate.** First action, before entering the transaction:

```dart
if (await preferences.getFirstRunComplete()) {
  return; // no-op second invocation
}
```

The flag is read with a fresh `dao.read('first_run_completed')`. False when the key is missing (default value in `_readJson`). Running `runFirstRunSeed(...)` a second time on the same DB is guaranteed to be a no-op; this is the risk-4 guardrail (master plan §9 risk 4).

**Step 1 — Seed `currencies`.** Seven fiat entries (PRD 276). Stable `sort_order` lets the Currency picker render a predictable list.

| Code | Decimals | Symbol | `name_l10n_key` (nullable — defer to M5)  | `is_token` | `sort_order` |
|------|----------|--------|-------------------------------------------|------------|--------------|
| USD  | 2        | `$`    | `null`                                    | false      | 0            |
| EUR  | 2        | `€`    | `null`                                    | false      | 1            |
| JPY  | 0        | `¥`    | `null`                                    | false      | 2            |
| TWD  | 2        | `NT$`  | `null`                                    | false      | 3            |
| CNY  | 2        | `¥`    | `null`                                    | false      | 4            |
| HKD  | 2        | `HK$`  | `null`                                    | false      | 5            |
| GBP  | 2        | `£`    | `null`                                    | false      | 6            |

Calls: `await currencies.upsert(Currency(code: 'USD', decimals: 2, symbol: r'$', isToken: false, sortOrder: 0, nameL10nKey: null));` × 7. `upsert` is idempotent by PK (`code`); re-running the step after a partial failure re-writes the same row.

**Step 2 — Resolve `default_currency` from device locale.** PRD 665. Exact mapping this stream owns:

| Locale prefix (normalized)        | `default_currency`                                                                  |
|-----------------------------------|-------------------------------------------------------------------------------------|
| `en_US`                           | USD                                                                                 |
| `en_GB`                           | GBP                                                                                 |
| `en_CA`                           | USD (MVP accepts USD for North American English not pinned to CAD — CAD not seeded) |
| `en_AU` / `en_NZ` / other `en_*`  | USD                                                                                 |
| `zh_TW`                           | TWD                                                                                 |
| `zh_HK`                           | HKD                                                                                 |
| `zh_MO`                           | HKD                                                                                 |
| `zh_CN` / `zh_SG` / other `zh_*`  | CNY                                                                                 |
| `zh` (bare, no region)            | CNY                                                                                 |
| `ja_JP` / bare `ja`               | JPY                                                                                 |
| `de_*` / `fr_*` / `es_*` / `it_*` | EUR                                                                                 |
| Anything else                     | **USD (fallback)**                                                                  |

**Chinese-locale note.** UI-locale resolution and default-currency resolution are related but distinct. PRD 889 maps `zh_HK` / `zh_MO` to the Traditional-Chinese ARB set (`zh_TW`) for copy; this seed mapping remains **region-first for currency** so Hong Kong and Macau default to `HKD` while Taiwan defaults to `TWD`.

Implementation shape (lives in this file, not in `LocaleService`):

```dart
String _defaultCurrencyForLocale(String rawLocale) {
  final normalized = rawLocale.replaceAll('-', '_'); // BCP-47 accepts both
  // exact-match fast path
  switch (normalized) {
    case 'en_US': case 'en_CA': case 'en_AU': case 'en_NZ': return 'USD';
    case 'en_GB': return 'GBP';
    case 'zh_TW': return 'TWD';
    case 'zh_HK': case 'zh_MO': return 'HKD';
    case 'zh_CN': case 'zh_SG': case 'zh':    return 'CNY';
    case 'ja_JP': case 'ja':                  return 'JPY';
  }
  // language-only prefix fallback
  final lang = normalized.split('_').first;
  switch (lang) {
    case 'de': case 'fr': case 'es': case 'it': return 'EUR';
    case 'en': return 'USD';
    case 'zh': return 'CNY';
  }
  return 'USD'; // documented fallback
}
```

Call site:

```dart
final locale = localeService.deviceLocale;
final defaultCurrencyCode = _defaultCurrencyForLocale(locale);
final defaultCurrency = await currencies.getByCode(defaultCurrencyCode);
if (defaultCurrency == null) {
  throw RepositoryException(
    'Seed expected currency $defaultCurrencyCode to exist after Step 1',
  );
}
```

**Step 3 — Seed default categories.** PRD 454–494. Order matches the PRD tables.

| DB `l10n_key`                | `type`  | Icon key (M2 Stream B)   | Palette index (constant)      | `sort_order` |
|------------------------------|---------|--------------------------|-------------------------------|--------------|
| `category.food`              | expense | `'restaurant'`           | `red60` (0)                   | 0            |
| `category.drinks`            | expense | `'local_cafe'`           | `green40` (1)                 | 1            |
| `category.transportation`    | expense | `'directions_bus'`       | `cyan70` (2)                  | 2            |
| `category.shopping`          | expense | `'shopping_bag'`         | `purple30` (3)                | 3            |
| `category.housing`           | expense | `'home'`                 | `green80` (4)                 | 4            |
| `category.entertainment`     | expense | `'movie'`                | `orange70` (5)                | 5            |
| `category.medical`           | expense | `'medical_services'`     | `red50` (6)                   | 6            |
| `category.education`         | expense | `'school'`               | `purple30` (3)                | 7            |
| `category.personal`          | expense | `'self_care'`            | `green80` (4)                 | 8            |
| `category.travel`            | expense | `'flight'`               | `cyan70` (2)                  | 9            |
| `category.threeC`            | expense | `'devices'`              | `blue30` (7)                  | 10           |
| `category.miscellaneous`     | expense | `'category'`             | `neutralVariant50` (8)        | 11           |
| `category.other`             | expense | `'more_horiz'`           | `neutralVariant50` (8)        | 12           |
| `category.income.salary`     | income  | `'payments'`             | `yellow80` (9)                | 13           |
| `category.income.freelance`  | income  | `'work'`                 | `yellow80` (9)                | 14           |
| `category.income.investment` | income  | `'trending_up'`          | `yellow80` (9)                | 15           |
| `category.income.gift`       | income  | `'redeem'`               | `yellow80` (9)                | 16           |
| `category.income.other`      | income  | `'attach_money'`         | `yellow80` (9)                | 17           |

**Icon key contract.** Icon keys are strings; the registry in `core/utils/icon_registry.dart` resolves them to `Symbols.*` at render time (PRD 817–822). The exact mapping is owned by M2 Stream B. The seed references whatever string key Stream B's registry exposes for each row; if a name in the table above differs from Stream B's canonical spelling, reconcile with Stream B (§7 coordination) and update this table — the plan does not commit to a key string Stream B hasn't confirmed.

**Call shape.** `await categories.upsertSeeded(...)` — Stream A's `CategoryRepository` exposes a `upsertSeeded({required String l10nKey, required String icon, required int color, required CategoryType type, required int sortOrder})` method designed for idempotent seeding (it looks up by `l10n_key` and inserts-or-updates, never duplicates). This is the narrow seed seam Stream A freezes so the seed does not route through the user-facing `save(Category)` path.

**Step 4 — Seed default account types.** PRD 497–507.

| DB `l10n_key`            | Icon key        | Palette index               | `default_currency` | `sort_order` |
|--------------------------|-----------------|-----------------------------|--------------------|--------------|
| `accountType.cash`       | `'wallet'`      | `neutralVariant70` (10)     | **seeded default** | 0            |
| `accountType.investment` | `'trending_up'` | `neutralVariant70` (10)     | **seeded default** | 1            |

**Seeded `default_currency`.** Per PRD 500, both account types' `default_currency` is "`user_preferences.default_currency` at seed time" — i.e. the `defaultCurrencyCode` computed in Step 2, resolved to a `Currency` domain model immediately after Step 1. The seed passes that resolved `Currency` to both account-type rows; it does NOT leave the column `NULL` (which would trigger the M3 fall-through in `AccountRepository`). This makes the seeded account-type rows self-documenting after the seed completes.

**Call shape.** `await accountTypes.upsertSeeded(l10nKey: 'accountType.cash', icon: 'wallet', color: CategoryPaletteIndex.neutralVariant70, defaultCurrency: defaultCurrency, sortOrder: 0)`. Stream B's `AccountTypeRepository` freezes `upsertSeeded(...)` as the idempotent seeded-row seam; same reason as categories.

**Step 5 — Seed the one Cash account.** PRD 664.

| Field                         | Value                                                  |
|-------------------------------|--------------------------------------------------------|
| `name`                        | Localized label — see below                            |
| `account_type_id`             | id of the just-seeded `accountType.cash` row           |
| `currency`                    | resolved `defaultCurrency` from Step 2                 |
| `opening_balance_minor_units` | `0` (int, literal `0` — G4)                            |
| `icon`                        | `null` (inherits from account type at render)          |
| `color`                       | `null` (inherits from account type at render)          |
| `sort_order`                  | `0`                                                    |
| `is_archived`                 | `false` (default)                                      |

**Localized name resolution.** The seeded account name is the English literal **`'Cash'`** written into the DB. Rationale: (a) `accounts.name` has no `l10n_key` column (unlike categories and account types — PRD 343), so localization at render would require a rename policy the DB can't express; (b) PRD 664 says "seed one `Cash` account" — the name itself is the label; (c) users rename at will, and the rename writes the new literal. `M5` surfaces the account name as-is. If a reviewer pushes for a localized seed name, the correct move is to introduce `accounts.l10n_key` (Phase 2 schema bump), not to alias via `AppLocalizations` in the seed.

**Call shape.** `final cashTypeId = await accountTypes.upsertSeeded(...)` returns the seeded Cash row id; the seed then passes that id into `accounts.save(Account(...))`. Stream B still does **not** need a dedicated `idForL10nKey` helper.

**Step 6 — Seed `user_preferences`.** The seed populates the minimum set bootstrap depends on. Every value goes through `UserPreferencesRepository` setters (never DAO.write directly) so the JSON codec path is exercised end-to-end.

| Key                   | Seed value                                                                    | Source                              |
|-----------------------|-------------------------------------------------------------------------------|-------------------------------------|
| `theme_mode`          | `ThemeMode.system`                                                            | PRD 902 default                     |
| `locale`              | `null`                                                                        | "follow device" (PRD 887)           |
| `default_currency`    | `defaultCurrency` from Step 2                                                 | PRD 665                             |
| `default_account_id`  | **not written** (null default)                                                | User picks later (PRD 686)          |
| `splash_enabled`      | `true`                                                                        | PRD 439, 666                        |
| `splash_start_date`   | `null`                                                                        | PRD 440 (user sets at first launch) |
| `splash_display_text` | `'Since {date}'` (literal template — runtime substitutes `{date}` / `{days}`) | PRD 441, 526                        |
| `splash_button_label` | `'Enter'`                                                                     | PRD 442, 527                        |

**`splash_display_text` seed value note.** The seeded default is the literal template string `'Since {date}'`, not a per-locale translation — M5 Splash reads the preference and, when it equals the literal default, falls back to the localized `AppLocalizations.splashSinceDate(date)` getter (M2 Stream C §5.3). If the user customises the text, the customised string is stored verbatim and never auto-translated (PRD 892).

**Step 7 — `markFirstRunComplete()`.** Last action inside the transaction. Once this commits, step 0 returns `true` on the next invocation.

### 2.4 Atomicity — Drift transaction wrapper

```dart
Future<void> runFirstRunSeed({...}) async {
  if (await preferences.getFirstRunComplete()) return;
  final localeCurrencyCode = _defaultCurrencyForLocale(localeService.deviceLocale);

  await db.transaction(() async {
    // Step 1 — currencies
    await _seedCurrencies(currencies);
    // Step 2 — resolve localeCurrencyCode into a Currency domain model
    final localeCurrency = await currencies.getByCode(localeCurrencyCode);
    if (localeCurrency == null) {
      throw RepositoryException(
        'Seed expected currency $localeCurrencyCode to exist after Step 1',
      );
    }
    // Step 3 — categories
    await _seedCategories(categories);
    // Step 4 — account types (defaultCurrency = localeCurrency)
    final cashTypeId = await _seedAccountTypes(accountTypes, localeCurrency);
    // Step 5 — one Cash account
    await _seedCashAccount(accounts, cashTypeId, localeCurrency);
    // Step 6 — user_preferences (excluding first_run_completed)
    await _seedPreferences(preferences, localeCurrency);
    // Step 7 — idempotency flag LAST
    await preferences.markFirstRunComplete();
  });
}
```

**Why the transaction is critical.** If step 3 throws halfway (e.g. a dirty FK because step 1 silently partially failed), `db.transaction` rolls back every write and `first_run_completed` stays unwritten. The next launch re-enters the seed, tries again, and either succeeds or leaves the DB empty again. There is no "partially seeded, flagged complete" state to diagnose.

**Why `_defaultCurrencyForLocale` runs outside the transaction.** The device locale read is synchronous and has no DB interaction. Reading it once before the transaction means every step in the transaction sees the same value (no TOCTOU against locale change during seed, not that it's possible in practice).

### 2.5 Consumer contract — M4 bootstrap call site

Per PRD bootstrap sequence (223–234), step 6 is the seed invocation. M4 wires it as:

```dart
// app/bootstrap.dart (sketch — M4 owns the full file)
Future<BootstrapResult> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();               // step 1
  final db = AppDatabase(driftDatabase(name: 'ledgerly')); // step 2
  const localeService = LocaleService();                   // step 3
  await _initIntlDateData(...);                            // step 4
  final prefs = DriftUserPreferencesRepository(db);        // step 5 (reads)
  final currencies = DriftCurrencyRepository(db);
  final categories = DriftCategoryRepository(db);
  final accountTypes = DriftAccountTypeRepository(db, currencies);
  final accounts = DriftAccountRepository(db, currencies);
  await runFirstRunSeed(                                   // step 6
    db: db,
    currencies: currencies,
    categories: categories,
    accountTypes: accountTypes,
    accounts: accounts,
    preferences: prefs,
    localeService: localeService,
  );
  return BootstrapResult(db: db, prefs: prefs, /* ... */); // feeds step 7 ProviderScope overrides
}
```

**G9 compliance.** Every `await` stays inside `bootstrap()`; `main.dart` is a one-liner (`void main() async => runApp(ProviderScope(overrides: await bootstrap().toOverrides(), child: App()));` or equivalent). The seed never calls `runApp` — that is the router's problem.

**Bootstrap-ordering guarantee (risk 8).** Step 3 (locale init) is before step 6 (seed). The seed's argument list declares `localeService` explicitly, so a mis-ordered bootstrap (seed before locale) would fail compilation in M4 — the dependency is typed, not ambient. Risk 8's mitigation is reinforced by: M4 adds a smoke test that asserts `_defaultCurrencyForLocale` produces the locale-appropriate default (same as this stream's seed test §6) once bootstrap has run.

---

## 3. Migration test harness

### 3.1 Goal

Activate `test/unit/repositories/migration_test.dart` so that the committed v1 snapshot is exercised against the current `AppDatabase.migrationStrategy.onUpgrade`, on both empty and seeded DBs, before Phase 2 lands. In MVP there is only `drift_schema_v1.json`, so the harness proves "v1 opens cleanly on empty + seeded DB and `schemaVersion` matches." When Phase 2 commits `drift_schema_v2.json`, the harness grows by adding the generated `SchemaV2` import and the explicit v1→v2 test blocks already called out in §3.3.

### 3.2 Prerequisite — generate schema helpers

`drift_dev` emits strongly-typed schema classes per snapshot via:

```bash
dart run drift_dev schema generate drift_schemas/ test/unit/repositories/_harness/generated/
```

This produces `test/unit/repositories/_harness/generated/schema_v1.dart` (and, in Phase 2, `schema_v2.dart`). The file exports `SchemaV1` — a `GeneratedDatabase` subclass with the v1-era table metadata. Commit the generated files; they become part of the test harness.

**Alternative if `drift_dev schema generate` is deferred.** A hand-written equivalent can open a raw `NativeDatabase.memory()`, execute the `CREATE TABLE` / `CREATE INDEX` DDL implied by the JSON snapshot, and then pass that executor to `AppDatabase(executor)` for the upgrade. The generated path is strongly preferred (zero hand-maintained DDL), but the harness is structured so that swapping the `SchemaV1()` constructor for a raw-DDL bootstrapper is mechanical. **Task C10 tries `drift_dev schema generate` first and falls back to the raw-DDL path only if it fails under the pinned `drift_dev ^2.28.0`.**

### 3.3 Harness shape

```dart
// test/unit/repositories/migration_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/database/app_database.dart';
import '_harness/generated/schema_v1.dart';

void main() {
  group('migrations', () {
    test('current schemaVersion matches the latest committed snapshot', () {
      // Trivial but catches the "bumped schemaVersion without dumping a snapshot"
      // mistake next time Phase 2 touches the file.
      expect(AppDatabase(NativeDatabase.memory()).schemaVersion, 1);
    });

    group('v1 snapshot', () {
      test('opens cleanly on an empty DB', () async {
        final executor = NativeDatabase.memory();
        final legacy = SchemaV1(executor);
        await legacy.customStatement('SELECT 1');           // force open
        await legacy.close();

        // Re-open the same snapshot DB with the real AppDatabase; onUpgrade(1 -> 1) is a no-op.
        final db = AppDatabase(executor);
        await db.customStatement('PRAGMA foreign_keys');  // forces beforeOpen
        expect(db.schemaVersion, 1);
        await db.close();
      });

      test('opens cleanly on a seeded DB (first-run seed committed)', () async {
        final db = AppDatabase(NativeDatabase.memory());
        final seedDeps = _wireSeedDepsFor(db);
        await runFirstRunSeed(
          db: db,
          currencies: seedDeps.currencies,
          categories: seedDeps.categories,
          accountTypes: seedDeps.accountTypes,
          accounts: seedDeps.accounts,
          preferences: seedDeps.preferences,
          localeService: _FakeLocaleService('en_US'),
        );
        // Sanity: the seed populated the expected row counts so that Phase 2
        // v1 -> v2 tests inherit a non-empty universe, not just schema DDL.
        expect(await db.select(db.currencies).get(), hasLength(7));
        expect(await db.select(db.categories).get(), hasLength(18));
        expect(await db.select(db.accountTypes).get(), hasLength(2));
        expect(await db.select(db.accounts).get(), hasLength(1));
        expect((await db.select(db.accounts).getSingle()).currency, 'USD');
        await db.close();
      });

      test('foreign keys stay ON after onUpgrade runs', () async {
        final db = AppDatabase(NativeDatabase.memory());
        // beforeOpen already ran PRAGMA foreign_keys = ON.
        final result = await db.customSelect(
          'PRAGMA foreign_keys',
        ).getSingle();
        expect(result.read<int>('foreign_keys'), 1);
        await db.close();
      });
    });

    // TODO(phase-2): add 'v1 -> v2 on empty DB' and
    // 'v1 -> v2 on seeded DB' blocks once drift_schema_v2.json lands.
  });
}
```

**`_wireSeedDepsFor(db)` is a test helper** that constructs real `DriftCurrencyRepository`, `DriftCategoryRepository`, `DriftAccountTypeRepository`, `DriftAccountRepository`, and `DriftUserPreferencesRepository` over the provided `AppDatabase`, then exposes them through interface-typed fields. It lives in `test/unit/repositories/_harness/test_app_database.dart` (§4) alongside `newTestAppDatabase()`.

**`_FakeLocaleService` is a local test double** that returns a fixed string. Using the real `LocaleService()` would make the test flaky across CI hosts. The test for locale-dependent seed behaviour lives in `first_run_seed_test.dart` (§6), not in the migration harness.

### 3.4 Why this is not trivially passing

The master plan §9 lists "migration harness silently passes because no v2 exists" as a risk. This harness defends against that in three ways:

1. **Seeded-DB test.** Opens v1 with a full first-run-seed worth of rows. If any FK constraint, CHECK constraint, or default value in the JSON snapshot has drifted from the code, the seed fails here before the `hasLength` asserts — this is a real integration smoke.
2. **PRAGMA foreign_keys assertion.** The `beforeOpen` hook must remain ON after migration. A v2 migration that accidentally runs `PRAGMA foreign_keys = OFF` during a table-rebuild and forgets to restore it would fail this test in Phase 2.
3. **schemaVersion / snapshot parity check.** The first test asserts `AppDatabase(...).schemaVersion == 1`. When Phase 2 bumps to 2, the test fails loudly until `drift_schema_v2.json` lands and the parity constant updates.

---

## 4. Shared in-memory Drift test harness

### 4.1 Ownership

**Stream C owns `test/unit/repositories/_harness/test_app_database.dart`.** Justification:

1. This stream ships the migration test harness, which is the **most structurally demanding** consumer of in-memory Drift in M3 — the sibling repository tests need a DB, but only this stream also needs schema-generation helpers and a seed fixture.
2. Pushing ownership to Stream A would force Stream A to ship the helper before their own tests can use it; Stream A's dependency graph is already fatter (two repos + business-rule tests).
3. Stream B has no migration concerns; asking them to own the harness would invert the complexity gradient.

If Stream A objects during merge coordination, the helper is 30 lines — moving it is cheap. The plan locks ownership here so no stream silently duplicates.

### 4.2 API

```dart
// test/unit/repositories/_harness/test_app_database.dart
import 'package:drift/native.dart';
import 'package:ledgerly/data/database/app_database.dart';

/// Returns a fresh in-memory `AppDatabase` for tests.
///
/// `NativeDatabase.memory()` gives each test an isolated DB with no disk
/// footprint. The caller MUST `await db.close()` in a `tearDown` block.
AppDatabase newTestAppDatabase() => AppDatabase(NativeDatabase.memory());

/// Bundle of repositories wired to a given AppDatabase, for tests that
/// exercise cross-repo flows (seed, migration-with-seeded-data).
class TestRepoBundle {
  TestRepoBundle(this.db)
      : currencies = DriftCurrencyRepository(db),
        categories = DriftCategoryRepository(db),
        accountTypes = DriftAccountTypeRepository(db, DriftCurrencyRepository(db)),
        accounts = DriftAccountRepository(db, DriftCurrencyRepository(db)),
        preferences = DriftUserPreferencesRepository(db);
  final AppDatabase db;
  final CurrencyRepository currencies;
  final CategoryRepository categories;
  final AccountTypeRepository accountTypes;
  final AccountRepository accounts;
  final UserPreferencesRepository preferences;

  Future<void> seedMinimalRepositoryFixtures() async {
    // Shared fixtures consumed by Streams A and B:
    // USD / JPY / TWD currencies, one seeded expense category,
    // one seeded income category, one seeded Cash account type,
    // and one Cash account in USD.
    //
    // Contract note for Stream A's day-bounded stream tests
    // (T-day-01..03, T-days-01..02, per Stream A §6.3): callers
    // that exercise watchByDay / watchDaysWithActivity are
    // responsible for inserting transactions across at least two
    // distinct local-timezone days inside the test body. This
    // helper does NOT seed any transactions — that is intentional,
    // because per-day fixtures vary per test.
  }
}
```

`newTestAppDatabase()` is the canonical shared harness entrypoint. `TestRepoBundle` wires concrete `Drift*Repository` implementations but exposes interface-typed collaborators so sibling tests consume the same abstraction surface as production code. The harness also owns `seedMinimalRepositoryFixtures()`, whose fixture contract is shared across Streams A and B.

### 4.3 Sibling-stream consumption contract

- Stream A imports via `package:ledgerly/../test/unit/repositories/_harness/test_app_database.dart` (relative `import`, since tests live outside the library path). Actual import: `import '_harness/test_app_database.dart';` from sibling test files.
- Stream B consumes the same way. No other API surface is exposed from `_harness/`; if siblings need more helpers, they add them here via PR — no silent forking into `test/unit/repositories/foo_helpers.dart`.

---

## 5. Implementation task breakdown

Each task is one PR-sized unit. Tasks C0–C11 are ordered by the ship sequence; C0 may run in parallel with Stream A / B once their plans land.

- [ ] **C0 — `import_lint` rule amendment.** Update `import_analysis_options.yaml` so `lib/data/seed/**` may import `lib/data/repositories/**` + `lib/data/services/locale_service.dart`. Confirm the pinned `import_lint ^0.1.6` (CLAUDE.md pin) actually enforces the new rule. If the 0.1.6 regex schema can't express this split, document the gap in the PR description — reviewer discipline stays the primary guard.
- [ ] **C1 — `UserPreferencesRepository` skeleton + key registry.** File header, constructor, nine `static const` key strings, `_readJson` / `_writeJson` / `_watchJson` helpers + `PreferenceDecodeException`. No typed getter methods yet. Ships with `user_preferences_repository_test.dart` red case asserting `PreferenceDecodeException.toString()` includes the key name.
- [ ] **C2 — Shared in-memory Drift test harness.** `test/unit/repositories/_harness/test_app_database.dart`. Ship `newTestAppDatabase()` + `TestRepoBundle` with concrete `Drift*Repository` wiring and interface-typed fields. Include `seedMinimalRepositoryFixtures()` with the exact shared fixture contract from §4.2, plus a trivial smoke test `await newTestAppDatabase().close();` to keep CI green.
- [ ] **C3 — `LocaleService` → default currency mapping.** Implement `_defaultCurrencyForLocale(String)` in `lib/data/seed/first_run_seed.dart` (top-level private). Unit test covers every row in §2.3 Step 2 table + the `zh` bare fallback + the "unknown" default. **Decision locked: mapping lives in the seed file, NOT in `LocaleService`.** Currency mapping is region-first where a seeded fiat exists (`zh_HK` / `zh_MO` → `HKD`), while UI copy localization still follows PRD 889's Chinese-locale resolution.
- [ ] **C4 — Typed theme / locale / default-currency / default-account / first-run-completed methods.** 10 methods total. Red tests assert: getter default values when key missing; setter round-trips; watcher emits on write. No splash keys yet — they ship in C5.
- [ ] **C5 — Splash preference methods.** `watchSplashEnabled` + `getSplashEnabled` + `setSplashEnabled` + start-date + display-text + button-label (9 methods). Red tests assert: `watchSplashEnabled()` default-emits `true`; `watchSplashStartDate()` default-emits `null`; `watchSplashDisplayText()` default-emits `'Since {date}'` when the seed has not yet run (i.e. the hard-coded `defaultValue` of `_watchJson`).
- [ ] **C6 — First-run seed: currencies step.** New `first_run_seed.dart` with an **unexported** `_seedCurrencies(CurrencyRepository)` helper. Public `runFirstRunSeed` exists but only calls step 0 (idempotency) + step 1 for now; **do not write `first_run_completed` yet**. Red test: calls `runFirstRunSeed`; asserts seven currency rows; the final idempotency/no-op contract is only locked once C7–C9 land and step 7 (`markFirstRunComplete`) is added last. Seed calls `await currencies.upsert(...)`; if Stream B has not merged yet, C6 depends on a merged Stream B branch — coordinate via §7.
- [ ] **C7 — Seed: categories step.** Adds `_seedCategories(CategoryRepository)`. Red test: 18 rows; 13 expense + 5 income; `l10n_key` values match §2.3 Step 3 table exactly; `sort_order` is 0..17; idempotency still holds.
- [ ] **C8 — Seed: account types + Cash account.** Adds `_seedAccountTypes(...)` and `_seedCashAccount(...)`. Red test: 2 account-type rows with `default_currency = 'USD'` when locale is `en_US`; 1 Cash account row with `opening_balance_minor_units = 0` (literal int, G4); account's `account_type_id` matches the Cash row's id. `_seedAccountTypes(...)` uses `AccountTypeRepository.upsertSeeded(...)` and reuses the returned Cash row id for step 5.
- [ ] **C9 — Seed: user_preferences step.** Adds `_seedPreferences(...)`. Red test: after seed, `preferences.getSplashEnabled() == true`; `getThemeMode() == ThemeMode.system`; `getLocale() == null`; `getDefaultCurrency() == 'USD'`; `getSplashDisplayText() == 'Since {date}'`; `getDefaultAccountId() == null` (deliberately unwritten).
- [ ] **C10 — Migration test harness activation.** `drift_dev schema generate` → commit `test/unit/repositories/_harness/generated/schema_v1.dart`. Extend `migration_test.dart` with the three blocks in §3.3. Keep the `TODO(phase-2)` comment for v1→v2.
- [ ] **C11 — Integration verification.** Extend `test/unit/repositories/first_run_seed_test.dart` (do not create a `test/integration/` file in this stream). Open a fresh `newTestAppDatabase()`, run the seed with `_FakeLocaleService('zh_TW')`, then read via the sibling repository watchers (`categories.watchAll()`, `currencies.watchAll()`, etc.) to confirm the reactive path lights up with the seeded data. This is the cross-seam smoke that catches "seed wrote rows but the watcher stream had already emitted `[]` and doesn't refresh."

---

## 6. Test plan

One file per concern; every test uses `newTestAppDatabase()` from §4.

### 6.1 `test/unit/repositories/user_preferences_repository_test.dart`

- `theme round-trip`: `setThemeMode(ThemeMode.dark)` → `getThemeMode() == ThemeMode.dark`; watcher emits in order `ThemeMode.system`, `ThemeMode.dark`.
- `theme decode failure`: DAO pre-seeded with `'"purple"'` at key `theme_mode` → `getThemeMode()` throws `PreferenceDecodeException` whose `.key == 'theme_mode'` and `.rawValue == '"purple"'`.
- `locale null round-trip`: `setLocale(null)` → `getLocale() == null`; `setLocale(const Locale('zh', 'TW'))` → `getLocale() == const Locale('zh', 'TW')`.
- `default currency round-trip`: `setDefaultCurrency('TWD')` → `getDefaultCurrency() == 'TWD'`.
- `default account id nullability`: missing key → `null`; `setDefaultAccountId(42)` → `42`; `setDefaultAccountId(null)` → `null`.
- `first-run-completed gate`: default `false`; `markFirstRunComplete()` writes `true`; second call is a no-op (no exception).
- `splash defaults match PRD`: on empty DB, `watchSplashEnabled()` emits `true`, `watchSplashStartDate()` emits `null`, `watchSplashDisplayText()` emits `'Since {date}'`, `watchSplashButtonLabel()` emits `'Enter'`. These are the hard-coded `defaultValue`s of `_watchJson` — they must match the seed (§2.3 Step 6) byte-for-byte.
- `splash start date ISO-8601 round-trip`: `setSplashStartDate(DateTime.utc(2026, 4, 22))` → `getSplashStartDate() == DateTime.utc(2026, 4, 22)`.
- `watcher emits on write`: subscribe to `watchSplashEnabled()`, call `setSplashEnabled(false)`, assert the second emitted value is `false`. Uses `expectLater(stream, emitsInOrder([true, false]))`.
- `corrupted JSON propagates as PreferenceDecodeException`: seed DAO with `'not-json-at-all'` at `splash_enabled` → `getSplashEnabled()` throws `PreferenceDecodeException`.

### 6.2 `test/unit/repositories/first_run_seed_test.dart`

- `empty DB → every step populates`: fresh `newTestAppDatabase()`, `runFirstRunSeed(...)`. Assert currency count == 7, category count == 18, account-type count == 2, account count == 1, `first_run_completed == true`, `splash_enabled == true`, `theme_mode == system`, `default_currency` matches the stub locale.
- `runs twice → no duplicates, no side effects`: call `runFirstRunSeed(...)` twice in a row. Assert row counts unchanged after the second call. Assert `preferences.getFirstRunComplete() == true` both times. Assert no `UNIQUE constraint failed: categories.l10n_key` error surfaces.
- `locale en_US → default_currency == USD`: stub `LocaleService` with `'en_US'`, run seed, assert `preferences.getDefaultCurrency() == 'USD'`.
- `locale zh_TW → default_currency == TWD`: assert TWD.
- `locale zh_CN → default_currency == CNY`: assert CNY.
- `locale ja_JP → default_currency == JPY`: assert JPY.
- `locale en_GB → default_currency == GBP`: assert GBP.
- `locale de_DE → default_currency == EUR`: assert EUR.
- `unknown locale → USD fallback`: stub with `'kl_GL'` (Kalaallisut, Greenland — intentionally unmapped), assert `'USD'`.
- `locale zh_HK → default_currency == HKD`: pins the §2.3 decision.
- `bare zh → default_currency == CNY`: pins the bare-language fallback.
- `transactional atomicity`: inject a sibling-repo stub whose `upsert` throws on the **3rd** category call. Run seed, expect it throws. Then re-open the DB and assert zero currencies, zero categories, zero account types, zero accounts, and `first_run_completed == false`. **This is the risk-4 guardrail** (master plan §9 risk 4).
- `Cash account points at Cash type`: seed with `en_US`, read the single `accounts` row, assert its `account_type_id` equals the `id` of the row where `l10n_key == 'accountType.cash'`.
- `opening_balance_minor_units is literal int 0`: the Freezed model field is `int`; the test is `expect(account.openingBalanceMinorUnits, 0);`. G4 guard.

### 6.3 `test/unit/repositories/migration_test.dart`

Full shape in §3.3. Four assertions:

- `schemaVersion matches latest snapshot` — `expect(AppDatabase(NativeDatabase.memory()).schemaVersion, 1);`.
- `v1 snapshot opens cleanly on empty DB`.
- `v1 snapshot opens cleanly on seeded DB with expected row counts`.
- `foreign_keys PRAGMA stays ON`.
- `TODO(phase-2)` placeholder comment for v1→v2 — **not** a `skip:`'d test; a bare comment so the file stays compile-clean and grep-discoverable.

### 6.4 Test-harness-level invariants (implicit in every test file)

- Every test opens a fresh `newTestAppDatabase()` in `setUp` and `await db.close()` in `tearDown`. No shared-DB tests.
- Ankr API calls: N/A in M3 (Phase 2).
- No `Future` goes unhandled: every `runFirstRunSeed(...)` is `await`ed.

---

## 7. Integration points with sibling streams

### 7.1 Contract table

| Dependency direction    | API frozen by | Contract this stream assumes (must appear in sibling plan)                                                                                                                                                                                    |
|-------------------------|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Stream B → Stream C** | Stream B      | `CurrencyRepository.upsert(Currency)` — idempotent upsert by PK `code`.                                                                                                                                                                       |
| Stream B → Stream C     | Stream B      | `AccountTypeRepository.upsertSeeded({required String l10nKey, required String icon, required int color, required Currency defaultCurrency, required int sortOrder}) → Future<int>` — idempotent seeded-row write that returns the row id.     |
| Stream B → Stream C     | Stream B      | `AccountRepository.save(Account) -> Future<int>` — plain insert/update seam; seed uses the returned id on insert when needed.                                                                                                                 |
| Stream B → Stream C     | Stream B      | `AccountRepository.watchAll()` — used by C11 integration test to assert reactive emission.                                                                                                                                                    |
| Stream B → Stream C     | Stream B      | `CurrencyRepository.watchAll()` — same.                                                                                                                                                                                                       |
| Stream B → Stream C     | Stream B      | `RepositoryException` base class — the shared error hierarchy.                                                                                                                                                                                |
| **Stream A → Stream C** | Stream A      | `CategoryRepository.upsertSeeded({required String l10nKey, required String icon, required int color, required CategoryType type, required int sortOrder})` — idempotent seed variant. Non-seed `save(Category)` is not called by this stream. |
| Stream A → Stream C     | Stream A      | `CategoryRepository.watchAll()` — used by C11 integration test.                                                                                                                                                                               |
| Stream A → Stream C     | Stream A      | `CategoryType` enum — `expense` / `income`. Stream A declares it (in Freezed model land, M1 Stream B produced it); this stream imports.                                                                                                       |
| **Stream C → M4**       | This stream   | `runFirstRunSeed(...)` top-level function, seven-arg named constructor.                                                                                                                                                                       |
| Stream C → M4           | This stream   | `UserPreferencesRepository.watchSplashEnabled()` — for router `redirect:`.                                                                                                                                                                    |
| Stream C → M4           | This stream   | `UserPreferencesRepository.watchThemeMode()` + `watchLocale()` — for theme + locale providers at the shell level.                                                                                                                             |
| **Stream C declares**   | This stream   | `test/unit/repositories/_harness/test_app_database.dart` — `newTestAppDatabase()` + `TestRepoBundle`. Sibling streams A and B import.                                                                                                         |

### 7.2 Merge order (mandatory, to prevent rebase-churn during the shared merge window)

1. **Stream C harness first.** The empty in-memory harness is a shared seam both sibling streams consume in tests.
2. **Stream B shared exception contract next.** `repository_exceptions.dart` is the other shared seam; Stream A and this stream import it.
3. **Streams A and B repository implementations next.** Stream C's seed waits for `CategoryRepository.upsertSeeded`, `AccountTypeRepository.upsertSeeded`, `AccountRepository.save`, and the concrete `Drift*Repository` classes.
4. **Stream C last for seed/migration work.** Seed and seeded-DB migration coverage compose both sibling repositories once their APIs are on main.

If Stream B or A slips, this stream can still land C1–C5 (`UserPreferencesRepository` + its tests) and the **empty-DB** half of C10 (schemaVersion parity + empty snapshot open). The seeded-DB migration case in C10, plus C6–C9 and C11, wait for sibling repository implementations.

### 7.3 Coordination checkpoint

- **Day 1 of M3.** Sibling plans publish their frozen seed-facing signatures plus the concrete `Drift*Repository` constructor shape in their own `§1 Public API contract` sections. This stream reads them and updates the §2.3 call sites to match.
- **Before any stream merges.** A three-way diff asserts that every call site in `first_run_seed.dart` references a method that exists in a sibling plan's API contract section. If the sibling plan changes a signature after Day 1, the author opens a coordination PR here — no silent ABI drift.

### 7.4 Test-harness ownership cross-reference

This stream's §4 declares `newTestAppDatabase()` + `TestRepoBundle`. Stream A's plan and Stream B's plan must reference this location (not reinvent the helper) and update their test files to import `'_harness/test_app_database.dart'`. If the sibling plans silently ship their own in-memory harness, this stream's author flags it at review and reconciles.

---

## 8. Guardrails enforced by this stream

| Guardrail (master plan §6)                                                       | This stream's assertion                                                                                                                                                                                                                                                                    |
|----------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **G1** Only repositories write to the DB / secure storage                        | `lib/data/seed/first_run_seed.dart` calls repositories only; no DAO imports. `user_preferences_repository_test.dart` imports the repo, not the DAO.                                                                                                                                        |
| **G4** Money is `int` minor units end-to-end                                     | `opening_balance_minor_units: 0` is a literal `int 0` in the seed; test `first_run_seed_test.dart` asserts `account.openingBalanceMinorUnits == 0` via the Freezed model's `int` field. `grep 'double.*balance'` over this stream's surface area returns zero hits.                        |
| **G7** Seeded categories / account types identified by `l10n_key`                | The §2.3 Step 3 / Step 4 tables enumerate the exact 18 + 2 dotted keys. Categories and account types both use dedicated `upsertSeeded` seams keyed on `l10n_key`. Re-running the seed updates by key, never duplicates. `first_run_seed_test.dart` "runs twice → no duplicates" pins this. |
| **G9** Bootstrap sequence matches PRD exactly                                    | `runFirstRunSeed(...)` is callable standalone (testable) but the only in-repo call site is M4 `bootstrap.dart` step 6. This stream does not spawn `await`s from `main.dart` and does not call `runApp`.                                                                                    |
| **G10** Router `redirect:` reads `splash_enabled`; no flag inside `SplashScreen` | `UserPreferencesRepository.watchSplashEnabled()` is the exact seam the router consumes. The repository exposes no widget-visible hook; `SplashScreen` reading the flag would require constructing the repository inside a widget layer, which G1/G2 already forbid.                        |
| **G12** Tests organized by layer                                                 | Every file in this stream lands under `test/unit/repositories/` (repo + seed + migration). No `test/features/`, no feature-folder mixing.                                                                                                                                                  |

Guardrails not owned by this stream: G2 (Drift types never leave repo — sibling streams' concern; this stream only consumes their domain models), G3 (controllers own presentation — M5), G5 (category type lock — Stream A), G6 (archive-instead-of-delete — Streams A / B), G8 (icon/color indirection — the seed writes string keys + int indices, trivially compliant), G11 (layout primitives — M5).

---

## 9. Risks specific to this stream

1. **Re-seeding duplicates rows if the idempotency check is wrong.** Master plan §9 risk 4. **Guardrail:** Step 0 reads `first_run_completed` before entering the transaction; `markFirstRunComplete()` runs last inside the transaction. The `runs twice → no duplicates` test in §6.2 + the `transactional atomicity` test (partial failure leaves the flag unwritten) prove both halves. If `upsertSeeded` semantics slip from update-by-`l10n_key` to plain-insert, the `runs twice` test fails first.
2. **Locale resolves after seed runs → `default_currency` is wrong.** Master plan §9 risk 8. **Guardrail:** `runFirstRunSeed` accepts `LocaleService` as a required argument — a wrong-ordered bootstrap (seed before locale init) fails compilation in M4, not at runtime. The M4 smoke test additionally asserts "seed with `en_US` device locale produces `default_currency == USD` after bootstrap completes" (this stream's §6.2 test covers the unit-level equivalent).
3. **Router redirect leaks splash because `SplashScreen` reads the flag instead of the router.** Master plan §9 risk 7. **Guardrail:** `UserPreferencesRepository.watchSplashEnabled()` is the only entry point for the flag, and the doc comment on that method explicitly says "consumed by the M4 router `redirect:`; not for widget-level use." M4 integration tests (master plan §7 M4 row) assert no splash render when the flag is false. If an M5 slice later tries to construct `UserPreferencesRepository` inside a `ConsumerWidget` to read `splash_enabled`, G1 / G2 `import_lint` rules catch it.
4. **Migration harness silently passes because no v2 exists.** **Guardrail:** §3.4 enumerates three non-trivial checks the v1-only harness still performs — seeded-DB open, FK PRAGMA stays ON, schemaVersion parity. If any of these regress, the harness fails. The Phase 2 slot (a `TODO(phase-2)` comment) is deliberately *not* a skipped test — grep-discoverable but not misleading CI.
5. **JSON decode corruption from a user-mutated DB.** Users who sideload the DB or flip a row via a debug tool can leave `user_preferences.value` in a non-parseable state. **Guardrail:** Typed `PreferenceDecodeException` includes the key + raw value in the message; the `theme decode failure` test in §6.1 locks the error path. UI error boundaries (M4 shell + M5 settings) render an error state rather than crashing — that is M4/M5's problem, but the exception type is stable so they can switch on it.
6. **Seed seam drift between siblings.** If Stream A ships `CategoryRepository.upsertSeeded` with different semantics than Stream B's `AccountTypeRepository.upsertSeeded`, the seed call sites become asymmetric and reviewers miss the pattern. **Guardrail:** §7.1 table freezes both seams in this plan. Day-1 coordination (§7.3) reconciles before merge.
7. **`l10n_key` typo (e.g. `category.threeC` vs `category.three_c`).** A silent ARB-vs-seed mismatch renders as a blank category name in the picker. **Guardrail:** §0.9 cross-check table line-checks each seeded key against `app_en.arb`; M2 Stream C's `arb_audit_test.dart` plus this stream's `first_run_seed_test.dart` "`l10n_key` values match §2.3 table" assertion triangulate the set.
8. **`splash_display_text` seeded value drift vs `UserPreferencesRepository`'s default.** The seed writes `'Since {date}'`; the repository's `_watchJson` also hard-codes `'Since {date}'` as the default. If the two drift (someone updates one but not the other), first launch shows one string and a subsequent wipe-and-reseed shows another. **Guardrail:** a small constant `const kDefaultSplashDisplayText = 'Since {date}';` lives in a single file (`lib/data/seed/first_run_seed.dart` or a dedicated `preference_defaults.dart`) and both the seed and the repository import it. §5 Task C5 + C9 wire the same constant.

---

## 10. Exit criteria (definition of done)

Maps to `docs/plans/implementation-plan.md` §5 M3 exit criteria for stream C.

- [ ] `UserPreferencesRepository` exposes every method in §1.3; all methods covered by `user_preferences_repository_test.dart` (§6.1) with happy + error branches.
- [ ] `PreferenceDecodeException` is the only way corrupted JSON surfaces to a consumer; tested via the `theme decode failure` test.
- [ ] `watchSplashEnabled()` exists and its default emission is `true`; the doc comment names the router `redirect:` as the canonical consumer (G10).
- [ ] `lib/data/seed/first_run_seed.dart` exports `runFirstRunSeed(...)` with the seven-argument signature in §2.2.
- [ ] Running `runFirstRunSeed` twice on the same DB is a no-op (row counts stable, no exceptions).
- [ ] A step-level failure rolls back every write and leaves `first_run_completed == false` (transactional atomicity test).
- [ ] Locale resolution table (§2.3 Step 2) is fully covered — every explicit row + the USD fallback path is asserted in `first_run_seed_test.dart`.
- [ ] The seeded DB contains exactly 7 currencies, 18 categories (13 expense + 5 income), 2 account types, 1 account with `opening_balance_minor_units == 0`, the 7 `user_preferences` keys written in §2.3 Step 6 (`theme_mode`, `locale`, `default_currency`, `splash_enabled`, `splash_start_date`, `splash_display_text`, `splash_button_label`), and `first_run_completed` written separately in Step 7.
- [ ] `test/unit/repositories/migration_test.dart` runs four real assertions against the v1 snapshot (`schemaVersion`, empty DB, seeded DB, `foreign_keys` PRAGMA) — no `skip:`, no TODO test cases.
- [ ] `test/unit/repositories/_harness/test_app_database.dart` ships `newTestAppDatabase()` + `TestRepoBundle`; sibling streams import it.
- [ ] `flutter analyze` is clean; `flutter test` is green; `dart run build_runner build --delete-conflicting-outputs` round-trips without error.
- [ ] `grep -E 'double.*(amount|balance|rate|price)' lib/data/seed/ lib/data/repositories/user_preferences_repository.dart` returns zero hits.
- [ ] `import_analysis_options.yaml` permits `lib/data/seed/**` → `lib/data/repositories/**` + `lib/data/services/locale_service.dart`; no repository imports a DAO outside `lib/data/repositories/` (G1 spirit); no test file outside `test/unit/repositories/` writes to `user_preferences`.

---

## 11. Verification log

Files read from disk while authoring this plan:

| File                                                      | Size / structure                                                                                                                                                                                          |
|-----------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `PRD.md`                                                  | 1051 lines; §Bootstrap Sequence 223–234, §user_preferences 429–442, §First-run Defaults 662–668, §Default Categories 454–494, §Default Account Types 497–507, §Migration Strategy 444–450, §i18n 864–892. |
| `docs/plans/implementation-plan.md`                       | 445 lines; §5 M3 row, §6 guardrails G1/G4/G7/G9/G10/G12, §7 testing rollout, §9 risks 4/7/8.                                                                                                              |
| `docs/plans/m2-core-utilities/stream-c-theme-l10n.md`     | 657 lines; style template for §0 verbatim dumps + §5 task checkboxes + §8 guardrails table.                                                                                                               |
| `docs/plans/m1-data-foundations/stream-a-drift-schema.md` | Read first 200 lines; confirms `user_preferences_table` shape (KV + JSON) and `app_database` migration hooks.                                                                                             |
| `lib/data/repositories/user_preferences_repository.dart`  | 8 lines (7 TODO + trailing blank). Verbatim in §0.1.                                                                                                                                                      |
| `lib/data/database/tables/user_preferences_table.dart`    | 26 lines. Verbatim in §0.2.                                                                                                                                                                               |
| `lib/data/database/daos/user_preferences_dao.dart`        | 57 lines. API summary in §0.3 (five public methods).                                                                                                                                                      |
| `lib/data/database/app_database.dart`                     | 72 lines. `schemaVersion = 1`; `beforeOpen` runs PRAGMA foreign_keys = ON; `onUpgrade` no-op at v1.                                                                                                       |
| `lib/data/services/locale_service.dart`                   | 23 lines. Returns `Platform.localeName` with `'en_US'` fallback.                                                                                                                                          |
| `drift_schemas/drift_schema_v1.json`                      | 743 lines, 6 tables + 4 indexes. Entity summary table in §0.6.                                                                                                                                            |
| `drift_schemas/README.md`                                 | 25 lines. `drift_dev schema dump` command; append-only rule.                                                                                                                                              |
| `test/unit/repositories/migration_test.dart`              | 32 lines. Verbatim in §0.8.                                                                                                                                                                               |
| `l10n/app_en.arb`                                         | 221 lines. 20 seeded-category / account-type keys cross-checked in §0.9.                                                                                                                                  |
| `lib/core/utils/color_palette.dart`                       | 77 lines. 11 palette indices (`red60` through `neutralVariant70`). Seed mapping pinned in §0.10.                                                                                                          |

This verification log is the audit trail reviewers use to confirm that the plan's numerical claims (row counts, palette indices, PRD line ranges) were read, not guessed.

---

## Critical Files for Implementation

- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/data/repositories/user_preferences_repository.dart`
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/data/seed/first_run_seed.dart` (new)
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/test/unit/repositories/user_preferences_repository_test.dart` (new)
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/test/unit/repositories/first_run_seed_test.dart` (new)
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/test/unit/repositories/migration_test.dart` (extend)
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/test/unit/repositories/_harness/test_app_database.dart` (new)
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/test/unit/repositories/_harness/generated/schema_v1.dart` (generated by `drift_dev schema generate`)
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/import_analysis_options.yaml` (rule amendment for `lib/data/seed/**`)
- `/Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/data/services/locale_service.dart` (no change — mapping lives in seed, per C3 decision)
