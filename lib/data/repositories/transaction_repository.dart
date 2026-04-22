// `TransactionRepository` — SSOT for `transactions` rows.
//
// See `docs/plans/m3-repositories-seed/stream-a-transaction-category.md`
// for the full specification. Drift data classes never leave this file.
//
// Invariants enforced here (and only here):
//   - Integer minor-unit arithmetic (G4 — PRD.md Money Storage Policy).
//   - Currency FK integrity — `save` pre-checks the FK and throws a
//     typed `CurrencyNotFoundException` before Drift's SQL layer can
//     surface an opaque `SqliteException` (G2 — PRD.md 286).
//   - `createdAt` / `updatedAt` populated by the repository, never by
//     SQL defaults (PRD.md 291-293).
//   - Home screen is day-bounded: `watchByDay` + `watchDaysWithActivity`
//     replace any notion of `watchAll` (Stream A §12 Q2/Q5).

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/currency_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../models/currency.dart';
import '../models/transaction.dart';
import 'repository_exceptions.dart';

/// Generic transaction-layer failure — used for "transaction not found"
/// / "disappeared mid-write" paths that do not deserve a dedicated
/// typed subclass. Kept Stream-A-local per §1.3.
///
/// Does **not** extend the sealed [RepositoryException] — the Phase 1
/// base class is closed to outside subclasses. This leaf `implements
/// Exception` directly and carries an identical `toString()` shape.
class TransactionRepositoryException implements Exception {
  const TransactionRepositoryException(this.message);

  /// Human-readable description.
  final String message;

  @override
  String toString() => 'TransactionRepositoryException: $message';
}

/// SSOT for `transactions`. Owns every write path to the Drift
/// `transactions` table. Drift data classes never leave this file.
///
/// Invariants enforced here (and only here):
/// - Integer minor-unit arithmetic for every amount (G4 — PRD.md
///   Money Storage Policy).
/// - Currency FK integrity — insert rejects unknown `Currency.code`
///   (G2 / PRD.md 286).
/// - `createdAt` / `updatedAt` populated by the repository, never by
///   SQL defaults (PRD.md 291-293).
abstract class TransactionRepository {
  /// Transactions for one calendar day, in the device's local timezone.
  /// Day window: `[localMidnight(day), localMidnight(day) + 24h)`.
  /// Reverse-chronological within the day.
  Stream<List<Transaction>> watchByDay(DateTime day);

  /// Newest-first stream of days that have at least one transaction,
  /// bounded by `limit`. Each element is the local-midnight `DateTime`
  /// of a distinct day.
  Stream<List<DateTime>> watchDaysWithActivity({int limit = 365});

  /// Transactions for a single account, reverse-chronological.
  Stream<List<Transaction>> watchForAccount(int accountId, {int limit = 200});

  /// Transactions for a single category, reverse-chronological.
  Stream<List<Transaction>> watchForCategory(int categoryId, {int limit = 200});

  /// One-shot read by id. Returns null when no row matches.
  Future<Transaction?> getById(int id);

  /// Insert-or-update. Treats `id == 0` as insert, `id != 0` as update
  /// by PK.
  ///
  /// On **insert**: sets `createdAt = updatedAt = clock()`. Returns the
  /// inserted row with populated `id`, `createdAt`, `updatedAt`.
  /// On **update**: refreshes `updatedAt = clock()`, preserves the
  /// stored `createdAt` untouched. Returns the updated row.
  ///
  /// Throws:
  /// - [CurrencyNotFoundException] when `tx.currency.code` is absent
  ///   from the `currencies` table.
  /// - [RepositoryException] on any other Drift-layer failure.
  Future<Transaction> save(Transaction tx);

  /// Delete by id. Returns `true` when a row was removed, `false` when
  /// no row matched.
  Future<bool> delete(int id);

  /// Quick-repeat / duplicate flow. Copies every field except `id` and
  /// timestamps; the duplicate is a brand-new transaction row.
  ///
  /// Throws [RepositoryException] when `sourceId` does not exist.
  Future<Transaction> duplicate(int sourceId);
}

