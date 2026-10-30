// Unit tests for `CsvExportController`: date bounds → default full range →
// range edits → export, with a mocked use case.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/use_cases/csv_export_use_case.dart';
import 'package:ledgerly/features/settings/csv_export/csv_export_controller.dart';
import 'package:ledgerly/features/settings/csv_export/csv_export_state.dart';

class _MockCsvExportUseCase extends Mock implements CsvExportUseCase {}

String _name(Category c) => 'name';

@Dependencies([CsvExportController])
void main() {
  late _MockCsvExportUseCase useCase;

  setUp(() {
    useCase = _MockCsvExportUseCase();
    when(() => useCase.getDateBounds()).thenAnswer(
      (_) async =>
          (first: DateTime(2024, 1, 2, 18, 30), last: DateTime(2026, 3, 4, 9)),
    );
    when(
      () => useCase.export(
        firstDay: any(named: 'firstDay'),
        lastDay: any(named: 'lastDay'),
        categoryName: any(named: 'categoryName'),
      ),
    ).thenAnswer((_) async => 12);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [csvExportUseCaseProvider.overrideWithValue(useCase)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Keeps the controller alive and returns it once loaded.
  @Dependencies([CsvExportController])
  Future<CsvExportController> loaded(ProviderContainer container) async {
    container.listen(csvExportControllerProvider, (_, _) {});
    await container.read(csvExportControllerProvider.future);
    return container.read(csvExportControllerProvider.notifier);
  }

  @Dependencies([CsvExportController])
  CsvExportReady readyOf(ProviderContainer container) =>
      container.read(csvExportControllerProvider).value! as CsvExportReady;

  test('empty when there are no transactions', () async {
    when(() => useCase.getDateBounds()).thenAnswer((_) async => null);
    final container = makeContainer();

    await loaded(container);

    expect(
      container.read(csvExportControllerProvider).value,
      const CsvExportState.empty(),
    );
  });

  test('defaults to the full range, in whole days', () async {
    final container = makeContainer();

    await loaded(container);

    expect(
      readyOf(container),
      CsvExportState.ready(
        firstDay: DateTime(2024, 1, 2),
        lastDay: DateTime(2026, 3, 4),
        rangeStart: DateTime(2024, 1, 2),
        rangeEnd: DateTime(2026, 3, 4),
      ),
    );
  });

  test('setRange keeps whole days and clears the last result', () async {
    final container = makeContainer();
    final controller = await loaded(container);
    await controller.export(_name);

    controller.setRange(DateTime(2025, 5, 6, 13), DateTime(2025, 6, 7, 1));

    final s = readyOf(container);
    expect(s.rangeStart, DateTime(2025, 5, 6));
    expect(s.rangeEnd, DateTime(2025, 6, 7));
    expect(s.status, CsvExportStatus.idle);
    expect(s.exportedCount, isNull);
  });

  test('export passes the range and reports the row count', () async {
    final container = makeContainer();
    final controller = await loaded(container);
    controller.setRange(DateTime(2025, 5, 6), DateTime(2025, 6, 7));

    await controller.export(_name);

    verify(
      () => useCase.export(
        firstDay: DateTime(2025, 5, 6),
        lastDay: DateTime(2025, 6, 7),
        categoryName: _name,
      ),
    ).called(1);
    expect(readyOf(container).status, CsvExportStatus.done);
    expect(readyOf(container).exportedCount, 12);
  });

  test('is exporting while the save dialog is open; ignores repeats', () async {
    final pending = Completer<int?>();
    when(
      () => useCase.export(
        firstDay: any(named: 'firstDay'),
        lastDay: any(named: 'lastDay'),
        categoryName: any(named: 'categoryName'),
      ),
    ).thenAnswer((_) => pending.future);
    final container = makeContainer();
    final controller = await loaded(container);

    final first = controller.export(_name);
    expect(readyOf(container).status, CsvExportStatus.exporting);
    controller.setRange(DateTime(2025, 5, 6), DateTime(2025, 6, 7));
    await controller.export(_name);
    pending.complete(3);
    await first;

    verify(
      () => useCase.export(
        firstDay: DateTime(2024, 1, 2),
        lastDay: DateTime(2026, 3, 4),
        categoryName: any(named: 'categoryName'),
      ),
    ).called(1);
    expect(readyOf(container).exportedCount, 3);
  });

  test('a cancelled save returns to idle', () async {
    when(
      () => useCase.export(
        firstDay: any(named: 'firstDay'),
        lastDay: any(named: 'lastDay'),
        categoryName: any(named: 'categoryName'),
      ),
    ).thenAnswer((_) async => null);
    final container = makeContainer();
    final controller = await loaded(container);

    await controller.export(_name);

    expect(readyOf(container).status, CsvExportStatus.idle);
    expect(readyOf(container).exportedCount, isNull);
  });

  test('an empty range reports noTransactions', () async {
    when(
      () => useCase.export(
        firstDay: any(named: 'firstDay'),
        lastDay: any(named: 'lastDay'),
        categoryName: any(named: 'categoryName'),
      ),
    ).thenAnswer((_) async => 0);
    final container = makeContainer();
    final controller = await loaded(container);

    await controller.export(_name);

    expect(readyOf(container).status, CsvExportStatus.noTransactions);
    expect(readyOf(container).exportedCount, isNull);
  });

  test('a failed export reports failed', () async {
    when(
      () => useCase.export(
        firstDay: any(named: 'firstDay'),
        lastDay: any(named: 'lastDay'),
        categoryName: any(named: 'categoryName'),
      ),
    ).thenThrow(Exception('disk full'));
    final container = makeContainer();
    final controller = await loaded(container);

    await controller.export(_name);

    expect(readyOf(container).status, CsvExportStatus.failed);
  });
}
