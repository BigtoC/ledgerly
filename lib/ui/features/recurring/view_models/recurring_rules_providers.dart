import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../domain/models/account.dart';
import '../../../../domain/models/category.dart';

@Dependencies([accountRepository])
final recurringActiveAccountsProvider =
    StreamProvider.autoDispose<List<Account>>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.watchAll();
    }, dependencies: [accountRepositoryProvider]);

/// `id → Category` lookup (active + archived) for the rules list, so a
/// rule on an archived category still shows its icon.
@Dependencies([categoryRepository])
final recurringCategoriesByIdProvider =
    StreamProvider.autoDispose<Map<int, Category>>((ref) {
      final repo = ref.watch(categoryRepositoryProvider);
      return repo
          .watchAll(includeArchived: true)
          .map((rows) => {for (final c in rows) c.id: c});
    }, dependencies: [categoryRepositoryProvider]);
