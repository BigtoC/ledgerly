import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'currencies_table.dart';

/// Drift table for `transactions`.
///
/// See `PRD.md` lines 275–291 (Database Schema → transactions) and
/// `docs/plans/m1-data-foundations/stream-a-drift-schema.md` §2.2.
///
/// - Transaction type (expense/income) is **derived** from the linked
///   category's `type`; there is no `type` column here.
/// - `created_at` and `updated_at` are **NOT NULL**. Both are populated
///   by `TransactionRepository` (M3): set to `DateTime.now()` on insert
///   and `updated_at` refreshed on every update. Drift does not populate
///   these; keeping the DAO stateless forces every write through the
///   repository.
@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_date_idx', columns: {#date})
@TableIndex(name: 'transactions_account_idx', columns: {#accountId})
@TableIndex(name: 'transactions_category_idx', columns: {#categoryId})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Integer minor units. Scaling factor is `currencies.decimals` —
  /// never a double. See `PRD.md` → Money Storage Policy and
  /// `CLAUDE.md` → Data-Model Invariants.
  IntColumn get amountMinorUnits => integer().named('amount_minor_units')();
  TextColumn get currency => text().references(Currencies, #code)();
  IntColumn get categoryId =>
      integer().named('category_id').references(Categories, #id)();
  IntColumn get accountId =>
      integer().named('account_id').references(Accounts, #id)();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}
