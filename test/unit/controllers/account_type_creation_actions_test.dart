// AccountTypeCreationActions unit tests.
//
// `accountTypeCreationActionsProvider.create` returns a
// `CreateAccountTypeOutcome` and never throws:
//   ATC01 - ok carries the row read back after the insert
//   ATC02 - an insert error maps to failed
//   ATC03 - a missing read-back maps to failed, so the sheet never waits
//           on a save that will not finish
//
// Repository mocked via `mocktail`; no live DB.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/account_type.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/repository_exceptions.dart';
import 'package:ledgerly/ui/features/accounts/view_models/accounts_providers.dart';
import 'package:ledgerly/ui/features/accounts/view_models/accounts_state.dart';

class _MockAccountTypeRepository extends Mock
    implements AccountTypeRepository {}

const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');

const _created = AccountType(
  id: 99,
  customName: 'Crypto',
  icon: 'wallet',
  color: 10,
  defaultCurrency: _jpy,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const AccountType(id: 0, icon: 'wallet', color: 10));
  });

  late _MockAccountTypeRepository typeRepo;

  setUp(() {
    typeRepo = _MockAccountTypeRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [accountTypeRepositoryProvider.overrideWithValue(typeRepo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('ATC01: create returns ok with the row read back', () async {
    when(() => typeRepo.save(any())).thenAnswer((_) async => 99);
    when(() => typeRepo.getById(99)).thenAnswer((_) async => _created);
    final container = makeContainer();

    final outcome = await container
        .read(accountTypeCreationActionsProvider)
        .create(name: 'Crypto', defaultCurrency: _jpy);

    expect(outcome, const CreateAccountTypeOutcome.ok(_created));
    final saved =
        verify(() => typeRepo.save(captureAny())).captured.single
            as AccountType;
    expect(saved.id, 0);
    expect(saved.customName, 'Crypto');
    expect(saved.defaultCurrency, _jpy);
  });

  test('ATC02: create returns failed when the insert throws', () async {
    when(() => typeRepo.save(any()))
        .thenThrow(const CurrencyNotFoundException('JPY'));
    final container = makeContainer();

    final outcome = await container
        .read(accountTypeCreationActionsProvider)
        .create(name: 'Crypto', defaultCurrency: _jpy);

    expect(outcome, const CreateAccountTypeOutcome.failed());
  });

  test('ATC03: create returns failed when the new row is missing', () async {
    when(() => typeRepo.save(any())).thenAnswer((_) async => 99);
    when(() => typeRepo.getById(99)).thenAnswer((_) async => null);
    final container = makeContainer();

    final outcome = await container
        .read(accountTypeCreationActionsProvider)
        .create(name: 'Crypto');

    expect(outcome, const CreateAccountTypeOutcome.failed());
  });
}
