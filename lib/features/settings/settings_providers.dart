import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/currency.dart';

final settingsDefaultAccountProvider = StreamProvider.autoDispose
    .family<Account?, int>((ref, id) {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.watchById(id);
    });

final settingsActiveAccountsProvider =
    StreamProvider.autoDispose<List<Account>>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.watchAll();
    });

final settingsFiatCurrenciesProvider =
    StreamProvider.autoDispose<List<Currency>>((ref) {
      final repo = ref.watch(currencyRepositoryProvider);
      return repo.watchAll().map(
        (rows) => rows.where((c) => !c.isToken).toList(growable: false),
      );
    });
