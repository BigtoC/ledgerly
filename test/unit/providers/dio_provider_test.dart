// Guards the shared `dioProvider`: HTTP services get their client from it,
// and the client is closed with the container that owns it.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';

class _MockDio extends Mock implements Dio {}

@Dependencies([exchangeRateService])
void main() {
  test('exchangeRateService sends requests through dioProvider', () async {
    final dio = _MockDio();
    when(
      () => dio.get<List<dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(data: const [], requestOptions: RequestOptions()),
    );
    final container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    await container.read(exchangeRateServiceProvider).fetchRates([
      (from: 'EUR', to: 'USD'),
    ]);

    verify(
      () =>
          dio.get<List<dynamic>>(any(), queryParameters: {'tickers': 'eurusd'}),
    ).called(1);
  });

  test(
    'dioProvider closes its client when the container is disposed',
    () async {
      final container = ProviderContainer();
      final dio = container.read(dioProvider);

      container.dispose();

      await expectLater(
        dio.get<void>('http://127.0.0.1:1/'),
        throwsA(
          isA<DioException>().having(
            (e) => e.message,
            'message',
            contains('after it was closed'),
          ),
        ),
      );
    },
  );
}
