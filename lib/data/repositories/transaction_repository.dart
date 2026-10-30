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
//   - Transaction currency is independent of account currency. The
//     controller sends `displayCurrency` (user-controlled) on save; the
//     repository accepts any valid seeded currency regardless of the
//     account's own currency.
//   - `createdAt` / `updatedAt` populated by the repository, never by
//     SQL defaults (PRD.md 291-293). One documented exception:
//     `insertImported` (CSV import) keeps the caller's `createdAt`, the
//     source app's Recorded At, and sets `updatedAt` to the clock.
//   - Home screen is day-bounded: `watchByDay` + `watchDaysWithActivity`
//     replace any notion of `watchAll` (Stream A §12 Q2/Q5).

import 'package:drift/drift.dart' show Value, Variable;

import '../../core/utils/date_helpers.dart';
import '../database/app_database.dart' as drift;
import '../database/daos/currency_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../models/account_slice.dart';
import '../models/category.dart' show CategoryType;
import '../models/category_slice.dart';
import '../models/currency.dart';
import '../models/currency_slice.dart';
import '../models/time_bucket_slice.dart';
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

/// Fields CSV import compares to find rows that already exist. See
/// [TransactionRepository.getImportSignatures].
typedef TransactionImportSignature = ({
  DateTime createdAt,
  int amountMinorUnits,
  String currencyCode,
  String? memo,
});

/// SSOT for `transactions`. Owns every write path to the Drift
/// `transactions` table. Drift data classes never leave this file.
///
/// Invariants enforced here (and only here):
/// - Integer minor-unit arithmetic for every amount (G4 — PRD.md
///   Money Storage Policy).
/// - Currency FK integrity — insert rejects unknown `Currency.code`
///   (G2 / PRD.md 286).
/// - `createdAt` / `updatedAt` populated by the repository, never by
///   SQL defaults (PRD.md 291-293). [insertImported] is the one exception:
///   it keeps the caller's `createdAt`.
///
/// **No `duplicate(id)` convenience method exists by design.** PRD's
/// quick-repeat flow ("user adjusts amount or date if needed → tap
/// Save") requires the user to edit the prefill *before* it persists,
/// so the UI drives the flow as `getById` → prefill in form state →
/// user edits → `save`. A repository-level duplicate-and-save would
/// bypass the edit step. Do not re-add it.
abstract class TransactionRepository {
  /// Transactions for one calendar day, in the device's local timezone.
  /// Day window: `[localMidnight(day), localMidnight(day) + 24h)`.
  /// Reverse-chronological within the day.
  Stream<List<Transaction>> watchByDay(DateTime day);

  /// Newest-first stream of days that have at least one transaction,
  /// bounded to the 365 most recent days. Each element is the
  /// local-midnight `DateTime` of a distinct day.
  Stream<List<DateTime>> watchDaysWithActivity();

  /// Split of daily totals by transaction type (expense vs income),
  /// grouped by currency. Both values are unsigned sums (non-negative).
  /// Day window is the device-local midnight-to-midnight boundary.
  /// Re-emits on every relevant mutation — Wave 3 §3.
  Stream<Map<String, ({int expense, int income})>> watchDailyTotalsByType(
    DateTime day,
  );

  /// Net per currency for the calendar month containing `month` (device
  /// local timezone). Income contributes positively, expense negatively
  /// (sign derived from `categories.type`). Re-emits on any transaction
  /// mutation within the month — Wave 3 §3.
  Stream<Map<String, int>> watchMonthNetByCurrency(DateTime month);

  /// Net per currency for transactions in `[start, end)`. Same sign rule
  /// as [watchMonthNetByCurrency]. Used by the Analysis net-total box.
  Stream<Map<String, int>> watchNetByCurrencyInRange({
    required DateTime start,
    required DateTime end,
  });

  /// Transactions for a single account, reverse-chronological.
  Stream<List<Transaction>> watchForAccount(int accountId, {int limit = 200});

  /// Transactions for a single category, reverse-chronological.
  Stream<List<Transaction>> watchForCategory(int categoryId, {int limit = 200});

  /// Transactions whose memo contains [query] (case-insensitive
  /// substring). Returns domain models ordered `date DESC, id DESC`.
  /// Empty/whitespace queries emit `[]` (DAO short-circuits).
  Stream<List<Transaction>> watchByMemo(String query);

