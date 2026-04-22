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
- Stream A — `TransactionRepository` + `CategoryRepository` + shared error base. Stream A depends on `CurrencyRepository.getByCode` (FK check on transaction save) and on `AccountRepository.getById` (nothing else crosses). Stream B ships those reads first.
- Stream C — `UserPreferencesRepository` + first-run seed + migration test harness. Stream C depends on `CurrencyRepository.upsert` (seed fiats), `AccountTypeRepository.save` (seed Cash + Investment), and `AccountRepository.save` (seed one Cash account). Stream B exposes those writes and nothing more — seed policy lives in Stream C.

Stream B touches **no file owned by Stream A or Stream C**. The only cross-cutting file is the shared error-type module — ownership resolved in §7.

**Upstream dependency (must be green before starting):** M1 merged. Specifically:
- Drift tables `Currencies`, `AccountTypes`, `Accounts` in `lib/data/database/tables/` with the shape documented in `docs/plans/m1-data-foundations/stream-a-drift-schema.md` §2.1, §2.4, §2.5.
- DAOs `CurrencyDao`, `AccountTypeDao`, `AccountDao` in `lib/data/database/daos/` per §3.1, §3.4, §3.5 of the same plan.
- Freezed domain models `Currency`, `AccountType`, `Account` in `lib/data/models/` per `docs/plans/m1-data-foundations/stream-b-freezed-models.md`.
- `AppDatabase` with `PRAGMA foreign_keys = ON` in `beforeOpen` (M1 Stream A §4). Without this, every FK test in §6 silently passes.

Verified on disk 2026-04-22 — see §11.

**Stack:** `drift ^2.28.0`, `drift_flutter ^0.2.7`, `freezed ^2.5.3`, `flutter_test` (sdk), Dart `^3.11.5`, Flutter `>=3.41.6`. **No new dependencies.** `pubspec.yaml` is not modified by this stream.

**Goal:** Ship the repository SSOT for currencies, account types, and accounts — reactive `Stream<…>` reads, typed command writes, Drift → Freezed mapping inside the repository, business rules (archive-instead-of-delete, FK integrity, `l10n_key` identity, integer minor units) enforced once — so Stream A's transaction / category writes compile against stable `CurrencyRepository.getByCode` / `AccountRepository.getById` signatures and Stream C's seed has a thin `upsert` + `save` surface to call.

**Architecture:** Three sibling files in `lib/data/repositories/`, each wrapping exactly one DAO, each returning Freezed domain models. Drift types (`Currency` the Drift row, `AccountRow`, `AccountTypeRow`, every `…Companion`) never leave these files. Shared exception types live in one module at `lib/data/repositories/exceptions.dart` (coordinated with Stream A — see §7). Tests are per-repository, built on an in-memory `AppDatabase` via `NativeDatabase.memory()`, sharing the test harness owned by Stream C.

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

### 0.4 Adjacent files read but NOT modified by Stream B

Verified to match the M1 contract:

