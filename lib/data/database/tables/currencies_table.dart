import 'package:drift/drift.dart';

/// Drift table for `currencies`.
///
/// See `PRD.md` lines 259–273 (Database Schema → currencies) and
/// `docs/plans/m1-data-foundations/stream-a-drift-schema.md` §2.1.
///
/// `decimals` is the **single source of truth** for minor-unit scaling
/// (2 for USD, 0 for JPY, 18 for ETH). Never duplicated onto transaction
/// or account rows — those columns store only raw minor units, and
/// formatting joins back to `currencies.decimals` at render time.
@DataClassName('Currency')
class Currencies extends Table {
  TextColumn get code => text()();
  IntColumn get decimals => integer()();
  TextColumn get symbol => text().nullable()();
  TextColumn get nameL10nKey => text().named('name_l10n_key').nullable()();
  BoolColumn get isToken =>
      boolean().named('is_token').withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().named('sort_order').nullable()();

  @override
  Set<Column<Object>> get primaryKey => {code};
}
