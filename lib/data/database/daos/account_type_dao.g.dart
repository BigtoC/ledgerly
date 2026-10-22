// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_type_dao.dart';

// ignore_for_file: type=lint
mixin _$AccountTypeDaoMixin on DatabaseAccessor<AppDatabase> {
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  AccountTypeDaoManager get managers => AccountTypeDaoManager(this);
}

class AccountTypeDaoManager {
  final _$AccountTypeDaoMixin _db;
  AccountTypeDaoManager(this._db);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db.attachedDatabase, _db.currencies);
  $$AccountTypesTableTableManager get accountTypes =>
      $$AccountTypesTableTableManager(_db.attachedDatabase, _db.accountTypes);
}
