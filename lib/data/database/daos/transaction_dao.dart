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

  /// Watch every transaction for a given account.
  Stream<List<TransactionRow>> watchByAccount(int accountId) {
    return (select(transactions)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
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
