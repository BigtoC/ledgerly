import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../app/providers/default_currency_provider.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../data/repositories/account_repository.dart';
import '../../../../data/repositories/account_type_repository.dart';
import '../../../../domain/models/account.dart';
import '../../../../domain/models/account_type.dart';
import '../../../../domain/models/currency.dart';
import 'accounts_state.dart';

final accountTypeByIdProvider = StreamProvider.autoDispose
    .family<AccountType?, int>((ref, id) {
      final repo = ref.watch(accountTypeRepositoryProvider);
      return repo.watchAll(includeArchived: true).map((rows) {
        for (final row in rows) {
          if (row.id == id) return row;
        }
        return null;
      });
    }, dependencies: [accountTypeRepositoryProvider]);

@Dependencies([accountTypeRepository])
final accountTypesProvider = StreamProvider.autoDispose<List<AccountType>>((
  ref,
) {
  final repo = ref.watch(accountTypeRepositoryProvider);
  return repo.watchAll();
}, dependencies: [accountTypeRepositoryProvider]);

@Dependencies([currencyRepository])
final selectableCurrenciesProvider = StreamProvider.autoDispose<List<Currency>>(
  (ref) {
    final repo = ref.watch(currencyRepositoryProvider);
    return repo.watchAll().map(
      (rows) => rows.where((c) => !c.isToken).toList(growable: false),
    );
  },
  dependencies: [currencyRepositoryProvider],
);

/// Read-only map from currency code (uppercase) to [Currency] model.
/// Used by [AccountTile] to resolve decimals/symbol for grouped balance
/// formatting without passing a full currency list down the widget tree.
@Dependencies([currencyRepository])
final currenciesByCodeProvider =
    StreamProvider.autoDispose<Map<String, Currency>>((ref) {
      final repo = ref.watch(currencyRepositoryProvider);
      return repo.watchAll().map(
        (rows) => {for (final c in rows) c.code.toUpperCase(): c},
      );
    }, dependencies: [currencyRepositoryProvider]);

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
    .family<AccountFormSeedData, int?>(
      (ref, accountId) async {
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
      },
      dependencies: [
        accountRepositoryProvider,
        accountTypeRepositoryProvider,
        userPreferencesRepositoryProvider,
        currencyRepositoryProvider,
      ],
    );

@Dependencies([initialDefaultCurrency, defaultCurrency, exchangeRateRepository])
class AccountFormActions {
  AccountFormActions(this._accountRepository, this._ref);

  final AccountRepository _accountRepository;
  final Ref _ref;

  final _pendingCodes = <String>{};
  Timer? _debounce;
  static const _debounceWindow = Duration(seconds: 30);

  /// Saves [draft] and never throws; the form switches on the outcome.
  Future<SaveAccountOutcome> save(Account draft) async {
    try {
      final initialDefault = _ref.read(initialDefaultCurrencyProvider);
      final currentDefault =
          _ref.read(defaultCurrencyProvider).value ?? initialDefault;

      final id = await _accountRepository.save(draft);

      if (draft.currency.code != currentDefault) {
        _pendingCodes.add(draft.currency.code);
        _debounce?.cancel();
        _debounce = Timer(_debounceWindow, () {
          final repo = _ref.read(exchangeRateRepositoryProvider);
          for (final code in _pendingCodes) {
            unawaited(repo.fetchRate(code, currentDefault));
          }
          _pendingCodes.clear();
        });
      }
      return SaveAccountOutcome.ok(id);
    } on AccountCurrencyLockedException {
      return const SaveAccountOutcome.currencyLocked();
    } catch (e) {
      debugPrint('[AccountFormActions] save failed: ${e.runtimeType}');
      return const SaveAccountOutcome.failed();
    }
  }
}

@Dependencies([
  accountRepository,
  initialDefaultCurrency,
  defaultCurrency,
  exchangeRateRepository,
])
final accountFormActionsProvider = Provider<AccountFormActions>(
  (ref) {
    final actions = AccountFormActions(
      ref.read(accountRepositoryProvider),
      ref,
    );
    ref.onDispose(() => actions._debounce?.cancel());
    return actions;
  },
  // `AccountFormActions` reads the last three through the stored `ref`.
  dependencies: [
    accountRepositoryProvider,
    initialDefaultCurrencyProvider,
    defaultCurrencyProvider,
    exchangeRateRepositoryProvider,
  ],
);

class AccountTypeCreationActions {
  AccountTypeCreationActions(this._repository);

  final AccountTypeRepository _repository;

  /// Creates a custom account type and never throws; the sheet switches
  /// on the outcome.
  Future<CreateAccountTypeOutcome> create({
    required String name,
    Currency? defaultCurrency,
  }) async {
    try {
      final id = await _repository.save(
        AccountType(
          id: 0,
          customName: name,
          icon: 'wallet',
          color: 10,
          defaultCurrency: defaultCurrency,
        ),
      );
      final created = await _repository.getById(id);
      if (created == null) return const CreateAccountTypeOutcome.failed();
      return CreateAccountTypeOutcome.ok(created);
    } catch (e) {
      debugPrint(
        '[AccountTypeCreationActions] create failed: ${e.runtimeType}',
      );
      return const CreateAccountTypeOutcome.failed();
    }
  }
}

@Dependencies([accountTypeRepository])
final accountTypeCreationActionsProvider = Provider<AccountTypeCreationActions>(
  (ref) {
    return AccountTypeCreationActions(ref.read(accountTypeRepositoryProvider));
  },
  dependencies: [accountTypeRepositoryProvider],
);
