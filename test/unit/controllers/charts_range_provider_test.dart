// chartsRangeProvider — the one place that resolves the selected period's
// `[start, end)` range. Day / Week / Month / Year snap the anchor; All runs
// from the first day of the earliest transaction's month to the start of
// next month (spec § All time, plan D13).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_range_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

class _MockTxRepo extends Mock implements TransactionRepository {}

@Dependencies([ChartsSelectionController, chartsRange])
void main() {
  late _MockTxRepo repo;
  late StreamController<DateBounds?> bounds;
  late ProviderContainer container;

  setUp(() {
    repo = _MockTxRepo();
    bounds = StreamController<DateBounds?>.broadcast();
    when(() => repo.watchDateBounds()).thenAnswer((_) => bounds.stream);
    container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
    );
    container.listen(chartsRangeProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await bounds.close();
  });

  @Dependencies([ChartsSelectionController])
  ChartsSelectionController selection() =>
      container.read(chartsSelectionControllerProvider.notifier);
  @Dependencies([chartsRange])
  AsyncValue<ChartsRange> range() => container.read(chartsRangeProvider);

  final now = DateTime.now();
  final nextMonth = DateTime(now.year, now.month + 1);

  group('Day / Week / Month / Year snap the anchor', () {
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));

    test('day: [anchor day, next day); the default week anchor is Monday', () {
      selection().setPeriod(PeriodType.day);
      expect(range().value, (
        start: monday,
        end: DateTime(monday.year, monday.month, monday.day + 1),
      ));
    });

    test('week: [Monday, next Monday)', () {
      expect(range().value, (
        start: monday,
        end: DateTime(monday.year, monday.month, monday.day + 7),
      ));
    });

    test('month: [first of the month, first of next month)', () {
      selection().setPeriod(PeriodType.month);
      expect(range().value, (
        start: DateTime(now.year, now.month),
        end: nextMonth,
      ));
    });

    test('year: [Jan 1, next Jan 1)', () {
      selection().setPeriod(PeriodType.year);
      expect(range().value, (
        start: DateTime(now.year),
        end: DateTime(now.year + 1),
      ));
    });

    test('follows previousPeriod', () {
      selection()
        ..setPeriod(PeriodType.month)
        ..previousPeriod();
      expect(range().value, (
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month),
      ));
    });

    test('never reads the date bounds', () {
      for (final p in [
        PeriodType.day,
        PeriodType.week,
        PeriodType.month,
        PeriodType.year,
      ]) {
        selection().setPeriod(p);
        range();
      }
      verifyNever(() => repo.watchDateBounds());
    });
  });
}
