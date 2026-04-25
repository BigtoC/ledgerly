// Home slice — co-located Riverpod providers (Wave 3 §2 inputs).
//
// Exposes lookup maps the screen needs to render rows + summary strip
// without importing the repository surfaces directly. Keeps screen
// imports compliant with the `widgets_forbid_data_internals` import_lint
// rule (only `app/providers/...` and feature-local files are
// reachable from the screen).
//
// Lookups are sourced from `watchAll(includeArchived: true)` so
// historical rows referencing archived categories / accounts still
// resolve to their metadata (Wave 3 §2 — "archived-safe lookups").

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/currency.dart';

/// `code → Currency` for `MoneyFormatter` lookups in the summary strip.
/// Includes tokens so any historical row whose `currency` was migrated
/// to a token still resolves; MVP creates only fiat transactions.
final homeCurrenciesByCodeProvider =
    StreamProvider.autoDispose<Map<String, Currency>>((ref) {
      final repo = ref.watch(currencyRepositoryProvider);
      return repo
          .watchAll(includeTokens: true)
          .map((rows) => {for (final c in rows) c.code: c});
    });

/// `id → Category` lookup (active + archived) for transaction rows.
final homeCategoriesByIdProvider =
    StreamProvider.autoDispose<Map<int, Category>>((ref) {
      final repo = ref.watch(categoryRepositoryProvider);
      return repo
          .watchAll(includeArchived: true)
          .map((rows) => {for (final c in rows) c.id: c});
    });

/// `id → Account` lookup (active + archived) for transaction rows.
final homeAccountsByIdProvider = StreamProvider.autoDispose<Map<int, Account>>((
  ref,
) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo
      .watchAll(includeArchived: true)
      .map((rows) => {for (final a in rows) a.id: a});
});
