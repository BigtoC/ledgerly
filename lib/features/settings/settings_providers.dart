import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/currency.dart';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

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