  /// Up to [limit] distinct memos (trimmed) previously used in
  /// [categoryId], most recently saved first (by `updatedAt`, not the
  /// transaction date). NULL and whitespace-only memos are excluded. Feeds the transaction form's memo suggestions.
  /// A null [limit] returns every distinct memo.
  Stream<List<String>> watchRecentMemosForCategory(
    int categoryId, {
    int? limit,
  });

  /// Per-(category, currency) subtotal in `[start, end)` filtered by
  /// transaction type. Emits one row per pair so chart controllers can
  /// run currency conversion before regrouping. See basic-charts spec
  /// § Data Layer / Query Examples.
  Stream<List<CategorySlice>> watchByCategoryInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  });

  /// Per-(account, currency) subtotal in `[start, end)` filtered by
  /// transaction type.
  Stream<List<AccountSlice>> watchByAccountInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  });

  /// Per-currency total in `[start, end)` filtered by transaction type.
  Stream<List<CurrencySlice>> watchByCurrencyInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  });

  /// Per-(bucketStart, currency) subtotal in `[start, end)` filtered by
  /// transaction type, with [granularity] selecting hour/day/month
  /// buckets. Local bucket math uses `DateHelpers` so midnight + DST
  /// behaviour matches the rest of the app.
  ///
  /// Optional plain filters scope the buckets for drill-down refiltering.
  /// All-null behaves identically to today (regression-protected).
  Stream<List<TimeBucketSlice>> watchTimeBucketsInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
    required TimeBucketGranularity granularity,
    int? categoryId,
    int? accountId,
    String? currencyCode,
  });

  /// Transactions matching the optional drill-down filters within
  /// `[start, end)`, of [type]. Ordered `date DESC, id DESC` to match
  /// Home / Search Level 2 row conventions. Backs the chart drill-down
  /// items list.
  Stream<List<Transaction>> watchTransactionsForSliceInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
    int? categoryId,
    int? accountId,
    String? currencyCode,
  });

  /// Earliest and latest transaction `date`, or null when there are no
  /// transactions. One-shot.
  Future<({DateTime first, DateTime last})?> getDateBounds();

  /// One-shot read of every transaction whose `date` falls in the
  /// half-open range `[start, end)`, oldest first (ties by id). Not
  /// capped: the CSV export reads the whole range.
  Future<List<Transaction>> getInDateRange(DateTime start, DateTime end);

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

  /// Inserts CSV-imported rows in list order, so ids ascend with the
  /// list, and returns how many were inserted. Each row keeps its own
  /// `createdAt` (the source's recorded time) and `date`; `updatedAt` is
  /// one clock reading shared by every row; `amountFormula` is null.
  /// This is the documented exception to "on insert both timestamps are
  /// set to now". All rows land in one transaction (a savepoint when the
  /// caller already holds one), so a failure inserts nothing.
  ///
  /// Throws [CurrencyNotFoundException] for any code absent from
  /// `currencies`, before anything is written.
  Future<int> insertImported(List<Transaction> txs);

  /// Duplicate-detection keys of every transaction whose `createdAt`
  /// lies in `[start, endInclusive]`. Returns only these four fields; the
  /// DAO also reads `id` to page.
  Future<List<TransactionImportSignature>> getImportSignatures(
    DateTime start,
    DateTime endInclusive,
  );

  /// Delete by id. Returns `true` when a row was removed, `false` when
  /// no row matched.
  Future<bool> delete(int id);
}

