import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/default_currency_provider.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/category_slice.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/time_bucket_slice.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/data/services/exchange_rate_service.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_section.dart';
import 'package:ledgerly/features/analysis/search/analysis_providers.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../../../unit/repositories/_harness/test_app_database.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

class _MockExchangeRateService extends Mock implements ExchangeRateService {}

const _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(CategoryType.expense);
    registerFallbackValue(TimeBucketGranularity.day);
  });

  testWidgets('renders pie + legend with single category slice', (
    tester,
  ) async {
    final repo = _MockTxRepo();
    when(
      () => repo.watchByCategoryInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<CategorySlice>[
        const CategorySlice(
          categoryId: 1,
          currencyCode: 'USD',
          totalMinorUnits: 5000,
        ),
      ]),
    );
    when(
      () => repo.watchTimeBucketsInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        type: any(named: 'type'),
        granularity: any(named: 'granularity'),
      ),
    ).thenAnswer(
      (_) => Stream.value(<TimeBucketSlice>[
        TimeBucketSlice(
          bucketStart: DateTime(2026, 5, 18),
          currencyCode: 'USD',
          totalMinorUnits: 5000,
        ),
      ]),
    );

    final fxService = _MockExchangeRateService();
    when(() => fxService.fetchRates(any())).thenAnswer((_) async => []);
    final fxDb = newTestAppDatabase();
    final fxRepo = ExchangeRateRepository(
      fxDb,
      fxService,
      const Stream<String>.empty(),
    );
    addTearDown(() async {
      fxRepo.dispose();
      await fxDb.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repo),
          exchangeRateRepositoryProvider.overrideWithValue(fxRepo),
          analysisCategoriesByIdProvider.overrideWith(
            (ref) => Stream.value({
              1: const Category(
                id: 1,
                type: CategoryType.expense,
                l10nKey: 'cat.test',
                customName: 'Food',
                icon: 'restaurant',
                color: 0,
              ),
            }),
          ),
          analysisAccountsByIdProvider.overrideWith(
            (ref) => Stream.value(const <int, Account>{}),
          ),
          chartsCurrenciesByCodeProvider.overrideWith(
            (ref) => Stream.value({'USD': _usd}),
          ),
          chartsFxStatusProvider.overrideWith(
            (ref) => Stream.value(
              const ChartsFxStatus(defaultCurrencyCode: 'USD', rates: {}),
            ),
          ),
          initialDefaultCurrencyProvider.overrideWithValue('USD'),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: ChartsSection())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsWidgets);
  });
}
