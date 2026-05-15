import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:mocktail/mocktail.dart';

import '_harness/test_app_database.dart';

class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late AppDatabase db;
  late MockExchangeRateService mockService;
  late StreamController<String> defaultCurrencyController;
  late ExchangeRateRepository repo;

  /// Seed an account-type row, account row, and return account id.
  Future<int> seedAccount(String currency) async {
    final typeId = await db
        .into(db.accountTypes)
        .insert(
          AccountTypesCompanion.insert(
            icon: 'wallet',
            color: 0,
            l10nKey: Value('accountType.cash.$currency'),
            sortOrder: const Value(1),
          ),
        );
    return db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: 'Cash $currency',
            accountTypeId: typeId,
            currency: currency,
            openingBalanceMinorUnits: const Value(0),
          ),
        );
  }

  setUp(() async {
    db = newTestAppDatabase();
    mockService = MockExchangeRateService();
    defaultCurrencyController = StreamController<String>.broadcast();

    await db
        .into(db.currencies)
        .insert(
          CurrenciesCompanion.insert(
            code: 'USD',
            decimals: 2,
            symbol: const Value(r'$'),
            nameL10nKey: const Value('currency.usd'),
            sortOrder: const Value(1),
          ),
        );
    await db
        .into(db.currencies)
        .insert(
          CurrenciesCompanion.insert(
            code: 'EUR',
            decimals: 2,
            symbol: const Value('€'),
            nameL10nKey: const Value('currency.eur'),
            sortOrder: const Value(2),
          ),
        );

    repo = ExchangeRateRepository(
      db,
      mockService,
      defaultCurrencyController.stream,
    );
  });

  tearDown(() async {
    repo.dispose();
    await defaultCurrencyController.close();
    await db.close();
  });

  group('ExchangeRateRepository', () {
    test('getRate returns 1e9 (identity) for same currency', () {
      expect(repo.getRate('USD', 'USD'), 1000000000);
    });

    test('getRate returns null for unknown pair', () {
      expect(repo.getRate('USD', 'EUR'), isNull);
    });

    test('refreshAll fetches, upserts, and builds snapshot (forward only)', () async {
      await seedAccount('EUR');

      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'USD',
            rate: 1.08,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );

      await repo.refreshAll('USD');
      // Allow the DAO watch() to emit so the snapshot updates.
      await Future<void>.delayed(Duration.zero);

      expect(repo.getRate('EUR', 'USD'), (1.08 * 1000000000).round());
      // Inverse not stored — UI never looks it up.
      expect(repo.getRate('USD', 'EUR'), isNull);
    });

    test('refreshAll rejects rate <= 0', () async {
      await seedAccount('EUR');
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'USD',
            rate: -1.0,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );
      await repo.refreshAll('USD');
      await Future<void>.delayed(Duration.zero);
      expect(repo.getRate('EUR', 'USD'), isNull);
    });

    test('refreshAll rejects rate outside plausible range', () async {
      await seedAccount('EUR');
      // Above the 1e6 ceiling.
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'USD',
            rate: 2000000.0,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );
      await repo.refreshAll('USD');
      await Future<void>.delayed(Duration.zero);
      expect(repo.getRate('EUR', 'USD'), isNull);

      // Below the 1e-6 floor.
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'USD',
            rate: 1e-9,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );
      await repo.refreshAll('USD');
      await Future<void>.delayed(Duration.zero);
      expect(repo.getRate('EUR', 'USD'), isNull);
    });

    test('defaultCurrency change triggers refreshAll', () async {
      await seedAccount('EUR');
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'USD',
            rate: 1.08,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );

      defaultCurrencyController.add('USD');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        () => mockService.fetchRates(any()),
      ).called(greaterThanOrEqualTo(1));
    });

    test('single-flight: concurrent refreshAll calls coalesce to one fetch', () async {
      await seedAccount('EUR');
      final completer =
          Completer<
            List<({String from, String to, double rate, DateTime fetchedAt})>
          >();
      when(
        () => mockService.fetchRates(any()),
      ).thenAnswer((_) => completer.future);

      // Fire three refreshAll calls in parallel for the same default currency.
      final f1 = repo.refreshAll('USD');
      final f2 = repo.refreshAll('USD');
      final f3 = repo.refreshAll('USD');

      // Allow microtasks to run.
      await Future<void>.delayed(Duration.zero);

      completer.complete([
        (
          from: 'EUR',
          to: 'USD',
          rate: 1.08,
          fetchedAt: DateTime(2026, 5, 14),
        ),
      ]);
      await Future.wait([f1, f2, f3]);

      // The mock was only invoked once thanks to single-flight.
      verify(() => mockService.fetchRates(any())).called(1);
    });

    test('fetchRate handles service errors silently (no rethrow)', () async {
      when(
        () => mockService.fetchRates(any()),
      ).thenThrow(Exception('network error'));
      await repo.fetchRate('EUR', 'USD'); // must not throw
      expect(repo.getRate('EUR', 'USD'), isNull);
    });
  });
}
