# M3 — Stream B: `AccountTypeRepository` + `AccountRepository` + `CurrencyRepository` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Owner:** Agent B (Data)
**Milestone:** M3 — Repositories + first-run seed (`docs/plans/implementation-plan.md` §5, M3)
**Authoritative PRD ranges:** [`PRD.md`](../../../PRD.md)
- *Money Storage Policy*: lines **253–257**
- *MVP Currency Policy*: lines **259–261**
- `currencies` schema (PK `code`, `decimals` SSOT, `is_token` default false): lines **263–278**
- `account_types` schema (`l10n_key` vs `custom_name`, nullable `default_currency` FK, archive rules): lines **322–340**
- `accounts` schema (`account_type_id` NOT NULL, `currency` NOT NULL FK, `opening_balance_minor_units` INTEGER DEFAULT 0, archive-instead-of-delete): lines **342–362**
- *Default Account Types* (Cash + Investment seeded with `l10n_key`s, Neutral Variant 70 palette): lines **497–507**
- *Error Handling Pattern*: lines **828–838**
- *Testing Strategy → Repository Tests*: lines **938–943**
- *Default Categories → Color Source*: lines **456–458** (MD3 baseline — informs AccountType color constraint)

**Sibling streams (same milestone, merge within the same window):**
- Stream A — `TransactionRepository` + `CategoryRepository` + shared error base. Stream A depends only on the shared `repository_exceptions.dart` contract from this stream; its runtime repository logic stays on its own DAOs.
- Stream C — `UserPreferencesRepository` + first-run seed + migration test harness. Stream C depends on `CurrencyRepository.upsert` (seed fiats), `AccountTypeRepository.upsertSeeded` (seed Cash + Investment), and `AccountRepository.save` (seed one Cash account). Stream B exposes those writes and nothing more — seed policy lives in Stream C.

Stream B touches **no file owned by Stream A or Stream C**. The only cross-cutting file is the shared error-type module — ownership resolved in §7.

**Upstream dependency (must be green before starting):** M1 merged. Specifically:
- Drift tables `Currencies`, `AccountTypes`, `Accounts` in `lib/data/database/tables/` with the shape documented in `docs/plans/m1-data-foundations/stream-a-drift-schema.md` §2.1, §2.4, §2.5.
- DAOs `CurrencyDao`, `AccountTypeDao`, `AccountDao` in `lib/data/database/daos/` per §3.1, §3.4, §3.5 of the same plan.
- Freezed domain models `Currency`, `AccountType`, `Account` in `lib/data/models/` per `docs/plans/m1-data-foundations/stream-b-freezed-models.md`.
- `AppDatabase` with `PRAGMA foreign_keys = ON` in `beforeOpen` (M1 Stream A §4). Without this, every FK test in §6 silently passes.

Verified on disk 2026-04-22 — see §11.

**Stack:** `drift ^2.28.0`, `drift_flutter ^0.2.7`, `freezed ^3.1.0`, `flutter_test` (sdk), Dart `^3.11.5`, Flutter `>=3.41.6`. **No new dependencies.** `pubspec.yaml` is not modified by this stream.

**Goal:** Ship the repository SSOT for currencies, account types, and accounts — reactive `Stream<…>` reads, typed command writes, Drift → Freezed mapping inside the repository, business rules (archive-instead-of-delete, FK integrity, `l10n_key` identity, integer minor units) enforced once — so Stream C's seed has a thin `upsert` / `upsertSeeded` / `save` surface to call and the shared repository exception contract is frozen for the rest of M3.

**Architecture:** Three sibling files in `lib/data/repositories/`, each exporting an abstract repository interface plus a concrete `Drift*Repository` implementation that wraps exactly one DAO and returns Freezed domain models. Drift types (`Currency` the Drift row, `AccountRow`, `AccountTypeRow`, every `…Companion`) never leave these files. Shared exception types live in the narrow module `lib/data/repositories/repository_exceptions.dart` (owned by Stream B; coordinated with Stream A and Stream C — see §7). Tests are per-repository and consume the shared in-memory harness owned by Stream C at `test/unit/repositories/_harness/test_app_database.dart`; no temporary local harnesses.

**One-sentence gap to flag up front:** `lib/data/repositories/account_type_repository.dart` **does not exist on disk** (see §0). M0 scaffolding created every other repo as a TODO-only stub but skipped this one — almost certainly because `account_types` was a late addition to the schema. This plan creates the file; it is the first task (B0) before any implementation begins.

---

## 0. Current state of the files being replaced or created

### 0.1 `ls lib/data/repositories/` — confirming the missing stub

Run on disk 2026-04-22:

```text
$ ls /Users/bigtochan/Documents/dev/BigtoC/ledgerly/lib/data/repositories/
account_repository.dart
category_repository.dart
currency_repository.dart
transaction_repository.dart
user_preferences_repository.dart
```

**`account_type_repository.dart` is absent.** No `.tmp`, no typo, no `account_types_repository.dart`. The file must be created as part of task B0 below, with the TODO-stub header style the other M0-scaffolded repos use, before any tests or production code land against it. No other files are affected by this omission.

### 0.2 `lib/data/repositories/account_repository.dart` — full current content (8 lines)

```dart
// TODO(M3): `AccountRepository` — SSOT for accounts.
//
// Business rules enforced here:
//   - Archive-instead-of-delete for accounts referenced by any transaction
//     (guardrail G6).
//   - New accounts default to `user_preferences.default_currency`, but the
//     creator may override on insert.
//   - Integer minor-unit arithmetic on `opening_balance_minor_units`.
```

Stream B replaces this file in full.

### 0.3 `lib/data/repositories/currency_repository.dart` — full current content (3 lines)

```dart
// TODO(M3): `CurrencyRepository` — SSOT for currency rows. Exposes a
// `Stream<List<Currency>>` for seeded fiats (+ Phase 2 tokens) and typed
// read helpers used by formatters and pickers.
```

Stream B replaces this file in full.

### 0.4 Adjacent files read and minimally extended by Stream B

Verified to match the M1 contract:

- `lib/data/database/tables/currencies_table.dart` — `Currencies` table, PK `code`, `decimals` INTEGER NOT NULL, `is_token` BOOL default false.
- `lib/data/database/tables/account_types_table.dart` — `AccountTypes` table, `l10nKey` nullable UNIQUE, `defaultCurrency` nullable FK, `icon` TEXT NOT NULL, `color` INTEGER NOT NULL, `is_archived` default false.
- `lib/data/database/tables/accounts_table.dart` — `Accounts` table, `accountTypeId` INTEGER NOT NULL FK → `account_types(id)`, `currency` TEXT NOT NULL FK → `currencies(code)`, `openingBalanceMinorUnits` INTEGER default 0, `icon` nullable, `color` nullable, `is_archived` default false.
- `lib/data/database/daos/currency_dao.dart` — `watchAll` / `findByCode` / `upsertAll` / `insert` / `updateRow`.
- `lib/data/database/daos/account_type_dao.dart` — `watchAll` (includes archived) / `watchActive` / `findById` / `findByL10nKey` / `insert` / `updateRow` / `archive` / `deleteById` / `hasReferencingAccounts`.
- `lib/data/database/daos/account_dao.dart` — `watchAll({includeArchived})` / `watchByType` / `findById` / `insert` / `updateRow` / `deleteById` / `archiveById` / `countByAccountType`. Stream B adds the leaf helper `Stream<AccountRow?> watchById(int id)` to this DAO as part of task B3 (§12 Q5; Stream A Q1 precedent for cross-stream DAO leaf extensions).
- `lib/data/models/currency.dart`, `lib/data/models/account_type.dart`, `lib/data/models/account.dart` — Freezed domain models. Already import the field names (`openingBalanceMinorUnits`, `isArchived`, etc.) the repositories will return.

