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
}
