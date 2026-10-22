// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringRuleDaoMixin on DatabaseAccessor<AppDatabase> {
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $CategoriesTable get categories => attachedDatabase.categories;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $RecurringRulesTable get recurringRules => attachedDatabase.recurringRules;
  RecurringRuleDaoManager get managers => RecurringRuleDaoManager(this);
}

class RecurringRuleDaoManager {
  final _$RecurringRuleDaoMixin _db;
  RecurringRuleDaoManager(this._db);
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
}
