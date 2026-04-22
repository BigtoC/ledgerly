# M3 — Stream A: `TransactionRepository` + `CategoryRepository` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Owner:** Agent A (Data)
**Milestone:** M3 — Repositories + first-run seed (`docs/plans/implementation-plan.md` §5, M3)
**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md)
- *Architecture → Layer Boundaries / SSOT rule / Controller Contract / Domain Models vs Drift Data Classes / Reactive Data Flow*: lines **56–102**
- *Error Handling Pattern*: lines **828–837**
- `currencies` schema — FK target: lines **264–278**
- `transactions` schema — integer minor units, currency FK, repository-populated timestamps: lines **280–299**
- `categories` schema — `l10n_key` stability, type-lock, archive-vs-delete, icon/color indirection: lines **301–320**
- *Default Categories* — shape Stream C seeds against: lines **454–494**
- *Testing Strategy → Repository Tests*: lines **938–949**

**Sibling streams (same M3 merge window — no files overlap):**
- **Stream B** — `account_type_repository.dart`, `account_repository.dart`, `currency_repository.dart` + rule tests.
- **Stream C** — `user_preferences_repository.dart` + first-run seed module + migration harness activation. **Owner of the shared in-memory Drift test harness** (see §7).

Stream A MUST NOT touch `account*_repository.dart`, `currency_repository.dart`, `user_preferences_repository.dart`, the seed module, or migration-harness wiring. Those are other streams' exit criteria. This stream's code changes are limited to `transaction_repository.dart`, `category_repository.dart`, their dedicated rule tests, and the one leaf DAO addition explicitly called out in task A3.3 (`TransactionDao.watchByCategory`).

**Upstream dependency (must be green before starting):**
- **M1 merged** — `lib/data/database/{tables,daos}/*`, `lib/data/database/app_database.dart`, `lib/data/models/{transaction,category,currency,account_type,account}.dart`, and `drift_schemas/drift_schema_v1.json` exist as described in `docs/plans/m1-data-foundations/stream-a-drift-schema.md` and `stream-b-freezed-models.md`. Verified 2026-04-22 on disk — see §11.
- **M2 merged** — `core/utils/money_formatter.dart` and friends exist, but Stream A does **not** import them. Repositories deal exclusively in integer minor units; formatting is a UI-layer concern.

**Stack:** Drift `^2.28.0`, `drift_flutter ^0.2.7`, Freezed `^3.1.0`, `flutter_riverpod ^2.6.1` (consumers only — this stream declares no `@riverpod` providers; Stream C wires DI), Dart `^3.11.5`, Flutter `>=3.41.6`, `flutter_test` (sdk), `mocktail ^1.0.4`. **No new `pubspec.yaml` entries.**

**Goal:** Replace the two TODO stubs with production `TransactionRepository` and `CategoryRepository` implementations that enforce the five PRD-mandated invariants (integer minor units, currency FK, category-type lock, archive-instead-of-delete, repository-populated timestamps), expose frozen public signatures the M4 bootstrap and M5 controllers compile against, and ship exhaustive in-memory-Drift rule tests.

**Architecture:** Stream A exports abstract repository interfaces plus concrete `Drift*Repository` implementations constructed with an `AppDatabase` handle. The concrete classes call per-entity DAOs, map Drift rows to Freezed domain models inside private helpers, and expose `Stream<T>` / `Future<T>` methods only. Drift types (`TransactionRow`, `CategoryRow`, `CategoriesCompanion`, `TransactionsCompanion`) do not escape. Business rules live **in the repository methods**, never in DAO SQL. Shared repository errors come from Stream B's narrow `repository_exceptions.dart`; Stream-A-specific leaf exceptions stay local to Stream A.

---

## 0. Current state of the files being replaced

At M0 scaffold time these two files were created as TODO-only stubs. Their full current content is reproduced verbatim below — Stream A replaces both in full (TODO comments go away, the exported API in §1 lands).

**`lib/data/repositories/transaction_repository.dart`** (10 lines, all comment — verified via `wc -l`):
```dart
// TODO(M3): `TransactionRepository` — SSOT for transactions.
//
// Public surface:
//   - `Stream<List<Transaction>> watchAll()` (backed by Drift `.watch()`)
//   - typed command methods: `save`, `delete`, `duplicate`
//
// Business rules enforced here (not in controllers):
//   - Integer minor-unit arithmetic for every amount.
//   - Currency FK integrity — transactions must reference a known currency.
//   - Drift -> Freezed mapping. Drift types never escape this file.
```

**`lib/data/repositories/category_repository.dart`** (9 lines, all comment — verified via `wc -l`):
```dart
// TODO(M3): `CategoryRepository` — SSOT for categories.
//
// Business rules enforced here:
//   - Category `type` is immutable after the first transaction references
//     it (guardrail G5). `update()` rejects type changes with a typed
//     exception once referenced.
//   - Archive-instead-of-delete when referenced (guardrail G6).
//   - Rename writes `custom_name` only; `l10n_key` is never modified so
//     locale switches do not duplicate or orphan rows (guardrail G7).
```

**Related Drift surface this stream queries (already merged in M1 — not modified here):**

| File                                               | Symbols this stream uses                                                                                                                           | Source of truth                 |
|----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------|
| `lib/data/database/app_database.dart`              | `AppDatabase` (constructor takes `QueryExecutor`; `beforeOpen` enables `foreign_keys = ON`)                                                        | `stream-a-drift-schema.md` §4   |
| `lib/data/database/tables/transactions_table.dart` | `Transactions`, `TransactionRow`, `TransactionsCompanion`                                                                                          | `stream-a-drift-schema.md` §2.2 |
| `lib/data/database/tables/categories_table.dart`   | `Categories`, `CategoryRow`, `CategoriesCompanion`                                                                                                 | `stream-a-drift-schema.md` §2.3 |
| `lib/data/database/daos/transaction_dao.dart`      | `TransactionDao.{watchAll, watchByDateRange, watchByAccount, watchById, findById, insert, updateRow, deleteById, countByCategory, countByAccount}` | `stream-a-drift-schema.md` §3.2 |
| `lib/data/database/daos/category_dao.dart`         | `CategoryDao.{watchAll, watchByType, findById, findByL10nKey, insert, updateRow, deleteById, archiveById}`                                         | `stream-a-drift-schema.md` §3.3 |
| `lib/data/models/transaction.dart`                 | `Transaction` (Freezed)                                                                                                                            | `stream-b-freezed-models.md`    |
| `lib/data/models/category.dart`                    | `Category`, `CategoryType.{expense, income}`                                                                                                       | `stream-b-freezed-models.md`    |
| `lib/data/models/currency.dart`                    | `Currency` (needed only because `Transaction.currency` holds a `Currency`)                                                                         | `stream-b-freezed-models.md`    |

Everything Stream A needs from Drift is already present. This stream adds **no schema or table changes** to `lib/data/database/`; the only database-layer change is the one leaf DAO addition explicitly called out later: `TransactionDao.watchByCategory`.

---

## 1. Public API contract (FROZEN on merge)

Downstream code — the M3-C seed routine, the M4 bootstrap, and every M5 controller touching transactions or categories — will import these symbols. Do not change a signature without bumping every consumer in lock-step.

### 1.1 `lib/data/repositories/transaction_repository.dart`

