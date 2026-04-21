import 'package:drift/drift.dart';

import 'currencies_table.dart';

/// Drift table for `account_types`.
///
/// See `docs/plans/m1-data-foundations/stream-a-drift-schema.md` §2.4
/// and `stream-c-field-name-contract.md` §3.4.
///
/// Replaces the legacy `accounts.type TEXT` enum (`'cash' | 'bank' |
/// 'other'`). `account_types` is a first-class table so users may add
/// custom account types; seeded rows (`accountType.cash`,
/// `accountType.investment`) are identified by `l10n_key`.
///
/// - `l10n_key` is nullable and UNIQUE — custom user rows have
///   `l10n_key = NULL` and a user-entered `custom_name`.
/// - `default_currency` is nullable and FKs to `currencies.code`. Feeds
///   the new-account default-currency chain:
///   `account_types.default_currency` →
///   `user_preferences.default_currency` → `'USD'` (resolved in the M3
///   `AccountRepository`).
/// - `icon` is a string key via `core/utils/icon_registry.dart`; `color`
///   is an index into `core/utils/color_palette.dart`.
/// - Archive-instead-of-delete when referenced by any `accounts` row;
///   enforcement lives in `AccountTypeRepository` (M3).
@DataClassName('AccountTypeRow')
class AccountTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get l10nKey =>
      text().named('l10n_key').nullable().unique()();
  TextColumn get customName =>
      text().named('custom_name').nullable()();
  TextColumn get defaultCurrency => text()
      .named('default_currency')
      .nullable()
      .references(Currencies, #code)();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  IntColumn get sortOrder => integer().named('sort_order').nullable()();
  BoolColumn get isArchived => boolean()
      .named('is_archived')
      .withDefault(const Constant(false))();
}
