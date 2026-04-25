import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';
import '../../data/models/account_type.dart';
import '../../data/models/currency.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/account_type_repository.dart';

final accountTypeByIdProvider = StreamProvider.autoDispose
    .family<AccountType?, int>((ref, id) {
      final repo = ref.watch(accountTypeRepositoryProvider);
      return repo.watchAll(includeArchived: true).map((rows) {
        for (final row in rows) {
          if (row.id == id) return row;
        }
        return null;
      });
    });

final accountTypesProvider = StreamProvider.autoDispose<List<AccountType>>((
  ref,
) {
  final repo = ref.watch(accountTypeRepositoryProvider);
  return repo.watchAll();
});

final selectableCurrenciesProvider = StreamProvider.autoDispose<List<Currency>>(
  (ref) {
    final repo = ref.watch(currencyRepositoryProvider);
    return repo.watchAll().map(
      (rows) => rows.where((c) => !c.isToken).toList(growable: false),
    );
  },
);

final accountByIdProvider = StreamProvider.autoDispose.family<Account?, int>((
  ref,
  id,
) {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.watchById(id);
});

class AccountFormSeedData {
  const AccountFormSeedData({
    this.account,
    this.accountType,
    this.defaultCurrency,
    this.isMissing = false,
  });

  const AccountFormSeedData.missing() : this(isMissing: true);

  final Account? account;
  final AccountType? accountType;
  final Currency? defaultCurrency;
  final bool isMissing;
}

final accountFormSeedDataProvider = FutureProvider.autoDispose
    .family<AccountFormSeedData, int?>((ref, accountId) async {
      final accountRepo = ref.read(accountRepositoryProvider);
      final typeRepo = ref.read(accountTypeRepositoryProvider);
      final prefs = ref.read(userPreferencesRepositoryProvider);
      final currencies = ref.read(currencyRepositoryProvider);

      if (accountId != null) {
        final account = await accountRepo.getById(accountId);
        if (account == null) {
          return const AccountFormSeedData.missing();
        }
        final type = await typeRepo.getById(account.accountTypeId);
        return AccountFormSeedData(account: account, accountType: type);
      }

      final code = await prefs.getDefaultCurrency();
      final defaultCurrency = await currencies.getByCode(code);
      return AccountFormSeedData(defaultCurrency: defaultCurrency);
    });

class AccountFormActions {
  AccountFormActions(this._accountRepository);

  final AccountRepository _accountRepository;

  Future<int> save(Account draft) => _accountRepository.save(draft);
}

final accountFormActionsProvider = Provider<AccountFormActions>((ref) {
  return AccountFormActions(ref.read(accountRepositoryProvider));
});

class AccountTypeCreationActions {
  AccountTypeCreationActions(this._repository);

  final AccountTypeRepository _repository;

  Future<AccountType?> create({
    required String name,
    Currency? defaultCurrency,
  }) async {
    final id = await _repository.save(
      AccountType(
        id: 0,
        customName: name,
        icon: 'wallet',
        color: 10,
        defaultCurrency: defaultCurrency,
      ),
    );
    return _repository.getById(id);
  }
}

final accountTypeCreationActionsProvider = Provider<AccountTypeCreationActions>(
  (ref) {
    return AccountTypeCreationActions(ref.read(accountTypeRepositoryProvider));
  },
);