**Missing DAO method flagged to Stream A** (NOT a Stream B deliverable, but needed by Stream B's `AccountRepository.isReferenced` / `delete` path): `TransactionDao.countByAccount(int accountId)` was specified in M1 §3.2 and confirmed by inspection. Used by `AccountRepository` to answer "is this account referenced?". If this DAO method is missing or misnamed in the merged main branch at start of M3, Stream B must coordinate with Stream A to add it before continuing.

---

## 1. Public API contracts (FROZEN on merge)

Downstream consumers (Stream A, Stream C, the M5 Accounts / Settings slices) will import these three classes by name. Do not change a signature without bumping every consumer in lock-step.

### 1.1 `lib/data/repositories/currency_repository.dart`

**Scope disclaimer.** `CurrencyRepository` is **read-mostly in MVP.** The only write path exercised in MVP is `upsert`, which the first-run seed (Stream C) calls for USD / EUR / JPY / TWD / CNY / HKD / GBP. Phase 2 reuses `upsert` for token registration (ETH, USDC, USDT, …). No `delete`, no `archive`, no `rename` in MVP — `currencies` has no `is_archived` column (PRD 263–278) and rename is a Phase 2 concern. The test plan in §6.1 reflects this honestly.

```dart
import '../models/currency.dart';

abstract class CurrencyRepository {
  /// Emits the current set of known currencies whenever the underlying
  /// row set changes. Ordered by `sort_order NULLS LAST, code ASC`.
  ///
  /// [includeTokens] defaults to `false` — MVP ships only fiats. Phase 2
  /// callers (wallet sync, token registration) pass `true`. The Drift
  /// column `is_token` is the discriminator.
  Stream<List<Currency>> watchAll({bool includeTokens = false});

  /// One-shot read by PK. Returns null if the code is not registered.
  /// Used by `TransactionRepository` (Stream A) for FK pre-checks, by
  /// `AccountRepository` for FK pre-checks (§1.3), and by
  /// `MoneyFormatter` lookups when only a code is available.
  Future<Currency?> getByCode(String code);

  /// Insert-or-update by PK `code`. Used by the first-run seed (Stream C)
  /// and by Phase 2 token registration. Idempotent on the same `code`.
  ///
  /// **Safety rail:** when a row with [currency].`code` already exists,
  /// the existing `decimals` value is preserved — see §3.8. A token that
  /// changes its decimal width across Ankr metadata revisions would
  /// silently invalidate every stored amount; the repository blocks that
  /// by raising [CurrencyDecimalsMismatchException] rather than writing.
  Future<void> upsert(Currency currency);
}

final class DriftCurrencyRepository implements CurrencyRepository {
  DriftCurrencyRepository(this._db);

  final AppDatabase _db;
}
```

### 1.2 `lib/data/repositories/account_type_repository.dart` *(new file)*

```dart
import '../models/account_type.dart';

abstract class AccountTypeRepository {
  /// Emits all known account types. `includeArchived` defaults to
  /// `false` (picker-safe); settings / admin screens pass `true`.
  /// Ordered by `sort_order NULLS LAST, id ASC`.
  Stream<List<AccountType>> watchAll({bool includeArchived = false});

  /// One-shot read by PK. Null if absent.
  Future<AccountType?> getById(int id);

  /// Insert when `id == 0`, otherwise replace.
  /// Returns the row id.
  ///
  /// Validates that `defaultCurrency` (when non-null) points at a
  /// registered currency; throws [CurrencyNotFoundException] otherwise.
  /// On update, preserves the stored `l10nKey`; seeded-row identity changes
  /// go through [upsertSeeded], and user renames go through [rename].
  Future<int> save(AccountType accountType);

  /// Seed-only insert-or-update keyed by `type.l10nKey`. Used by Stream C's
  /// first-run seed so seeded account-type writes stay idempotent while
  /// user-facing writes continue to flow through [save]. Returns the row id.
  ///
  /// Fields on [type] that are ignored by this write path:
  ///   - `id` — seed always passes `0`; the row is located by `l10nKey`.
  ///   - `customName` — seed always passes `null`; user renames flow through [rename].
  ///   - `isArchived` — seed always passes `false`.
  ///
  /// Throws [ArgumentError] when `type.l10nKey == null` or
  /// `type.defaultCurrency == null`. Seeded types must identify themselves
  /// by an `l10nKey` (guardrail G7) and carry a default currency (PRD 497–507).
  /// These are programming-error guards on the seed caller, not data errors —
  /// they do not extend [RepositoryException].
  Future<int> upsertSeeded(AccountType type);

  /// Rename a seeded account type. Writes `custom_name` only;
  /// `l10n_key` is preserved so locale changes do not duplicate or
  /// orphan the row (PRD 336–337, CLAUDE.md → Data-Model Invariants).
  /// Guardrail G7.
  Future<void> rename({required int id, required String customName});

  /// Marks the row archived. Archiving does NOT cascade to accounts of
  /// this type (PRD 358 — "archiving an account type does not
  /// cascade-archive accounts").
  Future<void> archive(int id);

  /// Hard-delete. Only succeeds when no `accounts` row references this
  /// type. Otherwise throws [AccountTypeInUseException] — callers are
  /// expected to call [archive] instead. PRD 339 + guardrail G6.
  Future<void> delete(int id);

  /// Cheap existence probe. Returns true when any `accounts` row
  /// references this type, regardless of `is_archived`. Used by the
  /// Settings screen to decide between enabling "Delete" vs "Archive"
  /// on the row action menu.
  Future<bool> isReferenced(int id);
}

final class DriftAccountTypeRepository implements AccountTypeRepository {
  DriftAccountTypeRepository(this._db, this._currencies);

  final AppDatabase _db;
  final CurrencyRepository _currencies;
}
```

### 1.3 `lib/data/repositories/account_repository.dart`

```dart
import '../models/account.dart';

abstract class AccountRepository {
  /// Emits all accounts. `includeArchived` defaults to `false`.
  /// Ordered by `sort_order NULLS LAST, id ASC`. Streams emit on
  /// every insert / update / delete / archive of any row.
  Stream<List<Account>> watchAll({bool includeArchived = false});

  /// Single-account stream for the Edit Account screen. Emits null
  /// after delete. Emits every update.
  Stream<Account?> watchById(int id);

  /// One-shot read by PK. Null if absent.
  Future<Account?> getById(int id);

  /// Insert when `id == 0`, otherwise replace. Returns the row id.
  ///
  /// Validates:
  /// - `currency.code` exists in `currencies` (FK pre-check; Drift FK
  ///   will also fire, but the repository throws the typed
  ///   [CurrencyNotFoundException] for a clean controller story).
  /// - `accountTypeId` exists in `account_types`. Throws
  ///   [AccountTypeNotFoundException] otherwise.
  ///
  /// Default-currency resolution
  /// (`account_types.default_currency → user_preferences.default_currency
  ///  → 'USD'`, PRD 357) is **the caller's responsibility** (Stream C
  /// seed, M5 Accounts controller). This repository validates whatever
  /// the caller supplies; it does not read `user_preferences`.
  Future<int> save(Account account);

  /// Marks the account archived (`is_archived = 1`). Does NOT delete
  /// any transactions. Controllers call this when the user asks to
  /// delete an account that has transactions.
  Future<void> archive(int id);

  /// Hard-delete. Only succeeds when no `transactions` row references
  /// this account. Otherwise throws [AccountInUseException] — callers
  /// are expected to call [archive] instead. PRD 361 + guardrail G6.
  Future<void> delete(int id);

  /// Cheap existence probe. Returns true when any `transactions` row
  /// references this account. Used by the Accounts screen row-action
  /// menu to gate Delete vs Archive.
  Future<bool> isReferenced(int id);
}

final class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._db, this._currencies);

  final AppDatabase _db;
  final CurrencyRepository _currencies;
}
```

### 1.4 Error types — `lib/data/repositories/repository_exceptions.dart`

**Ownership:** this file is shared with Streams A and C. **Stream B creates and owns it** as task B4. Keep it narrow: the repository-layer base plus the leaf exceptions reused cross-stream (`CurrencyNotFoundException`, `CurrencyDecimalsMismatchException`, `AccountTypeNotFoundException`, `AccountTypeInUseException`, `AccountInUseException`). Stream-A-only category exceptions stay local to Stream A unless later reused.

```dart
/// Base for every typed repository exception. Never thrown directly —
/// subclasses carry the specific failure.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

/// `currencies` row for the requested code does not exist.
///
/// **Thrown on write paths only** — `AccountRepository.save` /
/// `AccountTypeRepository.save` / `upsertSeeded` pre-check the FK before
/// inserting. Read-path `_toDomain` helpers use a `!` non-null assert
/// instead (unreachable under `foreign_keys = ON` + write-side pre-check).
/// Aligns with Stream A Q4 / this stream's §12 Q3.
class CurrencyNotFoundException extends RepositoryException {
  const CurrencyNotFoundException(this.code)
      : super('Currency not registered: $code');
  final String code;
}

/// Attempt to upsert a currency whose `decimals` disagrees with the
/// row already stored for this code. Guards against token metadata
/// changing decimal width across Ankr revisions. See §3.8.
class CurrencyDecimalsMismatchException extends RepositoryException {
  const CurrencyDecimalsMismatchException({
    required this.code,
    required this.existingDecimals,
    required this.attemptedDecimals,
  }) : super(
          'Currency $code already registered with $existingDecimals '
          'decimals; refusing to overwrite with $attemptedDecimals.',
        );
  final String code;
  final int existingDecimals;
  final int attemptedDecimals;
}

/// `account_types` row for the given id does not exist.
class AccountTypeNotFoundException extends RepositoryException {
  const AccountTypeNotFoundException(this.id)
      : super('Account type not found: $id');
  final int id;
}

/// Hard-delete of an `account_types` row blocked by a referencing
/// `accounts` row. Caller should archive instead.
class AccountTypeInUseException extends RepositoryException {
  const AccountTypeInUseException(this.id)
      : super('Account type $id is in use and cannot be deleted.');
  final int id;
}

/// Hard-delete of an `accounts` row blocked by a referencing
/// `transactions` row. Caller should archive instead.
class AccountInUseException extends RepositoryException {
  const AccountInUseException(this.id)
      : super('Account $id is in use and cannot be deleted.');
  final int id;
}
```

Stream A imports this file's shared base / reused leaves but keeps category-only exceptions local to `category_repository.dart`. Those category exceptions are outside Stream B's contract surface.

### 1.5 Contract rules (non-negotiable once merged)

1. **Every amount field is `int` minor units.** `Account.openingBalanceMinorUnits` is the only money field in this stream; it stays `int`. `double` does not appear in any signature. Guardrail G4.
2. **Drift types do not leak.** `AccountRow`, `AccountTypeRow`, the Drift-generated `Currency` data class, and every `…Companion` are **private** to the repository file — never exported, never returned. Guardrail G2.
3. **Freezed `Currency` is returned, not the Drift `Currency` row.** Both are named `Currency`. The repo imports the Drift row with an `as drift` prefix (`import '../database/app_database.dart' as drift;`) or uses a local typedef to avoid the collision at call sites. Pattern locked in the template at the top of §2.1.
4. **Icons are string keys, colors are palette indices.** `Account.icon` / `AccountType.icon` are `String?` / `String`; `Account.color` / `AccountType.color` are `int?` / `int`. Never `IconData`, never `Color`, never ARGB. Guardrail G8.
5. **No read of `user_preferences` from these repositories.** `AccountRepository.save` takes the currency as an already-resolved `Currency`; the caller does the `account_types.default_currency → user_preferences.default_currency → 'USD'` walk. This keeps the dependency graph acyclic (UserPreferencesRepository is owned by Stream C and would otherwise depend on AccountTypeRepository which depends on CurrencyRepository which ends up cyclic if Accounts pulls prefs).
6. **Streams are backed by Drift `.watch()`.** No manual refresh, no `BehaviorSubject`. If a test asserts "stream emits after insert", it works by `.first` after the insert completes; Drift's stream fires within the same event loop turn.
7. **Exceptions are typed.** Typed exceptions over `Future.error`. No `try` / `catch` inside repositories that swallows — the only `try` / `catch` blocks re-throw or wrap into the typed exception set in §1.4.

---

## 2. Drift → Freezed mapping helpers

Each repository owns its own private mapping functions. The template is identical across files; write it once per repository — do not extract into a shared mapper module (keeps `import_lint` rules simple, keeps mapping local to the owner).

### 2.1 `CurrencyRepository` — `Currency` mapping

```dart
// Drift row `Currency` collides with Freezed `Currency`. Import with prefix.
import '../database/app_database.dart' as drift;
import '../models/currency.dart';

