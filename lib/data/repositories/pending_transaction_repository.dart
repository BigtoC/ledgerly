// `PendingTransactionRepository` — minimal SSOT for `pending_transactions`.
//
// MVP exposes only the methods needed by [RecurringGenerationUseCase] and
// the recurring rule form's pending-count notice. The full repository
// (with approve/reject, stream watchers, etc.) lands with the Pending
// Transactions UI in Wave 3.

import 'package:drift/drift.dart' show Value;

import '../database/app_database.dart' as drift;
import '../database/daos/pending_transaction_dao.dart';

class PendingTransactionRepositoryException implements Exception {
  const PendingTransactionRepositoryException(this.message);
  final String message;
  @override
  String toString() => 'PendingTransactionRepositoryException: $message';
}

abstract class PendingTransactionRepository {
  /// Check if a pending row exists for the given recurring rule + date.
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date);

  /// Insert a new pending row. Returns the new id.
  Future<int> insert({
    required String source,
    required int amountMinorUnits,
    required String currencyCode,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  });

  /// Count pending rows for a specific recurring rule.
  Future<int> countByRecurringRule(int ruleId);
}

final class DriftPendingTransactionRepository
    implements PendingTransactionRepository {
  DriftPendingTransactionRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final drift.AppDatabase _db;
  // ignore: unused_field
  final DateTime Function() _clock;

  PendingTransactionDao get _dao => _db.pendingTransactionDao;

  @override
  Future<bool> existsForRuleAndDate(int ruleId, DateTime date) {
    return _dao.existsForRuleAndDate(ruleId, date);
  }

  @override
  Future<int> insert({
    required String source,
    required int amountMinorUnits,
    required String currencyCode,
    int? categoryId,
    required int accountId,
    String? memo,
    required DateTime date,
    required DateTime fetchedAt,
    int? recurringRuleId,
  }) {
    return _dao.insert(
      drift.PendingTransactionsCompanion(
        source: Value(source),
        amountMinorUnits: Value(amountMinorUnits),
        currency: Value(currencyCode),
        categoryId: categoryId != null
            ? Value(categoryId)
            : const Value.absent(),
        accountId: Value(accountId),
        memo: memo != null ? Value(memo) : const Value.absent(),
        date: Value(date),
        fetchedAt: Value(fetchedAt),
        recurringRuleId: recurringRuleId != null
            ? Value(recurringRuleId)
            : const Value.absent(),
      ),
    );
  }

  @override
  Future<int> countByRecurringRule(int ruleId) {
    return _dao.countByRecurringRule(ruleId);
  }
}
