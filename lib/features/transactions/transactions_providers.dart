// Co-located Riverpod providers for the Transactions slice (Wave 2 §4.1).
//
// Mirrors the Wave 1 provider conventions:
//   - `StreamProvider.autoDispose` for read-only watchers used by the
//     form widgets (active-account list, category list per type).
//   - `FutureProvider.autoDispose.family` for the one-shot hydration
//     seed that the controller consumes once on screen entry.
//
// The picker's data source (`categoriesByTypeProvider`) is the Wave 1
// family in `features/categories/categories_controller.dart`; reuse it
// directly rather than declaring a transactions-local copy.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';

/// Non-archived accounts for the in-form account selector sheet.
@Dependencies([accountRepository])
final txActiveAccountsProvider = StreamProvider.autoDispose<List<Account>>((
  ref,
) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAll();
}, dependencies: [accountRepositoryProvider]);

/// Upper bound on memo suggestions shown under the Memo field. The query
/// cost is dominated by aggregating the category's rows, not by the
/// LIMIT, so 6/8/10 benchmark the same.
const memoSuggestionLimit = 10;

/// Recently used distinct memos for a category, newest first. Drives the
/// suggestion chips under the transaction form's Memo field. Fetches one
/// past [memoSuggestionLimit] so the chips know to offer "More".
final txMemoSuggestionsProvider = StreamProvider.autoDispose
    .family<List<String>, int>((ref, categoryId) {
      final repo = ref.watch(transactionRepositoryProvider);
      return repo.watchRecentMemosForCategory(
        categoryId,
        limit: memoSuggestionLimit + 1,
      );
    }, dependencies: [transactionRepositoryProvider]);

/// Every distinct memo used in a category, newest first. Backs the
/// "More" sheet opened from the memo suggestion chips.
final txAllMemosProvider = StreamProvider.autoDispose.family<List<String>, int>(
  (ref, categoryId) {
    final repo = ref.watch(transactionRepositoryProvider);
    return repo.watchRecentMemosForCategory(categoryId);
  },
  dependencies: [transactionRepositoryProvider],
);
