import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:mocktail/mocktail.dart';

import '../support/test_app.dart';

class MockExchangeRateService extends Mock implements ExchangeRateService {}

void main() {
  late AppDatabase db;
  late MockExchangeRateService mockService;
  late StreamController<String> defaultCurrencyController;

  /// Seed the test DB with the first-run seed PLUS an EUR account so
  /// `distinctCurrenciesAcrossAllTables` returns a non-empty set when the
  /// default currency is USD or GBP. Without this, `refreshAll` would
  /// short-circuit (pairs is empty) and no fetch would happen.
  Future<void> seedDbWithEurAccount() async {
    await runTestSeed(db);
    final cashTypeId = await getAccountTypeId(db, 'accountType.cash');
    await createTestAccount(
      db,
      name: 'EUR Cash',
      currencyCode: 'EUR',
      accountTypeId: cashTypeId,
    );
  }

  setUp(() async {
    db = newTestAppDatabase();
    mockService = MockExchangeRateService();
    defaultCurrencyController = StreamController<String>.broadcast();
  });

  tearDown(() async {
    await defaultCurrencyController.close();
    await db.close();
  });

  group('Currency conversion flow', () {
    test('repository snapshot updates after API fetch (forward only)', () async {
      await seedDbWithEurAccount();
      final repo = ExchangeRateRepository(
        db,
        mockService,
        defaultCurrencyController.stream,
      );
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
      // Drift's watch() emits asynchronously after the upsert commits;
      // wait until the snapshot picks it up.
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (repo.getRate('EUR', 'USD') != null) break;
      }

      expect(repo.getRate('EUR', 'USD'), (1.08 * 1000000000).round());
      // Inverse is NOT stored — UI never looks it up.
      expect(repo.getRate('USD', 'EUR'), isNull);

      repo.dispose();
    });

    test('default currency change triggers re-fetch', () async {
      await seedDbWithEurAccount();
      final repo = ExchangeRateRepository(
        db,
        mockService,
        defaultCurrencyController.stream,
      );
      when(() => mockService.fetchRates(any())).thenAnswer(
        (_) async => [
          (
            from: 'EUR',
            to: 'GBP',
            rate: 0.86,
            fetchedAt: DateTime(2026, 5, 14),
          ),
        ],
      );
      defaultCurrencyController.add('GBP');
      await Future<void>.delayed(const Duration(milliseconds: 200));

      verify(
        () => mockService.fetchRates(any()),
      ).called(greaterThanOrEqualTo(1));
      repo.dispose();
    });

    test('cached rates persist across repository instances', () async {
      await seedDbWithEurAccount();

      final repo1 = ExchangeRateRepository(
        db,
        mockService,
        defaultCurrencyController.stream,
      );
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
      await repo1.refreshAll('USD');
      // Wait until the upsert is visible to repo1 (DB committed + DAO
      // watch emitted into the snapshot).
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (repo1.getRate('EUR', 'USD') != null) break;
      }
      expect(
        repo1.getRate('EUR', 'USD'),
        (1.08 * 1000000000).round(),
        reason: 'repo1 should have the freshly-upserted rate',
      );
      repo1.dispose();

      // New instance reads the same DAO; first emission populates snapshot.
      final repo2 = ExchangeRateRepository(
        db,
        mockService,
        defaultCurrencyController.stream,
      );
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (repo2.getRate('EUR', 'USD') != null) break;
      }

      expect(repo2.getRate('EUR', 'USD'), (1.08 * 1000000000).round());
      repo2.dispose();
    });
  });
}
