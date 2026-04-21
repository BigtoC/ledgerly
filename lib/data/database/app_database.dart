import 'package:drift/drift.dart';

import 'daos/account_dao.dart';
import 'daos/account_type_dao.dart';
import 'daos/category_dao.dart';
import 'daos/currency_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/user_preferences_dao.dart';
import 'tables/account_types_table.dart';
import 'tables/accounts_table.dart';
import 'tables/categories_table.dart';
import 'tables/currencies_table.dart';
import 'tables/transactions_table.dart';
import 'tables/user_preferences_table.dart';

part 'app_database.g.dart';

/// Root Drift database for Ledgerly.
///
/// Constructor takes a `QueryExecutor` so tests can inject
/// `NativeDatabase.memory()` and M4 bootstrap injects
/// `drift_flutter`'s `driftDatabase(name: 'ledgerly')`. Stream A
/// deliberately does **not** wire the production executor — that is
/// the M4 bootstrap's job.
///
/// `schemaVersion` stays at `1` until any schema change ships after
/// the first tagged release. `account_types` lands in v1 — this is
/// not a v1→v2 migration.
///
/// `beforeOpen` enables `PRAGMA foreign_keys = ON` so the
/// `.references(...)` constraints emitted by the MVP tables actually
/// fire at the SQLite engine level. SQLite defaults FKs off
/// per-connection; without this pragma, M3 repository tests for FK
/// integrity would silently pass.
@DriftDatabase(
  tables: [
    Currencies,
    Transactions,
    Categories,
    AccountTypes,
    Accounts,
    UserPreferences,
  ],
  daos: [
    CurrencyDao,
    TransactionDao,
    CategoryDao,
    AccountTypeDao,
    AccountDao,
    UserPreferencesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // MVP ships at v1; no upgrade steps exist. Phase 2 adds
      // v1→v2 here (pending_transactions, wallet_addresses,
      // exchange_rates, + token rows). Do NOT add v2 shapes in MVP.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