```dart
import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/currency_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../database/tables/transactions_table.dart';
import '../models/category.dart';
import '../models/currency.dart';
import '../models/transaction.dart';
import 'repository_exceptions.dart';

/// SSOT for `transactions`. Owns every write path to the Drift
/// `transactions` table. Drift data classes never leave this file.
///
/// Invariants enforced here (and only here):
/// - Integer minor-unit arithmetic for every amount (G4 — PRD.md 253-257).
/// - Currency FK integrity — insert rejects unknown `Currency.code`
///   (G2 / PRD.md 286).
/// - `createdAt` / `updatedAt` populated by the repository, never by
///   SQL defaults (PRD.md 291-293).
abstract class TransactionRepository {
  /// Transactions for one calendar day, in the device's local
  /// timezone. Day window: `[localMidnight(day), localMidnight(day) + 24h)`.
  /// Reverse-chronological within the day.
  ///
  /// Backs the Home screen. Per the Option B day-by-day UX (resolved
  /// 2026-04-22, see §12), Home shows one day at a time with prev/next
  /// navigation — `watchAll` is intentionally NOT part of this contract.
  ///
  /// The caller passes a `DateTime` whose date component identifies the
  /// day; time-of-day is ignored. Implementations MUST compute the day
  /// window in local time via `DateTime(day.year, day.month, day.day)` so
  /// transactions logged near midnight land in the day the user saw on
  /// the clock when they entered them.
  Stream<List<Transaction>> watchByDay(DateTime day);

  /// Newest-first stream of days that have at least one transaction,
  /// bounded by `limit`. Each element is the local-midnight `DateTime`
  /// of a distinct day.
  ///
  /// Backs Home's prev/next day navigation: the controller subscribes
  /// once to discover which days are non-empty, then subscribes to
  /// `watchByDay(...)` for the currently-selected day. Without this
  /// helper, Home would step one calendar day at a time and render
  /// empty lists for gap days, which is a poor UX.
  Stream<List<DateTime>> watchDaysWithActivity({int limit = 365});

  /// Transactions for a single account, reverse-chronological.
  /// Backs the Accounts tab detail (a full per-account history list).
  /// Bounded by `limit` to avoid unbounded streams; Accounts screen
  /// never needs more than the default. `AccountRepository` (Stream B)
  /// decides archive-vs-delete through its own `TransactionDao.countByAccount`
  /// probe, not this stream.
  Stream<List<Transaction>> watchForAccount(int accountId, {int limit = 200});

  /// Transactions for a single category, reverse-chronological.
  /// Backs the Categories management screen (M5), which surfaces
  /// "N transactions under this category" reactively. Bounded by
  /// `limit` — the management screen never needs more.
  Stream<List<Transaction>> watchForCategory(int categoryId, {int limit = 200});

  /// One-shot read by id. Consumed by the duplicate flow and by
  /// controllers that need a snapshot for form prefill.
  Future<Transaction?> getById(int id);

  /// Insert-or-update. Treats `id == 0` as insert, `id != 0` as
  /// update by PK.
  ///
  /// On **insert**: sets `createdAt = updatedAt = clock()`. Returns the
  /// inserted row with populated `id`, `createdAt`, `updatedAt`.
  /// On **update**: refreshes `updatedAt = clock()`, preserves the
  /// stored `createdAt` untouched. Returns the updated row.
  ///
  /// Throws:
  /// - [CurrencyNotFoundException] when `tx.currency.code`
  ///   is absent from the `currencies` table.
  /// - [RepositoryException] on any other Drift-layer failure.
  ///
  /// Does NOT validate `categoryId` / `accountId` — the SQLite FK
  /// constraints (`foreign_keys = ON`, PRD.md 286-288) surface those
  /// as a `SqliteException` wrapped in [RepositoryException]. Callers
  /// should select from the current category/account lists in the UI,
  /// so this is a degenerate error path.
  Future<Transaction> save(Transaction tx);

  /// Delete by id. Returns `true` when a row was removed, `false` when
  /// no row matched. No referential cascade — `transactions` is the
  /// child side of every FK it participates in.
  Future<bool> delete(int id);

  /// Quick-repeat / duplicate flow (PRD.md 716-722).
  ///
  /// Copies `categoryId`, `accountId`, `currency`, `amountMinorUnits`,
  /// `memo`, and `date` from the source row. Allocates a new `id` and
  /// sets `createdAt = updatedAt = clock()` — the duplicate is a new
  /// transaction, not a history entry of the source.
  ///
  /// Throws [RepositoryException] when `sourceId` does not exist.
  Future<Transaction> duplicate(int sourceId);
}

final class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  TransactionDao get _dao => _db.transactionDao;
  CategoryDao get _categoryDao => _db.categoryDao;
  CurrencyDao get _currencyDao => _db.currencyDao;
}
```

**Exported:** abstract interface `TransactionRepository` plus concrete `DriftTransactionRepository`. No top-level functions.

### 1.2 `lib/data/repositories/category_repository.dart`

```dart
import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../database/tables/categories_table.dart';
import '../models/category.dart';
import 'repository_exceptions.dart';

/// SSOT for `categories`. Owns every write path to the Drift
/// `categories` table. Drift data classes never leave this file.
///
/// Invariants enforced here (and only here):
/// - `Category.type` is immutable after the first referencing
///   transaction (G5 — PRD.md 293-294, 315, 735-737).
/// - Archive-instead-of-delete for referenced categories; hard-delete
///   only when no transaction references the row (G6 — PRD.md 315-316).
/// - Renames write `customName` only; `l10nKey` is never mutated by
///   application code (G7 — PRD.md 314, CLAUDE.md → Data-Model
///   Invariants).
/// - Wire values of `CategoryType` are `'expense'` / `'income'` (no
///   third variant, ever — PRD.md 293-294).
abstract class CategoryRepository {
  /// Categories stream, optionally filtered by type and including
  /// archived rows. Ordered by `sortOrder NULLS LAST, id ASC`.
  ///
  /// - `type == null` → all types.
  /// - `includeArchived == false` (default) → archived rows omitted
  ///   (pickers want this).
  /// - `includeArchived == true` → archived rows included (the
  ///   Categories management screen wants this).
  Stream<List<Category>> watchAll({
    CategoryType? type,
    bool includeArchived = false,
  });

  /// One-shot read by id. Returns `null` when no row matches.
  Future<Category?> getById(int id);

  /// One-shot read by `l10nKey`. Consumed by the M3-C seed module to
  /// check idempotency for seeded rows (`category.food`, etc.).
  Future<Category?> getByL10nKey(String l10nKey);

  /// Seed-only insert-or-update keyed by `l10nKey`. Used exclusively by
  /// Stream C's first-run seed to make seeded category writes idempotent
  /// without routing through the user-facing `save(Category)` path.
  ///
  /// - Insert path: creates the row with the supplied seed-owned fields.
  /// - Update path: rewrites seed-owned fields (`icon`, `color`,
  ///   `sortOrder`, `isArchived`) and preserves row identity.
  /// - `customName` is preserved on existing rows.
  /// - If the incoming `type` disagrees with a referenced row, the same
  ///   type-lock guard as [save] applies.
  Future<Category> upsertSeeded({
    required String l10nKey,
    required String icon,
    required int color,
    required CategoryType type,
    required int sortOrder,
  });

  /// Insert-or-update.
  ///
  /// On **insert** (`category.id == 0`): writes a new row. `l10nKey` is
  /// accepted as-is (seed writes it; user-created rows leave it null).
  /// On **update**: compares `type` against the stored row; if they
  /// differ and the stored category has at least one referencing
  /// transaction, throws [CategoryTypeLockedException] (G5). Otherwise
  /// persists the row.
  ///
  /// `save` does NOT mutate `l10nKey`. If a caller supplies a
  /// `l10nKey` value that differs from the stored one on update, the
  /// mismatch is treated as a repository contract violation and throws
  /// [RepositoryException]. Seeded-row renames must go through
  /// [rename].
  Future<Category> save(Category category);

  /// Rename a category. Writes `customName` only and leaves `l10nKey`
  /// untouched so locale switches do not duplicate or orphan rows
  /// (G7 — PRD.md 314, 494).
  ///
  /// `customName` may be `null` (revert to localized default) or a
  /// non-empty string. Empty strings are treated as `null`.
  Future<Category> rename(int id, String? customName);

  /// Mark the category as archived. Non-destructive; referenced rows
  /// remain queryable via `includeArchived: true`. Idempotent — calling
  /// archive on an already-archived row is a no-op that returns the
  /// archived row.
  Future<Category> archive(int id);

  /// Hard-delete. Only allowed when the category has no referencing
  /// transactions. Throws [CategoryInUseException] when at least one
  /// transaction references the id. Caller should invoke [archive]
  /// instead.
  Future<bool> delete(int id);

  /// Returns `true` when at least one row in `transactions` references
  /// this category. Backs the Categories management screen's
  /// archive-vs-delete UI affordance and the delete guard above.
  Future<bool> isReferenced(int id);
}

final class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;

  CategoryDao get _dao => _db.categoryDao;
  TransactionDao get _txDao => _db.transactionDao;
}
```

**Exported:** abstract interface `CategoryRepository` plus concrete `DriftCategoryRepository`. No top-level functions.

### 1.3 `lib/data/repositories/repository_exceptions.dart` (shared, owned by Stream B)

This shared file stays deliberately narrow. Stream B owns and defines the canonical contents of `repository_exceptions.dart` in its §1.4. Stream A imports `RepositoryException` and `CurrencyNotFoundException` from that shared file and keeps `CategoryTypeLockedException` / `CategoryInUseException` local to `category_repository.dart` because they are Stream-A-only guardrails.

### 1.4 Contract rules (non-negotiable once this stream merges)

1. **`int` minor units end-to-end.** No public method accepts or returns `double` near `amount`, `balance`, `rate`, or `price`. Repositories never call `money_formatter` — that is a UI concern.
2. **Drift types never appear in a public signature.** `TransactionRow`, `CategoryRow`, `CategoriesCompanion`, `TransactionsCompanion` are **forbidden** in any `lib/data/repositories/*.dart` exported type. Import them inside implementation bodies, map at the boundary.
3. **Streams are reactive.** Every `watch*` method is backed by Drift `.watch()` via its DAO; the repository adds a `.map(_toDomain)` step and returns. No manual refresh primitives, no polling, no cache.
4. **Timestamps are repository concerns.** The `DateTime Function()? clock` constructor parameter lets tests pin the clock (e.g. `clock: () => DateTime(2026, 4, 22, 12, 0)`) without touching production code. DB defaults never populate `created_at` / `updated_at` — PRD.md 291-293, resolved in Stream A M1 §10.Q4.
5. **Freezed models are plain data.** A returned `Category` or `Transaction` has no methods that touch the database; if a consumer needs to persist a change, it calls `repository.save(category)` with the updated Freezed value.

---

## 2. Drift ↔ Freezed mapping helpers (in-repository)

Each repository declares private helpers below its public methods. These are the **only** places `TransactionRow` / `CategoryRow` / Drift companions appear in this stream.

### 2.1 Transactions

