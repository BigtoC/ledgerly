import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ExchangeRateService service;

  setUp(() {
    mockDio = MockDio();
    service = ExchangeRateService(mockDio);
  });

  group('ExchangeRateService.fetchRates', () {
    test('builds correct ticker query string', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [
            {
              'rate': 0.1277,
              'from': 'HKD',
              'to': 'USD',
              'fetched_at': '2026-05-14T06:35:14.459Z',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await service.fetchRates([
        (from: 'HKD', to: 'USD'),
        (from: 'EUR', to: 'USD'),
      ]);

      verify(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: {'tickers': 'hkdusd,eurusd'},
        ),
      ).called(1);
    });

    test('normalizes from/to to uppercase', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [
            {
              'rate': 0.1277,
              'from': 'hkd',
              'to': 'usd',
              'fetched_at': '2026-05-14T06:35:14.459Z',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final results = await service.fetchRates([(from: 'HKD', to: 'USD')]);

      expect(results, hasLength(1));
      expect(results[0].from, 'HKD');
      expect(results[0].to, 'USD');
    });

    test('accepts integer JSON rates', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [
            {
              'rate': 160,
              'from': 'JPY',
              'to': 'USD',
              'fetched_at': '2026-05-14T06:35:14.459Z',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final results = await service.fetchRates([(from: 'JPY', to: 'USD')]);

      expect(results, hasLength(1));
      expect(results[0].rate, 160.0);
    });

    test('skips malformed entries', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [
            {'rate': 'not_a_number', 'from': 'HKD', 'to': 'USD'},
            {
              'rate': 0.1277,
              'from': 'HKD',
              'to': 'USD',
              'fetched_at': '2026-05-14T06:35:14.459Z',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final results = await service.fetchRates([(from: 'HKD', to: 'USD')]);

      expect(results, hasLength(1));
    });

    test('skips entries with rate <= 0', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [
            {'rate': 0.0, 'from': 'HKD', 'to': 'USD'},
            {'rate': -1.0, 'from': 'EUR', 'to': 'USD'},
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final results = await service.fetchRates([(from: 'HKD', to: 'USD')]);

      expect(results, isEmpty);
    });

    test('throws DioException on network error', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      expect(
        () => service.fetchRates([(from: 'HKD', to: 'USD')]),
        throwsA(isA<DioException>()),
      );
    });

    test('returns empty list for empty pairs', () async {
      final results = await service.fetchRates([]);
      expect(results, isEmpty);
    });

    test('skips pairs with malformed ISO codes', () async {
      when(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: const <dynamic>[],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      // 'US' (2 chars) and 'USDX' (4 chars) are both invalid — the service
      // should reject both and return an empty list without calling Dio
      // when no valid pairs remain.
      final results = await service.fetchRates([
        (from: 'US', to: 'EUR'),
        (from: 'USDX', to: 'EUR'),
      ]);
      expect(results, isEmpty);
      verifyNever(
        () => mockDio.get<List<dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    });
  });
}
