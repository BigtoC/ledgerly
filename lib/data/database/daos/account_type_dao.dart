import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/account_types_table.dart';

part 'account_type_dao.g.dart';

/// Thin SQL wrapper for `account_types`.
///
/// Business rules (cannot hard-delete seeded rows, archive-vs-delete,
/// must reassign accounts before delete) live in
/// `AccountTypeRepository` (M3). This DAO returns Drift rows only.
@DriftAccessor(tables: [AccountTypes])
class AccountTypeDao extends DatabaseAccessor<AppDatabase>
    with _$AccountTypeDaoMixin {
  AccountTypeDao(super.db);

  /// Watch every account type, **including archived rows**. Backs the
  /// settings / admin view.
  Stream<List<AccountTypeRow>> watchAll() {
    return (select(accountTypes)..orderBy([
          (t) => OrderingTerm(
            expression: t.sortOrder,
            mode: OrderingMode.asc,
            nulls: NullsOrder.last,
          ),
          (t) => OrderingTerm(expression: t.id),
        ]))
        .watch();
  }

  /// Watch non-archived account types — feeds the account-type picker
  /// in the Add/Edit Account form.
  Stream<List<AccountTypeRow>> watchActive() {
    return (select(accountTypes)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.sortOrder,
              mode: OrderingMode.asc,
              nulls: NullsOrder.last,
            ),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .watch();
  }

  Future<AccountTypeRow?> findById(int id) {
    return (select(
      accountTypes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Used by M3 seed idempotency check for `accountType.cash` /
  /// `accountType.investment`.
  Future<AccountTypeRow?> findByL10nKey(String key) {
    return (select(
      accountTypes,
    )..where((t) => t.l10nKey.equals(key))).getSingleOrNull();
  }

  Future<int> insert(AccountTypesCompanion row) {
    return into(accountTypes).insert(row);
  }

  /// Replace row by PK — used for rename, icon/color/default-currency
  /// change.
  Future<bool> updateRow(AccountTypesCompanion row) {
    return update(accountTypes).replace(row);
  }

  /// `UPDATE ... SET is_archived = 1`. Repository decides archive-vs-
  /// delete; DAO just flips the bit.
  Future<int> archive(int id) {
    return (update(accountTypes)..where((t) => t.id.equals(id))).write(
      const AccountTypesCompanion(isArchived: Value(true)),
    );
  }

  /// Hard-delete — repository restricts to unused custom rows.
  Future<int> deleteById(int id) {
    return (delete(accountTypes)..where((t) => t.id.equals(id))).go();
  }

  /// `SELECT EXISTS(SELECT 1 FROM accounts WHERE account_type_id = ?)`.
  /// Required by `accounts_account_type_idx`. Feeds the M3 archive-vs-
  /// delete decision without materializing every referencing row.
  Future<bool> hasReferencingAccounts(int id) async {
    final query = customSelect(
      'SELECT EXISTS('
      'SELECT 1 FROM accounts WHERE account_type_id = ?'
      ') AS has_ref',
      variables: [Variable<int>(id)],
    );
    final row = await query.getSingle();
    return row.read<int>('has_ref') == 1;
  }
}
