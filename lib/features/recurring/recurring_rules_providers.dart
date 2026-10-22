import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';

@Dependencies([accountRepository])
final recurringActiveAccountsProvider =
    StreamProvider.autoDispose<List<Account>>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.watchAll();
    }, dependencies: [accountRepositoryProvider]);