/// Concrete Drift-backed implementation of [TransactionRepository].
final class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final drift.AppDatabase _db;
  final DateTime Function() _clock;

  TransactionDao get _dao => _db.transactionDao;
  CurrencyDao get _currencyDao => _db.currencyDao;

  // ---------- Reads ----------

  @override
  Stream<List<Transaction>> watchByDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _dao
        .watchInDateRange(start: start, end: end)
        .asyncMap((rows) => Future.wait(rows.map(_toDomain)));
  }

  @override
  Stream<List<DateTime>> watchDaysWithActivity({int limit = 365}) {
    return _dao
        .watchDistinctActivityDays(limit: limit)
        .map((days) => List.unmodifiable(days));
  }

  @override
  Stream<List<Transaction>> watchForAccount(int accountId, {int limit = 200}) {
    return _dao
        .watchByAccount(accountId, limit: limit)
        .asyncMap((rows) => Future.wait(rows.map(_toDomain)));
  }

  @override
  Stream<List<Transaction>> watchForCategory(
    int categoryId, {
    int limit = 200,
  }) {
    return _dao
        .watchByCategory(categoryId, limit: limit)
        .asyncMap((rows) => Future.wait(rows.map(_toDomain)));
  }

  @override
  Future<Transaction?> getById(int id) async {
    final row = await _dao.findById(id);
    if (row == null) return null;
    return _toDomain(row);
  }

  // ---------- Writes ----------

  @override
  Future<Transaction> save(Transaction tx) async {
    // Currency FK pre-check (G2). Producing a typed exception beats
    // surfacing an opaque `SqliteException` from the insert.
    final resolved = await _currencyDao.findByCode(tx.currency.code);
    if (resolved == null) {
      throw CurrencyNotFoundException(tx.currency.code);
    }

    final now = _clock();
    if (tx.id == 0) {
      // Insert path.
      final companion = _toCompanion(tx, createdAt: now, updatedAt: now);
      final newId = await _dao.insert(companion);
      final inserted = await _dao.findById(newId);
      if (inserted == null) {
        throw const TransactionRepositoryException(
          'Inserted transaction disappeared before read-back',
        );
      }
      return _toDomain(inserted);
    }

    // Update path. Preserve stored `createdAt`.
    final stored = await _dao.findById(tx.id);
    if (stored == null) {
      throw TransactionRepositoryException('Transaction ${tx.id} not found');
    }
    final companion = _toCompanion(
      tx,
      createdAt: stored.createdAt,
      updatedAt: now,
    );
    await _dao.updateRow(companion);
    final updated = await _dao.findById(tx.id);
    if (updated == null) {
      throw TransactionRepositoryException(
        'Transaction ${tx.id} disappeared after update',
      );
    }
    return _toDomain(updated);
  }

  @override
  Future<bool> delete(int id) async {
    final removed = await _dao.deleteById(id);
    return removed > 0;
  }

  @override
  Future<Transaction> duplicate(int sourceId) async {
    final source = await _dao.findById(sourceId);
    if (source == null) {
      throw TransactionRepositoryException(
        'Cannot duplicate: transaction $sourceId not found',
      );
    }
    final domain = await _toDomain(source);
    final copy = Transaction(
      id: 0,
      amountMinorUnits: domain.amountMinorUnits,
      currency: domain.currency,
      categoryId: domain.categoryId,
      accountId: domain.accountId,
      memo: domain.memo,
      date: domain.date,
      // Placeholders; `save` overwrites with `clock()` on the insert path.
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
    );
    return save(copy);
  }

  // ---------- Private mapping ----------

  Future<Transaction> _toDomain(drift.TransactionRow row) async {
    // Currency FK-resolved on read. Non-null asserted because the row
    // cannot exist without a matching `currencies` entry:
    //   (a) `save` runs a pre-insert `CurrencyDao.findByCode` check,
    //   (b) `AppDatabase.beforeOpen` sets `PRAGMA foreign_keys = ON`.
    // See Q4 resolution in Stream A plan §12.
    final currencyRow = (await _currencyDao.findByCode(row.currency))!;
    return Transaction(
      id: row.id,
      amountMinorUnits: row.amountMinorUnits,
      currency: _currencyFromRow(currencyRow),
      categoryId: row.categoryId,
      accountId: row.accountId,
      memo: row.memo,
      date: row.date,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Currency _currencyFromRow(drift.Currency row) => Currency(
    code: row.code,
    decimals: row.decimals,
    symbol: row.symbol,
    nameL10nKey: row.nameL10nKey,
    customName: row.customName,
    isToken: row.isToken,
    sortOrder: row.sortOrder,
  );

  drift.TransactionsCompanion _toCompanion(
    Transaction tx, {
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return drift.TransactionsCompanion(
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
}
