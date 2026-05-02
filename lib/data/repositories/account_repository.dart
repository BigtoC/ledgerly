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
import '../database/daos/shopping_list_dao.dart';
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

  /// Grouped balance for `accountId`, keyed by currency code (uppercase).
  /// Each entry is the sum of all transactions in that currency plus, for
  /// the account's native currency, `opening_balance_minor_units`. Expense
  /// transactions subtract; income transactions add.
  ///
  /// Zero-value groups are suppressed so the map only contains entries
  /// with a non-zero balance. An account with no transactions and
  /// `opening_balance_minor_units == 0` emits `{}`. Missing accounts also
  /// emit `{}`. Archived accounts still emit their grouped balance.
  ///
  /// Emits on every insert / update / delete of a transaction that
  /// references this account, on account-row changes (opening balance
  /// edits), and on category-type changes (since expense/income sign
  /// depends on `categories.type`).
  Stream<Map<String, int>> watchBalanceByCurrency(int accountId);

  /// One-shot lookup of the most recently used non-archived account, used by
  /// the Add Transaction default-account fallback chain (M5 Wave 2 §3.2,
  /// PRD → Add/Edit Interaction Rules). "Most recently used" is the account
  /// referenced by the newest transaction (`date DESC, id DESC`) among rows
  /// whose owning account is not archived.
  ///
  /// The archive filter applies in SQL — archived rows never leave the DAO.
  /// If the newest transaction overall belongs to an archived account, this
  /// method skips it and returns the next active account. Returns `null`
  /// only when no transaction exists for any active account.
  Future<Account?> getLastUsedActiveAccount();
}

/// Concrete Drift-backed implementation of [AccountRepository].
final class DriftAccountRepository implements AccountRepository {
  DriftAccountRepository(this._db, this._currencies);

  final drift.AppDatabase _db;
  final CurrencyRepository _currencies;

  AccountDao get _dao => _db.accountDao;
  AccountTypeDao get _typeDao => _db.accountTypeDao;
  TransactionDao get _txDao => _db.transactionDao;
  ShoppingListDao get _slDao => _db.shoppingListDao;

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
    final slCount = await _slDao.countByAccount(id);
    if (slCount > 0) throw AccountInUseException(id);
    final count = await _txDao.countByAccount(id);
    if (count > 0) throw AccountInUseException(id);
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
  Stream<Map<String, int>> watchBalanceByCurrency(int accountId) {
    // One grouped query across all transactions for this account, keyed by
    // transaction currency. The sign is driven by category.type (expense
    // subtracts, income adds).
    //
    // categories is excluded from readsFrom because category.type is
    // immutable after first use (PRD.md invariant), so unrelated
    // category metadata edits must not invalidate every balance stream.
    final query = _db.customSelect(
      'SELECT t.currency AS code, '
      'SUM(CASE c.type '
      "WHEN 'income' THEN t.amount_minor_units "
      "WHEN 'expense' THEN -t.amount_minor_units "
      'END) AS net '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.account_id = ? '
      'GROUP BY t.currency',
      variables: [Variable<int>(accountId)],
      readsFrom: {_db.accounts, _db.transactions},
    );

    return query.watch().asyncMap((rows) async {
      // Build map from SQL rows; normalise codes to uppercase.
      final Map<String, int> map = {};
      for (final row in rows) {
        final code = row.read<String>('code').toUpperCase();
        map[code] = row.read<int>('net');
      }

      // Merge opening balance into the account's native currency group.
      // Only do the extra account read when needed: the account row is
      // fetched once per emission to recover native currency and opening
      // balance, but categories is not in readsFrom so category metadata
      // edits don't trigger this path.
      final account = await _dao.findById(accountId);
      if (account != null) {
        final native = account.currency.toUpperCase();
        final opening = account.openingBalanceMinorUnits;
        if (opening != 0) {
          map[native] = (map[native] ?? 0) + opening;
        } else if (!map.containsKey(native)) {
          // Native currency has no transactions and zero opening balance —
          // do not add a zero entry.
        }
      }

      // Suppress zero-value groups after the opening-balance merge.
      map.removeWhere((_, balance) => balance == 0);
      return map;
    });
  }

  @override
  Future<Account?> getLastUsedActiveAccount() async {
    // SQL-side archive filter (§3.2): the JOIN against accounts gated on
    // `is_archived = 0` skips rows whose owning account is archived, so the
    // newest *eligible* transaction surfaces directly. Doing the filter in
    // Dart after a single-row read would return null when the absolute
    // newest transaction belongs to an archived account, which is wrong.
    final rows = await _db
        .customSelect(
          'SELECT t.account_id AS account_id '
          'FROM transactions t '
          'JOIN accounts a ON a.id = t.account_id '
          'WHERE a.is_archived = 0 '
          'ORDER BY t.date DESC, t.id DESC '
          'LIMIT 1',
        )
        .get();
    if (rows.isEmpty) return null;
    return getById(rows.first.read<int>('account_id'));
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
