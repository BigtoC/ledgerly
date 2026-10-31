// chartsNetTotalProvider tests — the Analysis net-total box recomputes
// for the period picked in the time picker and converts every currency
// into the default currency.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/features/analysis/charts/charts_net_total_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_providers.dart';
import 'package:ledgerly/features/analysis/charts/charts_selection_controller.dart';
import 'package:ledgerly/features/analysis/charts/charts_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _jpy = Currency(code: 'JPY', decimals: 0, symbol: '¥');
const _eur = Currency(code: 'EUR', decimals: 2, symbol: '€');

ProviderContainer _container({
  required TransactionRepository repo,
  Map<String, int> ratesToUsd = const {},
}) {
  final container = ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repo),
      chartsCurrenciesByCodeProvider.overrideWith(
        (ref) => Stream.value({'USD': _usd, 'JPY': _jpy, 'EUR': _eur}),
      ),
      chartsFxStatusProvider.overrideWith(
        (ref) => Stream.value(
          ChartsFxStatus(
            defaultCurrencyCode: 'USD',
            rates: {
              for (final e in ratesToUsd.entries)
                '${e.key}→USD': ExchangeRateMetadata(
                  rateScaledE9: e.value,
                  fetchedAt: DateTime(2026, 10, 30),
                ),
            },
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Keeps the provider alive and waits until it has a non-null value.
@Dependencies([chartsNetTotal])
Future<ChartsNetTotal> _settle(ProviderContainer container) async {
  container.listen(chartsNetTotalProvider, (_, _) {});
  for (var i = 0; i < 20; i++) {
    final value = container.read(chartsNetTotalProvider);
    if (value != null) return value;
    await Future<void>.delayed(Duration.zero);
  }
  fail('chartsNetTotalProvider never produced a value');
}

@Dependencies([ChartsSelectionController, chartsNetTotal])
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  test('sums the net of the selected period in the default currency', () async {
    final repo = _MockTxRepo();
    when(
      () => repo.watchNetByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) => Stream.value({'USD': -1250}));

    final net = await _settle(_container(repo: repo));

    expect(net.currency, _usd);
    expect(net.netMinorUnits, -1250);
    expect(net.excludedCurrencyCodes, isEmpty);
  });

  test('converts other currencies into the default currency', () async {
    final repo = _MockTxRepo();
    when(
      () => repo.watchNetByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) => Stream.value({'USD': 1000, 'JPY': 1500}));

    // 1 JPY = 0.0067 USD → ¥1,500 = $10.05 = 1005 minor units.
    final net = await _settle(
      _container(repo: repo, ratesToUsd: {'JPY': 6700000}),
    );

    expect(net.netMinorUnits, 2005);
    expect(net.excludedCurrencyCodes, isEmpty);
  });

  test('leaves out currencies without a rate and lists them', () async {
    final repo = _MockTxRepo();
    when(
      () => repo.watchNetByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) => Stream.value({'USD': 500, 'JPY': 900, 'EUR': -100}));

    final net = await _settle(_container(repo: repo));

    expect(net.netMinorUnits, 500);
    expect(net.excludedCurrencyCodes, ['EUR', 'JPY']);
  });

  test('has no net amount when every currency lacks a rate', () async {
    final repo = _MockTxRepo();
    when(
      () => repo.watchNetByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) => Stream.value({'JPY': -900}));

    final net = await _settle(_container(repo: repo));

    expect(net.netMinorUnits, isNull);
    expect(net.excludedCurrencyCodes, ['JPY']);
  });

  test('a period with no transactions nets zero', () async {
    final repo = _MockTxRepo();
    when(
      () => repo.watchNetByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) => Stream.value(const <String, int>{}));

    final net = await _settle(_container(repo: repo));

    expect(net.netMinorUnits, 0);
    expect(net.excludedCurrencyCodes, isEmpty);
  });

  test('re-queries with the new range when the period type changes', () async {
    final repo = _MockTxRepo();
    final ranges = <({DateTime start, DateTime end})>[];
    when(
      () => repo.watchNetByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((invocation) {
      ranges.add((
        start: invocation.namedArguments[#start] as DateTime,
        end: invocation.namedArguments[#end] as DateTime,
      ));
      return Stream.value({'USD': ranges.length * 100});
    });

    final container = _container(repo: repo);
    await _settle(container);
    final weekQueries = ranges.length;
    // Calendar days, not a Duration: a week that crosses a DST change is
    // 167 or 169 hours long.
    final week = ranges.last.start;
    expect(ranges.last.end, DateTime(week.year, week.month, week.day + 7));

    container
        .read(chartsSelectionControllerProvider.notifier)
        .setPeriod(PeriodType.year);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(ranges.length, weekQueries + 1);
    final year = ranges.last.start.year;
    expect(ranges.last.start, DateTime(year));
    expect(ranges.last.end, DateTime(year + 1));
    expect(
      container.read(chartsNetTotalProvider)?.netMinorUnits,
      ranges.length * 100,
    );
  });

  test(
    're-queries the repository when the time picker moves the period',
    () async {
      final repo = _MockTxRepo();
      final ranges = <({DateTime start, DateTime end})>[];
      when(
        () => repo.watchNetByCurrencyInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((invocation) {
        final start = invocation.namedArguments[#start] as DateTime;
        final end = invocation.namedArguments[#end] as DateTime;
        ranges.add((start: start, end: end));
        // A distinct net per query so the test can tell the periods apart.
        return Stream.value({'USD': ranges.length * 100});
      });

      final container = _container(repo: repo);
      final selection = container.read(
        chartsSelectionControllerProvider.notifier,
      );
      selection.setPeriod(PeriodType.month);
      await _settle(container);
      final firstQueries = ranges.length;
      final first = ranges.last;
      expect(first.start.day, 1);
      expect(first.end, DateTime(first.start.year, first.start.month + 1));

      selection.previousPeriod();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(ranges.length, firstQueries + 1);
      expect(ranges.last.end, first.start);
      expect(
        container.read(chartsNetTotalProvider)?.netMinorUnits,
        ranges.length * 100,
      );
    },
  );

  test('hides the previous period net when the new query fails', () async {
    final repo = _MockTxRepo();
    var queries = 0;
    when(
      () => repo.watchNetByCurrencyInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenAnswer((_) {
      queries++;
      return queries == 1
          ? Stream.value({'USD': 100})
          : Stream.error(StateError('query failed'));
    });

    final container = _container(repo: repo);
    await _settle(container);

    container.read(chartsSelectionControllerProvider.notifier).previousPeriod();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(queries, 2);
    expect(container.read(chartsNetTotalProvider), isNull);
  });

  test(
    'does not re-query when only the chart type or dimension changes',
    () async {
      final repo = _MockTxRepo();
      var queries = 0;
      when(
        () => repo.watchNetByCurrencyInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) {
        queries++;
        return Stream.value({'USD': 100});
      });

      final container = _container(repo: repo);
      await _settle(container);
      expect(queries, 1);

      final selection = container.read(
        chartsSelectionControllerProvider.notifier,
      );
      selection.toggleType();
      selection.setDimension(ChartDimension.account);
      await Future<void>.delayed(Duration.zero);

      expect(queries, 1);
    },
  );
}
