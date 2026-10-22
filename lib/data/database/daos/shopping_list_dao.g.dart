// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_dao.dart';

// ignore_for_file: type=lint
mixin _$ShoppingListDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $ShoppingListItemsTable get shoppingListItems =>
      attachedDatabase.shoppingListItems;
  ShoppingListDaoManager get managers => ShoppingListDaoManager(this);
}

class ShoppingListDaoManager {
  final _$ShoppingListDaoMixin _db;
  ShoppingListDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db.attachedDatabase, _db.currencies);
  $$AccountTypesTableTableManager get accountTypes =>
      $$AccountTypesTableTableManager(_db.attachedDatabase, _db.accountTypes);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$ShoppingListItemsTableTableManager get shoppingListItems =>
      $$ShoppingListItemsTableTableManager(
        _db.attachedDatabase,
        _db.shoppingListItems,
      );
}
