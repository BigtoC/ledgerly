import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';

final recurringActiveAccountsProvider =
    StreamProvider.autoDispose<List<Account>>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.watchAll();
    });
