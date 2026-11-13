// Co-located Riverpod providers for the Transactions slice (Wave 2 §4.1).
//
// Mirrors the Wave 1 provider conventions:
//   - `StreamProvider.autoDispose` for read-only watchers used by the
//     form widgets (active-account list, category list per type).
//   - `FutureProvider.autoDispose.family` for the one-shot hydration
//     seed that the controller consumes once on screen entry.
//
// The picker's data source (`categoriesByTypeProvider`) is the Wave 1
// family in `categories/view_models/categories_controller.dart`; reuse it
// directly rather than declaring a transactions-local copy.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../domain/models/account.dart';

/// Non-archived accounts for the in-form account selector sheet.
@Dependencies([accountRepository])
final txActiveAccountsProvider = StreamProvider.autoDispose<List<Account>>((
  ref,
) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAll();
}, dependencies: [accountRepositoryProvider]);

/// One-shot account lookup by id. The account picker uses it after
/// "Create account" to return the account the user just saved, so the
/// picker never touches the repository itself.
///
/// A function rather than a `FutureProvider.family`: the picker calls it
/// with `ref.read` and nothing listens, so an autoDispose provider would
/// be disposed while its `.future` is still loading. The function holds
/// the app-wide repository and keeps working after this provider goes.
@Dependencies([accountRepository])
final txAccountLookupProvider =
    Provider.autoDispose<Future<Account?> Function(int id)>(
      (ref) => ref.watch(accountRepositoryProvider).getById,
      dependencies: [accountRepositoryProvider],
    );

/// Upper bound on memo suggestions shown under the Memo field. The query
/// cost is dominated by aggregating the category's rows, not by the
/// LIMIT, so 6/8/10 benchmark the same.
const memoSuggestionLimit = 10;

/// A memo suggestion and the account that the memo's most recently
/// saved transaction used. [account] is null when that account is
/// archived; picking the memo then leaves the form's account alone.
typedef MemoSuggestion = ({String memo, Account? account});

/// [TransactionRepository.watchRecentMemosForCategory] with each account
/// id resolved against the active accounts.
@Dependencies([transactionRepository])
Stream<List<MemoSuggestion>> _memoSuggestions(
  Ref ref,
  int categoryId, {
  int? limit,
}) async* {
  final active = {
    for (final a in await ref.watch(txActiveAccountsProvider.future)) a.id: a,
  };
  yield* ref
      .watch(transactionRepositoryProvider)
      .watchRecentMemosForCategory(categoryId, limit: limit)
      .map(
        (rows) => [
          for (final r in rows) (memo: r.memo, account: active[r.accountId]),
        ],
      );
}

/// Recently used distinct memos for a category, newest first. Drives the
/// suggestion chips under the transaction form's Memo field. Fetches one
/// past [memoSuggestionLimit] so the chips know to offer "More".
final txMemoSuggestionsProvider = StreamProvider.autoDispose
    .family<List<MemoSuggestion>, int>(
      (ref, categoryId) =>
          _memoSuggestions(ref, categoryId, limit: memoSuggestionLimit + 1),
      dependencies: [transactionRepositoryProvider, txActiveAccountsProvider],
    );

/// Every distinct memo used in a category, newest first. Backs the
/// "More" sheet opened from the memo suggestion chips.
final txAllMemosProvider = StreamProvider.autoDispose
    .family<List<MemoSuggestion>, int>(
      (ref, categoryId) => _memoSuggestions(ref, categoryId),
      dependencies: [transactionRepositoryProvider, txActiveAccountsProvider],
    );
