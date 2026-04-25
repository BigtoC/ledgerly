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

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';

/// Non-archived accounts for the in-form account selector sheet.
final txActiveAccountsProvider = StreamProvider.autoDispose<List<Account>>((
  ref,
) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchAll();
});