/// Rows per DAO page in [DriftTransactionRepository.getImportSignatures].
const _kImportSignaturePage = 2000;

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
    final start = DateHelpers.startOfDay(day);
    final end = DateHelpers.startOfDay(
      DateTime(day.year, day.month, day.day + 1),
    );
    return _dao
        .watchInDateRange(start: start, end: end)
        .asyncMap(_rowsToDomain);
  }

  @override
  Stream<List<DateTime>> watchDaysWithActivity() {
    return _dao.watchDistinctActivityDays().map(
      (days) => List.unmodifiable(days),
    );
  }

  @override
  Stream<Map<String, ({int expense, int income})>> watchDailyTotalsByType(
    DateTime day,
  ) {
    final start = DateHelpers.startOfDay(day);
    final end = DateHelpers.startOfDay(
      DateTime(day.year, day.month, day.day + 1),
    );
    // Both totals are unsigned (non-negative); the screen splits them
    // for the summary strip.
    final query = _db.customSelect(
      'SELECT t.currency AS code, '
      "COALESCE(SUM(CASE WHEN c.type = 'expense' "
      'THEN t.amount_minor_units ELSE 0 END), 0) AS expense, '
      "COALESCE(SUM(CASE WHEN c.type = 'income' "
      'THEN t.amount_minor_units ELSE 0 END), 0) AS income '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? '
      'GROUP BY t.currency',
      variables: <Variable<Object>>[
        Variable<DateTime>(start),
        Variable<DateTime>(end),
      ],
      readsFrom: {_db.transactions, _db.categories},
    );
    return query.watch().map((rows) {
      final out = <String, ({int expense, int income})>{};
      for (final row in rows) {
        out[row.read<String>('code')] = (
          expense: row.read<int>('expense'),
          income: row.read<int>('income'),
        );
      }
      return out;
    });
  }

  @override
  Stream<Map<String, int>> watchMonthNetByCurrency(DateTime month) {
    final start = DateHelpers.startOfDay(DateTime(month.year, month.month, 1));
    final end = DateHelpers.startOfDay(
      DateTime(month.year, month.month + 1, 1),
    );
    return _watchNetByCurrency(start: start, end: end);
  }

  @override
  Stream<Map<String, int>> watchNetByCurrencyInRange({
    required DateTime start,
    required DateTime end,
  }) => _watchNetByCurrency(start: start, end: end);

  Stream<Map<String, int>> _watchNetByCurrency({
    required DateTime start,
    required DateTime end,
  }) {
    final query = _db.customSelect(
      'SELECT t.currency AS code, '
      'SUM(CASE c.type '
      "WHEN 'income' THEN t.amount_minor_units "
      "WHEN 'expense' THEN -t.amount_minor_units "
      'END) AS net '
      'FROM transactions t '
      'JOIN categories c ON c.id = t.category_id '
      'WHERE t.date >= ? AND t.date < ? '
      'GROUP BY t.currency',
      variables: <Variable<Object>>[
        Variable<DateTime>(start),
        Variable<DateTime>(end),
      ],
      readsFrom: {_db.transactions, _db.categories},
    );
    return query.watch().map((rows) {
      final out = <String, int>{};
      for (final row in rows) {
        out[row.read<String>('code')] = row.read<int>('net');
      }
      return out;
    });
  }

  @override
  Stream<List<Transaction>> watchForAccount(int accountId, {int limit = 200}) {
    return _dao.watchByAccount(accountId, limit: limit).asyncMap(_rowsToDomain);
  }

  @override
  Stream<List<Transaction>> watchForCategory(
    int categoryId, {
    int limit = 200,
  }) {
    return _dao
        .watchByCategory(categoryId, limit: limit)
        .asyncMap(_rowsToDomain);
  }

  @override
  Stream<List<Transaction>> watchByMemo(String query) {
    return _dao.watchByMemo(query).asyncMap(_rowsToDomain);
  }

  @override
  Stream<List<String>> watchRecentMemosForCategory(
    int categoryId, {
    int? limit,
  }) {
    return _dao.watchRecentMemosByCategory(categoryId, limit: limit);
  }

  String _typeWire(CategoryType type) =>
      type == CategoryType.expense ? 'expense' : 'income';

  @override
  Stream<List<CategorySlice>> watchByCategoryInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  }) {
    return _dao
        .watchCategoryTotalsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
        )
        .map(
          (rows) => rows
              .map(
                (r) => CategorySlice(
                  categoryId: r.categoryId,
                  currencyCode: r.currency,
                  totalMinorUnits: r.total,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<AccountSlice>> watchByAccountInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  }) {
    return _dao
        .watchAccountTotalsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
        )
        .map(
          (rows) => rows
              .map(
                (r) => AccountSlice(
                  accountId: r.accountId,
                  currencyCode: r.currency,
                  totalMinorUnits: r.total,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<CurrencySlice>> watchByCurrencyInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
  }) {
    return _dao
        .watchCurrencyTotalsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
        )
        .map(
          (rows) => rows
              .map(
                (r) => CurrencySlice(
                  currencyCode: r.currency,
                  totalMinorUnits: r.total,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<TimeBucketSlice>> watchTimeBucketsInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
    required TimeBucketGranularity granularity,
    int? categoryId,
    int? accountId,
    String? currencyCode,
  }) {
    return _dao
        .watchChartRowsInRange(
          start: start,
          end: end,
          type: _typeWire(type),
          categoryId: categoryId,
          accountId: accountId,
          currencyCode: currencyCode,
        )
        .map((rows) {
          // Bucket locally so DST / midnight semantics match DateHelpers.
          final acc = <(DateTime, String), int>{};
          for (final r in rows) {
            final bucketStart = switch (granularity) {
              TimeBucketGranularity.hour => DateTime(
                r.date.year,
                r.date.month,
                r.date.day,
                r.date.hour,
              ),
              TimeBucketGranularity.day => DateHelpers.startOfDay(r.date),
              TimeBucketGranularity.month => DateHelpers.startOfMonth(r.date),
            };
            final key = (bucketStart, r.currency);
            acc[key] = (acc[key] ?? 0) + r.amountMinorUnits;
          }
          return acc.entries
              .map(
                (e) => TimeBucketSlice(
                  bucketStart: e.key.$1,
                  currencyCode: e.key.$2,
                  totalMinorUnits: e.value,
                ),
              )
              .toList(growable: false);
        });
  }

  @override
  Stream<List<Transaction>> watchTransactionsForSliceInRange({
    required DateTime start,
    required DateTime end,
    required CategoryType type,
    int? categoryId,
    int? accountId,
    String? currencyCode,
  }) {
    return _dao
        .watchTransactionRowsForSliceInRange(
          start: start,
          end: end,
          type: _typeWire(type),
          categoryId: categoryId,
          accountId: accountId,
          currencyCode: currencyCode,
        )
        .asyncMap(_rowsToDomain);
  }

  @override
  Future<({DateTime first, DateTime last})?> getDateBounds() =>
      _dao.getDateBounds();

  @override
  Future<List<Transaction>> getInDateRange(DateTime start, DateTime end) async {
    return _rowsToDomain(await _dao.getInDateRange(start: start, end: end));
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
  Future<int> insertImported(List<Transaction> txs) async {
    for (final code in txs.map((tx) => tx.currency.code).toSet()) {
      if (await _currencyDao.findByCode(code) == null) {
        throw CurrencyNotFoundException(code);
      }
    }

    final now = _clock();
    final rows = [
      for (final tx in txs)
        _toCompanion(
          tx,
          createdAt: tx.createdAt,
          updatedAt: now,
        ).copyWith(id: const Value.absent(), amountFormula: const Value(null)),
    ];
    await _db.transaction(() => _dao.insertBatch(rows));
    return rows.length;
  }

  @override
  Future<List<TransactionImportSignature>> getImportSignatures(
    DateTime start,
    DateTime endInclusive,
  ) async {
    // Keyset pages keep each read, and the isolate hop that carries it,
    // bounded however much history the range spans.
    final signatures = <TransactionImportSignature>[];
    var afterId = 0;
    while (true) {
      final page = await _dao.getImportSignatureRows(
        start: start,
        endInclusive: endInclusive,
        afterId: afterId,
        limit: _kImportSignaturePage,
      );
      for (final r in page) {
        signatures.add((
          createdAt: r.createdAt,
          amountMinorUnits: r.amountMinorUnits,
          currencyCode: r.currency,
          memo: r.memo,
        ));
      }
      if (page.length < _kImportSignaturePage) return signatures;
      afterId = page.last.id;
    }
  }

  @override
  Future<bool> delete(int id) async {
    final removed = await _dao.deleteById(id);
    return removed > 0;
  }

  // ---------- Private mapping ----------

  Future<List<Transaction>> _rowsToDomain(
    List<drift.TransactionRow> rows,
  ) async {
    if (rows.isEmpty) {
      return const <Transaction>[];
    }

    final codes = rows.map((row) => row.currency).toSet();
    final currenciesByCode = <String, Currency>{};
    for (final code in codes) {
      // Currency FK-resolved on read. Non-null asserted because the row
      // cannot exist without a matching `currencies` entry:
      //   (a) `save` runs a pre-insert `CurrencyDao.findByCode` check,
      //   (b) `AppDatabase.beforeOpen` sets `PRAGMA foreign_keys = ON`.
      // See Q4 resolution in Stream A plan §12.
      final currencyRow = (await _currencyDao.findByCode(code))!;
      currenciesByCode[code] = _currencyFromRow(currencyRow);
    }

    return rows
        .map(
          (row) => Transaction(
            id: row.id,
            amountMinorUnits: row.amountMinorUnits,
            currency: currenciesByCode[row.currency]!,
            categoryId: row.categoryId,
            accountId: row.accountId,
            memo: row.memo,
            amountFormula: row.amountFormula,
            date: row.date,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<Transaction> _toDomain(drift.TransactionRow row) async =>
      (await _rowsToDomain([row])).single;

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
      // Always written so an edit that drops the expression clears it.
      amountFormula: Value(tx.amountFormula),
      date: Value(tx.date),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
