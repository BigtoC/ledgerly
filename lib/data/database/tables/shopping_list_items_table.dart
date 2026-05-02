import 'package:drift/drift.dart';

import 'accounts_table.dart';
import 'categories_table.dart';
import 'currencies_table.dart';

/// Drift table for `shopping_list_items`.
///
/// Stores draft transaction intents — items the user plans to turn into real
/// transactions. Each item carries a required `draft_date`, optional memo, and
/// an all-or-nothing nullable pair (`draft_amount_minor_units` /
/// `draft_currency_code`) for amount-bearing drafts.
///
/// The all-or-nothing invariant (both null or both non-null) is enforced at
/// the repository layer, not in the DDL.
///
/// `created_at` and `updated_at` are NOT NULL and populated by
/// `ShoppingListRepository`, mirroring the pattern in `TransactionRepository`.
@DataClassName('ShoppingListItemRow')
@TableIndex(name: 'shopping_list_items_account_idx', columns: {#accountId})
@TableIndex(name: 'shopping_list_items_category_idx', columns: {#categoryId})
class ShoppingListItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().named('category_id').references(Categories, #id)();
  IntColumn get accountId =>
      integer().named('account_id').references(Accounts, #id)();
  TextColumn get memo => text().nullable()();

  /// Integer minor units. Null for zero-amount drafts. If non-null,
  /// `draft_currency_code` must also be non-null (enforced at repository
  /// layer).
  IntColumn get draftAmountMinorUnits =>
      integer().named('draft_amount_minor_units').nullable()();

  /// FK → `currencies.code`. Null for zero-amount drafts. If non-null,
  /// `draft_amount_minor_units` must also be non-null (enforced at repository
  /// layer).
  TextColumn get draftCurrencyCode => text()
      .named('draft_currency_code')
      .nullable()
      .references(Currencies, #code)();

  /// The date the user plans to make the transaction. Always required so
  /// drafts round-trip the planned date.
  DateTimeColumn get draftDate => dateTime().named('draft_date')();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
}
