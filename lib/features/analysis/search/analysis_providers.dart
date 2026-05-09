// Analysis slice — co-located Riverpod providers.
//
// Lookups are sourced from `watchAll(includeArchived: true)` so search
// results referencing archived categories / accounts still resolve to
// their metadata. Mirrors `home_providers.dart` style — plain
// `StreamProvider.autoDispose`, not `@Riverpod`-annotated.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';

/// `id → Category` lookup (active + archived) for search-result tiles.
final analysisCategoriesByIdProvider =
    StreamProvider.autoDispose<Map<int, Category>>((ref) {
      final repo = ref.watch(categoryRepositoryProvider);
      return repo
          .watchAll(includeArchived: true)
          .map((rows) => {for (final c in rows) c.id: c});
    });

/// `id → Account` lookup (active + archived) for the detail screen's
/// transaction rows.
final analysisAccountsByIdProvider =
    StreamProvider.autoDispose<Map<int, Account>>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return repo
          .watchAll(includeArchived: true)
          .map((rows) => {for (final a in rows) a.id: a});
    });
