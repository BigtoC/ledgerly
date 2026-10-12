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
}