Currency _toDomain(drift.Currency row) => Currency(
      code: row.code,
      decimals: row.decimals,
      symbol: row.symbol,
      nameL10nKey: row.nameL10nKey,
      isToken: row.isToken,
      sortOrder: row.sortOrder,
    );

drift.CurrenciesCompanion _toCompanion(Currency currency) =>
    drift.CurrenciesCompanion(
      code: Value(currency.code),
      decimals: Value(currency.decimals),
      symbol: Value(currency.symbol),
      nameL10nKey: Value(currency.nameL10nKey),
      isToken: Value(currency.isToken),
      sortOrder: Value(currency.sortOrder),
    );
```

### 2.2 `AccountTypeRepository` — `AccountType` mapping

`AccountType.defaultCurrency` is a Freezed `Currency?` — not a string code. The mapper must resolve the FK via `CurrencyRepository.getByCode` or a pre-loaded map; do **not** over-query Drift per row.

Pattern: the repository takes an injected `CurrencyRepository` for the resolution. `watchAll` batches: read the AccountType rows, then read the currencies map once, then map rows.

```dart
Future<AccountType> _toDomain(AccountTypeRow row) async {
  // Read-path `!`-assert is safe under `foreign_keys = ON` + write-side
  // FK pre-check (§3.5-adjacent). §12 Q3 / Stream A Q4.
  final defaultCurrency = row.defaultCurrency == null
      ? null
      : (await _currencies.getByCode(row.defaultCurrency!))!;
  return AccountType(
    id: row.id,
    l10nKey: row.l10nKey,
    customName: row.customName,
    defaultCurrency: defaultCurrency,
    icon: row.icon,
    color: row.color,
    sortOrder: row.sortOrder ?? 0,
    isArchived: row.isArchived,
  );
}
```

For streams (`watchAll`), **branch on the `includeArchived` flag at the DAO boundary** (§12 Q6). `AccountTypeDao.watchActive` returns active-only rows; `AccountTypeDao.watchAll` returns everything. Picking the right DAO method per call avoids loading — and then currency-resolving — archived rows that the caller will throw away.

```dart
Stream<List<AccountType>> watchAll({bool includeArchived = false}) {
  final rowsStream = includeArchived
      ? _dao.watchAll()
      : _dao.watchActive();
  return rowsStream.asyncMap((rows) async {
    final codes = rows
        .map((r) => r.defaultCurrency)
        .whereType<String>()
        .toSet();
    final currencyByCode = <String, Currency>{};
    for (final code in codes) {
      final c = await _currencies.getByCode(code);
      // Non-null under FK ON; see _toDomain comment.
      currencyByCode[code] = c!;
    }
    return rows.map((r) => AccountType(
          id: r.id,
          l10nKey: r.l10nKey,
          customName: r.customName,
          defaultCurrency: r.defaultCurrency == null
              ? null
              : currencyByCode[r.defaultCurrency!]!,
          icon: r.icon,
          color: r.color,
          sortOrder: r.sortOrder ?? 0,
          isArchived: r.isArchived,
        )).toList(growable: false);
  });
}
```

**Decision (§12 Q6):** `AccountTypeRepository.watchAll` uses `AccountTypeDao.watchActive` when `includeArchived: false`, and `AccountTypeDao.watchAll` when `includeArchived: true`. The DAO already exposes both methods (M1 contract, §0.4); branching at the DAO boundary skips the wasted currency lookup on rows the caller will discard. The old "filter in-repo to keep DAO generic" justification does not apply — the DAO is not generic.

```dart
AccountTypesCompanion _toCompanion(AccountType t) => AccountTypesCompanion(
      id: t.id == 0 ? const Value.absent() : Value(t.id),
      l10nKey: Value(t.l10nKey),
      customName: Value(t.customName),
      defaultCurrency: Value(t.defaultCurrency?.code),
      icon: Value(t.icon),
      color: Value(t.color),
      sortOrder: Value(t.sortOrder == 0 ? null : t.sortOrder),
      isArchived: Value(t.isArchived),
    );
```

### 2.3 `AccountRepository` — `Account` mapping

`Account.currency` is a Freezed `Currency`, not a string code. Same resolution pattern as AccountType, but non-nullable: every row has a NOT NULL `currency` column, so the map lookup must always succeed. The read path uses a `!` non-null assert — `foreign_keys = ON` combined with the write-side FK pre-check in §3.5 makes the missing case unreachable in practice. Aligns with Stream A Q4 / §12 Q3; `CurrencyNotFoundException` lives only on write paths (§3.5).

```dart
AccountsCompanion _toCompanion(Account a) => AccountsCompanion(
      id: a.id == 0 ? const Value.absent() : Value(a.id),
      name: Value(a.name),
      accountTypeId: Value(a.accountTypeId),
      currency: Value(a.currency.code),
      openingBalanceMinorUnits: Value(a.openingBalanceMinorUnits),
      icon: Value(a.icon),
      color: Value(a.color),
      sortOrder: Value(a.sortOrder),
      isArchived: Value(a.isArchived),
    );