```dart
// --- private mapping helpers ---

Future<Transaction> _toDomain(TransactionRow row) async {
  // Currency is FK-resolved on read. Non-null-asserted because the
  // row cannot exist without a matching `currencies` entry:
  //   (a) `TransactionRepository.save` runs a pre-insert
  //       `CurrencyDao.findByCode` check (§3.3), and
  //   (b) `AppDatabase.beforeOpen` sets `PRAGMA foreign_keys = ON`.
  // Together those make a row-with-unresolvable-currency unreachable
  // under normal operation. Users do not type currency codes by hand;
  // every code in the DB was put there by the seed or by a controlled
  // Phase 2 token-registration path. See Q4 resolution in §12.
  final currency = (await _currencyDao.findByCode(row.currency))!;
  return Transaction(
    id: row.id,
    amountMinorUnits: row.amountMinorUnits,
    currency: currency, // Currency domain model
    categoryId: row.categoryId,
    accountId: row.accountId,
    memo: row.memo,
    date: row.date,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

TransactionsCompanion _toCompanion(
  Transaction tx, {
  required DateTime createdAt,
  required DateTime updatedAt,
}) {
  return TransactionsCompanion(
    id: tx.id == 0 ? const Value.absent() : Value(tx.id),
    amountMinorUnits: Value(tx.amountMinorUnits),
    currency: Value(tx.currency.code),
    categoryId: Value(tx.categoryId),
    accountId: Value(tx.accountId),
    memo: tx.memo == null ? const Value.absent() : Value(tx.memo),
    date: Value(tx.date),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}
```

**Stream mapping rule.** `watchByDay` composes `dao.watchByDay(...).asyncMap((rows) => Future.wait(rows.map(_toDomain)))`. `asyncMap` (not `map`) because `_toDomain` awaits the currency lookup. The day-bounded stream emits at most a single day's transactions per tick (typically < 20 rows), so the per-row PK lookup into `currencies` is trivially cheap; a DAO-level JOIN is not warranted for MVP.

**`Value.absent()` rule.** `id == 0` triggers autoincrement on insert; on update, the caller must pass the real id. `memo == null` uses `Value.absent()`, not `Value(null)` — otherwise Drift writes SQL `NULL` on every insert, blanking any DB-side default we might add later.

### 2.2 Categories

```dart
// --- private mapping helpers ---

Category _toDomain(CategoryRow row) => Category(
  id: row.id,
  icon: row.icon,
  color: row.color,
  type: switch (row.type) {
    'expense' => CategoryType.expense,
    'income' => CategoryType.income,
    final other => throw RepositoryException(
      'Unknown category type wire value "$other" for id ${row.id}',
    ),
  },
  l10nKey: row.l10nKey,
  customName: row.customName,
  sortOrder: row.sortOrder,
  isArchived: row.isArchived,
);

CategoriesCompanion _toCompanion(Category c) {
  return CategoriesCompanion(
    id: c.id == 0 ? const Value.absent() : Value(c.id),
    icon: Value(c.icon),
    color: Value(c.color),
    type: Value(switch (c.type) {
      CategoryType.expense => 'expense',
      CategoryType.income => 'income',
    }),
    l10nKey: c.l10nKey == null
        ? const Value.absent()
        : Value(c.l10nKey),
    customName: c.customName == null
        ? const Value.absent()
        : Value(c.customName),
    sortOrder: c.sortOrder == null
        ? const Value.absent()
        : Value(c.sortOrder),
    isArchived: Value(c.isArchived),
  );
}
```

The wire-value switch hard-codes `'expense'` / `'income'` per the M1 Stream B contract and the SQL `CHECK` constraint declared in `categories_table.dart`. Adding a third variant is a schema migration — deliberately locked at two mapping sites (`_toDomain`, `_toCompanion`) to catch accidental extensions.

---

## 3. Business rules and how they are enforced

One subsection per rule. Each names the exact enforcement point, the PRD citation, and the test in §6 that asserts it.

### 3.1 Category `type` lock after first use (guardrail G5)

**PRD:** lines **293–294** ("A category's `type` becomes immutable after the first transaction uses it"), **315** ("Used categories keep their current type forever"), **735–737**.

**Enforcement:** `CategoryRepository.save(Category)` on the update path.

```dart
Future<Category> save(Category category) async {
  if (category.id != 0) {
    final stored = await _dao.findById(category.id);
    if (stored == null) {
      throw RepositoryException('Category ${category.id} not found');
    }
    final storedType = _typeFromWire(stored.type);
    if (category.type != storedType) {
      final refCount = await _txDao.countByCategory(category.id);
      if (refCount > 0) {
        throw CategoryTypeLockedException(category.id);
      }
    }
    if ((stored.l10nKey ?? '') != (category.l10nKey ?? '')) {
      throw RepositoryException(
        'l10nKey mutation forbidden for category ${category.id}; use rename()',
      );
    }
  }
  // ... write path ...
}
```

**Both branches tested:**
- **Mutable branch:** no referencing transaction → `save` with a flipped `type` succeeds.
- **Locked branch:** exactly one referencing transaction → `save` with a flipped `type` throws `CategoryTypeLockedException`; the stored row is unchanged.

Tests: C-type-lock-01, C-type-lock-02 (§6).

### 3.2 Archive-instead-of-delete for referenced categories (guardrail G6)

**PRD:** lines **315–316**, **735** ("used categories can be archived but not deleted").

**Enforcement:** `CategoryRepository.delete(int)` inspects `transactions.category_id` via `TransactionDao.countByCategory`. If the count is non-zero, throws `CategoryInUseException` and the caller is expected to call `archive(id)` instead. Hard-delete is allowed only when `count == 0`.

```dart
Future<bool> delete(int id) async {
  final refCount = await _txDao.countByCategory(id);
  if (refCount > 0) {
    throw CategoryInUseException(id);
  }
  final removed = await _dao.deleteById(id);
  return removed > 0;
}
```

Archive writes `is_archived = 1` via the DAO; referenced rows remain queryable via `watchAll(includeArchived: true)`. Tests: C-archive-01, C-archive-02, C-delete-01 (§6).

### 3.3 Currency FK integrity on transaction save (guardrail G2, PRD 286)

**Enforcement:** `TransactionRepository.save(Transaction)` verifies `Currency.code` exists in `currencies` **before** insert/update. The `PRAGMA foreign_keys = ON` pragma in `AppDatabase.beforeOpen` is the SQLite-layer safety net, but the repository-side check runs first so the thrown exception is `CurrencyNotFoundException` (typed, carries the offending code) rather than an opaque `SqliteException`.

```dart
Future<Transaction> save(Transaction tx) async {
  final resolved = await _currencyDao.findByCode(tx.currency.code);
  if (resolved == null) {
    throw CurrencyNotFoundException(tx.currency.code);
  }
  // ... proceed with insert / update ...
}
```

Test: T-currency-fk-01 (§6).

### 3.4 Integer minor-unit arithmetic (guardrail G4, PRD 253-257)

**Enforcement:** the `TransactionsCompanion.amountMinorUnits` field is `Value<int>`. `_toCompanion` wraps `tx.amountMinorUnits` (already `int` on the Freezed model) directly. No `double`, no division, no `num`. The M1 stream locked the column type to `IntColumn`; Stream A simply does not introduce a conversion path.

**Pre-merge grep (enforced in CI via §10):**
```bash
grep -rnE 'double\s+\w*(amount|balance|rate|price)' lib/data/repositories/
```
Must return zero hits. `money_formatter` is the only file in the tree where `double` is permitted near money.

### 3.5 Repository-populated `createdAt` / `updatedAt` (PRD 291-293, M1-A §10.Q4)

**Enforcement:** `TransactionRepository.save`:

- **Insert** (`tx.id == 0`):
  `final now = _clock(); companion = _toCompanion(tx, createdAt: now, updatedAt: now);`
- **Update** (`tx.id != 0`):
  `final stored = await _dao.findById(tx.id); final now = _clock(); companion = _toCompanion(tx, createdAt: stored.createdAt, updatedAt: now);`

`createdAt` is never re-read from the incoming `tx`: callers are free to hand back the model they got from any `watch*` stream (`watchByDay`, `watchForAccount`, `watchForCategory`), which already carries the stored `createdAt`, and we trust the stored row regardless. This is a deliberate belt-and-braces choice — one test case (T-timestamps-03) proves a caller with a mangled `createdAt` in the incoming `Transaction` does not corrupt the stored value.

Tests: T-timestamps-01, T-timestamps-02, T-timestamps-03 (§6).

### 3.6 `l10nKey` stability under rename (guardrail G7, PRD 314 + 494)

**Enforcement:** Two complementary guards.

1. **`CategoryRepository.rename(id, customName)`** writes **only** the `custom_name` column via a `CategoriesCompanion` whose every other field is `Value.absent()`. It never touches `l10n_key`.

```dart
Future<Category> rename(int id, String? customName) async {
  final normalized = (customName?.trim().isEmpty ?? true) ? null : customName!.trim();
  await _dao.updateRow(CategoriesCompanion(
    id: Value(id),
    customName: normalized == null
        ? const Value(null)
        : Value(normalized),
  ));
  final updated = await _dao.findById(id);
  if (updated == null) throw RepositoryException('Category $id not found');
  return _toDomain(updated);
}
```

   `Value(null)` on `customName` is intentional here — the semantics of rename include "clear the override", which requires an explicit SQL `NULL`. Every other column is `Value.absent()` so the `UPDATE` statement touches only `custom_name`.

