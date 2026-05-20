// Analysis slice — co-located Riverpod providers.
//
// Lookups are sourced from `watchAll(includeArchived: true)` so search
// results referencing archived categories / accounts still resolve to
// their metadata. Generated providers (`@riverpod`) so controllers can
// declare scoped deps that satisfy the `provider_dependencies` lint.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';

part 'analysis_providers.g.dart';

/// `id → Category` lookup (active + archived) for search-result tiles.
@Riverpod(dependencies: [categoryRepository])
Stream<Map<int, Category>> analysisCategoriesById(Ref ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo
      .watchAll(includeArchived: true)
      .map((rows) => {for (final c in rows) c.id: c});
}

/// `id → Account` lookup (active + archived) for the detail screen's
/// transaction rows.
@Riverpod(dependencies: [accountRepository])
Stream<Map<int, Account>> analysisAccountsById(Ref ref) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo
      .watchAll(includeArchived: true)
      .map((rows) => {for (final a in rows) a.id: a});
}
