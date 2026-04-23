import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

/// Thin SQL wrapper for `transactions`.
///
/// Business rules (category type-lock checks, archive-vs-delete,
/// created_at/updated_at population) live in `TransactionRepository`
/// (M3). This DAO returns Drift rows only.
@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// Watch the most recent `limit` transactions, ordered by
  /// `date DESC, id DESC`. Default cap is the MVP pagination limit of
  /// 10,000 (see `CLAUDE.md` → Pagination Cap).
  Stream<List<TransactionRow>> watchAll({int limit = 10000}) {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  /// Watch transactions whose `date` falls in the half-open range
  /// `[start, end)`. Used by month/day summaries.
  Stream<List<TransactionRow>> watchByDateRange(DateTime start, DateTime end) {
    return (select(transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Watch transactions whose `date` falls in the half-open range
  /// `[start, end)`, ordered by `date DESC, id DESC`. Backs
  /// `TransactionRepository.watchByDay` — see
  /// `docs/plans/m3-repositories-seed/stream-a-transaction-category.md` §4.
  ///
  /// Named-argument sibling of [watchByDateRange], kept distinct so
  /// consumers that want a local-midnight day window can pick the
  /// intention-revealing helper.
  Stream<List<TransactionRow>> watchInDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    return (select(transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Newest-first distinct local-midnight `DateTime`s for days that have
  /// at least one transaction, bounded by `limit`. Backs
  /// `TransactionRepository.watchDaysWithActivity` — see
  /// `docs/plans/m3-repositories-seed/stream-a-transaction-category.md` §4.
  ///
  /// SQL groups by `date(date, 'localtime')` so days are segmented in
  /// the device's local timezone, matching the home screen UX.
  Stream<List<DateTime>> watchDistinctActivityDays({int limit = 365}) {
    final dayExpr = transactions.date
        .modify(const DateTimeModifier.localTime())
        .date;
    final query = selectOnly(transactions, distinct: true)
      ..addColumns([dayExpr])
      ..orderBy([OrderingTerm(expression: dayExpr, mode: OrderingMode.desc)])
      ..limit(limit);
    return query.watch().map(
      (rows) => rows
          .map((r) => r.read(dayExpr)!)
          .map(
            (d) => DateTime(
              int.parse(d.substring(0, 4)),
              int.parse(d.substring(5, 7)),
              int.parse(d.substring(8, 10)),
            ),
          )
          .toList(growable: false),
    );
  }

  /// Watch every transaction for a given account, reverse-chronological,
  /// bounded by `limit`. Backs
  /// `TransactionRepository.watchForAccount` — see
  /// `docs/plans/m3-repositories-seed/stream-a-transaction-category.md` §4.
  Stream<List<TransactionRow>> watchByAccount(
    int accountId, {
    int limit = 200,
  }) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  /// Watch every transaction for a given category, reverse-chronological,
  /// bounded by `limit`. Backs
  /// `TransactionRepository.watchForCategory` — see
  /// `docs/plans/m3-repositories-seed/stream-a-transaction-category.md` §4.
  Stream<List<TransactionRow>> watchByCategory(
    int categoryId, {
    int limit = 200,
  }) {
    return (select(transactions)
          ..where((t) => t.categoryId.equals(categoryId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  /// Watch a single transaction by id (Edit screen).
  Stream<TransactionRow?> watchById(int id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// One-shot read by id (e.g. duplicate flow).
  Future<TransactionRow?> findById(int id) {
    return (select(
      transactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new row. Returns the new `id`.
  Future<int> insert(TransactionsCompanion row) {
    return into(transactions).insert(row);
  }

  /// Replace row by PK.
  Future<bool> updateRow(TransactionsCompanion row) {
    return update(transactions).replace(row);
  }

  /// Delete by id. Returns the number of affected rows.
  Future<int> deleteById(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Count transactions referencing the given category. Fuels the M3
  /// category type-lock check.
  Future<int> countByCategory(int categoryId) async {
    final countExp = transactions.id.count();
    final row =
        await (selectOnly(transactions)
              ..addColumns([countExp])
              ..where(transactions.categoryId.equals(categoryId)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Count transactions referencing the given account. Fuels the M3
  /// account archive-vs-delete check.
  Future<int> countByAccount(int accountId) async {
    final countExp = transactions.id.count();
    final row =
        await (selectOnly(transactions)
              ..addColumns([countExp])
              ..where(transactions.accountId.equals(accountId)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }
}
