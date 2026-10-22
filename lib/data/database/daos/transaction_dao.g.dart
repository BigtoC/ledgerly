// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_dao.dart';

// ignore_for_file: type=lint
mixin _$TransactionDaoMixin on DatabaseAccessor<AppDatabase> {
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $CategoriesTable get categories => attachedDatabase.categories;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  TransactionDaoManager get managers => TransactionDaoManager(this);
}

class TransactionDaoManager {
  final _$TransactionDaoMixin _db;
  TransactionDaoManager(this._db);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db.attachedDatabase, _db.currencies);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$AccountTypesTableTableManager get accountTypes =>
      $$AccountTypesTableTableManager(_db.attachedDatabase, _db.accountTypes);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
