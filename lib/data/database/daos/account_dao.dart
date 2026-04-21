import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/accounts_table.dart';

part 'account_dao.g.dart';

/// Thin SQL wrapper for `accounts`.
///
/// Business rules (archive-instead-of-delete, default currency
/// resolution chain) live in `AccountRepository` (M3). This DAO
/// returns Drift rows only.
@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  /// Watch every account, optionally excluding archived rows.
  Stream<List<AccountRow>> watchAll({bool includeArchived = false}) {
    final query = select(accounts);
    if (!includeArchived) {
      query.where((a) => a.isArchived.equals(false));
    }
    query.orderBy([
      (a) => OrderingTerm(
        expression: a.sortOrder,
        mode: OrderingMode.asc,
        nulls: NullsOrder.last,
      ),
      (a) => OrderingTerm(expression: a.id),
    ]);
    return query.watch();
  }

  /// Watch non-archived accounts filtered by account type.
  /// Uses `accounts_account_type_idx` for reverse lookup.
  Stream<List<AccountRow>> watchByType(int accountTypeId) {
    return (select(accounts)
          ..where(
            (a) =>
                a.accountTypeId.equals(accountTypeId) &
                a.isArchived.equals(false),
          )
          ..orderBy([
            (a) => OrderingTerm(
              expression: a.sortOrder,
              mode: OrderingMode.asc,
              nulls: NullsOrder.last,
            ),
            (a) => OrderingTerm(expression: a.id),
          ]))
        .watch();
  }

  Future<AccountRow?> findById(int id) {
    return (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();
  }

  Future<int> insert(AccountsCompanion row) {
    return into(accounts).insert(row);
  }

  Future<bool> updateRow(AccountsCompanion row) {
    return update(accounts).replace(row);
  }

  /// Hard delete. Repository decides archive vs delete.
  Future<int> deleteById(int id) {
    return (delete(accounts)..where((a) => a.id.equals(id))).go();
  }

  /// `UPDATE ... SET is_archived = 1`.
  Future<int> archiveById(int id) {
    return (update(accounts)..where((a) => a.id.equals(id))).write(
      const AccountsCompanion(isArchived: Value(true)),
    );
  }

  /// Count accounts referencing the given account-type id.
  /// Complement of `AccountTypeDao.hasReferencingAccounts` for
  /// settings/display use cases that want the actual count.
  Future<int> countByAccountType(int accountTypeId) async {
    final countExp = accounts.id.count();
    final row =
        await (selectOnly(accounts)
              ..addColumns([countExp])
              ..where(accounts.accountTypeId.equals(accountTypeId)))
            .getSingle();
    return row.read(countExp) ?? 0;
  }
}