2. **`CategoryRepository.save`** rejects any update that changes `l10nKey` (§3.1). Callers who need to set or clear an `l10nKey` must do so via the seed module (Stream C), not via `save`.

Stream C's seed is contractually forbidden from rewriting `l10n_key` once the row exists. It must go through `upsertSeeded(...)`, which keeps identity fixed by `l10nKey` while updating the seed-owned fields. Stream A's contribution is making `save` refuse arbitrary `l10nKey` mutation so a buggy caller cannot silently renumber rows.

Test: C-rename-01, C-rename-02, C-rename-03, C-l10nkey-lock-01 (§6).

### 3.7 Reactive stream emissions on every write (PRD 100-102)

Drift's `.watch()` re-emits whenever any statement writes to the watched table. This is behavior Stream A gets for free from `TransactionDao.watchInDateRange(...)` / `TransactionDao.watchDistinctActivityDays(...)` / `TransactionDao.watchByAccount(...)` / `TransactionDao.watchByCategory(...)` / `CategoryDao.watchAll()` — **so long as** every write goes through the DAO. The repository's `save`/`delete`/`rename`/`archive` methods funnel through `dao.insert` / `dao.updateRow` / `dao.deleteById` / `dao.archiveById`; none of them bypasses via `customStatement`.

Tests assert emissions by subscribing to the stream with a `StreamQueue` (package:async), performing a write, and awaiting the next item. Tests: T-day-01, T-days-01, T-stream-02, T-stream-03, C-stream-01, C-stream-02 (§6).

---

## 4. Reactive streams — composition detail

### 4.1 `TransactionRepository.watchByDay(DateTime day)`

```dart
@override
Stream<List<Transaction>> watchByDay(DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  return _dao
      .watchInDateRange(start: start, end: end)
      .asyncMap((rows) => Future.wait(rows.map(_toDomain)));
}
```

- **Local-time day window.** `DateTime(y, m, d)` builds a local-midnight boundary. The caller passes any `DateTime` whose date component is the target day; the repository does the canonicalization. This matches Home's UX: the user thinks in local time.
- **DAO boundary condition.** `watchInDateRange` uses `start <= date < end` (half-open interval). A transaction stamped at exactly local midnight belongs to the *later* day — consistent with how calendars render 00:00 as the start of a day.
- **`asyncMap`, not `map`.** `_toDomain` awaits `CurrencyDao.findByCode`. Using `map` would return `Stream<List<Future<Transaction>>>`.
- **No `.distinct()`.** Adjacent emissions always come from a real DB mutation; Drift coalesces same-transaction writes already. Accept duplicate-looking emissions; controllers can `.distinct` at their layer if a widget complains.
- **DAO leaf addition.** `TransactionDao.watchInDateRange({DateTime start, DateTime end})` is added by this stream as a leaf extension to `lib/data/database/daos/transaction_dao.dart` (see §5 task A3.3; ownership exception approved 2026-04-22 per §12 Q1).

### 4.2 `TransactionRepository.watchDaysWithActivity({int limit = 365})`

```dart
@override
Stream<List<DateTime>> watchDaysWithActivity({int limit = 365}) {
  return _dao
      .watchDistinctActivityDays(limit: limit)
      .map((localMidnights) => List.unmodifiable(localMidnights));
}
```

- DAO emits `List<DateTime>` of distinct local-midnight instants, newest first. The SQL groups by `date(date, 'localtime')` and orders descending; the DAO converts back to `DateTime` at local midnight before handing to the repo.
- The `limit` default of 365 caps the set for UI paging. A user with activity across > 365 distinct days is a future-tense concern (cursor pagination lands in Phase 2 per PRD → Pagination).
- No currency lookup is needed here — the method returns plain `DateTime` instances, so `map` suffices. Cheap.
- **DAO leaf addition.** `TransactionDao.watchDistinctActivityDays({int limit})` is added by this stream as a leaf extension alongside `watchInDateRange` (see §5 task A3.3).

### 4.3 `TransactionRepository.watchForAccount(int accountId, {int limit = 200})` and `watchForCategory(int categoryId, {int limit = 200})`

Same shape as `watchByDay`, but the DAO call is `_dao.watchByAccount(accountId, limit: limit)` / `_dao.watchByCategory(categoryId, limit: limit)`. M1 ships `watchByAccount` already; `watchByCategory` is the thinnest possible DAO extension, added inline in this stream (§5 task A3.3).

### 4.4 `CategoryRepository.watchAll({CategoryType? type, bool includeArchived = false})`

```dart
@override
Stream<List<Category>> watchAll({CategoryType? type, bool includeArchived = false}) {
  final Stream<List<CategoryRow>> source = switch ((type, includeArchived)) {
    (null, false) => _dao.watchAll(includeArchived: false),
    (null, true) => _dao.watchAll(includeArchived: true),
    (final t?, false) => _dao.watchByType(_wireFromType(t)),
    // includeArchived+type composite: no DAO helper exists; compose inline.
    (final t?, true) => _dao
        .watchAll(includeArchived: true)
        .map((rows) => rows.where((r) => r.type == _wireFromType(t)).toList()),
  };
  return source.map((rows) => rows.map(_toDomain).toList());
}
```

- **Synchronous `map`** (vs `asyncMap` in transactions) — category mapping does not await. Cheaper.
- The fourth case (`type != null && includeArchived`) is the Categories management screen's "Show archived" toggle filtered by expense/income. No M1 DAO helper ships this combination — we filter on the Dart side rather than adding a fifth DAO method, because the row count is bounded (seeded categories + user custom; typically < 30).

### 4.5 Stream warm-up vs seed (coordination note)

Drift's `.watch()` emits an immediate first value when subscribed. If a Home controller subscribes **before** the Stream C seed routine has populated categories, the first emission is an empty list, and the UI flashes an empty state. M4's bootstrap sequence (PRD.md 223-234) guarantees seed runs before `runApp`; Stream A's contract is "behave correctly when subscribed; do not attempt to race the seed". Tests pin the clock and pre-seed fixtures before subscribing — see §6 Common test harness.

---

## 5. Implementation task breakdown

