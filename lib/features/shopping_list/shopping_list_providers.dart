// Slice-local providers for the shopping-list feature.
//
// All providers are autoDispose (keepAlive: false) per the project rule
// for slice-local providers (CLAUDE.md → Architecture).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:async';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';
import '../../data/models/shopping_list_item.dart';

part 'shopping_list_providers.g.dart';

/// Combined preview + total-count stream.
///
/// Watches [shoppingListRepositoryProvider.watchAll()] once and maps it into a
/// record with the first 3 items (`preview`) and the full list length
/// (`totalCount`). Using a single stream avoids opening two live DB queries.
@riverpod
Stream<({List<ShoppingListItem> preview, int totalCount})> shoppingListPreview(
  Ref ref,
) {
  final repo = ref.watch(shoppingListRepositoryProvider);
  late final StreamController<
    ({List<ShoppingListItem> preview, int totalCount})
  >
  controller;
  StreamSubscription<List<ShoppingListItem>>? previewSub;
  StreamSubscription<int>? countSub;
  List<ShoppingListItem>? preview;
  int? totalCount;

  void emitIfReady() {
    if (controller.isClosed || preview == null || totalCount == null) return;
    controller.add((preview: preview!, totalCount: totalCount!));
  }

  controller =
      StreamController<
        ({List<ShoppingListItem> preview, int totalCount})
      >.broadcast(
        onListen: () {
          previewSub = repo.watchAll(limit: 3).listen((items) {
            preview = items;
            emitIfReady();
          });
          countSub = repo.watchCount().listen((count) {
            totalCount = count;
            emitIfReady();
          });
        },
        onCancel: () async {
          await previewSub?.cancel();
          await countSub?.cancel();
          previewSub = null;
          countSub = null;
        },
      );

  ref.onDispose(() async {
    await previewSub?.cancel();
    await countSub?.cancel();
    await controller.close();
  });

  return controller.stream;
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
