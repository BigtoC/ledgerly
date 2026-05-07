import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'currencies_table.dart';

/// Drift table for `recurring_rules`.
///
/// Stores user-defined rules that generate `pending_transactions` rows on
/// cold-start (and on save). `next_due_date` is denormalized so the
/// generation engine can find due rules with a single index lookup.
///
/// `last_error` / `last_error_at` capture the most recent generation
/// failure for surfacing in UI; cleared on the next successful pass.
@DataClassName('RecurringRuleRow')
@TableIndex(
  name: 'idx_recurring_active_due',
  columns: {#isActive, #nextDueDate},
)
@TableIndex(name: 'idx_recurring_archived', columns: {#isArchived})
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// User-friendly label ("Netflix", "Rent").
  TextColumn get name => text()();

  /// Fixed amount per occurrence, in minor units.
  IntColumn get amountMinorUnits => integer().named('amount_minor_units')();

  /// FK → `currencies.code`.
  TextColumn get currency => text().references(Currencies, #code)();

  /// FK → `categories.id`.
  IntColumn get categoryId =>
      integer().named('category_id').references(Categories, #id)();

  /// FK → `accounts.id`.
  IntColumn get accountId =>
      integer().named('account_id').references(Accounts, #id)();

  /// Optional memo pre-filled on each generated item.
  TextColumn get memo => text().nullable()();

  /// 'daily', 'weekly', 'monthly', 'yearly'.
  TextColumn get frequency => text()();

  /// 0=Sun..6=Sat. Required when frequency='weekly'.
  IntColumn get dayOfWeek => integer().named('day_of_week').nullable()();

  /// 1-31. Required when frequency='monthly' or 'yearly'.
  IntColumn get dayOfMonth => integer().named('day_of_month').nullable()();

  /// 1-12. Required when frequency='yearly'.
  IntColumn get monthOfYear => integer().named('month_of_year').nullable()();

  /// false = paused.
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  /// true = soft-deleted.
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();

  /// Denormalized for fast "which rules are due?" queries.
  DateTimeColumn get nextDueDate => dateTime().named('next_due_date')();

  /// Most recent generation failure for this rule, or null if the last
  /// generation pass succeeded. Cleared on the next successful pass.
  TextColumn get lastError => text().named('last_error').nullable()();

  /// When [lastError] was recorded. Null when [lastError] is null.
  DateTimeColumn get lastErrorAt =>
      dateTime().named('last_error_at').nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}