All tasks land on `feature/M3-Stream-A-repositories` (or the agent's equivalent) with one commit per checkbox block. Run after every task: `flutter test test/unit/repositories/ -r expanded`. Full matrix: §6.

### Phase A1. Skeleton + shared exception types

- [ ] **Task A1.1 — Pull in Stream B's shared exception base.** Verify `lib/data/repositories/repository_exceptions.dart` exists with `RepositoryException` + `CurrencyNotFoundException` per §1.3, then add Stream-A-local `CategoryTypeLockedException` / `CategoryInUseException` to `category_repository.dart`.
  - Commit: `feat(data): wire shared repository exceptions into Stream A repos`.

- [ ] **Task A1.2 — Remove the M0 TODO stub** in `lib/data/repositories/transaction_repository.dart`. Replace it with the abstract `TransactionRepository` interface plus a `DriftTransactionRepository` skeleton: constructor, `_clock` field, DAO getters, every method body `throw UnimplementedError(...)` for now. This is the "contract is frozen" marker — once merged, M5 controllers can import the interface and bootstrap can construct the concrete class.
  - Commit: `feat(data): freeze TransactionRepository interface and Drift implementation`.

- [ ] **Task A1.3 — Remove the M0 TODO stub** in `lib/data/repositories/category_repository.dart`. Same pattern as A1.2: abstract `CategoryRepository` interface plus `DriftCategoryRepository` skeleton, `throw UnimplementedError(...)`, and Stream-A-local category exception declarations.
  - Commit: `feat(data): freeze CategoryRepository interface and Drift implementation`.

### Phase A2. Test harness import

- [ ] **Task A2.1 — Import Stream C's in-memory harness.** By the M3 kick-off day, Stream C publishes `test/unit/repositories/_harness/test_app_database.dart` that returns a `AppDatabase(NativeDatabase.memory())` with seed currencies, two seed categories (one expense, one income), one account_type and one account. Verify it exists on `main` before starting tests. If Stream C has not merged the harness yet, block here and coordinate — **do not fork a local copy.**
  - Verify: `ls test/unit/repositories/_harness/test_app_database.dart`.
  - No commit for this task; it is a precondition gate.

### Phase A3. `TransactionRepository` — TDD by rule

- [ ] **Task A3.1 — Drift mapping helpers + happy-path insert.** Write `T-happy-01` (red), implement `_toDomain`/`_toCompanion` + `save` insert path + `getById`, make green.
  - Commit: `feat(data): TransactionRepository insert + getById + Drift mapping`.

- [ ] **Task A3.2 — `watchByDay` + `watchDaysWithActivity` reactive streams.** Write `T-day-01` (in-window emission), `T-day-02` (out-of-window exclusion), `T-day-03` (local-timezone boundary at midnight), and `T-days-01` (newest-first distinct-day set); implement `watchByDay` via `asyncMap` and `watchDaysWithActivity` via plain `map`. The DAO leaf additions are landed in task A3.3 — do that first.
  - Commit: `feat(data): TransactionRepository day-bounded streams for Home (watchByDay, watchDaysWithActivity)`.

- [ ] **Task A3.3 — DAO leaf additions for day-bounded + filtered streams.** Add three methods to `lib/data/database/daos/transaction_dao.dart`:
  - `Stream<List<TransactionRow>> watchInDateRange({required DateTime start, required DateTime end})` — half-open `[start, end)` filter, ordered `date DESC, id DESC`.
  - `Stream<List<DateTime>> watchDistinctActivityDays({int limit = 365})` — distinct local-midnight days, newest first, bounded.
  - `Stream<List<TransactionRow>> watchByCategory(int categoryId, {int limit = 200})` — alongside the existing `watchByAccount` (which is updated to take the same bounded `limit` parameter).
  Each method ships with a dartdoc backref to `docs/plans/m3-repositories-seed/stream-a-transaction-category.md § 4`. Keep the commit scoped to the DAO file plus this plan's test scaffold. This crosses M1 ownership — approval recorded in §12 Q1 (2026-04-22).
  - Commit: `feat(data): TransactionDao leaf methods for day-bounded + filtered transaction streams (G2)`.

- [ ] **Task A3.3b — `watchForAccount` + `watchForCategory`.** Implement both repository methods as thin `asyncMap` wrappers over the DAO helpers landed in A3.3. Write `T-stream-02` and `T-stream-03`.
  - Commit: `feat(data): TransactionRepository filtered streams (account, category)`.

- [ ] **Task A3.4 — Currency FK guard.** Write `T-currency-fk-01` (red — expects `CurrencyNotFoundException`), wire the pre-insert `CurrencyDao.findByCode` check.
  - Commit: `feat(data): reject TransactionRepository.save on unknown currency (G2)`.

- [ ] **Task A3.5 — Update path + timestamp policy.** Write `T-timestamps-01/02/03`, implement update branch that preserves `createdAt` and refreshes `updatedAt` from `_clock`.
  - Commit: `feat(data): TransactionRepository update preserves createdAt, bumps updatedAt`.

- [ ] **Task A3.6 — `delete`.** Write `T-delete-01/02` (happy + missing-id), implement.
  - Commit: `feat(data): TransactionRepository.delete`.

- [ ] **Task A3.7 — `duplicate`.** Write `T-duplicate-01/02/03`, implement in terms of `findById` + `save(insert)`. Confirm new `id`, new `createdAt`/`updatedAt`, all other fields copied, and the missing-source path throws `RepositoryException`.
  - Commit: `feat(data): TransactionRepository.duplicate (quick-repeat flow)`.

### Phase A4. `CategoryRepository` — TDD by rule

- [ ] **Task A4.1 — Happy-path CRUD + seed seam + mapping.** Write `C-happy-01`, `C-happy-02`, `C-seed-01`, and `C-seed-02`; implement `_toDomain`/`_toCompanion`, `save` insert path, `getById`, `getByL10nKey`, and `upsertSeeded`.
  - Commit: `feat(data): CategoryRepository insert, lookups, seed seam, and Drift mapping`.

- [ ] **Task A4.2 — `watchAll` with type and archive filters.** Write `C-stream-01/02/03/04`, implement the four-way switch in §4.4.
  - Commit: `feat(data): CategoryRepository.watchAll (type, includeArchived)`.

- [ ] **Task A4.3 — Type-lock update path (G5, mutable branch).** Write `C-type-lock-01` — no referencing transaction yet, flip type, expect success.
  - Commit: `feat(data): CategoryRepository.save update path (type mutable when unreferenced)`.

- [ ] **Task A4.4 — Type-lock update path (G5, locked branch).** Write `C-type-lock-02` — insert a transaction referencing the category, then flip type, expect `CategoryTypeLockedException`. This is the single most-regressed rule in the milestone; write the test **before** the guard.
  - Commit: `feat(data): reject CategoryRepository.save type mutation once referenced (G5)`.

- [ ] **Task A4.5 — Archive (G6).** Write `C-archive-01/02` (archive referenced row; watchAll omits by default, surfaces under `includeArchived: true`). Implement `archive`.
  - Commit: `feat(data): CategoryRepository.archive (non-destructive flag flip)`.

- [ ] **Task A4.6 — Delete guards (G6).** Write `C-delete-01` (unused custom category → delete succeeds) and `C-delete-02` (used category → `CategoryInUseException`). Implement `delete`.
  - Commit: `feat(data): CategoryRepository.delete with CategoryInUseException guard (G6)`.

- [ ] **Task A4.7 — Rename preserves `l10nKey` (G7).** Write `C-rename-01/02/03` (set, clear, empty-string normalized to null); implement `rename` touching only `custom_name`.
  - Commit: `feat(data): CategoryRepository.rename writes custom_name only (G7)`.

- [ ] **Task A4.8 — `l10nKey` mutation guard (G7 defence).** Write `C-l10nkey-lock-01` — call `save` on a seeded row with a different `l10nKey` value, expect `RepositoryException`.
  - Commit: `feat(data): reject CategoryRepository.save l10nKey mutation (G7 defence)`.

- [ ] **Task A4.9 — `isReferenced` probe.** Write `C-isref-01/02`, implement as a thin wrapper over `TransactionDao.countByCategory`.
  - Commit: `feat(data): CategoryRepository.isReferenced`.

### Phase A5. Sweep + exit criteria

- [ ] **Task A5.1 — Pre-merge money grep.** Run:
  ```
  grep -rnE 'double\s+\w*(amount|balance|rate|price)' lib/data/repositories/
  ```
  Must return zero hits (G4).

- [ ] **Task A5.2 — Drift-leak grep.** Run:
  ```
  grep -rnE '\b(TransactionRow|CategoryRow|TransactionsCompanion|CategoriesCompanion|AppDatabase)\b' lib/data/repositories/*.dart
  ```
  Every hit must be inside an import, a private helper, a private field, or the concrete `Drift*Repository` constructor/private state. Public repository interfaces must not mention any of these Drift/database types. (Expected hits: imports + `_toDomain` / `_toCompanion` bodies + the `_db` field + concrete constructor wiring.)

- [ ] **Task A5.3 — Full test run.** `flutter test test/unit/repositories/transaction_repository_test.dart test/unit/repositories/category_repository_test.dart -r expanded`. All tests green.

- [ ] **Task A5.4 — Lint gate.** `flutter analyze` clean. `dart format .` applied. Verify no `import_lint` violations (import of `data/database/daos/*` outside `data/repositories/` is what G1 blocks).

- [ ] **Task A5.5 — Cross-stream checkpoint.** Ping Stream B and Stream C owners: confirm `repository_exceptions.dart` compiles cleanly when they import it, confirm `newTestAppDatabase()` + `TestRepoBundle` match §7.

- [ ] **Task A5.6 — Merge.** Squash-merge in the same PR window as Streams B and C. Per the M3 plan, the three streams overlap the same Drift transaction API and should not sit in isolation long enough to accumulate rebase churn.

---

## 6. Test plan

### 6.1 File layout

| Path                                                                                       | Responsibility                                    |
|--------------------------------------------------------------------------------------------|---------------------------------------------------|
| `test/unit/repositories/transaction_repository_test.dart` (new)                            | Every row in §6.3                                 |
| `test/unit/repositories/category_repository_test.dart` (new)                               | Every row in §6.4                                 |
| `test/unit/repositories/_harness/test_app_database.dart` (Stream C owns; Stream A imports) | In-memory `AppDatabase` factory + seeded fixtures |

Existing files — **do not touch**:
- `test/unit/repositories/category_dao_test.dart` (M1 regression guard on flat category schema).
- `test/unit/repositories/migration_test.dart` (Stream C activates).

### 6.2 Common test harness

Every test in §6.3 / §6.4 uses the same `setUp` / `tearDown` shape:

```dart
import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/repository_exceptions.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/transaction.dart';

import '_harness/test_app_database.dart';

void main() {
  late AppDatabase db;
  late TestRepoBundle bundle;
  late TransactionRepository txRepo;
  late CategoryRepository catRepo;
  DateTime frozenNow = DateTime.utc(2026, 4, 22, 12, 0);

  setUp(() async {
    db = newTestAppDatabase();
    bundle = TestRepoBundle(db);
    await bundle.seedMinimalRepositoryFixtures();
    txRepo = DriftTransactionRepository(db, clock: () => frozenNow);
    catRepo = DriftCategoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ... groups below ...
}
```

`newTestAppDatabase()` (Stream C) returns a fresh in-memory `AppDatabase`, and `TestRepoBundle.seedMinimalRepositoryFixtures()` seeds the shared repository fixtures Stream A depends on:
- `currencies`: `USD(2, $)`, `JPY(0, ¥)`, `TWD(2, NT$)`.
- `categories`: one seeded expense (`category.food`, icon `'restaurant'`, color `0`), one seeded income (`category.salary`, icon `'work'`, color `1`).
- `account_types`: `accountType.cash`.
- `accounts`: one `Cash` account in USD with `id = 1`.
- No transactions pre-seeded.

Stream clock freezing uses the constructor parameter on `TransactionRepository`. `CategoryRepository` does not take a clock — it writes no timestamps.

### 6.3 `transaction_repository_test.dart` matrix

Test IDs prefixed `T-*`. Every row is a single `test(...)` invocation inside a named `group(...)`.

| ID               | Group             | Scenario                                                       | Assertion                                                                                           | PRD / Guardrail   |
|------------------|-------------------|----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|-------------------|
| T-happy-01       | save / getById    | Insert a valid USD expense                                         | `getById(inserted.id)` returns a `Transaction` with same data; `watchByDay(today)` emits length 1                   | 280-299           |
| T-happy-02       | save / getById    | Round-trip `memo == null`                                          | Inserted row has `memo == null`, not empty string                                                                   | 297               |
| T-day-01         | watchByDay        | Subscribe to today, insert one today + one yesterday               | Today's stream emits only the today row; reverse-chronological within the day                                       | 100-102, 938-943  |
| T-day-02         | watchByDay        | Subscribe, then delete a row in that day                           | Next emission excludes the deleted row                                                                              | 100-102           |
| T-day-03         | watchByDay (tz)   | Insert tx at `2026-04-22T23:59:59` local; query `watchByDay(22nd)` | Emission includes it. Insert tx at `2026-04-23T00:00:00` local; query `watchByDay(22nd)` emission excludes it       | local-time window |
| T-days-01        | watchDaysActivity | Seed activity on three distinct days                               | `watchDaysWithActivity()` emits a list of three local-midnight `DateTime`s, newest first, no duplicates             | 100-102           |
| T-days-02        | watchDaysActivity | Activity on same day from two different accounts                   | Only one `DateTime` emitted for that day                                                                            | 100-102           |
| T-stream-02      | watchForAccount   | Two accounts, insert into each                                     | `watchForAccount(accountId)` only emits transactions for its account; respects default `limit`                      | 100-102           |
| T-stream-03      | watchForCategory  | Two categories, insert into each                                   | `watchForCategory(categoryId)` only emits transactions for its category                                             | 100-102           |
| T-currency-fk-01 | save → FK         | Save `Transaction` whose `currency.code == 'XXX'` (not seeded)     | Throws `CurrencyNotFoundException('XXX')`; no row inserted (`watchByDay(today)` still length 0)                     | 286, G2           |
| T-timestamps-01  | save → timestamps | Insert at `frozenNow`                                              | Returned `createdAt == frozenNow && updatedAt == frozenNow`                                                         | 291-293           |
| T-timestamps-02  | save → timestamps | Update at `frozenNow + 1h`                                         | `updatedAt == frozenNow + 1h`; `createdAt` unchanged from insert                                                    | 291-293           |
| T-timestamps-03  | save → timestamps | Update with a mangled `Transaction.createdAt` (e.g. epoch 0)       | Stored `createdAt` is preserved (matches the original insert), not the incoming mangled value                       | 291-293 (defence) |
| T-delete-01      | delete            | Delete an inserted row                                             | Returns `true`; `getById` returns `null`; `watchByDay(today)` emits empty list                                      | 100-102           |
| T-delete-02      | delete            | Delete a non-existent id                                           | Returns `false`; no exception                                                                                       | 100-102           |
| T-duplicate-01   | duplicate         | Duplicate an existing row                                          | New row has different `id`, same `categoryId/accountId/currency/amountMinorUnits/memo/date`                         | 716-722           |
| T-duplicate-02   | duplicate         | Duplicate sets new timestamps                                      | `createdAt == updatedAt == frozenNow` on the duplicate, not the source's timestamps                                 | 716-722, 291-293  |
| T-duplicate-03   | duplicate         | Duplicate of a missing id                                          | Throws `RepositoryException`                                                                                        | 828-837           |
| T-amount-int-01  | save → money      | Insert `amountMinorUnits = 1500000000000000000` (ETH-scale)        | Round-trips exactly; no precision loss                                                                              | 253-257, G4       |

**Total:** 18 tests.

### 6.4 `category_repository_test.dart` matrix

Test IDs prefixed `C-*`.

| ID                | Group                   | Scenario                                                                        | Assertion                                                                           | PRD / Guardrail   |
|-------------------|-------------------------|---------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|-------------------|
| C-happy-01        | save / getById          | Insert a custom expense category                                                | Returned `Category` has new `id != 0`; `getById` round-trips                        | 301-320           |
| C-happy-02        | getByL10nKey            | Lookup seeded `category.food`                                                   | Returns non-null with matching `l10nKey`; lookup for `'not.a.key'` returns null     | 315 + idempotency |
| C-seed-01         | upsertSeeded            | Seed `category.food` into an empty DB                                           | Inserts once, returns row with matching `l10nKey`, `type`, `icon`, `color`          | 315, G7           |
| C-seed-02         | upsertSeeded            | Re-run seed for existing `category.food`                                        | Returns same logical row, does not create duplicate `l10n_key`                      | 315, G7           |
| C-stream-01       | watchAll                | Default watch (no type, no archived)                                            | Emits the two seeded categories, sorted as specified                                | 100-102           |
| C-stream-02       | watchAll / type filter  | `watchAll(type: CategoryType.expense)`                                          | Emits only expense rows                                                             | 100-102           |
| C-stream-03       | watchAll / archive flag | Archive a category, watch with `includeArchived: false` then `true`             | First emission excludes archived; second includes                                   | 315-316           |
| C-stream-04       | watchAll / both filters | `(type: income, includeArchived: true)` after archiving the seeded income       | Emits the archived income row (filtered-in-dart branch of §4.4)                     | 315-316           |
| C-type-lock-01    | save / type lock        | Unreferenced category — flip `type` and save                                    | Succeeds; new type persisted                                                        | 293-294, G5       |
| C-type-lock-02    | save / type lock        | Insert a transaction referencing the category; then save with flipped `type`    | Throws `CategoryTypeLockedException`; stored row's `type` unchanged                 | 293-294, G5       |
| C-archive-01      | archive                 | Archive a seeded category                                                       | `isArchived == true`; default `watchAll` omits it; `includeArchived: true` includes | 315-316, G6       |
| C-archive-02      | archive                 | Archive an already-archived row                                                 | Idempotent — returns same row, no exception                                         | 315-316           |
| C-delete-01       | delete                  | Delete a custom category that has **no** referencing transactions               | Returns `true`; `getById` returns `null`                                            | 315-316, G6       |
| C-delete-02       | delete                  | Delete a category that **has** one referencing transaction                      | Throws `CategoryInUseException`; row still present                                  | 315-316, G6       |
| C-rename-01       | rename                  | Rename seeded category to `"Meals"`                                             | `customName == "Meals"`; `l10nKey == "category.food"` unchanged                     | 314, 494, G7      |
| C-rename-02       | rename                  | Clear the rename by passing `null`                                              | `customName == null`; `l10nKey` unchanged                                           | 314, G7           |
| C-rename-03       | rename                  | Rename with `"   "` (whitespace) → treated as null                              | `customName == null`                                                                | 314, G7           |
| C-l10nkey-lock-01 | save / l10nKey lock     | Load seeded `category.food`, mutate `l10nKey` to `'category.different'`, `save` | Throws `RepositoryException`; stored `l10nKey` unchanged                            | 314, G7 (defence) |
| C-isref-01        | isReferenced            | Unused category                                                                 | Returns `false`                                                                     | 315-316           |
| C-isref-02        | isReferenced            | Category with one referencing transaction                                       | Returns `true`                                                                      | 315-316           |

**Total:** 20 tests.

### 6.5 Reactive-stream test recipe (applies to T-stream-0*, C-stream-0*)

```dart
test('T-day-01: insert into today triggers emission', () async {
  final today = DateTime(frozenNow.year, frozenNow.month, frozenNow.day);
  final queue = StreamQueue(txRepo.watchByDay(today));
  final first = await queue.next;
  expect(first, isEmpty);

  final inserted = await txRepo.save(_sampleTx(amount: 1234, date: frozenNow));
  final second = await queue.next;
  expect(second, hasLength(1));
  expect(second.single.id, inserted.id);
  expect(second.single.amountMinorUnits, 1234);

  await queue.cancel();
});
```

`StreamQueue` comes from `package:async`, which is already a transitive dependency of `flutter_test`. No `pubspec.yaml` changes required.

---

## 7. Integration points with sibling streams

### 7.1 Who owns what, this milestone

| Artifact                                                                     | Owner (stream)    | Consumed by                                                       |
|------------------------------------------------------------------------------|-------------------|-------------------------------------------------------------------|
| `lib/data/repositories/transaction_repository.dart`                          | **A (this plan)** | M4 bootstrap, M5 Home / Transactions / Accounts controllers       |
| `lib/data/repositories/category_repository.dart`                             | **A (this plan)** | M4 bootstrap, M5 Transactions / Categories controllers            |
| `lib/data/repositories/repository_exceptions.dart`                           | **B**             | Streams A, C; all M5 controllers that surface typed errors        |
| `lib/data/repositories/{account_type,account,currency}_repository.dart`      | B                 | M4 bootstrap, M5 Accounts / Categories / Transactions controllers |
| `lib/data/repositories/user_preferences_repository.dart`                     | C                 | M4 bootstrap, M5 Splash / Settings controllers                    |
| `lib/data/seed/first_run_seed.dart` (path TBD by Stream C)                   | C                 | M4 bootstrap                                                      |
| `test/unit/repositories/_harness/test_app_database.dart`                     | **C**             | A, B, C tests                                                     |
| Migration harness activation in `test/unit/repositories/migration_test.dart` | C                 | CI                                                                |

**Stream A does not:** touch accounts/currencies/prefs repositories; write the seed module; flip the migration-harness skip flag.

**Stream A does:** own the one-file extension of `TransactionDao.watchByCategory` (documented in task A3.3). That touches `lib/data/database/daos/transaction_dao.dart`, which M1 Stream A owns — but the extension is a leaf addition with no cross-cutting effect, and Stream A's PR is the natural home.

### 7.2 Merge order

Target the **same PR stack** (implementation-plan.md §5, M3 parallel-window note: "merge within a tight window — same week, ideally same PR stack"):

1. **Stream C harness** merges first (§6.1 imports it).
2. **Stream B shared exception contract** merges alongside or immediately after the harness.
3. **Streams A and B repository implementations** land in parallel PRs after those shared seams exist.
4. **Stream C seed + migration harness activation** lands last, because the seed consumes Stream A's and Stream B's repositories.

### 7.3 What Stream A exports to B / C

- `CategoryRepository.upsertSeeded(...)` for Stream C's first-run seed.
- Concrete `DriftTransactionRepository` / `DriftCategoryRepository` classes for M4 bootstrap and Stream C's shared test harness wiring.
- `TransactionRepository.watchForAccount`, `.watchForCategory` (C's seed does not use these, but Stream B's `AccountRepository` uses `TransactionDao.countByAccount` independently; we do not leak streams to B).
- No shared utility functions: Drift mapping is per-repo, not in a common `_mapping.dart`. Each repo's mapping is small enough that centralizing would be premature.

### 7.4 What Stream A imports from B / C

- **Nothing from B's runtime repositories.** Production code imports only the shared `repository_exceptions.dart` module (`RepositoryException` + `CurrencyNotFoundException`). Currency resolution still goes through `CurrencyDao` (M1 deliverable), not `CurrencyRepository`.
- **Nothing from C at runtime.** Stream A's tests import the Stream C harness; production code does not.

---

## 8. Guardrails enforced by this stream

Cross-referencing `docs/plans/implementation-plan.md` §6 — G1, G2, G4, G5, G6, G7, G12.

| #   | Rule                                                                       | Stream-A enforcement                                                                                                                 | Specific assertion                                                                                                                        |
|-----|----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| G1  | Only repositories write to the DB                                          | Every Drift write in §1 / §2 goes through a DAO, never via `customStatement`. Controllers/widgets cannot reach DAOs (`import_lint`). | No `customStatement(…INSERT…)` or `customStatement(…UPDATE…)` anywhere in `lib/data/repositories/{transaction,category}_repository.dart`. |
| G2  | Drift types never cross the repository boundary                            | §1.4 rule 2; §2 mapping helpers are private.                                                                                         | Task A5.2 grep shows every `TransactionRow`/`CategoryRow`/`*Companion` hit is inside a private member or a `_db.*Dao` getter.             |
| G4  | Money is `int` minor units end-to-end                                      | `Transaction.amountMinorUnits` is `int` on the Freezed model; `_toCompanion` wraps as `Value<int>`; no `double` introduced.          | Task A5.1 grep is zero hits. Test T-amount-int-01 round-trips `1500000000000000000` losslessly.                                           |
| G5  | Category `type` locked after first use                                     | §3.1 guard in `CategoryRepository.save`.                                                                                             | Tests C-type-lock-01 (mutable branch) and C-type-lock-02 (locked branch).                                                                 |
| G6  | Archive-instead-of-delete for referenced rows                              | §3.2 guard in `CategoryRepository.delete`.                                                                                           | Tests C-delete-01 (unused → hard delete), C-delete-02 (used → `CategoryInUseException`), C-archive-01 (archive is non-destructive).       |
| G7  | Seeded categories identified by `l10nKey`; renames write `customName` only | §3.6: `rename` touches only `custom_name`; `save` rejects `l10nKey` mutation.                                                        | Tests C-rename-01/02/03 (rename preserves `l10nKey`), C-l10nkey-lock-01 (save rejects `l10nKey` change).                                  |
| G12 | Tests organized by layer, not by feature                                   | New test files land under `test/unit/repositories/`.                                                                                 | `transaction_repository_test.dart` and `category_repository_test.dart` live in `test/unit/repositories/`, not in a per-feature folder.    |

G3 (controllers own presentation transformation), G8 (icons/colors indirection), G9 (bootstrap order), G10 (router redirect), G11 (layout primitives) are **out of scope** for this stream.

---

## 9. Risks specific to this stream

Each risk links to a prevention and a test or grep that would catch it.

1. **Type-lock bypass via `copyWith` on a cached model.** A controller reads a `Category`, calls `category.copyWith(type: CategoryType.income)`, and submits. Without the §3.1 check, the DAO writes it.
   - **Prevention:** §3.1 always re-reads the stored row and compares `storedType` before writing.
   - **Catch:** C-type-lock-02.

2. **`Value.absent()` vs `Value(null)` confusion.** `companion.copyWith(memo: null)` under Drift writes SQL `NULL`; `companion.copyWith(memo: Value(null))` also writes `NULL`; `companion.copyWith(memo: Value.absent())` leaves the column alone on `UPDATE`. Rename-with-null-to-clear uses `Value(null)` intentionally (§3.6); `_toCompanion` for transactions uses `Value.absent()` for null memo on **insert** to let future DB defaults work, and `Value(null)` would be equivalent at v1 because there is no memo default. The failure mode is subtle enough to deserve §2.1's inline rule statement.
   - **Prevention:** §2.1 rule; `_toCompanion` helpers audited in Task A3.1 review.
   - **Catch:** T-happy-02 (round-trip null memo), plus reviewer discipline.

3. **`.watch()` subscribing before seed completes, flashing empty state.** The M4 bootstrap guarantees seed runs before `runApp`; tests must not race. Stream A's tests explicitly seed fixtures via `TestRepoBundle.seedMinimalRepositoryFixtures()` in `setUp`.
   - **Prevention:** §4.5; §6.2.
   - **Catch:** any stream test would drift-fail if seed was racy; explicit expectation for first-emission content.

4. **Timezone boundary for `watchByDay`.** Comparing `transactions.date` as UTC against a local-midnight window silently misplaces transactions logged near midnight — a 23:59 local-time entry could land in the *next* day depending on the offset. The DAO helper `watchInDateRange` MUST receive the window as local-time `DateTime` and compare against the stored column after converting both sides consistently. Stored `date` values are written with `DateTime.now()` (local), so a local-vs-local comparison is the natural choice; the rule is "never mix local and UTC in the window math."
   - **Prevention:** §4.1 spells out `DateTime(day.year, day.month, day.day)` canonicalization; §4.2 notes the DAO groups by `date(date, 'localtime')`.
   - **Catch:** T-day-03 explicitly tests the 23:59/00:00 boundary pair.

5. **Stream C's harness contract drifts.** If `seedMinimalRepositoryFixtures()` changes which categories it seeds (e.g. drops the income one), C-stream-02 and type-lock tests silently break.
   - **Prevention:** Task A5.5 (cross-stream checkpoint).
   - **Catch:** CI test failure on Stream C's PR that changes the harness. A terse contract comment in `_harness/test_app_database.dart` documents the fixtures Streams A and B depend on.

6. **Silent FK miss when `PRAGMA foreign_keys` is OFF.** If a future hand-rolled DB connection forgets the `beforeOpen` pragma, `TransactionDao.insert` with a bogus `account_id` succeeds. The repository-side `CurrencyDao.findByCode` guard only covers `currency`; `accountId` / `categoryId` rely on SQLite FK enforcement.
   - **Prevention:** `AppDatabase.beforeOpen` sets `foreign_keys = ON` (M1 Stream A §4); not a Stream A concern to duplicate.
   - **Catch:** out-of-scope for this stream's tests; M4 bootstrap's DB-open smoke test covers it.

7. **`createdAt` stomp on update.** An agent re-implementing `save` shortcuts and passes the incoming `tx.createdAt` into the companion.
   - **Prevention:** T-timestamps-03 fails with a mangled incoming `createdAt`.
   - **Catch:** T-timestamps-03.

---

## 10. Exit criteria (definition of done)

Stream A is done when **all** hold:

- [ ] `lib/data/repositories/transaction_repository.dart` — implements the public API in §1.1, no `throw UnimplementedError` remains, TODO stub is gone.
- [ ] `lib/data/repositories/category_repository.dart` — implements the public API in §1.2, no `throw UnimplementedError` remains, TODO stub is gone.
- [ ] Stream A imports `lib/data/repositories/repository_exceptions.dart` from Stream B, uses `CurrencyNotFoundException` from that shared file, and keeps only Stream-A-specific leaf exceptions local per §1.3.
- [ ] `test/unit/repositories/transaction_repository_test.dart` — all 18 tests in §6.3 green, including **T-day-01 / T-day-03** (day-bounded emissions, local-timezone boundary) and **T-days-01** (distinct activity days).
- [ ] `test/unit/repositories/category_repository_test.dart` — all 20 tests in §6.4 green, including **C-type-lock-02 ("reject `type` change after first referencing transaction")** which is the mandatory M3 exit criterion from `implementation-plan.md` §5.
- [ ] `test/unit/repositories/category_dao_test.dart` (M1 regression) still green — not modified.
- [ ] `flutter analyze` clean. `dart format .` applied. `custom_lint` / `import_lint` clean.
- [ ] `grep -rnE 'double\s+\w*(amount|balance|rate|price)' lib/data/repositories/` returns zero hits (G4).
- [ ] No public method in either repository returns a Drift type (Task A5.2 grep).
- [ ] Every `watch*` method on the public surface is reactive — a write through `save` / `delete` / `archive` / `rename` / `duplicate` triggers the next emission (tests T-day-01/02, T-days-01, T-stream-02/03, C-stream-01/02/03/04).
- [ ] No public method named `watchAll` exists on `TransactionRepository`. Home queries day-by-day via `watchByDay` + `watchDaysWithActivity` per the Option B UX resolution (§12 Q2).
- [ ] Currency FK enforcement proven by T-currency-fk-01.
- [ ] Archive-instead-of-delete proven by C-delete-02 and C-archive-01.
- [ ] Category type-lock proven by C-type-lock-01 (mutable) and C-type-lock-02 (locked).
- [ ] Stream A's PR merges in the same window as Stream B's and does not block Stream C's seed PR.

---

## 11. Verification log

Captured 2026-04-22 when writing this plan (UTC). Commands to re-run for fresh verification:

| Verified            | Command                                                                                  | Finding                                                                                                                                                                                                                                                                                                                                                                                           |
|---------------------|------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Stub sizes          | `wc -l lib/data/repositories/{transaction,category}_repository.dart`                     | 10 lines (transaction), 9 lines (category) — both TODO-only                                                                                                                                                                                                                                                                                                                                       |
| Stub contents       | `cat lib/data/repositories/transaction_repository.dart` & `... category_repository.dart` | Matches the verbatim dumps in §0                                                                                                                                                                                                                                                                                                                                                                  |
| Drift tables        | `cat lib/data/database/tables/{transactions,categories}_table.dart`                      | Confirms integer `amountMinorUnits`, FK to `Currencies`/`Categories`/`Accounts`, `CHECK (type IN ('expense','income'))`, `is_archived BOOL DEFAULT false`                                                                                                                                                                                                                                         |
| Drift DAOs          | `cat lib/data/database/daos/{transaction,category}_dao.dart`                             | `watchAll`, `watchByDateRange`, `watchByAccount`, `watchById`, `findById`, `insert`, `updateRow`, `deleteById`, `countByCategory`, `countByAccount` on `TransactionDao`. No `watchByCategory` — to be added in Task A3.3. `CategoryDao` exposes `watchAll`, `watchByType`, `findById`, `findByL10nKey`, `insert`, `updateRow`, `deleteById`, `archiveById`                                        |
| Freezed models      | `cat lib/data/models/{transaction,category,currency}.dart`                               | `Transaction` has `int amountMinorUnits`, `Currency currency`, `DateTime createdAt`, `DateTime updatedAt` (both required, non-null). `Category` has `CategoryType type` (enum with wire values `'expense'` / `'income'`), nullable `l10nKey` / `customName`, `@Default(false) bool isArchived`. `Currency` has `required String code`, `required int decimals`, nullable `symbol` / `nameL10nKey` |
| `AppDatabase` shape | `cat lib/data/database/app_database.dart`                                                | `schemaVersion = 1`; all six DAOs registered; `beforeOpen` enables `PRAGMA foreign_keys = ON`; constructor takes `QueryExecutor` — ready for `NativeDatabase.memory()` injection in tests                                                                                                                                                                                                         |
| Existing repo tests | `ls test/unit/repositories/`                                                             | `category_dao_test.dart` (M1 regression on flat schema), `migration_test.dart` (Stream C will activate). Neither overlaps with this stream's new test files                                                                                                                                                                                                                                       |
| Git branch          | `git status --short` on `feature/M2-Core-utilities`                                      | Clean; Stream A will branch from the M3 kick-off base after M2 merges to `main`                                                                                                                                                                                                                                                                                                                   |

---

## 12. Open-question resolution log

All open questions surfaced during plan review on **2026-04-22**. Decisions are locked for this stream; cross-stream implications listed against each.

| #  | Question                                                                                                                                                                                                                                                       | Resolution                                                                                                                                                                                                                                                                                                                             | Plan impact                                                                                                                                                                                                        |
|----|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Q1 | Stream A needs leaf additions to `lib/data/database/daos/transaction_dao.dart` (an M1 deliverable). Approve the boundary crossing, or split into a separate M1-follow-up PR?                                                                                   | **Approved.** Stream A lands `watchInDateRange`, `watchDistinctActivityDays`, `watchByCategory` on `TransactionDao` in its own PR as leaf additions. Each method ships with a dartdoc backref to this plan. No M1-follow-up PR needed.                                                                                                 | §5 Task A3.3 captures the ownership exception and the exact DAO surface being added.                                                                                                                               |
| Q2 | `TransactionRepository.watchAll({int limit = 10000})` for the Home list vs day-by-day querying?                                                                                                                                                                | **Option B — full UX change.** Remove `watchAll` entirely. Repo exposes `watchByDay(DateTime day)` + `watchDaysWithActivity({int limit = 365})`. Home UX changes to "one day at a time with prev/next nav".                                                                                                                            | §1.1 API contract, §2.1 stream mapping rule, §3.7 test IDs, §4.1–4.3 composition detail, §5 tasks A3.2 + A3.3 + A3.3b, §6.3 test matrix, §6.5 reactive recipe, §10 exit criteria all rewritten for day-bounded UX. |
| Q3 | `CurrencyDao.findByCode` per-row on stream emissions — N+1 concern at MVP pagination cap?                                                                                                                                                                      | **Moot under Q2.** With `watchByDay`, each emission contains at most an intra-day row count (typically <20), so N+1 is trivially cheap. Kept `asyncMap` + per-row lookup; rejected both JOIN-at-DAO and in-memory cache (the cache would go stale when Phase 2 registers new tokens dynamically).                                      | §4.1 + §2.1 note the intra-day bound; §9 Risk #4 replaced with a timezone-boundary risk (which matters more now that day windows are the primary query).                                                           |
| Q4 | `_toDomain` throws `CurrencyNotFoundException` when FK-resolved currency is missing — keep the defensive throw, or drop it?                                                                                                                                    | **Drop.** The user correctly notes users never type currency codes by hand; every code in the DB was put there by the seed or by the controlled Phase 2 token-registration path. Combined with `PRAGMA foreign_keys = ON` and the pre-insert `save`-side FK check, the read-path throw is dead code. Replaced with `!` non-null assert. | §2.1 `_toDomain` helper simplified. `CurrencyNotFoundException` remains in the write path (`TransactionRepository.save` pre-insert check, §3.3) — that one is still required.                                      |
| Q5 | If Q2 is accepted, what exactly replaces the infinite-scroll Home?                                                                                                                                                                                             | **Day-by-day navigation.** One day shown at a time; prev/next affordance walks through days-with-activity (driven by `watchDaysWithActivity`). Empty gap days are skipped by the controller, not the repository.                                                                                                                       | §1.1 `watchDaysWithActivity` added explicitly to support this pattern. Downstream PRD / master-plan reconciliation flagged in §12 Follow-ups (below).                                                               |
| Q6 | `seedMinimalRepositoryFixtures()` shape contract — does Stream C's commitment (USD/JPY/TWD + 1 expense + 1 income + 1 Cash account_type + 1 USD Cash account) match Stream A's test needs?                                                                     | **Confirmed.** The contract is sufficient for every T-* and C-* test in §6. A terse fixture-contract comment will ship in `_harness/test_app_database.dart` — Stream C already plans this in its §C2.                                                                                                                                  | No plan change. Cross-stream checkpoint (§5 A5.5) confirms the match at merge time.                                                                                                                                |

### 12.1 Follow-ups triggered by these resolutions (not Stream A's responsibility)

These are downstream documents that diverge from Q2's Option B decision. Stream A flags but does NOT edit them.

- **`PRD.md` → Home Screen (line ~673).** Current text: "daily transaction list grouped by date, newest first". Needs rewording to "one day at a time with prev/next day navigation".
- **`PRD.md` → Layout Primitives → Home screen (lines ~781–786).** Current text shows an infinite `CustomScrollView` with a `SliverList` of day headers + transaction rows. Needs replacement with a single-day layout (summary strip + the day's transaction list + a prev/next day control).
- **`PRD.md` → Primary User Flow / Home interactions (lines ~709–714).** Should note that "returns to Home with new entry visible at the top" implicitly means "returns to Home pinned to the day of the just-saved transaction".
- **`docs/plans/implementation-plan.md` §5 M5 Home slice (lines ~260–261).** Describes "currency-grouped summary strip, sliver day list, FAB, swipe-to-delete + undo, duplicate entry point, pending badge". The "sliver day list" phrasing bakes in the old UX. Needs to read "single-day list with prev/next navigation" (or equivalent).
- **`CLAUDE.md` → Layout Primitives → Home.** Repeats the infinite `SliverList` shape; needs the same rewrite as PRD.
- **Stream B and Stream C plans.** No API-surface changes required (neither uses `TransactionRepository.watchAll`), but the `seedMinimalRepositoryFixtures` comment in Stream C's harness file should note that Stream A's tests rely on transactions being groupable into at least two distinct local-timezone days so T-day-03 / T-days-01 can exercise the timezone boundary.

These are listed for product-owner awareness. Resolving them is scope for whoever owns PRD / CLAUDE / master-plan edits — not for Stream A's implementer.

---

*When this plan conflicts with `PRD.md`, `PRD.md` wins. When it conflicts with `docs/plans/implementation-plan.md`, that plan wins. When both are silent on something this stream touches, stop and ask — do not invent. This stream's contract with M4/M5 is §1; its contract with Streams B and C is §7. Anything beyond those seams is over-reach.*
