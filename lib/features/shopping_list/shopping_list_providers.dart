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
import '../../data/models/shopping_list_item.dart';

part 'shopping_list_providers.g.dart';

/// Preview rows: newest 3 drafts.
///
/// Watches [shoppingListRepositoryProvider.watchAll()] and emits the first 3
/// items. The full stream is still used by the card to compute overflow.
@riverpod
Stream<List<ShoppingListItem>> shoppingListPreview(Ref ref) {
  final repo = ref.watch(shoppingListRepositoryProvider);
  return repo.watchAll().map((items) => items.take(3).toList());
}

/// Full count stream — used alongside [shoppingListPreviewProvider] to
/// compute the overflow count shown in the card.
@riverpod
Stream<int> shoppingListTotalCount(Ref ref) {
  final repo = ref.watch(shoppingListRepositoryProvider);
  return repo.watchAll().map((items) => items.length);
}

/// One-shot read for archived-safe category name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
@riverpod
Future<Category?> shoppingListCategoryById(Ref ref, int id) {
  return ref.watch(categoryRepositoryProvider).getById(id);
}

/// One-shot read for archived-safe account name hydration.
///
/// Calls [getById] which returns the row even if archived, so archived names
/// still display in preview rows.
@riverpod
Future<Account?> shoppingListAccountById(Ref ref, int id) {
  return ref.watch(accountRepositoryProvider).getById(id);
}

/// One-shot currency lookup by code — used by preview rows to format amounts.
///
/// Returns null when the code is not registered (should not happen in practice
/// since amounts always reference a seeded currency).
@riverpod
Future<Currency?> shoppingListCurrencyByCode(Ref ref, String code) {
  return ref.watch(currencyRepositoryProvider).getByCode(code);
}
