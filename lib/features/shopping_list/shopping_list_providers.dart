// Slice-local providers for the shopping-list feature.
//
// All providers are autoDispose (keepAlive: false) per the project rule
// for slice-local providers (CLAUDE.md → Architecture).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';

part 'shopping_list_providers.g.dart';

/// Reactive total count of all shopping-list drafts.
///
/// Used by the Home screen mini-FAB badge. Returns 0 on error/loading so
/// the badge never breaks the Home screen layout.
@Riverpod(dependencies: [shoppingListRepository])
Stream<int> shoppingListTotalCount(Ref ref) =>
    ref.watch(shoppingListRepositoryProvider).watchCount();

/// One-shot read for archived-safe category name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
@Riverpod(dependencies: [categoryRepository])
Future<Category?> shoppingListCategoryById(Ref ref, int id) {
  return ref.watch(categoryRepositoryProvider).getById(id);
}

/// One-shot read for archived-safe account name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
@Riverpod(dependencies: [accountRepository])
Future<Account?> shoppingListAccountById(Ref ref, int id) {
  return ref.watch(accountRepositoryProvider).getById(id);
}

/// One-shot currency lookup by code — used by preview rows to format amounts.
///
/// Returns null when the code is not registered (should not happen in practice
/// since amounts always reference a seeded currency).
@Riverpod(dependencies: [currencyRepository])
Future<Currency?> shoppingListCurrencyByCode(Ref ref, String code) {
  return ref.watch(currencyRepositoryProvider).getByCode(code);
}