```

**Decision: `AccountRepository.watchAll` does NOT join with `AccountType`.** The returned `Account` domain model holds `accountTypeId: int`, not the full type. Rationale:
- Controllers that need the type display name already watch `AccountTypeRepository.watchAll` for the picker — they can join in the controller layer cheaply (`Map<int, AccountType> byId`).
- Joining in the repo forces every list-read to load every account type, even on the Home summary strip which does not render the type name.
- The `defaultCurrency` FK already costs one lookup per unique currency; adding an AccountType resolution doubles the per-row cost for zero UI gain.

Documented for the record. M5 Accounts controller is responsible for the zip when needed.

---

## 3. Business rules and how they are enforced

One rule per subsection, with the enforcement point, the PRD cite, and the test that proves it.

### 3.1 Archive-instead-of-delete for accounts with transactions (G6)

- **PRD cite:** lines 361 ("Accounts with existing transactions can be archived but not hard-deleted.")
- **Enforcement point:** `AccountRepository.delete(id)`.
- **Implementation:** call `_transactionDao.countByAccount(id)` (or `isReferenced`) before `_accountDao.deleteById(id)`. When count > 0, throw `AccountInUseException(id)`. When count == 0, delete.
- **Test (§6.3):** seeded transaction referencing account → `delete` throws `AccountInUseException`; no row ref → `delete` succeeds and `watchAll` emits without the row.
- **Note:** `isReferenced(id)` is the single source for the probe; `delete` internally calls `isReferenced` and throws with the same predicate. UI code may also call `isReferenced` to gate menu items.

### 3.2 Archive-instead-of-delete for account types with accounts (G6)

- **PRD cite:** lines 339 ("Account types with existing accounts can be archived but not hard-deleted. Unused custom account types may be deleted.")
- **Enforcement point:** `AccountTypeRepository.delete(id)`.
- **Implementation:** call `_accountTypeDao.hasReferencingAccounts(id)` — already existing in M1 — before `_accountTypeDao.deleteById(id)`. When true, throw `AccountTypeInUseException(id)`.
- **Critical gotcha:** `hasReferencingAccounts` counts **both archived and non-archived** accounts (it is a simple `EXISTS(SELECT 1 FROM accounts WHERE account_type_id = ?)` with no `is_archived` predicate — see the DAO implementation). This is intentional: a user who archived their only "Crypto Wallet" account expects to keep the archived row in history, so the type cannot be hard-deleted either. Archive the type instead.
- **Test (§6.2):** seed an account of the type → `delete` throws; archive the account → `delete` still throws (history preserved); hard-delete the account first → `delete` succeeds.

### 3.3 Account-type rename preserves `l10n_key` (G7)

- **PRD cite:** lines 337 ("Renaming a seeded account type writes `custom_name` but keeps `l10n_key`…"). Same rule as `categories` (PRD 316).
- **Enforcement point:** `AccountTypeRepository.rename({id, customName})`.
- **Implementation:** read the row, build a companion that sets `customName` and **explicitly does NOT touch `l10nKey`**, call `_dao.updateRow(companion)`.

    ```dart
    Future<void> rename({required int id, required String customName}) async {
      final row = await _dao.findById(id);
      if (row == null) throw AccountTypeNotFoundException(id);
      await _dao.updateRow(AccountTypesCompanion(
        id: Value(id),
        customName: Value(customName),
        // l10nKey explicitly preserved from the stored row.
        // defaultCurrency, icon, color, sortOrder, isArchived likewise.
        l10nKey: Value(row.l10nKey),
        defaultCurrency: Value(row.defaultCurrency),
        icon: Value(row.icon),
        color: Value(row.color),
        sortOrder: Value(row.sortOrder),
        isArchived: Value(row.isArchived),
      ));
    }
    ```

  Drift's `replace` does a full-row update; every column must be present in the companion. Omitting a column would set it to its SQL default. The pattern is verbose but safe.
- **Test (§6.2):** seed a row with `l10nKey: 'accountType.cash'` → call `rename(id, 'My Wallet')` → `findByL10nKey('accountType.cash')` still returns the row, now with `customName: 'My Wallet'`. Then call `rename(id, 'My Cash')` again; `l10nKey` is still preserved.

### 3.4 Seeded account-type identity survives locale changes (G7)

- **PRD cite:** lines 336–337 + 497–507 (Default Account Types: `accountType.cash`, `accountType.investment`).
- **Enforcement point:** `AccountTypeRepository.rename` (previous rule). Corollary: `save` preserves the stored `l10nKey` on update rather than trusting the caller-supplied value, while `upsertSeeded` is the only path allowed to manage seeded-row identity by `l10nKey`. Seed code (Stream C) always inserts with the l10n key set.
- **Implementation (§12 Q4, Option B — re-read and preserve):** on update (`type.id != 0`), `save` reads the current row by id and copies the stored `l10nKey` into the companion. The caller-supplied `type.l10nKey` is ignored on update. On insert (`type.id == 0`), the caller-supplied value is taken verbatim (first insert sets identity). Mirrors the `rename` template in §3.3.

    ```dart
    Future<int> save(AccountType type) async {
      // FK pre-check — see §3.5-adjacent.
      if (type.defaultCurrency != null) {
        final c = await _currencies.getByCode(type.defaultCurrency!.code);
        if (c == null) throw CurrencyNotFoundException(type.defaultCurrency!.code);
      }
      if (type.id == 0) {
        // Insert — caller-supplied l10nKey is authoritative.
        return _dao.insert(_toCompanion(type));
      }
      // Update — re-read to preserve stored l10nKey.
      final existing = await _dao.findById(type.id);
      if (existing == null) throw AccountTypeNotFoundException(type.id);
      await _dao.updateRow(AccountTypesCompanion(
        id: Value(type.id),
        l10nKey: Value(existing.l10nKey), // stored value wins
        customName: Value(type.customName),
        defaultCurrency: Value(type.defaultCurrency?.code),
        icon: Value(type.icon),
        color: Value(type.color),
        sortOrder: Value(type.sortOrder == 0 ? null : type.sortOrder),
        isArchived: Value(type.isArchived),
      ));
      return type.id;
    }
    ```
- **Test (§6.2) — round-trip scenario:** seed `accountType.cash` + `accountType.investment` → user renames Cash to "Wallet" → call `watchAll` → two rows, one with `l10nKey='accountType.cash', customName='Wallet'`, one with `l10nKey='accountType.investment', customName=null`. Re-running the seed is idempotent (Stream C's concern, exercised in Stream C's test).
- **Test (§6.2) — `save` cannot overwrite stored `l10nKey`:** seed with `l10nKey: 'accountType.cash'`; call `save` passing an `AccountType` with the same id but `l10nKey: 'accountType.wallet'`; assert the stored row's `l10nKey` is still `'accountType.cash'`. Proves Q4 Option B.

### 3.5 `accounts.currency` FK integrity (G2, G4-adjacent)

- **PRD cite:** lines 277 ("`transactions.currency`, `accounts.currency`, … are foreign keys to `currencies.code`.") + 349.
- **Enforcement point:** `AccountRepository.save(account)`.
- **Layering:** Drift-level FK (`foreign_keys = ON`) will raise a SQLite constraint error on insert if the code is missing. The repository pre-checks with `_currencies.getByCode(...)` and throws a **typed** `CurrencyNotFoundException` instead of letting a raw `SqliteException` escape — controllers need a typed error for the snackbar story (PRD 828–838). The SQLite FK is still on as a belt-and-suspenders safety net.
- **Test (§6.3):** `save(account with currency 'XYZ')` where `XYZ` has never been upserted → throws `CurrencyNotFoundException`, row count unchanged. `save(account with currency 'USD')` where `USD` is seeded → succeeds.

### 3.6 `accounts.account_type_id` FK integrity (G2)

- **PRD cite:** lines 348, 358.
- **Enforcement point:** `AccountRepository.save`.
- **Implementation:** pre-check with `_accountTypeDao.findById(id)`; throw `AccountTypeNotFoundException` when null. Same belt-and-suspenders argument as §3.5.
- **Test (§6.3):** `save(account with accountTypeId: 999)` with 999 unseen → throws `AccountTypeNotFoundException`.

### 3.7 Integer minor-unit arithmetic on `openingBalanceMinorUnits` (G4)

- **PRD cite:** lines 253–257 (Money Storage Policy), 350 (`DEFAULT 0`).
- **Enforcement point:** every Drift column, every Freezed field, every repository signature is `int`. No `double` anywhere in this stream.
- **Implementation:** `_toCompanion` wraps the field in `Value(a.openingBalanceMinorUnits)`; `_toDomain` reads it as `row.openingBalanceMinorUnits`. Both are `int`. The Freezed model already defaults it to `0`.
- **Test (§6.3):** explicit test with `openingBalanceMinorUnits: -12345` (debt-like) and `: 1500000000000000000` (18-digit ETH-width) round-trip exactly.
- **Pre-merge grep (G4):** `flutter analyze` + pre-merge `grep -n 'double.*\(amount\|balance\|rate\|price\)' lib/data/repositories/` in the stream's diff → zero hits. Run as the final task (G task) in §5.

### 3.8 `CurrencyRepository.upsert` preserves `decimals` + `sort_order` append-only (Phase-2 safety rail)

- **PRD cite:** lines 264–278 (`decimals` NOT NULL, SSOT); lines 271 (`sort_order` INTEGER).
- **Enforcement point:** `CurrencyRepository.upsert(currency)`.
- **Implementation:**
    ```dart
    Future<void> upsert(Currency currency) async {
      final existing = await _dao.findByCode(currency.code);
      if (existing != null && existing.decimals != currency.decimals) {
        throw CurrencyDecimalsMismatchException(
          code: currency.code,
          existingDecimals: existing.decimals,
          attemptedDecimals: currency.decimals,
        );
      }
      // Preserve existing sort_order when the caller did not set one.
      // Seed passes explicit sort_order; Phase 2 token registration may
      // pass null and let the row keep whatever order it had (or null).
      final effectiveSortOrder =
          currency.sortOrder ?? existing?.sortOrder;
      final companion = CurrenciesCompanion(
        code: Value(currency.code),
        decimals: Value(currency.decimals),
        symbol: Value(currency.symbol),
        nameL10nKey: Value(currency.nameL10nKey),
        isToken: Value(currency.isToken),
        sortOrder: Value(effectiveSortOrder),
      );
      if (existing == null) {
        await _dao.insert(companion);
      } else {
        await _dao.updateRow(companion);
      }
    }
    ```
- **Tests (§6.1):** upsert USD then upsert USD again with a new symbol → row updated, decimals unchanged, sort_order preserved. Upsert USD with `decimals: 4` after it was registered with `decimals: 2` → throws `CurrencyDecimalsMismatchException`.

### 3.9 Icons / colors are string keys + palette indices, never `IconData` / ARGB (G8)

- **PRD cite:** lines 319–320 (categories), 340 (account types), 351–352 (accounts), 820–823 (icon registry + color palette indirection).
- **Enforcement point:** Drift column types: `icon` is TEXT, `color` is INTEGER. Freezed field types: `String` / `String?` for icon, `int` / `int?` for color. Repository signatures match.
- **Test (§6.2, §6.3):** assert-on-type — construct a test row, round-trip, inspect the returned domain model: `expect(type.icon, isA<String>())`, `expect(type.color, isA<int>())`. Any drift to `IconData` would break compilation, which is the real guardrail.
- **Note:** no raw `Color` / `IconData` import lands in `lib/data/repositories/` by this stream — verified by pre-merge grep (G task).

### 3.10 `CurrencyRepository` is MVP read-mostly — documented

- **PRD cite:** lines 263–278. `currencies` has no `is_archived` column, no deletion flow. MVP does not ship `delete` or `archive` on this repo.
- **Enforcement:** the `CurrencyRepository` interface in §1.1 exposes only `watchAll`, `getByCode`, `upsert`. No TODO comments for Phase-2 methods in MVP — adding them later is additive and safe.
- **Phase 2 future-proofing:** `upsert` is deliberately generic enough to serve Phase 2 token registration. `watchAll({includeTokens: true})` is the Phase-2 switch; MVP callers never pass `true`.

---

## 4. Reactive streams

Drift `.watch()` is the foundation. Every stream-returning method composes from a DAO `.watch()`:

- `CurrencyRepository.watchAll` → `CurrencyDao.watchAll()` → `.map` Drift rows to Freezed. Filter `isToken == false` when `includeTokens == false` (MVP default).
- `AccountTypeRepository.watchAll` → branches on `includeArchived` (§12 Q6): `false` → `AccountTypeDao.watchActive()`; `true` → `AccountTypeDao.watchAll()`. Each branch `.asyncMap`s with currency resolution (§2.2).
- `AccountRepository.watchAll` → `AccountDao.watchAll(includeArchived: ...)` → `.asyncMap` with currency resolution.
- `AccountRepository.watchById` → `AccountDao.watchById(int id)` → `.asyncMap(_toDomain)`. The DAO method is added as part of task B3 as an M1-leaf extension (§12 Q5; Stream A Q1 precedent). Implementation inside `AccountDao`: `select(accounts)..where((t) => t.id.equals(id)).watchSingleOrNull()`.

**Emission invariant (proven in every rule test):** after any mutating call completes (insert / update / delete / archive), the `watchAll` stream emits a new snapshot. Drift handles the invalidation; tests assert it explicitly via `expectLater(stream, emitsInOrder([...]))` or by awaiting `stream.first` after the mutation.

**Caveat on `asyncMap`:** when the account-type stream emits a new snapshot before the currency lookup for the previous snapshot has finished, `asyncMap` processes in order but may coalesce. For MVP scale (10k transactions, dozens of accounts, handful of account types, ~10 currencies), the lookup is a handful of `SELECT WHERE code = ?` calls — effectively free. Test in §6.2 asserts ordering, not latency.

**Cross-stream coordination:** Stream C consumes `CurrencyRepository.upsert`, `AccountTypeRepository.upsertSeeded`, and `AccountRepository.save` for first-run seeding. Stream A consumes only the shared exception contract from this stream; no runtime cross-repository wiring.

---

## 5. Implementation task breakdown

Each task is a committable unit. The dev may stack them into a single PR or land them sequentially in the same merge window — but the **order is fixed** because B1 unblocks Stream A and B4 unblocks B1 / B2 / B3.

**Note on numbering (§12 Q7 + Q8):** B-tasks are numbered by topical grouping (`B0` reserved for filesystem scaffolding, `B4` for error types, `B5` for tests); the sections below appear in **dependency order**, not lexicographic order. Final task list: B4 → B1 → B2 → B3 → B5. B0 was folded into B2 (§12 Q8); no intermediate stub commit is made.

### B4. Error types module

- [ ] Create `lib/data/repositories/repository_exceptions.dart` with the six types in §1.4 (`RepositoryException` base + 5 subclasses).
- [ ] Export from each repository file that throws (Dart barrel-file is not required — consumers `import 'package:ledgerly/data/repositories/repository_exceptions.dart'` directly).
- [ ] Coordinate with Stream A: notify them in the PR description that `repository_exceptions.dart` now exists and that only cross-stream-reused leaf exceptions belong there; Stream-A-only category exceptions stay local unless reused.
- [ ] Commit as `feat(m3-b): shared repository exception types`. Lands first because B1's `CurrencyRepository.upsert` throws `CurrencyDecimalsMismatchException` and `CurrencyNotFoundException` — B1 will not compile without this module.

### B1. `CurrencyRepository` (read-mostly)

- [ ] Write the `CurrencyRepository` interface per §1.1.
- [ ] Write the concrete `DriftCurrencyRepository` implementation with `_toDomain` / `_toCompanion` helpers per §2.1.
- [ ] Implement `watchAll({includeTokens})` by `.map`-ing the DAO stream and filtering `isToken` in-repo.
- [ ] Implement `getByCode` by delegating to `CurrencyDao.findByCode` + `_toDomain`.
- [ ] Implement `upsert` with the `decimals` mismatch guard per §3.8.
- [ ] Commit as `feat(m3-b): CurrencyRepository`. This commit unblocks Stream C's seed wiring and freezes the shared currency exception contract early in the merge window.

### B2. `AccountTypeRepository`

- [ ] **(Absorbs former B0 — §12 Q8.)** Create `lib/data/repositories/account_type_repository.dart` (file does not exist on disk, §0.1) with the `AccountTypeRepository` interface + `DriftAccountTypeRepository` implementation per §1.2 and §2.2. No intermediate stub commit.
- [ ] Constructor stays DB-based per §1.2: `DriftAccountTypeRepository(AppDatabase db, CurrencyRepository currencies)`. Resolve DAOs from `db` inside the concrete class; do NOT widen the public constructor surface to raw DAOs.
- [ ] Implement `watchAll` with the DAO-branch + currency-resolution pattern in §2.2 (§12 Q6): `includeArchived: false` → `AccountTypeDao.watchActive`; `includeArchived: true` → `AccountTypeDao.watchAll`.
- [ ] Implement `getById` by `findById` + `_toDomain`. Remember: `_toDomain` is async because it resolves currency.
- [ ] Implement `save` per §3.4 (§12 Q4). Branch on `id == 0`: insert takes caller-supplied `l10nKey`; update re-reads the row and preserves the stored `l10nKey`.
- [ ] Implement `upsertSeeded(AccountType type)` per §1.2 (§12 Q1 + Q2). Throw `ArgumentError` when `type.l10nKey == null` or `type.defaultCurrency == null`. Locate the existing row via `AccountTypeDao.findByL10nKey(type.l10nKey!)`; insert when absent, update when present. Zero `id` / `customName` / `isArchived` before writing regardless of what the caller supplies.
- [ ] Implement `rename` per §3.3 — write `customName` only, preserve `l10nKey` + every other column.
- [ ] Implement `archive` by delegating to `AccountTypeDao.archive`.
- [ ] Implement `delete` per §3.2 — `hasReferencingAccounts` first, throw `AccountTypeInUseException`, otherwise `deleteById`.
- [ ] Implement `isReferenced` by delegating to `hasReferencingAccounts`.
- [ ] Commit as `feat(m3-b): AccountTypeRepository`. Unblocks Stream C's seed of Cash + Investment.

### B3. `AccountRepository`

- [ ] **Leaf extension to `AccountDao` (M1-adjacent, §12 Q5):** add `Stream<AccountRow?> watchById(int id)` to `lib/data/database/daos/account_dao.dart`, implemented as `select(accounts)..where((t) => t.id.equals(id)).watchSingleOrNull()`. Dartdoc backref: "See M3 Stream B plan §4 / §12 Q5." Commit as the first sub-commit of B3 so the repo code has a DAO method to wrap. Mirrors the Stream A Q1 precedent for cross-stream DAO leaf extensions.
- [ ] Replace the 8-line TODO stub (§0.2) with the `AccountRepository` interface + `DriftAccountRepository` implementation per §1.3 and §2.3.
- [ ] Constructor stays DB-based per §1.3: `DriftAccountRepository(AppDatabase db, CurrencyRepository currencies)`. Resolve `AccountDao`, `AccountTypeDao`, and `TransactionDao` from `db` inside the concrete class.
- [ ] Implement `watchAll({includeArchived})` + `watchById(id)` with currency resolution. `watchById` delegates to the new `AccountDao.watchById` and `.asyncMap`s through `_toDomain`.
- [ ] Implement `getById`.
- [ ] Implement `save` with **both** FK pre-checks (§3.5, §3.6). Branch on `id == 0` for insert vs replace. Return the id.
- [ ] Implement `archive` via `AccountDao.archiveById`.
- [ ] Implement `delete` per §3.1 — `_transactionDao.countByAccount(id) > 0` → throw `AccountInUseException`, else `deleteById`.
- [ ] Implement `isReferenced` via `_transactionDao.countByAccount(id) > 0`.
- [ ] Commit as `feat(m3-b): AccountRepository`. Unblocks Stream C's seed of the one Cash account + M5 Accounts slice.

### B5. Tests

- [ ] Create `test/unit/repositories/currency_repository_test.dart` per §6.1.
- [ ] Create `test/unit/repositories/account_type_repository_test.dart` per §6.2.
- [ ] Create `test/unit/repositories/account_repository_test.dart` per §6.3.
- [ ] Use the shared in-memory Drift harness owned by Stream C — see §7 for the ownership rule. Import the harness; do NOT duplicate.
- [ ] Each test file runs green in isolation: `flutter test test/unit/repositories/currency_repository_test.dart`.
- [ ] Commit each test file in its own commit (3 commits) so review can inspect the contract per-repo. Acceptable to bundle if the reviewer prefers — no rebase-hell concern since test files are isolated.

### G. Exit-criteria sweep

- [ ] Run `flutter test test/unit/repositories/` — all three files green.
- [ ] Run `flutter analyze` — clean.
- [ ] Run `grep -nE 'double.*\b(amount|balance|rate|price)\b' lib/data/repositories/` — **zero hits** (G4).
- [ ] Run `grep -nE '(IconData|\bColor\b|ARGB)' lib/data/repositories/` — **zero hits** outside of doc comments (G8).
- [ ] Verify `import_lint` is happy (layer-boundary rules, G1/G2): `flutter analyze` surfaces `import_lint` diagnostics.
- [ ] Confirm the stream tick: `expectLater(repo.watchAll(), emitsInOrder([isA<List<...>>(), ...]))` fires in each repo test — catches accidental broken stream wiring.

---

## 6. Test plan

Every repository has one test file. All three use the shared in-memory harness from Stream C — `newTestAppDatabase()` plus `TestRepoBundle` in `test/unit/repositories/_harness/test_app_database.dart` — with `foreign_keys = ON` and opt-in fixture helpers.

Minimum coverage below. Implementer may add more — none may be removed.

### 6.1 `test/unit/repositories/currency_repository_test.dart`

| #    | Test                                                                  | Method               | Assertion                                                                                                        | Rule cite |
|------|-----------------------------------------------------------------------|----------------------|------------------------------------------------------------------------------------------------------------------|-----------|
| CR01 | Empty DB → `watchAll` emits `[]`                                      | `watchAll`           | `expect(await stream.first, isEmpty)`                                                                            | §1.1      |
| CR02 | After `upsert(USD)` → `watchAll` emits `[USD]`                        | `watchAll`, `upsert` | Stream emits two snapshots in order: `[]` then `[USD]`                                                           | §4        |
| CR03 | `watchAll(includeTokens: false)` filters `isToken == true`            | `watchAll`           | Seed USD (`isToken: false`) and ETH (`isToken: true`); default call returns `[USD]`, `true` returns `[USD, ETH]` | §1.1      |
| CR04 | `getByCode('USD')` after upsert → Freezed Currency with decimals == 2 | `getByCode`          | Round-trip equality on every field                                                                               | §2.1      |
| CR05 | `getByCode('XYZ')` unregistered → null                                | `getByCode`          | `expect(result, isNull)`                                                                                         | §1.1      |
| CR06 | `upsert(USD)` twice is idempotent                                     | `upsert`             | Second call succeeds; `watchAll` emits `[USD]` both times (no duplicate)                                         | §3.8      |
| CR07 | `upsert` does NOT mutate `decimals` on an existing code               | `upsert`             | Upsert USD with decimals=2, then upsert USD with decimals=4 → throws `CurrencyDecimalsMismatchException`         | §3.8      |
| CR08 | `upsert` updates symbol / nameL10nKey on an existing code             | `upsert`             | Upsert USD symbol `$`, then upsert USD symbol `US$` (same decimals) → second `watchAll` snapshot shows `US$`     | §3.8      |
| CR09 | `upsert` preserves `sortOrder` when new value is null                 | `upsert`             | Upsert USD sortOrder=1, then upsert USD sortOrder=null → row keeps sortOrder=1                                   | §3.8      |
| CR10 | Drift data class is never returned                                    | All                  | Assert-on-type: `expect(result, isA<Currency>())` where `Currency` is the Freezed model (structural)             | §1.5.2    |

### 6.2 `test/unit/repositories/account_type_repository_test.dart`

Preconditions: every test first seeds USD (and sometimes JPY) via `CurrencyRepository.upsert`.

Seed-specific coverage also includes:
- `AT17`: `upsertSeeded(AccountType(l10nKey: 'accountType.cash', defaultCurrency: USD, …))` inserts once and returns the row id.
- `AT18`: re-running the same `upsertSeeded(AccountType(…))` updates the same logical row, preserves `l10nKey`, and does not duplicate rows.
- `AT19` (§12 Q2): `upsertSeeded(AccountType(l10nKey: 'accountType.cash', defaultCurrency: null, …))` throws `ArgumentError` and writes nothing.
- `AT20` (§12 Q2): `upsertSeeded(AccountType(l10nKey: null, defaultCurrency: USD, …))` throws `ArgumentError` and writes nothing.
- `AT21` (§12 Q4): `save` on an already-seeded row with a mutated `l10nKey` in the passed model leaves the stored `l10nKey` unchanged — proves Option B's re-read-and-preserve behavior.

| #    | Test                                                                     | Method                | Assertion                                                                                                                                          | Rule cite     |
|------|--------------------------------------------------------------------------|-----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| AT01 | Empty DB → `watchAll` emits `[]`                                         | `watchAll`            | `await stream.first` → `[]`                                                                                                                        | §1.2          |
| AT02 | `save(Cash seeded)` → `watchAll` emits `[Cash]`                          | `save`, `watchAll`    | Row round-trip preserves `l10nKey`, `icon`, `color`, `defaultCurrency`                                                                             | §1.2          |
| AT03 | `save` with unknown `defaultCurrency.code` → `CurrencyNotFoundException` | `save`                | Construct an AccountType with a Currency not upserted; expect throw                                                                                | §3.5-adjacent |
| AT04 | `save` with `defaultCurrency == null` → inserts row with NULL default    | `save`                | DAO round-trip: `row.defaultCurrency` is null                                                                                                      | §2.2          |
| AT05 | `rename(id, 'Wallet')` writes `customName` only; `l10nKey` preserved     | `rename`              | Seed with `l10nKey: 'accountType.cash'`; after `rename`, `findByL10nKey('accountType.cash')` still returns row with `customName: 'Wallet'`         | §3.3 G7       |
| AT06 | Second `rename` does not disturb `l10nKey`                               | `rename`              | Round-trip: two `rename` calls, `l10nKey` stable across both                                                                                       | §3.4          |
| AT07 | `rename` on nonexistent id → `AccountTypeNotFoundException`              | `rename`              | Expect throw                                                                                                                                       | §1.2          |
| AT08 | `archive(id)` marks archived; `watchAll()` default excludes archived     | `archive`, `watchAll` | Seed, archive, `watchAll` → row absent                                                                                                             | §1.2          |
| AT09 | `watchAll(includeArchived: true)` returns archived rows                  | `watchAll`            | Seed, archive, `watchAll(includeArchived: true)` → row present                                                                                     | §1.2          |
| AT10 | `delete(id)` with no referencing accounts → succeeds                     | `delete`              | Seed custom type with `l10nKey: null`, no accounts → `delete` succeeds, stream emits `[]`                                                          | §3.2          |
| AT11 | `delete(id)` with referencing account → `AccountTypeInUseException`      | `delete`              | Seed type + seed account of that type → `delete` throws; row unchanged                                                                             | §3.2 G6       |
| AT12 | `delete(id)` with archived referencing account → still throws            | `delete`              | Seed account, archive it, then call `delete(type.id)` → throws (history preserved)                                                                 | §3.2          |
| AT13 | `isReferenced` matches `delete` predicate                                | `isReferenced`        | Seed with account → true; delete account → false                                                                                                   | §1.2          |
| AT14 | `getById(id)` returns `AccountType` with resolved `defaultCurrency`      | `getById`             | Seed type with `defaultCurrency: USD`; `getById` returns a Freezed Currency matching USD                                                           | §2.2          |
| AT15 | Reactive emission after insert / update / delete / archive               | `watchAll`            | `emitsInOrder([ [], [row], [updatedRow], [] ])`                                                                                                    | §4            |
| AT16 | Guardrail G8 — `icon` is `String`, `color` is `int`                      | save / round-trip     | `expect(result.icon, isA<String>())`; `expect(result.color, isA<int>())`                                                                           | §3.9 G8       |
| AT19 | `upsertSeeded` rejects `defaultCurrency == null`                         | `upsertSeeded`        | `expect(() => repo.upsertSeeded(typeWithNullDefault), throwsArgumentError)`; `watchAll` still emits `[]`                                           | §1.2, §12 Q2  |
| AT20 | `upsertSeeded` rejects `l10nKey == null`                                 | `upsertSeeded`        | `expect(() => repo.upsertSeeded(typeWithNullL10nKey), throwsArgumentError)`; `watchAll` still emits `[]`                                           | §1.2, §12 Q2  |
| AT21 | `save` preserves stored `l10nKey` on update                              | `save`                | Seed with `l10nKey: 'accountType.cash'`; call `save` with same id but `l10nKey: 'accountType.wallet'`; stored `l10nKey` still `'accountType.cash'` | §3.4, §12 Q4  |

### 6.3 `test/unit/repositories/account_repository_test.dart`

Preconditions: seed USD + JPY via `CurrencyRepository.upsert`; seed one `accountType.cash` via `AccountTypeRepository.upsertSeeded`.

| #    | Test                                                                     | Method                | Assertion                                                                                               | Rule cite |
|------|--------------------------------------------------------------------------|-----------------------|---------------------------------------------------------------------------------------------------------|-----------|
| AC01 | Empty DB → `watchAll` emits `[]`                                         | `watchAll`            | `await stream.first` → `[]`                                                                             | §1.3      |
| AC02 | `save` happy path                                                        | `save`, `watchAll`    | Round-trip all fields: `name`, `accountTypeId`, `currency`, `openingBalanceMinorUnits`, `icon`, `color` | §1.3      |
| AC03 | `save` with unknown currency → `CurrencyNotFoundException`               | `save`                | Construct Account with `currency: Currency(code: 'XYZ', decimals: 2)` (never upserted) → expect throw   | §3.5 G2   |
| AC04 | `save` with unknown accountTypeId → `AccountTypeNotFoundException`       | `save`                | `accountTypeId: 999` (nonexistent) → expect throw                                                       | §3.6 G2   |
| AC05 | `save` round-trips `openingBalanceMinorUnits: -12345`                    | `save`                | `await getById(id)` returns `-12345` exactly                                                            | §3.7 G4   |
| AC06 | `save` round-trips `openingBalanceMinorUnits: 1500000000000000000` (ETH) | `save`                | 18-digit integer preserved as `int` (Dart int is 64-bit on VM, safe up to 2^63-1 ≈ 9.2e18)              | §3.7 G4   |
| AC07 | `archive(id)` hides row from default `watchAll`                          | `archive`             | Seed, archive, `watchAll()` default → row absent; `watchAll(includeArchived: true)` → present           | §1.3      |
| AC08 | `watchById(id)` emits null after delete                                  | `watchById`, `delete` | Seed, `watchById` emits the row, `delete` → stream emits null                                           | §4        |
| AC09 | `delete(id)` with no referencing transactions → succeeds                 | `delete`              | Seed, `delete` → stream empty                                                                           | §3.1      |
| AC10 | `delete(id)` with a referencing transaction → `AccountInUseException`    | `delete`              | Seed a transaction with `account_id = id` → `delete` throws; row still present                          | §3.1 G6   |
| AC11 | `isReferenced(id)` true when transaction exists, false otherwise         | `isReferenced`        | Seed / assert both branches                                                                             | §1.3      |
| AC12 | `watchAll` excludes archived by default; `sortOrder` respected           | `watchAll`            | Seed two accounts with `sortOrder: 1` / `sortOrder: 0`; archive one → remaining ordered                 | §2.3      |
| AC13 | `watchAll({includeArchived: true})` includes archived                    | `watchAll`            | Seed one archived + one active → both returned                                                          | §1.3      |
| AC14 | `getById` resolves `currency` to Freezed `Currency`                      | `getById`             | Returns Freezed Currency, not a string code                                                             | §2.3      |
| AC15 | Reactive emission after insert / update / archive / delete               | `watchAll`            | `emitsInOrder([ [], [a], [updated], [] ])`                                                              | §4        |
| AC16 | Guardrail G8 — `icon` is `String?`, `color` is `int?`                    | save / round-trip     | Accept nulls; `isA<String>()` / `isA<int>()` when non-null                                              | §3.9 G8   |

### 6.4 Shared test harness (reference — owned by Stream C)

Stream C creates `test/unit/repositories/_harness/test_app_database.dart` with:

```dart
AppDatabase newTestAppDatabase() => AppDatabase(NativeDatabase.memory());

