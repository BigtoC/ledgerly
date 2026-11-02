// chartsNetTotalProvider tests — the Analysis summary card's expense,
// income and net totals recompute for the period picked in the time
// picker and convert every currency into the default currency.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/exchange_rate_repository.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

typedef _Totals = Map<String, ({int expense, int income})>;

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

void _stubTotals(_MockTxRepo repo, _Totals totals) {
  when(
    () => repo.watchTotalsByTypeInRange(
      start: any(named: 'start'),
      end: any(named: 'end'),
      accountId: any(named: 'accountId'),
    ),
  ).thenAnswer((_) => Stream.value(totals));
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

  test(
    'exposes expense, income and their net in the default currency',
    () async {
      final repo = _MockTxRepo();
      _stubTotals(repo, {'USD': (expense: 2000, income: 750)});

      final totals = await _settle(_container(repo: repo));

      expect(totals.currency, _usd);
      expect(totals.expenseMinorUnits, 2000);
      expect(totals.incomeMinorUnits, 750);
      expect(totals.netMinorUnits, -1250);
      expect(totals.excludedCurrencyCodes, isEmpty);
    },
  );

  test('converts other currencies into the default currency', () async {
    final repo = _MockTxRepo();
    _stubTotals(repo, {
      'USD': (expense: 0, income: 1000),
      'JPY': (expense: 3000, income: 1500),
    });

    // 1 JPY = 0.0067 USD → ¥1,500 = $10.05, ¥3,000 = $20.10.
    final totals = await _settle(
      _container(repo: repo, ratesToUsd: {'JPY': 6700000}),
    );

    expect(totals.expenseMinorUnits, 2010);
    expect(totals.incomeMinorUnits, 2005);
    expect(totals.netMinorUnits, -5);
    expect(totals.excludedCurrencyCodes, isEmpty);
  });

  test(
    'leaves currencies without a rate out of all three and lists them',
    () async {
      final repo = _MockTxRepo();
      _stubTotals(repo, {
        'USD': (expense: 200, income: 700),
        'JPY': (expense: 0, income: 900),
        'EUR': (expense: 100, income: 0),
      });

      final totals = await _settle(_container(repo: repo));

      expect(totals.expenseMinorUnits, 200);
      expect(totals.incomeMinorUnits, 700);
      expect(totals.netMinorUnits, 500);
      expect(totals.excludedCurrencyCodes, ['EUR', 'JPY']);
    },
  );

  test(
    'a type is unavailable when every currency carrying it lacks a rate',
    () async {
      final repo = _MockTxRepo();
      _stubTotals(repo, {
        'USD': (expense: 400, income: 0),
        'JPY': (expense: 0, income: 900),
      });

      final totals = await _settle(_container(repo: repo));

      expect(totals.expenseMinorUnits, 400);
      expect(totals.incomeMinorUnits, isNull);
      expect(totals.netMinorUnits, -400);
      expect(totals.excludedCurrencyCodes, ['JPY']);
    },
  );

  test('has no amounts when every currency lacks a rate', () async {
    final repo = _MockTxRepo();
    _stubTotals(repo, {
      'JPY': (expense: 900, income: 0),
      'EUR': (expense: 50, income: 70),
    });

    final totals = await _settle(_container(repo: repo));

    expect(totals.expenseMinorUnits, isNull);
    expect(totals.incomeMinorUnits, isNull);
    expect(totals.netMinorUnits, isNull);
    expect(totals.excludedCurrencyCodes, ['EUR', 'JPY']);
  });

  test('a period with no transactions totals zero', () async {
    final repo = _MockTxRepo();
    _stubTotals(repo, const {});

    final totals = await _settle(_container(repo: repo));

    expect(totals.expenseMinorUnits, 0);
    expect(totals.incomeMinorUnits, 0);
    expect(totals.netMinorUnits, 0);
    expect(totals.excludedCurrencyCodes, isEmpty);
  });

  test('queries every account', () async {
    final repo = _MockTxRepo();
    _stubTotals(repo, const {});

    await _settle(_container(repo: repo));

    verify(
      () => repo.watchTotalsByTypeInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        accountId: null,
      ),
    ).called(1);
  });

  test('re-queries with the new range when the period type changes', () async {
    final repo = _MockTxRepo();
    final ranges = <({DateTime start, DateTime end})>[];
    when(
      () => repo.watchTotalsByTypeInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((invocation) {
      ranges.add((
        start: invocation.namedArguments[#start] as DateTime,
        end: invocation.namedArguments[#end] as DateTime,
      ));
      return Stream.value({'USD': (expense: 0, income: ranges.length * 100)});
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
        () => repo.watchTotalsByTypeInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((invocation) {
        final start = invocation.namedArguments[#start] as DateTime;
        final end = invocation.namedArguments[#end] as DateTime;
        ranges.add((start: start, end: end));
        // A distinct net per query so the test can tell the periods apart.
        return Stream.value({'USD': (expense: 0, income: ranges.length * 100)});
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

  test('hides the previous period totals when the new query fails', () async {
    final repo = _MockTxRepo();
    var queries = 0;
    when(
      () => repo.watchTotalsByTypeInRange(
        start: any(named: 'start'),
        end: any(named: 'end'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) {
      queries++;
      return queries == 1
          ? Stream.value({'USD': (expense: 0, income: 100)})
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
        () => repo.watchTotalsByTypeInRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) {
        queries++;
        return Stream.value({'USD': (expense: 0, income: 100)});
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
