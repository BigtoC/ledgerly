// AccountFormActions unit tests.
//
// `accountFormActionsProvider.save` returns a `SaveAccountOutcome` and
// never throws. One test per variant:
//   AFA01 - ok carries the id the repository returned
//   AFA02 - AccountCurrencyLockedException maps to currencyLocked
//   AFA03 - any other error maps to failed
//
// The draft uses the default currency, so no rate fetch is scheduled.
// Repositories mocked via `mocktail`; no live DB.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/ui/features/accounts/view_models/accounts_providers.dart';
import 'package:ledgerly/ui/features/accounts/view_models/accounts_state.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

const _draft = Account(
  id: 7,
  name: 'Checking',
  accountTypeId: 1,
  currency: _usd,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_draft);
  });

  late _MockAccountRepository accountRepo;

  setUp(() {
    accountRepo = _MockAccountRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(accountRepo),
        initialDefaultCurrencyProvider.overrideWithValue('USD'),
        defaultCurrencyProvider.overrideWith(
          (ref) => const Stream<String>.empty(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('AFA01: save returns ok with the saved id', () async {
    when(() => accountRepo.save(any())).thenAnswer((_) async => 7);
    final container = makeContainer();

    final outcome = await container
        .read(accountFormActionsProvider)
        .save(_draft);

    expect(outcome, const SaveAccountOutcome.ok(7));
  });

  test(
    'AFA02: save maps AccountCurrencyLockedException to currencyLocked',
    () async {
      when(() => accountRepo.save(any()))
          .thenThrow(const AccountCurrencyLockedException(7));
      final container = makeContainer();

      final outcome = await container
          .read(accountFormActionsProvider)
          .save(_draft);

      expect(outcome, const SaveAccountOutcome.currencyLocked());
    },
  );

  test('AFA03: save returns failed on any other error', () async {
    when(() => accountRepo.save(any()))
        .thenThrow(const AccountRepositoryException('Account 7 not found'));
    final container = makeContainer();

    final outcome = await container
        .read(accountFormActionsProvider)
        .save(_draft);

    expect(outcome, const SaveAccountOutcome.failed());
  });
}