class TestRepoBundle {
  TestRepoBundle(this.db);
  final AppDatabase db;
  // interface-typed repository collaborators backed by concrete Drift repos
}
```

Plus helpers for seeding the minimal shared repository fixtures. Stream B consumes this harness and **does not re-implement or temporarily duplicate it**.

---

## 7. Integration points with sibling streams

| Seam                            | Sibling stream | Direction                 | What Stream B exposes                                                                                                | What Stream B consumes                                                                                        |
|---------------------------------|----------------|---------------------------|----------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|
| Shared exception contract       | A              | B → A                     | `repository_exceptions.dart` (`RepositoryException`, `CurrencyNotFoundException`, etc.)                              | —                                                                                                             |
| Account referenced-by-txn probe | A              | B → A (via DAO contract)  | Stream B **calls** `TransactionDao.countByAccount` directly from `AccountRepository`                                 | Stream B **requires** `TransactionDao.countByAccount` to exist (M1 §3.2); Stream A owns the DAO               |
| Shared error types              | A              | Shared file, written by B | Stream B creates `lib/data/repositories/repository_exceptions.dart` with the base + 5 subclasses from §1.4           | Stream A imports the shared base / reused leaves and keeps category-only leaves local                         |
| Seed currencies                 | C              | B → C                     | `CurrencyRepository.upsert` — Stream C calls it 7× for MVP fiats                                                     | —                                                                                                             |
| Seed account types              | C              | B → C                     | `AccountTypeRepository.upsertSeeded` — Stream C calls it for `accountType.cash` + `accountType.investment`           | Stream B's seed seam validates the resolved `default_currency`; Stream C orders currencies first              |
| Seed Cash account               | C              | B → C                     | `AccountRepository.save` — Stream C calls it once with `accountTypeId = <cash.id>` and the resolved default currency | Stream B's `save` requires both upstream seeds to have landed — Stream C's ordering again                     |
| Shared test DB harness          | C              | C → B (Stream B consumes) | —                                                                                                                    | `test/unit/repositories/_harness/test_app_database.dart` with `newTestAppDatabase()` + `TestRepoBundle`       |
| Default-currency resolution     | C              | C owns the chain          | `AccountRepository.save` validates whatever currency the caller supplies; does NOT read user_prefs                   | Stream C's seed + the M5 Accounts controller own the `account_type.default_currency → user_pref → 'USD'` walk |

**Merge-window rule:** Streams A / B / C merge in the same week (implementation plan §5, "Streams overlap the same Drift transaction API — merge within a tight window"). The shared seams land first in this order:

1. **Stream C harness preflight (§12 Q9)** — Stream C merges `test/unit/repositories/_harness/test_app_database.dart` + `seedMinimalRepositoryFixtures` to `main` as its own small commit (or small PR) **before** Streams A or B open their tests PRs. Without this, Stream B's B5 tests import a file that does not yet exist and branch CI turns red. §6.4's ban on temporary local harnesses is what forces this ordering.
2. **`repository_exceptions.dart` (B4)** — lands next; B1 will not compile without it.
3. **`CurrencyRepository` (B1)** — unblocks Stream C's seed-currency call site and freezes the currency exception contract for Stream A.
4. **Remainder** — B2 / B3 / B5 and the parallel Stream A and Stream C commits land in whatever order each stream's own task graph dictates.

Stream B's PR description must call out precondition #1 explicitly so a reviewer does not accidentally merge Stream B's tests commit ahead of Stream C's harness.

**Field-name contract:** already frozen in `docs/plans/m1-data-foundations/stream-c-field-name-contract.md`. Stream B does not rename any field. Any pressure to rename (e.g. `openingBalanceMinorUnits` → `openingBalance`) is rejected; a rename would invalidate every M5 widget test.

---

## 8. Guardrails enforced by this stream

Cross-referenced to `docs/plans/implementation-plan.md` §6.

| #   | Rule                                                                          | Stream B enforcement                                                                                                                                             | Proven by                                         |
|-----|-------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------|
| G1  | Only repositories write to the DB / secure storage                            | Stream B's three repos are the only writers to `currencies`, `account_types`, `accounts`. `import_lint` blocks any non-repo from importing `data/database/daos`. | `flutter analyze` in task G                       |
| G2  | Drift types never cross the repository boundary                               | `AccountRow`, `AccountTypeRow`, Drift `Currency`, every `…Companion` stay in `lib/data/repositories/*.dart`; never exported. Prefix import for Drift `Currency`. | Inspection + `import_lint` + `grep` during task G |
| G4  | Money is `int` minor units end-to-end                                         | `Account.openingBalanceMinorUnits` stays `int`. No `double` in any signature. FK / amount columns store raw minor units.                                         | Test AC05 / AC06 + pre-merge grep in task G       |
| G6  | Archive-instead-of-delete for referenced rows                                 | `AccountRepository.delete` + `AccountTypeRepository.delete` each throw a typed exception when referenced; both branches tested.                                  | Tests AC10 / AT11 / AT12                          |
| G7  | Seeded rows identified by `l10n_key`; renames write `custom_name` only        | `AccountTypeRepository.rename` never mutates `l10nKey`. Seed (Stream C) identifies rows by `l10nKey`.                                                            | Tests AT05 / AT06                                 |
| G8  | Icons / colors are string keys + palette indices, never raw `IconData` / ARGB | `icon` is `String` / `String?`, `color` is `int` / `int?` throughout the stream. No Flutter `Color` / `IconData` imported in `lib/data/repositories/*.dart`.     | Tests AT16 / AC16 + task-G grep                   |
| G12 | Tests organized by layer, not by feature                                      | All tests land under `test/unit/repositories/` with one file per repo.                                                                                           | File layout at commit time                        |

Stream B does **not** enforce G3, G5, G9, G10, G11 — those are controller / bootstrap / router / layout concerns.

---

## 9. Risks specific to this stream

1. **Currency FK pre-check forgotten in `AccountRepository.save`.** Drift's FK would still fire at SQLite level, but the raised error is a `SqliteException` the controller cannot pattern-match. Enforce via test AC03 + code review. Mitigation: the `save` method's first lines read `_currencies.getByCode(currency.code)`. Omission is a missing-lines diff.
2. **Account-type archive silently cascading to accounts.** PRD 358 is explicit: archiving a type does NOT cascade. Risk: a dev writes a "cascade archive" convenience. Mitigation: no cascade method is defined in §1.2; test AT08 seeds an account of the type, archives the type, confirms the account is still active and visible.
3. **`custom_name` overwriting `l10n_key` by accident.** The `rename` implementation (§3.3) uses Drift's `replace`, which writes every companion field. Omitting `l10nKey` from the companion would silently set it to NULL. Mitigation: the template in §3.3 explicitly copies every other column from the existing row; test AT05 / AT06 proves it.
4. **Async map stream ordering under load.** `AccountTypeRepository.watchAll`'s `asyncMap` could, in principle, reorder snapshots during rapid seed + rename + archive bursts. MVP does not hit the load. Mitigation: test AT15 asserts ordering under rapid emits, and Dart's single-threaded event loop guarantees FIFO.
5. **Test harness divergence between streams.** If Stream B writes its own in-memory DB helper instead of consuming Stream C's canonical harness, the first full-tree `flutter test` run drifts immediately. Mitigation: §7 pins ownership to Stream C and §6.4 forbids local fallback helpers.
6. **Drift `Currency` vs Freezed `Currency` name collision.** Both classes are called `Currency`. Accidentally returning the Drift one breaks every controller cast. Mitigation: Import pattern in §2.1 — always `import '../database/app_database.dart' as drift;`. Pre-merge grep for `'../database/app_database.dart'` without a prefix in the repository diff.
7. **`isToken` filter forgotten in `watchAll({includeTokens: false})`.** MVP has no token rows, so the bug is invisible until Phase 2 land. Mitigation: test CR03 seeds an explicit ETH row (`isToken: true`) and asserts exclusion.
8. **Phase-2 pressure to add `CurrencyRepository.delete` / `archive`.** The schema lacks `is_archived` on `currencies`. Resist any Phase-2 addition here; tokens are append-only in the current PRD. Any future delete requires a schema change + new snapshot. Document at the top of the repo file.
9. **Stream A's `TransactionDao.countByAccount` drifting.** Stream B's `AccountRepository.delete` depends on this exact DAO method name. Mitigation: §0.4 calls it out; §5 task B3 explicitly lists it as a precondition; pre-PR checklist includes `grep -n 'countByAccount' lib/data/database/daos/transaction_dao.dart`.

---

## 10. Exit criteria (definition of done)

Direct mapping to `docs/plans/implementation-plan.md` §5 M3 exit criteria, scoped to Stream B:

- [ ] Stream C's harness preflight (`test/unit/repositories/_harness/test_app_database.dart` + `seedMinimalRepositoryFixtures`) has merged to `main` **before** this stream's B5 tests commit (§12 Q9). Verify by `git log main -- test/unit/repositories/_harness/` immediately before opening the Stream B tests PR.
- [ ] `test/unit/repositories/currency_repository_test.dart` exists and passes with every CR01–CR10 case from §6.1.
- [ ] `test/unit/repositories/account_type_repository_test.dart` exists and passes with every AT01–AT16 case from §6.2.
- [ ] `test/unit/repositories/account_type_repository_test.dart` includes the seeded-row idempotency cases `AT17` / `AT18` for `upsertSeeded`, the `ArgumentError` guards `AT19` / `AT20` (§12 Q2), and the `save`-preserves-`l10nKey` case `AT21` (§12 Q4).
- [ ] `test/unit/repositories/account_repository_test.dart` exists and passes with every AC01–AC16 case from §6.3.
- [ ] Happy path covered for each of three repos (CR02, AT02, AC02).
- [ ] Archive-instead-of-delete covered (AC10, AT11).
- [ ] Reactive stream emissions on insert / update / delete covered (CR02, AT15, AC15).
- [ ] Currency FK enforcement covered (AC03, AT03) — the master plan's required "currency FK enforcement" case.
- [ ] `CurrencyRepository` documented as read-mostly in the repo file's class dartdoc; only `watchAll` / `getByCode` / `upsert` exposed.
- [ ] `lib/data/repositories/account_type_repository.dart` exists (created in B0, implemented in B2).
- [ ] `lib/data/repositories/repository_exceptions.dart` exists with `RepositoryException` + 5 subclasses; Stream A and Stream C import it without edits from Stream B.
- [ ] `flutter analyze` clean on the branch.
- [ ] `grep -nE 'double.*\b(amount|balance|rate|price)\b' lib/data/repositories/` → zero hits (G4).
- [ ] `grep -nE '(IconData|ARGB)' lib/data/repositories/` → zero hits (G8).
- [ ] No Drift type (`AccountRow`, `AccountTypeRow`, Drift `Currency`, `…Companion`) appears in any method signature in `lib/data/repositories/*.dart` (G2).
- [ ] Cross-stream seams in §7 documented in the PR description so Stream A and Stream C merges land cleanly.

---

## 11. Verification log (what I read on disk, 2026-04-22)

- [x] `PRD.md` — lines 253–362 (currency policy, currencies schema, transactions schema, categories schema, account_types schema, accounts schema), lines 444–451 (migration strategy), lines 456–507 (default categories / account types), lines 820–923 (error handling, a11y, i18n, theme), lines 928–945 (testing strategy → repository tests). Cites in this plan use the numbering in the read output.
- [x] `docs/plans/implementation-plan.md` — §5 M3 row (`transaction_repository + category_repository` for Stream A; `account_type_repository + account_repository + currency_repository` for Stream B; `user_preferences_repository + seed + migration harness` for Stream C), §6 G1 / G2 / G4 / G6 / G7 / G8 / G12, §7 testing rollout, §9 top risks.
- [x] `CLAUDE.md` — Data-Model Invariants (currency SSOT, archive-instead-of-delete, icons / colors indirection, l10n_key identity, money storage integer minor units).
- [x] `docs/plans/m2-core-utilities/stream-a-money-date.md` — style template (structure, tone, depth, checkbox task format).
- [x] `docs/plans/m1-data-foundations/stream-a-drift-schema.md` — DAO contracts (§3.1, §3.4, §3.5), AppDatabase setup (§4 — `foreign_keys = ON` in `beforeOpen` — critical for test harness).
- [x] `lib/data/repositories/account_repository.dart` — 8-line TODO stub, full content at §0.2.
- [x] `lib/data/repositories/currency_repository.dart` — 3-line TODO stub, full content at §0.3.
- [x] `ls lib/data/repositories/` — confirms `account_type_repository.dart` absent, listed at §0.1.
- [x] `lib/data/database/tables/accounts_table.dart` — `account_type_id` INTEGER NOT NULL FK, `currency` TEXT NOT NULL FK, `opening_balance_minor_units` INTEGER default 0, `icon` TEXT nullable, `color` INTEGER nullable.
- [x] `lib/data/database/tables/account_types_table.dart` — `l10n_key` TEXT nullable UNIQUE, `default_currency` TEXT nullable FK, `icon` TEXT NOT NULL, `color` INTEGER NOT NULL.
- [x] `lib/data/database/tables/currencies_table.dart` — PK `code`, `decimals` INTEGER NOT NULL, `is_token` BOOL default false, `sort_order` INTEGER nullable.
- [x] `lib/data/database/daos/account_dao.dart` — `watchAll({includeArchived})`, `watchByType`, `findById`, `insert`, `updateRow`, `deleteById`, `archiveById`, `countByAccountType`. **Note:** no `watchById(int)` stream variant in the merged M1 code — Stream B adds it as part of task B3 if needed, or exposes `watchById` directly at the repository level via `select(accounts)..watchSingleOrNull()`.
- [x] `lib/data/database/daos/account_type_dao.dart` — `watchAll` (includes archived), `watchActive`, `findById`, `findByL10nKey`, `insert`, `updateRow`, `archive`, `deleteById`, `hasReferencingAccounts`.
- [x] `lib/data/database/daos/currency_dao.dart` — `watchAll`, `findByCode`, `upsertAll` (bulk `InsertMode.insertOrIgnore`), `insert`, `updateRow`. **Note:** no per-row `upsert` on the DAO — Stream B's `CurrencyRepository.upsert` composes `findByCode` + `insert` / `updateRow`.
- [x] `lib/data/models/account.dart` — Freezed `Account` with `openingBalanceMinorUnits: int`, `accountTypeId: int`, `currency: Currency`.
- [x] `lib/data/models/account_type.dart` — Freezed `AccountType` with `l10nKey: String?`, `customName: String?`, `defaultCurrency: Currency?`, `icon: String`, `color: int`.
- [x] `lib/data/models/currency.dart` — Freezed `Currency` with `code: String`, `decimals: int`, `symbol: String?`, `nameL10nKey: String?`, `isToken: bool`, `sortOrder: int?`.

---

## 12. Open-question resolution log

All open questions surfaced during plan review on **2026-04-22**. Decisions are locked for this stream; cross-stream implications listed against each. Format mirrors Stream A §12.

| #  | Question                                                                                                                                                                                                                                                                     | Resolution                                                                                                                                                                                                                                                                                                                                     | Plan impact                                                                                                                                                                                                                                                              |
|----|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Q1 | `AccountTypeRepository.upsertSeeded` takes discrete keyword args (`l10nKey`, `icon`, `color`, `defaultCurrency`, `sortOrder`) while `save` takes an `AccountType`. Keep the asymmetry, or pass a single `AccountType`?                                                       | **Pass a single `AccountType`.** Signature becomes `Future<int> upsertSeeded(AccountType type)`. Dartdoc notes that `id`, `customName`, and `isArchived` on the passed model are ignored; seed always supplies `id: 0`, `customName: null`, `isArchived: false`. Matches `save`'s shape and the "one model type per repo surface" pattern.     | §1.2 signature rewrites to `upsertSeeded(AccountType type)`. §6.2 AT17/AT18 bodies construct `AccountType` literals rather than passing keyword args.                                                                                                                    |
| Q2 | After Q1, `AccountType.defaultCurrency` is `Currency?` — does the seed path allow null, or must `upsertSeeded` reject it?                                                                                                                                                    | **Reject at runtime.** `upsertSeeded` throws `ArgumentError` when `type.defaultCurrency == null`. Plain `ArgumentError`, not a `RepositoryException` — this is a programming error on the seed caller, not a data error. PRD 497–507 (Cash + Investment) guarantees every seeded type has a default currency.                                  | §1.2 dartdoc adds the non-null guard. §6.2 adds a new case: `upsertSeeded` on an `AccountType` with `defaultCurrency: null` throws `ArgumentError` and writes nothing.                                                                                                   |
| Q3 | `_toDomain` throws `CurrencyNotFoundException` when a currency-by-code lookup misses in the read path (§2.2, §2.3). Keep the defensive throw, or drop it?                                                                                                                    | **Drop.** Mirrors Stream A Q4: `foreign_keys = ON` + write-side pre-check makes the read path unreachable for a missing code. Replace with a `!` non-null assert on the map lookup. Keep `CurrencyNotFoundException` only on write paths (`AccountRepository.save`, `AccountTypeRepository.save`, `upsertSeeded`).                             | §2.2 + §2.3 `_toDomain` helpers simplified (no throw in read path). §3.5 write-side pre-check unchanged. Note added in §1.4 dartdoc that `CurrencyNotFoundException` is write-only.                                                                                      |
| Q4 | `AccountTypeRepository.save` "preserves the stored `l10nKey` on update" (§3.4). Mechanism — trust the caller, re-read and preserve, or forbid `save` from touching `l10nKey` entirely?                                                                                       | **Re-read and preserve (Option B).** On update (`id != 0`), `save` reads the row by id and copies the stored `l10nKey` into the companion — identical pattern to `rename` (§3.3). On insert (`id == 0`), the caller-supplied `l10nKey` is taken verbatim (first insert sets identity).                                                         | §3.4 gets a code template (analogous to §3.3). §6.2 adds a test: `save` on a seeded row with a mutated `l10nKey` in the passed model leaves the stored `l10nKey` unchanged.                                                                                              |
| Q5 | `AccountDao` has no `watchById(int)` in the M1 contract (§0.4). Add the DAO method, or inline `select(accounts)..where(...).watchSingleOrNull()` in the repo?                                                                                                                | **Add `Stream<AccountRow?> watchById(int id)` to `AccountDao`** as an M1-leaf extension. Matches the Stream A Q1 precedent for cross-stream DAO leaf additions; keeps `import_lint` boundaries clean and makes `AccountRepository.watchById` a trivial `.map(_toDomain)` wrapper.                                                              | §4 wording changes from "add if missing" to "add as part of B3." §5 B3 gets an explicit task line for the DAO edit, with a dartdoc backref to this plan. §0.4's "DAO contract" note flags the addition.                                                                  |
| Q6 | `AccountTypeRepository.watchAll(includeArchived:false)` calls `AccountTypeDao.watchAll()` and filters archived rows in-repo (§2.2), even though `AccountTypeDao.watchActive` already exists (§0.4). Keep the in-repo filter, or branch on the flag?                          | **Branch on the flag.** `includeArchived:false` → `AccountTypeDao.watchActive`. `includeArchived:true` → `AccountTypeDao.watchAll`. Uses each DAO method as designed; skips the wasted currency lookup on archived rows.                                                                                                                       | §2.2 rewritten to show the `if (includeArchived) { … watchAll() } else { … watchActive() }` branch. The "keep DAO generic" comment is removed — the DAO is already non-generic.                                                                                          |
| Q7 | §5 task-section headers are ordered B0 → B1 → B2 → B3 → B4 → B5, but the note at line 683 says the real dependency order is B0 → B4 → B1 → B2 → B3 → B5 (B1's `upsert` throws exceptions defined in B4). Fix by renumbering or by reordering?                                | **Option 2 — reorder section headers, keep the task names.** §5 sections appear top-to-bottom in dependency order: B0 → B4 → B1 → B2 → B3 → B5. Add a one-line preamble at §5 top: "numbered by topical grouping; ordered below by dependency." Cross-references elsewhere in the plan use rule/test IDs, not B-numbers, so churn stays local. | §5 section order. §5 gets the preamble note. After Q8 folds B0 into B2 (below), the final order is B4 → B1 → B2 → B3 → B5.                                                                                                                                               |
| Q8 | §5 B0 creates an empty stub for `account_type_repository.dart` and commits it, only for B2 to overwrite the file. The original rationale ("so the rest of the branch can import it without a missing-file error") is moot — nothing in B4/B1 imports the file. Keep or drop? | **Fold B0 into B2.** Drop the B0 intermediate stub commit. B2's first sub-checkbox becomes "create `lib/data/repositories/account_type_repository.dart` with the interface + `DriftAccountTypeRepository` implementation." §0.1's note about the file being absent on disk stays — useful historical context.                                  | §5 task list loses B0; B2's first checkbox absorbs the file creation. Final task list: B4 → B1 → B2 → B3 → B5.                                                                                                                                                           |
| Q9 | Stream B's B5 tests import `test/unit/repositories/_harness/test_app_database.dart`, which Stream C owns. If Stream B commits tests before Stream C's harness lands, branch CI is red. What's the landing order?                                                             | **Option A — Stream C opens a preflight commit** (or a small PR) landing only `_harness/test_app_database.dart` + `seedMinimalRepositoryFixtures` to `main` **before** Streams A and B open their tests PRs. Matches §7's "shared seams land first" rule. Satisfies §6.4's ban on temporary local harnesses.                                   | §7 merge-order paragraph gets a cross-stream coordination note. §10 gains an exit-criterion: "Stream C's harness preflight has merged to `main` before this stream's tests commit." Both Stream A's and Stream B's PR descriptions call out the precondition explicitly. |

### 12.1 Follow-ups triggered by these resolutions (not Stream B's responsibility)

These are downstream items that the resolutions above imply but Stream B does not own. Stream B flags but does NOT edit them.

- **Stream C plan (`stream-c-preferences-seed-migration.md`).** Q9 adds a preflight-commit obligation: Stream C must land `_harness/test_app_database.dart` + `seedMinimalRepositoryFixtures` to `main` ahead of the rest of Stream C's seed + migration work. Stream C's plan should surface this as its own first task and merge checkpoint.
- **Stream C seed call site.** Q1 + Q2 change the `upsertSeeded` signature. Stream C's seed code constructs `AccountType` literals with `id: 0`, `customName: null`, `isArchived: false`, `defaultCurrency: <resolved non-null Currency>`. No API-level blocker; flagged so Stream C's plan reflects the shape.
- **Stream A plan (`stream-a-transaction-category.md`).** No API change here — Stream A already uses `repository_exceptions.dart` from Stream B. Q3's alignment with Stream A Q4 is retroactive confirmation, not a Stream A edit.
- **`AccountDao` (M1 deliverable).** Q5 adds `watchById(int)` as a leaf extension committed by Stream B. This is inside Stream B's task list (B3) per the Stream A Q1 cross-stream-DAO precedent — no separate M1 follow-up PR required.

These are listed for product / implementer awareness. Resolving them in sibling plans is scope for whoever owns those plans — not for Stream B's implementer.

---

*When this plan conflicts with `PRD.md`, `PRD.md` wins. When it conflicts with `docs/plans/implementation-plan.md`, that plan wins. When both are silent on something this stream touches, stop and ask — do not invent. This stream's contract with M4/M5 is §1; its contract with Streams A and C is §7. Anything beyond those seams is over-reach.*

End of plan.
