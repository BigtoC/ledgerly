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

import 'package:drift/drift.dart' show Value, Variable;

import '../database/app_database.dart' as drift;
import '../database/daos/account_dao.dart';
import '../database/daos/account_type_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../models/account.dart';
import '../models/currency.dart';
import 'currency_repository.dart';
import 'repository_exceptions.dart';

/// Generic account-layer failure for stale/missing-row writes that do not map
/// to one of the shared cross-stream repository exceptions.
class AccountRepositoryException implements Exception {
  const AccountRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AccountRepositoryException: $message';
}

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

  /// Reactive existence probe — emits `true` whenever at least one
  /// transaction references this account.
  Stream<bool> watchIsReferenced(int id);

  /// Sum of all transactions for `accountId` in the account's native
  /// currency, expressed as minor units. Expense transactions subtract
  /// from the balance; income transactions add. `opening_balance_minor_units`
  /// is included. Emits on every insert / update / delete of a transaction
  /// that references this account, and on changes to the account row
  /// itself (opening balance edits). No cross-currency conversion — the
  /// transaction form enforces that transactions on an account use the
  /// account's currency, per PRD.md → Add/Edit Interaction Rules.
  /// Archived accounts still compute a balance.
  ///
  /// Missing accounts emit `0` (subquery collapses via `COALESCE`), not
  /// an error — matches `watchById`'s null-on-missing contract.
  Stream<int> watchBalanceMinorUnits(int accountId);
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

    final stored = await _dao.findById(account.id);
    if (stored == null) {
      throw AccountRepositoryException('Account ${account.id} not found');
    }
    if (stored.currency != account.currency.code &&
        await isReferenced(account.id)) {
      throw AccountRepositoryException(
        'Account ${account.id} currency cannot change after transactions exist',
      );
    }

    final updated = await _dao.updateRow(_toCompanion(account));
    if (!updated) {
      throw AccountRepositoryException('Account ${account.id} not found');
    }
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

  @override
  Stream<bool> watchIsReferenced(int id) {
    return _txDao.watchCountByAccount(id).map((count) => count > 0);
  }

  @override
  Stream<int> watchBalanceMinorUnits(int accountId) {
    // Tracked balance is derived, not stored. The outer `SELECT` assembles
    // opening balance + signed transaction sum; category.type drives the
    // sign (expense subtracts, income adds). Both subqueries are wrapped
    // in COALESCE so a missing account or empty transaction set collapses
    // to `0` instead of NULL.
    //
    // `readsFrom: {accounts, transactions}` tells Drift's stream-query
    // store to re-emit on account-row edits and transaction writes. The
    // aggregate also depends on `categories.type`, but CategoryRepository
    // forbids changing a referenced category's type after first use, so
    // unrelated category metadata edits should not invalidate every active
    // balance stream.
    final query = _db.customSelect(
      'SELECT '
      'COALESCE('
      '(SELECT opening_balance_minor_units FROM accounts WHERE id = ?),'
      ' 0'
      ') + COALESCE('
      '(SELECT SUM('
      "CASE c.type WHEN 'income' THEN t.amount_minor_units "
      "WHEN 'expense' THEN -t.amount_minor_units END"
      ') '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.account_id = ?'
      '), 0) AS balance',
      variables: [Variable<int>(accountId), Variable<int>(accountId)],
      readsFrom: {_db.accounts, _db.transactions},
    );
    // The outer SELECT has no FROM clause, so Drift always yields exactly
    // one row; both COALESCEs guarantee the `balance` column is never
    // NULL.
    return query.watch().map((rows) => rows.first.read<int>('balance'));
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
