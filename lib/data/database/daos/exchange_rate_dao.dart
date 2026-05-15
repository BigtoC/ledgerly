import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts_table.dart';
import '../tables/exchange_rates_table.dart';
import '../tables/pending_transactions_table.dart';
import '../tables/transactions_table.dart';

part 'exchange_rate_dao.g.dart';

/// Thin SQL wrapper for `exchange_rates`.
///
/// Provides bulk upsert, watch-all, and a cross-table query to discover
/// every currency code in use across accounts, transactions, and
/// pending_transactions. Business logic (sanity bounds, scaling,
/// snapshot management) lives in `ExchangeRateRepository`.
@DriftAccessor(
  tables: [ExchangeRates, Accounts, Transactions, PendingTransactions],
)
class ExchangeRateDao extends DatabaseAccessor<AppDatabase>
    with _$ExchangeRateDaoMixin {
  ExchangeRateDao(super.db);

  /// Watch all exchange-rate rows. Emits on every change to the table.
  Stream<List<ExchangeRateRow>> watchAll() {
    return select(exchangeRates).watch();
  }

  /// Bulk upsert. Uses `insertOrReplace` so re-fetching the same pair
  /// overwrites the previous row (the unique index on
  /// `(base_currency, quote_currency)` is the conflict target).
  Future<void> upsertAll(List<ExchangeRatesCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(exchangeRates, rows, mode: InsertMode.insertOrReplace);
    });
  }

  /// Returns the set of distinct currency codes appearing in `accounts`,
  /// `transactions`, and `pending_transactions`. Uses Drift's type-safe
  /// query API so any future column rename surfaces at compile time
  /// instead of failing silently at runtime.
  Future<Set<String>> distinctCurrenciesAcrossAllTables() async {
    final results = await Future.wait([
      (selectOnly(accounts, distinct: true)..addColumns([accounts.currency]))
          .get(),
      (selectOnly(transactions, distinct: true)
            ..addColumns([transactions.currency]))
          .get(),
      (selectOnly(pendingTransactions, distinct: true)
            ..addColumns([pendingTransactions.currency]))
          .get(),
    ]);
    final codes = <String>{};
    codes.addAll(results[0].map((r) => r.read(accounts.currency)!));
    codes.addAll(results[1].map((r) => r.read(transactions.currency)!));
    codes.addAll(results[2].map((r) => r.read(pendingTransactions.currency)!));
    return codes;
  }
}