- `lib/data/database/tables/currencies_table.dart` — `Currencies` table, PK `code`, `decimals` INTEGER NOT NULL, `is_token` BOOL default false.
- `lib/data/database/tables/account_types_table.dart` — `AccountTypes` table, `l10nKey` nullable UNIQUE, `defaultCurrency` nullable FK, `icon` TEXT NOT NULL, `color` INTEGER NOT NULL, `is_archived` default false.
- `lib/data/database/tables/accounts_table.dart` — `Accounts` table, `accountTypeId` INTEGER NOT NULL FK → `account_types(id)`, `currency` TEXT NOT NULL FK → `currencies(code)`, `openingBalanceMinorUnits` INTEGER default 0, `icon` nullable, `color` nullable, `is_archived` default false.
- `lib/data/database/daos/currency_dao.dart` — `watchAll` / `findByCode` / `upsertAll` / `insert` / `updateRow`.
- `lib/data/database/daos/account_type_dao.dart` — `watchAll` (includes archived) / `watchActive` / `findById` / `findByL10nKey` / `insert` / `updateRow` / `archive` / `deleteById` / `hasReferencingAccounts`.
- `lib/data/database/daos/account_dao.dart` — `watchAll({includeArchived})` / `watchByType` / `findById` / `insert` / `updateRow` / `deleteById` / `archiveById` / `countByAccountType`.
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

  /// Insert when `id == null` / `id == 0`, otherwise replace.
  /// Returns the row id.
  ///
  /// Validates that `defaultCurrency` (when non-null) points at a
  /// registered currency; throws [CurrencyNotFoundException] otherwise.
  /// Does NOT mutate `l10n_key` — see [rename] for the rename path.
  Future<int> save(AccountType accountType);

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
```

### 1.4 Error types — `lib/data/repositories/exceptions.dart`

**Ownership:** this file is shared with Stream A. **Stream B creates it** as task B4 with the full set below; Stream A adds only its own category-specific type (`CategoryInUseException`, `CategoryTypeLockedException`) later in the same merge window. Rationale: Stream A needs `CurrencyNotFoundException` on day 1 of its `TransactionRepository.save`, and Stream B needs it on day 1 of `AccountRepository.save` — the only sane resolution is a shared module, created by whichever stream writes it first. Stream B writes `CurrencyRepository` first (task B1), so Stream B creates the file.

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

Stream A extends this file with:

```dart
class CategoryInUseException extends RepositoryException { ... }
class CategoryTypeLockedException extends RepositoryException { ... }
```

Those are NOT Stream B's concern. This plan only mentions them to confirm no name collision.

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
  final defaultCurrency = row.defaultCurrency == null
      ? null
      : await _currencies.getByCode(row.defaultCurrency!);
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

For streams (`watchAll`), use `Stream.asyncMap` with a single currencies snapshot captured at the top of the stream:

```dart
Stream<List<AccountType>> watchAll({bool includeArchived = false}) {
  final rowsStream = _dao.watchAll(/* DAO's watchAll returns includes-archived;
                                       filter in-repo to keep DAO generic */);
  return rowsStream.asyncMap((rows) async {
    final codes = rows
        .map((r) => r.defaultCurrency)
        .whereType<String>()
        .toSet();
    final currencyByCode = <String, Currency>{};
    for (final code in codes) {
      final c = await _currencies.getByCode(code);
      if (c != null) currencyByCode[code] = c;
    }
    final filtered = includeArchived
        ? rows
        : rows.where((r) => !r.isArchived).toList();
    return filtered.map((r) => AccountType(
          id: r.id,
          l10nKey: r.l10nKey,
          customName: r.customName,
          defaultCurrency: r.defaultCurrency == null
              ? null
              : currencyByCode[r.defaultCurrency!],
          icon: r.icon,
          color: r.color,
          sortOrder: r.sortOrder ?? 0,
          isArchived: r.isArchived,
        )).toList(growable: false);
  });
}
```

**Decision:** `AccountTypeRepository.watchAll` filters `includeArchived` at the repository layer, not at the DAO. `AccountTypeDao.watchAll` returns everything; this keeps the DAO generic and mirrors the pattern used by `AccountDao.watchAll`. A future "archived" filter inside the DAO would need a second query variant per caller — not worth it.

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

`Account.currency` is a Freezed `Currency`, not a string code. Same resolution pattern as AccountType, but non-nullable: every row has a NOT NULL `currency` column, so the map lookup must always succeed. When a snapshot is missing a currency (indicating a corrupt DB), throw `CurrencyNotFoundException` rather than silently drop the row.

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
        // l10nKey omitted — replace(...) uses the existing value.
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
- **Enforcement point:** `AccountTypeRepository.rename` (previous rule). Corollary: `save` never mutates `l10nKey` either — the mapper copies the incoming `l10nKey` verbatim. Seed code (Stream C) always inserts with the l10n key set.
- **Test (§6.2) — round-trip scenario:** seed `accountType.cash` + `accountType.investment` → user renames Cash to "Wallet" → call `watchAll` → two rows, one with `l10nKey='accountType.cash', customName='Wallet'`, one with `l10nKey='accountType.investment', customName=null`. Re-running the seed is idempotent (Stream C's concern, exercised in Stream C's test).

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
- **Enforcement:** the `abstract class CurrencyRepository` signature in §1.1 exposes only `watchAll`, `getByCode`, `upsert`. No TODO comments for Phase-2 methods in MVP — adding them later is additive and safe.
- **Phase 2 future-proofing:** `upsert` is deliberately generic enough to serve Phase 2 token registration. `watchAll({includeTokens: true})` is the Phase-2 switch; MVP callers never pass `true`.

---

## 4. Reactive streams

Drift `.watch()` is the foundation. Every stream-returning method composes from a DAO `.watch()`:

- `CurrencyRepository.watchAll` → `CurrencyDao.watchAll()` → `.map` Drift rows to Freezed. Filter `isToken == false` when `includeTokens == false` (MVP default).
- `AccountTypeRepository.watchAll` → `AccountTypeDao.watchAll()` → `.asyncMap` with currency resolution (§2.2). Filter archived in the repo.
- `AccountRepository.watchAll` → `AccountDao.watchAll(includeArchived: ...)` → `.asyncMap` with currency resolution.
- `AccountRepository.watchById` → `select(accounts)..where(...).watchSingleOrNull()` via a small helper on top of `AccountDao.findById` — add a `Stream<AccountRow?> watchById(int id)` method to `AccountDao` if missing; otherwise use the same selector pattern inline. Prefer pushing the `.watch()` into the DAO for symmetry.

**Emission invariant (proven in every rule test):** after any mutating call completes (insert / update / delete / archive), the `watchAll` stream emits a new snapshot. Drift handles the invalidation; tests assert it explicitly via `expectLater(stream, emitsInOrder([...]))` or by awaiting `stream.first` after the mutation.

**Caveat on `asyncMap`:** when the account-type stream emits a new snapshot before the currency lookup for the previous snapshot has finished, `asyncMap` processes in order but may coalesce. For MVP scale (10k transactions, dozens of accounts, handful of account types, ~10 currencies), the lookup is a handful of `SELECT WHERE code = ?` calls — effectively free. Test in §6.2 asserts ordering, not latency.

**Cross-stream coordination:** Stream A's `TransactionRepository` will need `AccountRepository.getById` (to resolve an account's currency into the transaction on read). It does **not** need an Account stream — Stream A joins at the controller level too, per the decision in §2.3. No cross-stream stream wiring.

---

## 5. Implementation task breakdown

Each task is a committable unit. The dev may stack them into a single PR or land them sequentially in the same merge window — but the **order is fixed** because B1 unblocks Stream A and B4 unblocks B2 / B3.

### B0. Create the missing `account_type_repository.dart` stub

- [ ] Create the file at `lib/data/repositories/account_type_repository.dart` with the same TODO-only shape that the other M0 stubs use.
- [ ] Content is a header comment block (matches the prose and line style of the existing `account_repository.dart` stub in §0.2 — same tense, same PRD cite density):

    ```dart
    // TODO(M3): `AccountTypeRepository` — SSOT for account types.
    //
    // Business rules enforced here (see PRD.md 322-340):
    //   - Archive-instead-of-delete when referenced by any account (G6).
    //   - Rename writes `custom_name` only; `l10n_key` is preserved so
    //     locale changes do not duplicate or orphan the row (G7).
    //   - `default_currency` FK integrity — rejects unknown currency codes
    //     with a typed `CurrencyNotFoundException`.
    ```

- [ ] Commit as `feat(m3-b): scaffold AccountTypeRepository stub` so the rest of the branch can import it without a missing-file error. Do not implement the class yet.

### B1. `CurrencyRepository` (read-mostly, lands first)

- [ ] Write the abstract class signature per §1.1.
- [ ] Write the concrete `DriftCurrencyRepository` implementation with `_toDomain` / `_toCompanion` helpers per §2.1.
- [ ] Implement `watchAll({includeTokens})` by `.map`-ing the DAO stream and filtering `isToken` in-repo.
- [ ] Implement `getByCode` by delegating to `CurrencyDao.findByCode` + `_toDomain`.
- [ ] Implement `upsert` with the `decimals` mismatch guard per §3.8.
- [ ] Commit as `feat(m3-b): CurrencyRepository`. This commit unblocks Stream A (they can start mocking `CurrencyRepository.getByCode` in their transaction tests).

### B2. `AccountTypeRepository`

- [ ] Replace the B0 stub with the abstract class + `DriftAccountTypeRepository` implementation per §1.2 and §2.2.
- [ ] Constructor takes `AccountTypeDao _dao` and `CurrencyRepository _currencies`. Do NOT inject `AccountDao` — use `hasReferencingAccounts` on the account-type DAO (already a `customSelect`).
- [ ] Implement `watchAll` with the async map currency-resolution pattern in §2.2.
- [ ] Implement `getById` by `findById` + `_toDomain`. Remember: `_toDomain` is async because it resolves currency.
- [ ] Implement `save` (§1.2). Branch on `id == 0` for insert vs replace.
- [ ] Implement `rename` per §3.3 — write `customName` only, preserve `l10nKey` + every other column.
- [ ] Implement `archive` by delegating to `AccountTypeDao.archive`.
- [ ] Implement `delete` per §3.2 — `hasReferencingAccounts` first, throw `AccountTypeInUseException`, otherwise `deleteById`.
- [ ] Implement `isReferenced` by delegating to `hasReferencingAccounts`.
- [ ] Commit as `feat(m3-b): AccountTypeRepository`. Unblocks Stream C's seed of Cash + Investment.

### B3. `AccountRepository`

- [ ] Replace the 8-line TODO stub (§0.2) with the abstract class + `DriftAccountRepository` implementation per §1.3 and §2.3.
- [ ] Constructor takes `AccountDao _accountDao`, `AccountTypeDao _accountTypeDao`, `TransactionDao _transactionDao`, `CurrencyRepository _currencies`.
- [ ] Implement `watchAll({includeArchived})` + `watchById(id)` with currency resolution.
- [ ] Implement `getById`.
- [ ] Implement `save` with **both** FK pre-checks (§3.5, §3.6). Branch on `id == 0` for insert vs replace. Return the id.
- [ ] Implement `archive` via `AccountDao.archiveById`.
- [ ] Implement `delete` per §3.1 — `_transactionDao.countByAccount(id) > 0` → throw `AccountInUseException`, else `deleteById`.
- [ ] Implement `isReferenced` via `_transactionDao.countByAccount(id) > 0`.
- [ ] Commit as `feat(m3-b): AccountRepository`. Unblocks Stream C's seed of the one Cash account + M5 Accounts slice.

### B4. Error types module

- [ ] Create `lib/data/repositories/exceptions.dart` with the six types in §1.4 (`RepositoryException` base + 5 subclasses).
- [ ] Export from each repository file that throws (Dart barrel-file is not required — consumers `import 'package:ledgerly/data/repositories/exceptions.dart'` directly).
- [ ] Coordinate with Stream A: notify them in the PR description that `exceptions.dart` now exists and that their category-specific exceptions should extend `RepositoryException` and live in the same file.
- [ ] Commit as `feat(m3-b): shared repository exception types`. Can ship between B1 and B2 (B1 also needs `CurrencyDecimalsMismatchException` and `CurrencyNotFoundException`). Practically, write B4 first, then B1 compiles.

    **Dependency order in practice:** B0 → B4 → B1 → B2 → B3 → B5. The §5 section header lists B0-first-then-B1 because B0 is purely filesystem; B4 is code. Both are written before any test runs.

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

Every repository has one test file. All three use the shared in-memory harness from Stream C — a `TestDatabase` factory that returns `AppDatabase(NativeDatabase.memory())` with `foreign_keys = ON`, pre-built currencies seeded (USD / JPY / EUR) so tests opt into seeding what they need.

Minimum coverage below. Implementer may add more — none may be removed.

### 6.1 `test/unit/repositories/currency_repository_test.dart`

| #    | Test                                                                  | Method                 | Assertion                                                                                                   | Rule cite |
|------|-----------------------------------------------------------------------|------------------------|-------------------------------------------------------------------------------------------------------------|-----------|
| CR01 | Empty DB → `watchAll` emits `[]`                                      | `watchAll`             | `expect(await stream.first, isEmpty)`                                                                       | §1.1      |
| CR02 | After `upsert(USD)` → `watchAll` emits `[USD]`                        | `watchAll`, `upsert`   | Stream emits two snapshots in order: `[]` then `[USD]`                                                      | §4        |
| CR03 | `watchAll(includeTokens: false)` filters `isToken == true`            | `watchAll`             | Seed USD (`isToken: false`) and ETH (`isToken: true`); default call returns `[USD]`, `true` returns `[USD, ETH]` | §1.1      |
| CR04 | `getByCode('USD')` after upsert → Freezed Currency with decimals == 2 | `getByCode`            | Round-trip equality on every field                                                                          | §2.1      |
| CR05 | `getByCode('XYZ')` unregistered → null                                | `getByCode`            | `expect(result, isNull)`                                                                                    | §1.1      |
| CR06 | `upsert(USD)` twice is idempotent                                     | `upsert`               | Second call succeeds; `watchAll` emits `[USD]` both times (no duplicate)                                    | §3.8      |
| CR07 | `upsert` does NOT mutate `decimals` on an existing code               | `upsert`               | Upsert USD with decimals=2, then upsert USD with decimals=4 → throws `CurrencyDecimalsMismatchException`    | §3.8      |
| CR08 | `upsert` updates symbol / nameL10nKey on an existing code             | `upsert`               | Upsert USD symbol `$`, then upsert USD symbol `US$` (same decimals) → second `watchAll` snapshot shows `US$` | §3.8      |
| CR09 | `upsert` preserves `sortOrder` when new value is null                 | `upsert`               | Upsert USD sortOrder=1, then upsert USD sortOrder=null → row keeps sortOrder=1                             | §3.8      |
| CR10 | Drift data class is never returned                                    | All                    | Assert-on-type: `expect(result, isA<Currency>())` where `Currency` is the Freezed model (structural)       | §1.5.2    |

### 6.2 `test/unit/repositories/account_type_repository_test.dart`

Preconditions: every test first seeds USD (and sometimes JPY) via `CurrencyRepository.upsert`.

| #    | Test                                                                      | Method                | Assertion                                                                                                     | Rule cite |
|------|---------------------------------------------------------------------------|-----------------------|---------------------------------------------------------------------------------------------------------------|-----------|
| AT01 | Empty DB → `watchAll` emits `[]`                                          | `watchAll`            | `await stream.first` → `[]`                                                                                   | §1.2      |
| AT02 | `save(Cash seeded)` → `watchAll` emits `[Cash]`                           | `save`, `watchAll`    | Row round-trip preserves `l10nKey`, `icon`, `color`, `defaultCurrency`                                        | §1.2      |
| AT03 | `save` with unknown `defaultCurrency.code` → `CurrencyNotFoundException`  | `save`                | Construct an AccountType with a Currency not upserted; expect throw                                           | §3.5-adjacent |
| AT04 | `save` with `defaultCurrency == null` → inserts row with NULL default     | `save`                | DAO round-trip: `row.defaultCurrency` is null                                                                 | §2.2      |
| AT05 | `rename(id, 'Wallet')` writes `customName` only; `l10nKey` preserved      | `rename`              | Seed with `l10nKey: 'accountType.cash'`; after `rename`, `findByL10nKey('accountType.cash')` still returns row with `customName: 'Wallet'` | §3.3 G7 |
| AT06 | Second `rename` does not disturb `l10nKey`                                | `rename`              | Round-trip: two `rename` calls, `l10nKey` stable across both                                                  | §3.4      |
| AT07 | `rename` on nonexistent id → `AccountTypeNotFoundException`               | `rename`              | Expect throw                                                                                                  | §1.2      |
| AT08 | `archive(id)` marks archived; `watchAll()` default excludes archived      | `archive`, `watchAll` | Seed, archive, `watchAll` → row absent                                                                        | §1.2      |
| AT09 | `watchAll(includeArchived: true)` returns archived rows                   | `watchAll`            | Seed, archive, `watchAll(includeArchived: true)` → row present                                                | §1.2      |
| AT10 | `delete(id)` with no referencing accounts → succeeds                      | `delete`              | Seed custom type with `l10nKey: null`, no accounts → `delete` succeeds, stream emits `[]`                    | §3.2      |
| AT11 | `delete(id)` with referencing account → `AccountTypeInUseException`       | `delete`              | Seed type + seed account of that type → `delete` throws; row unchanged                                        | §3.2 G6   |
| AT12 | `delete(id)` with archived referencing account → still throws             | `delete`              | Seed account, archive it, then call `delete(type.id)` → throws (history preserved)                            | §3.2      |
| AT13 | `isReferenced` matches `delete` predicate                                 | `isReferenced`        | Seed with account → true; delete account → false                                                              | §1.2      |
| AT14 | `getById(id)` returns `AccountType` with resolved `defaultCurrency`       | `getById`             | Seed type with `defaultCurrency: USD`; `getById` returns a Freezed Currency matching USD                      | §2.2      |
| AT15 | Reactive emission after insert / update / delete / archive                | `watchAll`            | `emitsInOrder([ [], [row], [updatedRow], [] ])`                                                               | §4        |
| AT16 | Guardrail G8 — `icon` is `String`, `color` is `int`                        | save / round-trip     | `expect(result.icon, isA<String>())`; `expect(result.color, isA<int>())`                                      | §3.9 G8   |

### 6.3 `test/unit/repositories/account_repository_test.dart`

Preconditions: seed USD + JPY via `CurrencyRepository.upsert`; seed one `accountType.cash` via `AccountTypeRepository.save`.

| #    | Test                                                                      | Method                        | Assertion                                                                                                     | Rule cite |
|------|---------------------------------------------------------------------------|-------------------------------|---------------------------------------------------------------------------------------------------------------|-----------|
| AC01 | Empty DB → `watchAll` emits `[]`                                          | `watchAll`                    | `await stream.first` → `[]`                                                                                   | §1.3      |
| AC02 | `save` happy path                                                         | `save`, `watchAll`            | Round-trip all fields: `name`, `accountTypeId`, `currency`, `openingBalanceMinorUnits`, `icon`, `color`        | §1.3      |
| AC03 | `save` with unknown currency → `CurrencyNotFoundException`                | `save`                        | Construct Account with `currency: Currency(code: 'XYZ', decimals: 2)` (never upserted) → expect throw         | §3.5 G2   |
| AC04 | `save` with unknown accountTypeId → `AccountTypeNotFoundException`        | `save`                        | `accountTypeId: 999` (nonexistent) → expect throw                                                             | §3.6 G2   |
| AC05 | `save` round-trips `openingBalanceMinorUnits: -12345`                     | `save`                        | `await getById(id)` returns `-12345` exactly                                                                  | §3.7 G4   |
| AC06 | `save` round-trips `openingBalanceMinorUnits: 1500000000000000000` (ETH)  | `save`                        | 18-digit integer preserved as `int` (Dart int is 64-bit on VM, safe up to 2^63-1 ≈ 9.2e18)                    | §3.7 G4   |
| AC07 | `archive(id)` hides row from default `watchAll`                           | `archive`                     | Seed, archive, `watchAll()` default → row absent; `watchAll(includeArchived: true)` → present                 | §1.3      |
| AC08 | `watchById(id)` emits null after delete                                   | `watchById`, `delete`         | Seed, `watchById` emits the row, `delete` → stream emits null                                                  | §4        |
| AC09 | `delete(id)` with no referencing transactions → succeeds                  | `delete`                      | Seed, `delete` → stream empty                                                                                  | §3.1      |
| AC10 | `delete(id)` with a referencing transaction → `AccountInUseException`     | `delete`                      | Seed a transaction with `account_id = id` → `delete` throws; row still present                                | §3.1 G6   |
| AC11 | `isReferenced(id)` true when transaction exists, false otherwise          | `isReferenced`                | Seed / assert both branches                                                                                    | §1.3      |
| AC12 | `watchAll` excludes archived by default; `sortOrder` respected            | `watchAll`                    | Seed two accounts with `sortOrder: 1` / `sortOrder: 0`; archive one → remaining ordered                       | §2.3      |
| AC13 | `watchAll({includeArchived: true})` includes archived                     | `watchAll`                    | Seed one archived + one active → both returned                                                                 | §1.3      |
| AC14 | `getById` resolves `currency` to Freezed `Currency`                       | `getById`                     | Returns Freezed Currency, not a string code                                                                    | §2.3      |
| AC15 | Reactive emission after insert / update / archive / delete                | `watchAll`                    | `emitsInOrder([ [], [a], [updated], [] ])`                                                                     | §4        |
| AC16 | Guardrail G8 — `icon` is `String?`, `color` is `int?`                      | save / round-trip             | Accept nulls; `isA<String>()` / `isA<int>()` when non-null                                                    | §3.9 G8   |

### 6.4 Shared test harness (reference — owned by Stream C)

Stream C creates `test/support/test_database.dart` with:

```dart
AppDatabase buildTestDatabase() => AppDatabase(NativeDatabase.memory());
```

Plus helpers for seeding a minimal set of currencies (USD, JPY) and constructing a `DriftCurrencyRepository` on top. Stream B consumes this harness — **does not re-implement**. If Stream C has not yet merged the harness when Stream B starts B5, Stream B writes a temporary `buildTestDatabase()` at the top of its first test file and moves it to `test/support/` when Stream C lands. The temporary version is identical in shape to the shared one to minimize the later diff.

---

## 7. Integration points with sibling streams

| Seam                            | Sibling stream | Direction                         | What Stream B exposes                                                                               | What Stream B consumes                                                                         |
|---------------------------------|----------------|-----------------------------------|-----------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| FK pre-check on transaction save | A              | B → A                             | `CurrencyRepository.getByCode`                                                                      | —                                                                                              |
| FK pre-check on transaction save | A              | B → A                             | `AccountRepository.getById` (transaction needs the account's currency when displaying totals)       | —                                                                                              |
| Account referenced-by-txn probe  | A              | B → A (via DAO contract)          | Stream B **calls** `TransactionDao.countByAccount` directly from `AccountRepository`                | Stream B **requires** `TransactionDao.countByAccount` to exist (M1 §3.2); Stream A owns the DAO |
| Shared error types               | A              | Shared file, written by B         | Stream B creates `lib/data/repositories/exceptions.dart` with the base + 5 subclasses from §1.4     | Stream A extends with `CategoryInUseException`, `CategoryTypeLockedException`                 |
| Seed currencies                 | C              | B → C                             | `CurrencyRepository.upsert` — Stream C calls it 7× for MVP fiats                                    | —                                                                                              |
| Seed account types              | C              | B → C                             | `AccountTypeRepository.save` — Stream C calls it for `accountType.cash` + `accountType.investment` | Stream B's `save` pre-check requires USD (or the resolved `default_currency`) to be upserted *first* — Stream C orders accordingly |
| Seed Cash account               | C              | B → C                             | `AccountRepository.save` — Stream C calls it once with `accountTypeId = <cash.id>` and the resolved default currency | Stream B's `save` requires both upstream seeds to have landed — Stream C's ordering again |
| Shared test DB harness          | C              | C → B (Stream B consumes)         | —                                                                                                   | `test/support/test_database.dart` with `buildTestDatabase()` + seeded currencies helper        |
| Default-currency resolution     | C              | C owns the chain                  | `AccountRepository.save` validates whatever currency the caller supplies; does NOT read user_prefs | Stream C's seed + the M5 Accounts controller own the `account_type.default_currency → user_pref → 'USD'` walk |

**Merge-window rule:** Streams A / B / C merge in the same week (implementation plan §5, "Streams overlap the same Drift transaction API — merge within a tight window"). Land B1 (CurrencyRepository) first within the window; A and C can both start the moment B1 is on main.

**Field-name contract:** already frozen in `docs/plans/m1-data-foundations/stream-c-field-name-contract.md`. Stream B does not rename any field. Any pressure to rename (e.g. `openingBalanceMinorUnits` → `openingBalance`) is rejected; a rename would invalidate every M5 widget test.

---

## 8. Guardrails enforced by this stream

Cross-referenced to `docs/plans/implementation-plan.md` §6.

| # | Rule                                                                             | Stream B enforcement                                                                                                                                             | Proven by                                                                        |
|---|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| G1 | Only repositories write to the DB / secure storage                              | Stream B's three repos are the only writers to `currencies`, `account_types`, `accounts`. `import_lint` blocks any non-repo from importing `data/database/daos`. | `flutter analyze` in task G                                                      |
| G2 | Drift types never cross the repository boundary                                 | `AccountRow`, `AccountTypeRow`, Drift `Currency`, every `…Companion` stay in `lib/data/repositories/*.dart`; never exported. Prefix import for Drift `Currency`. | Inspection + `import_lint` + `grep` during task G                               |
| G4 | Money is `int` minor units end-to-end                                            | `Account.openingBalanceMinorUnits` stays `int`. No `double` in any signature. FK / amount columns store raw minor units.                                         | Test AC05 / AC06 + pre-merge grep in task G                                     |
| G6 | Archive-instead-of-delete for referenced rows                                    | `AccountRepository.delete` + `AccountTypeRepository.delete` each throw a typed exception when referenced; both branches tested.                                  | Tests AC10 / AT11 / AT12                                                        |
| G7 | Seeded rows identified by `l10n_key`; renames write `custom_name` only           | `AccountTypeRepository.rename` never mutates `l10nKey`. Seed (Stream C) identifies rows by `l10nKey`.                                                             | Tests AT05 / AT06                                                               |
| G8 | Icons / colors are string keys + palette indices, never raw `IconData` / ARGB    | `icon` is `String` / `String?`, `color` is `int` / `int?` throughout the stream. No Flutter `Color` / `IconData` imported in `lib/data/repositories/*.dart`.     | Tests AT16 / AC16 + task-G grep                                                 |
| G12 | Tests organized by layer, not by feature                                        | All tests land under `test/unit/repositories/` with one file per repo.                                                                                           | File layout at commit time                                                      |

Stream B does **not** enforce G3, G5, G9, G10, G11 — those are controller / bootstrap / router / layout concerns.

---

## 9. Risks specific to this stream

1. **Currency FK pre-check forgotten in `AccountRepository.save`.** Drift's FK would still fire at SQLite level, but the raised error is a `SqliteException` the controller cannot pattern-match. Enforce via test AC03 + code review. Mitigation: the `save` method's first lines read `_currencies.getByCode(currency.code)`. Omission is a missing-lines diff.
2. **Account-type archive silently cascading to accounts.** PRD 358 is explicit: archiving a type does NOT cascade. Risk: a dev writes a "cascade archive" convenience. Mitigation: no cascade method is defined in §1.2; test AT08 seeds an account of the type, archives the type, confirms the account is still active and visible.
3. **`custom_name` overwriting `l10n_key` by accident.** The `rename` implementation (§3.3) uses Drift's `replace`, which writes every companion field. Omitting `l10nKey` from the companion would silently set it to NULL. Mitigation: the template in §3.3 explicitly copies every other column from the existing row; test AT05 / AT06 proves it.
4. **Async map stream ordering under load.** `AccountTypeRepository.watchAll`'s `asyncMap` could, in principle, reorder snapshots during rapid seed + rename + archive bursts. MVP does not hit the load. Mitigation: test AT15 asserts ordering under rapid emits, and Dart's single-threaded event loop guarantees FIFO.
5. **Test harness divergence between streams.** If Stream B writes its own `buildTestDatabase` and Stream C writes another, two versions diverge, breaking the first attempt at running `flutter test` on the full tree. Mitigation: §7 pins ownership to Stream C; §6.4 documents the fallback when C hasn't merged yet.
6. **Drift `Currency` vs Freezed `Currency` name collision.** Both classes are called `Currency`. Accidentally returning the Drift one breaks every controller cast. Mitigation: Import pattern in §2.1 — always `import '../database/app_database.dart' as drift;`. Pre-merge grep for `'../database/app_database.dart'` without a prefix in the repository diff.
7. **`isToken` filter forgotten in `watchAll({includeTokens: false})`.** MVP has no token rows, so the bug is invisible until Phase 2 land. Mitigation: test CR03 seeds an explicit ETH row (`isToken: true`) and asserts exclusion.
8. **Phase-2 pressure to add `CurrencyRepository.delete` / `archive`.** The schema lacks `is_archived` on `currencies`. Resist any Phase-2 addition here; tokens are append-only in the current PRD. Any future delete requires a schema change + new snapshot. Document at the top of the repo file.
9. **Stream A's `TransactionDao.countByAccount` drifting.** Stream B's `AccountRepository.delete` depends on this exact DAO method name. Mitigation: §0.4 calls it out; §5 task B3 explicitly lists it as a precondition; pre-PR checklist includes `grep -n 'countByAccount' lib/data/database/daos/transaction_dao.dart`.

---

## 10. Exit criteria (definition of done)

Direct mapping to `docs/plans/implementation-plan.md` §5 M3 exit criteria, scoped to Stream B:

- [ ] `test/unit/repositories/currency_repository_test.dart` exists and passes with every CR01–CR10 case from §6.1.
- [ ] `test/unit/repositories/account_type_repository_test.dart` exists and passes with every AT01–AT16 case from §6.2.
- [ ] `test/unit/repositories/account_repository_test.dart` exists and passes with every AC01–AC16 case from §6.3.
- [ ] Happy path covered for each of three repos (CR02, AT02, AC02).
- [ ] Archive-instead-of-delete covered (AC10, AT11).
- [ ] Reactive stream emissions on insert / update / delete covered (CR02, AT15, AC15).
- [ ] Currency FK enforcement covered (AC03, AT03) — the master plan's required "currency FK enforcement" case.
- [ ] `CurrencyRepository` documented as read-mostly in the repo file's class dartdoc; only `watchAll` / `getByCode` / `upsert` exposed.
- [ ] `lib/data/repositories/account_type_repository.dart` exists (created in B0, implemented in B2).
- [ ] `lib/data/repositories/exceptions.dart` exists with `RepositoryException` + 5 subclasses; Stream A can extend it without edits from Stream B.
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

End of plan.
