import 'package:drift/drift.dart';

import 'daos/account_dao.dart';
import 'daos/account_type_dao.dart';
import 'daos/category_dao.dart';
import 'daos/currency_dao.dart';
import 'daos/exchange_rate_dao.dart';
import 'daos/pending_transaction_dao.dart';
import 'daos/recurring_rule_dao.dart';
import 'daos/shopping_list_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/user_preferences_dao.dart';
import 'tables/account_types_table.dart';
import 'tables/accounts_table.dart';
import 'tables/categories_table.dart';
import 'tables/currencies_table.dart';
import 'tables/exchange_rates_table.dart';
import 'tables/pending_transactions_table.dart';
import 'tables/recurring_rules_table.dart';
import 'tables/shopping_list_items_table.dart';
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
/// MVP started at schema version 1. Adding `currencies.custom_name`
/// requires a real v1 -> v2 migration so existing databases pick up the
/// new nullable column without rewriting the historical v1 snapshot.
/// v3 introduced `shopping_list_items`. v4 introduces `recurring_rules`
/// and `pending_transactions` along with the partial UNIQUE index
/// `idx_pending_recurring_unique_partial` (added imperatively because
/// Drift cannot express the partial WHERE clause declaratively).
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
    ShoppingListItems,
    RecurringRules,
    PendingTransactions,
    ExchangeRates,
  ],
  daos: [
    CurrencyDao,
    TransactionDao,
    CategoryDao,
    AccountTypeDao,
    AccountDao,
    UserPreferencesDao,
    ShoppingListDao,
    RecurringRuleDao,
    PendingTransactionDao,
    ExchangeRateDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _addRecurringPartialUniqueIndex();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(currencies, currencies.customName);
      }
      if (from < 3) {
        await m.createTable(shoppingListItems);
        await m.createIndex(shoppingListItemsAccountIdx);
        await m.createIndex(shoppingListItemsCategoryIdx);
      }
      if (from < 4) {
        // Create recurring_rules first — pending_transactions FK references it.
        await m.createTable(recurringRules);
        await m.createIndex(idxRecurringActiveDue);
        await m.createIndex(idxRecurringArchived);

        await m.createTable(pendingTransactions);
        await m.createIndex(idxPendingSource);
        await m.createIndex(idxPendingAccount);

        await _addRecurringPartialUniqueIndex();
      }
      if (from < 5) {
        await m.createTable(exchangeRates);
        await m.createIndex(idxExchangeRatesPair);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Partial UNIQUE index for recurring-source idempotency.
  /// Drift cannot express the partial WHERE clause declaratively, so we
  /// add it imperatively. Runs on both fresh installs (`onCreate`) and
  /// on v3→v4 upgrades.
  Future<void> _addRecurringPartialUniqueIndex() {
    return customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_pending_recurring_unique_partial '
      'ON pending_transactions(recurring_rule_id, date) '
      "WHERE source = 'recurring' AND recurring_rule_id IS NOT NULL",
    );
  }
}
