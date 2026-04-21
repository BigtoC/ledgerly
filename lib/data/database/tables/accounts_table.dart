import 'package:drift/drift.dart';

import 'account_types_table.dart';
import 'currencies_table.dart';

/// Drift table for `accounts`.
///
/// See `PRD.md` lines 315–334 (Database Schema → accounts) and
/// `docs/plans/m1-data-foundations/stream-a-drift-schema.md` §2.5.
///
/// - `account_type_id` replaces the old `type TEXT` enum and FKs into
///   the first-class `account_types` table. FK enforcement relies on
///   `PRAGMA foreign_keys = ON` (set in `AppDatabase`).
/// - `opening_balance_minor_units` is stored as integer minor units.
///   Scaling factor is `currencies.decimals` — never a double. See
///   `PRD.md` → Money Storage Policy and
///   `CLAUDE.md` → Data-Model Invariants.
/// - Tracked balance is **derived**, not stored. There is no
///   `current_balance` column.
@DataClassName('AccountRow')
@TableIndex(name: 'accounts_account_type_idx', columns: {#accountTypeId})
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get accountTypeId =>
      integer().named('account_type_id').references(AccountTypes, #id)();
  TextColumn get currency => text().references(Currencies, #code)();

  /// Integer minor units. Scaling factor is `currencies.decimals` —
  /// never a double. See `PRD.md` → Money Storage Policy and
  /// `CLAUDE.md` → Data-Model Invariants.
  IntColumn get openingBalanceMinorUnits => integer()
      .named('opening_balance_minor_units')
      .withDefault(const Constant(0))();
  TextColumn get icon => text().nullable()();
  IntColumn get color => integer().nullable()();
  IntColumn get sortOrder => integer().named('sort_order').nullable()();
  BoolColumn get isArchived =>
      boolean().named('is_archived').withDefault(const Constant(false))();
}
