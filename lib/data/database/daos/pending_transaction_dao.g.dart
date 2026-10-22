// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_transaction_dao.dart';

// ignore_for_file: type=lint
mixin _$PendingTransactionDaoMixin on DatabaseAccessor<AppDatabase> {
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $CategoriesTable get categories => attachedDatabase.categories;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $RecurringRulesTable get recurringRules => attachedDatabase.recurringRules;
  $PendingTransactionsTable get pendingTransactions =>
      attachedDatabase.pendingTransactions;
  PendingTransactionDaoManager get managers =>
      PendingTransactionDaoManager(this);
}

class PendingTransactionDaoManager {
  final _$PendingTransactionDaoMixin _db;
  PendingTransactionDaoManager(this._db);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db.attachedDatabase, _db.currencies);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$AccountTypesTableTableManager get accountTypes =>
      $$AccountTypesTableTableManager(_db.attachedDatabase, _db.accountTypes);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(
        _db.attachedDatabase,
        _db.recurringRules,
      );
  $$PendingTransactionsTableTableManager get pendingTransactions =>
      $$PendingTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.pendingTransactions,
      );
}
