import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'currencies_table.dart';
import 'recurring_rules_table.dart';

/// Drift table for `pending_transactions`.
///
/// Universal staging table for items awaiting user approval, discriminated
/// by `source` ('blockchain' or 'recurring'). Source-specific columns are
/// nullable. The partial UNIQUE index `idx_pending_recurring_unique_partial`
/// is added imperatively in the migration / `onCreate` (Drift cannot express
/// the partial WHERE clause declaratively).
@DataClassName('PendingTransactionRow')
@TableIndex(name: 'idx_pending_source', columns: {#source})
@TableIndex(name: 'idx_pending_account', columns: {#accountId})
class PendingTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'blockchain' or 'recurring'.
  TextColumn get source => text()();

  IntColumn get amountMinorUnits => integer().named('amount_minor_units')();
  TextColumn get currency => text().references(Currencies, #code)();
  IntColumn get categoryId =>
      integer().named('category_id').nullable().references(Categories, #id)();
  IntColumn get accountId =>
      integer().named('account_id').references(Accounts, #id)();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get fetchedAt => dateTime().named('fetched_at')();

  // Blockchain-specific (nullable).
  TextColumn get tokenName => text().named('token_name').nullable()();
  TextColumn get tokenSymbol => text().named('token_symbol').nullable()();
  IntColumn get tokenDecimals => integer().named('token_decimals').nullable()();
  TextColumn get contractAddress =>
      text().named('contract_address').nullable()();
  TextColumn get fromAddress => text().named('from_address').nullable()();
  TextColumn get toAddress => text().named('to_address').nullable()();
  TextColumn get txHash => text().named('tx_hash').nullable().unique()();
  TextColumn get blockchain => text().nullable()();

  /// FK → `recurring_rules.id`. Null for blockchain items.
  IntColumn get recurringRuleId => integer()
      .named('recurring_rule_id')
      .nullable()
      .references(RecurringRules, #id)();
}
