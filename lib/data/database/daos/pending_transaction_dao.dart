import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/pending_transactions_table.dart';

part 'pending_transaction_dao.g.dart';

/// Thin SQL wrapper for `pending_transactions`.
///
/// Approve/reject and richer query methods will be added by the Pending
/// Transactions UI plan (Wave 3). MVP exposes only what
/// [RecurringGenerationUseCase] and the form's pending-count notice need.
@DriftAccessor(tables: [PendingTransactions])
class PendingTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$PendingTransactionDaoMixin {
  PendingTransactionDao(super.db);

  /// Check if a pending row already exists for the given recurring rule
  /// + date. Used by the generation engine's fast-path idempotency skip.
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date) async {
    final countExp = pendingTransactions.id.count();
    final row =
        await (selectOnly(pendingTransactions)
              ..addColumns([countExp])
              ..where(
                pendingTransactions.recurringRuleId.equals(ruleId) &
                    pendingTransactions.date.equals(date) &
                    pendingTransactions.source.equals('recurring'),
              ))
            .getSingle();
    return (row.read(countExp) ?? 0) > 0;
  }

  /// Insert a new pending row. Returns the new id.
  Future<int> insert(PendingTransactionsCompanion row) {
    return into(pendingTransactions).insert(row);
  }

  /// Count pending rows for a specific recurring rule.
  /// Used by the form screen's inline notice.
  Future<int> countByRecurringRule(int ruleId) async {
    final countExp = pendingTransactions.id.count();
    final row =
        await (selectOnly(pendingTransactions)
              ..addColumns([countExp])
              ..where(
                pendingTransactions.recurringRuleId.equals(ruleId) &
                    pendingTransactions.source.equals('recurring'),
              ))
            .getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Stream pending rows produced by recurring rules, ordered by date DESC,
  /// id DESC.
  ///
  /// Filtered to `source = 'recurring'` for v1. PendingTile is shaped around
  /// recurring-row fields (memo as title, category icon as leading) and would
  /// not render correctly for blockchain rows. Wallet sync (Phase 2) will
  /// either drop this filter or replace this stream with a `watchAllForUI`.
  Stream<List<PendingTransactionRow>> watchAll() {
    return (select(pendingTransactions)
          ..where((t) => t.source.equals('recurring'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Load a single pending row by id, or null if not found.
  Future<PendingTransactionRow?> findById(int id) {
    return (select(
      pendingTransactions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Delete a pending row by id. Returns the number of rows affected.
  Future<int> rejectRow(int id) {
    return (delete(pendingTransactions)..where((t) => t.id.equals(id))).go();
  }
}
