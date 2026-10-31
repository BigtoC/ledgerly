// Guards `txAccountLookupProvider`, the account picker's one-shot lookup
// after "Create account". The picker reads it with `ref.read` and awaits
// the result, so the lookup must still work once the provider has been
// disposed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/features/transactions/transactions_providers.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

const _account = Account(
  id: 42,
  name: 'Wallet',
  accountTypeId: 1,
  currency: Currency(code: 'USD', decimals: 2, symbol: r'$'),
);

void main() {
  late _MockAccountRepository accountRepo;
  late ProviderContainer container;

  setUp(() {
    accountRepo = _MockAccountRepository();
    container = ProviderContainer(
      overrides: [accountRepositoryProvider.overrideWithValue(accountRepo)],
    );
    addTearDown(container.dispose);
  });

  test('looks the account up by id', () async {
    when(() => accountRepo.getById(42)).thenAnswer((_) async => _account);

    final lookup = container.read(txAccountLookupProvider);

    expect(await lookup(42), _account);
    verify(() => accountRepo.getById(42)).called(1);
  });

  test('returns null when no account has the id', () async {
    when(() => accountRepo.getById(7)).thenAnswer((_) async => null);

    expect(await container.read(txAccountLookupProvider)(7), isNull);
  });

  test('still works after the provider is disposed', () async {
    when(() => accountRepo.getById(42)).thenAnswer((_) async => _account);
    final lookup = container.read(txAccountLookupProvider);

    // Nothing listens, so the autoDispose provider is disposed here.
    await container.pump();
    expect(container.exists(txAccountLookupProvider), isFalse);

    expect(await lookup(42), _account);
  });
}
