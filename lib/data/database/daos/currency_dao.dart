import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/currencies_table.dart';

part 'currency_dao.g.dart';

/// Thin SQL wrapper for `currencies`.
///
/// Business rules (archive, rename, seed, locale-to-currency default)
/// live in `CurrencyRepository` (M3). This DAO returns Drift rows only.
@DriftAccessor(tables: [Currencies])
class CurrencyDao extends DatabaseAccessor<AppDatabase>
    with _$CurrencyDaoMixin {
  CurrencyDao(super.db);

  /// Watch all currencies. Ordered by `sort_order` (NULLs last), then
  /// `code` ascending — the shape expected by currency pickers.
  Stream<List<Currency>> watchAll() {
    return (select(currencies)
          ..orderBy([
            (c) => OrderingTerm(
                  expression: c.sortOrder,
                  mode: OrderingMode.asc,
                  nulls: NullsOrder.last,
                ),
            (c) => OrderingTerm(expression: c.code),
          ]))
        .watch();
  }

  /// One-shot read by primary key.
  Future<Currency?> findByCode(String code) {
    return (select(currencies)..where((c) => c.code.equals(code)))
        .getSingleOrNull();
  }

  /// Bulk upsert used by the M3 seed. Inserts with
  /// `InsertMode.insertOrIgnore` so re-seed passes do not duplicate.
  /// Returns the number of rows processed.
  Future<int> upsertAll(List<CurrenciesCompanion> rows) async {
    await batch((b) {
      b.insertAll(currencies, rows, mode: InsertMode.insertOrIgnore);
    });
    return rows.length;
  }

  /// Single insert. Returns the rowid (unused — PK is `code`). Rethrows
  /// any FK/UNIQUE constraint errors.
  Future<int> insert(CurrenciesCompanion row) {
    return into(currencies).insert(row);
  }

  /// Replace row by PK. Returns true on success.
  Future<bool> updateRow(CurrenciesCompanion row) {
    return update(currencies).replace(row);
  }
}
