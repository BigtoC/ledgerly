// Guards the provider wiring between `defaultCurrencyProvider` and the
// exchange-rate repository. Riverpod 3 removed `StreamProvider.stream`, so
// `exchangeRateRepositoryProvider` bridges default-currency values into the
// repository's `Stream<String>` itself; every value must still trigger a
// rate refresh.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/app_database_provider.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';

import '../../support/test_app.dart';

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

@Dependencies([exchangeRateRepository])
void main() {
  test('each default-currency value triggers a rate refresh', () async {
    final db = newTestAppDatabase();
    addTearDown(db.close);
    await runTestSeed(db);
    await createTestAccount(
      db,
      name: 'Euro cash',
      currencyCode: 'EUR',
      accountTypeId: await getAccountTypeId(db, 'accountType.cash'),
    );

    final service = _MockExchangeRateService();
    when(() => service.fetchRates(any())).thenAnswer((_) async => const []);
    final defaults = StreamController<String>();
    addTearDown(defaults.close);

    final container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exchangeRateServiceProvider.overrideWithValue(service),
        defaultCurrencyProvider.overrideWith((_) => defaults.stream),
      ],
    );
    addTearDown(container.dispose);
    container.listen(exchangeRateRepositoryProvider, (_, _) {});

    defaults.add('USD');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(() => service.fetchRates([(from: 'EUR', to: 'USD')])).called(1);

    defaults.add('JPY');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(
      () => service.fetchRates(any(that: contains((from: 'EUR', to: 'JPY')))),
    ).called(1);
  });
}
