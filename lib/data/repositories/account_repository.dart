// `AccountRepository` — SSOT for `accounts` rows.
//
// See `docs/plans/m3-repositories-seed/stream-b-account-currency.md`
// for the full specification. Drift data classes never leave this file.
//
// Invariants enforced here (and only here):
//   - Archive-instead-of-delete when at least one `transactions` row
//     references the account (G6 — PRD.md 361).
//   - Currency FK integrity — `save` pre-checks `currencies.code` and
//     throws a typed [CurrencyNotFoundException] before Drift's SQL
//     layer can surface an opaque `SqliteException` (G2 — PRD.md 349).
//   - Account-type FK integrity — `save` pre-checks
//     `account_types.id` and throws [AccountTypeNotFoundException]
//     (G2 — PRD.md 348).
//   - Integer minor-unit arithmetic on `opening_balance_minor_units`;
//     no `double` in any signature (G4 — PRD.md Money Storage Policy).
//   - `icon` is a string key, `color` is a palette index (G8).
//
// Default-currency resolution
// (`account_types.default_currency → user_preferences.default_currency
// → 'USD'`, PRD 357) is the **caller's** responsibility; this
// repository only validates whatever currency the caller supplies. It
// does NOT read `user_preferences`.

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/account_dao.dart';
import '../database/daos/account_type_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../models/account.dart';
import '../models/currency.dart';
import 'currency_repository.dart';
import 'repository_exceptions.dart';

/// SSOT for `accounts`. Owns every write path to the Drift `accounts`
/// table. Drift data classes never leave this file.
abstract class AccountRepository {
  /// Emits all accounts. `includeArchived` defaults to `false`.
  /// Ordered by `sort_order NULLS LAST, id ASC`.
  Stream<List<Account>> watchAll({bool includeArchived = false});

  /// Single-account stream for the Edit Account screen. Emits `null`
  /// after delete. Emits every update.
  Stream<Account?> watchById(int id);

  /// One-shot read by PK. Returns `null` when the id is absent.
  Future<Account?> getById(int id);

  /// Insert when `account.id == 0`, otherwise update. Returns the row
  /// id.
  ///
  /// Validates:
  ///   - `account.currency.code` exists in `currencies` — throws
  ///     [CurrencyNotFoundException] on miss.
  ///   - `account.accountTypeId` exists in `account_types` — throws
  ///     [AccountTypeNotFoundException] on miss.
  Future<int> save(Account account);

  /// Marks the account archived (`is_archived = 1`). Does NOT delete
  /// any transactions.
  Future<void> archive(int id);

  /// Hard-delete. Only succeeds when no `transactions` row references
  /// this account; otherwise throws [AccountInUseException]. Callers
  /// are expected to call [archive] instead.
  Future<void> delete(int id);

  /// Cheap existence probe — returns true when any `transactions` row
  /// references this account.
  Future<bool> isReferenced(int id);
}

/// Concrete Drift-backed implementation of [AccountRepository].
final class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._db, this._currencies);

  final drift.AppDatabase _db;
  final CurrencyRepository _currencies;

  AccountDao get _dao => _db.accountDao;
  AccountTypeDao get _typeDao => _db.accountTypeDao;
  TransactionDao get _txDao => _db.transactionDao;

  // ---------- Reads ----------

  @override
  Stream<List<Account>> watchAll({bool includeArchived = false}) {
    return _dao.watchAll(includeArchived: includeArchived).asyncMap((
      rows,
    ) async {
      final codes = rows.map((r) => r.currency).toSet();
      final byCode = <String, Currency>{};
      for (final code in codes) {
        final c = await _currencies.getByCode(code);
        // Non-null under `foreign_keys = ON` + write-side pre-check;
        // see §2.3 / §12 Q3.
        byCode[code] = c!;
      }
      return rows.map((r) => _rowToDomain(r, byCode)).toList(growable: false);
    });
  }

  @override
  Stream<Account?> watchById(int id) {
    return _dao.watchById(id).asyncMap((row) async {
      if (row == null) return null;
      return _toDomain(row);
    });
  }

  @override
  Future<Account?> getById(int id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toDomain(row);
  }

  // ---------- Writes ----------

  @override
  Future<int> save(Account account) async {
    // Write-path FK pre-checks. Typed exceptions before Drift's SQL
    // layer surfaces an opaque SqliteException (§3.5, §3.6).
    final resolvedCurrency = await _currencies.getByCode(account.currency.code);
    if (resolvedCurrency == null) {
      throw CurrencyNotFoundException(account.currency.code);
    }
    final resolvedType = await _typeDao.findById(account.accountTypeId);
    if (resolvedType == null) {
      throw AccountTypeNotFoundException(account.accountTypeId);
    }

    if (account.id == 0) {
      return _dao.insert(_toCompanion(account));
    }

    await _dao.updateRow(_toCompanion(account));
    return account.id;
  }

  @override
  Future<void> archive(int id) async {
    await _dao.archiveById(id);
  }

  @override
  Future<void> delete(int id) async {
    final count = await _txDao.countByAccount(id);
    if (count > 0) {
      throw AccountInUseException(id);
    }
    await _dao.deleteById(id);
  }

  @override
  Future<bool> isReferenced(int id) async {
    final count = await _txDao.countByAccount(id);
    return count > 0;
  }

  // ---------- Private mapping ----------

  Future<Account> _toDomain(drift.AccountRow row) async {
    final currency = (await _currencies.getByCode(row.currency))!;
    return Account(
      id: row.id,
      name: row.name,
      accountTypeId: row.accountTypeId,
      currency: currency,
      openingBalanceMinorUnits: row.openingBalanceMinorUnits,
      icon: row.icon,
      color: row.color,
      sortOrder: row.sortOrder,
      isArchived: row.isArchived,
    );
  }

  Account _rowToDomain(drift.AccountRow row, Map<String, Currency> byCode) {
    return Account(
      id: row.id,
      name: row.name,
      accountTypeId: row.accountTypeId,
      currency: byCode[row.currency]!,
      openingBalanceMinorUnits: row.openingBalanceMinorUnits,
      icon: row.icon,
      color: row.color,
      sortOrder: row.sortOrder,
      isArchived: row.isArchived,
    );
  }

  drift.AccountsCompanion _toCompanion(Account a) {
    return drift.AccountsCompanion(
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
  }
}
