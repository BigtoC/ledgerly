// CsvExportScreen widget tests, with a fake controller whose `build()`
// returns a fixed state and whose commands only record calls.
//
// Covers loading, empty, the ready range and buttons, the date range
// picker, exporting, the done and failed messages, and 2x text scale.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/features/settings/csv_export/csv_export_controller.dart';
import 'package:ledgerly/features/settings/csv_export/csv_export_screen.dart';
import 'package:ledgerly/features/settings/csv_export/csv_export_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

const _food = Category(
  id: 1,
  icon: 'restaurant',
  color: 0,
  type: CategoryType.expense,
  l10nKey: 'category.food',
);

class _FakeCsvExportController extends CsvExportController {
  _FakeCsvExportController(this._initial, this.calls);

  /// Null keeps the controller loading.
  final CsvExportState? _initial;
  final List<Object> calls;

  @override
  Future<CsvExportState> build() => _initial == null
      ? Completer<CsvExportState>().future
      : Future.value(_initial);

  @override
  void setRange(DateTime start, DateTime end) =>
      calls.add(('setRange', start, end));

  /// Records the localized name of a seeded category, proving the screen
  /// passes a resolver bound to its locale.
  @override
  Future<void> export(String Function(Category) categoryName) async =>
      calls.add(('export', categoryName(_food)));
}

final _full = CsvExportState.ready(
  firstDay: DateTime(2024, 1, 2),
  lastDay: DateTime(2026, 3, 4),
  rangeStart: DateTime(2024, 1, 2),
  rangeEnd: DateTime(2026, 3, 4),
);

CsvExportReady _ready({
  DateTime? rangeStart,
  CsvExportStatus status = CsvExportStatus.idle,
  int? exportedCount,
}) => (_full as CsvExportReady).copyWith(
  rangeStart: rangeStart ?? DateTime(2024, 1, 2),
  status: status,
  exportedCount: exportedCount,
);

@Dependencies([CsvExportController])
Future<List<Object>> _pump(
  WidgetTester tester,
  CsvExportState? state, {
  double textScale = 1.0,
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final calls = <Object>[];
  final container = ProviderContainer(
    overrides: [
      csvExportControllerProvider.overrideWith(
        () => _FakeCsvExportController(state, calls),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const CsvExportScreen(),
      ),
    ),
  );
  // Not pumpAndSettle: the loading and exporting spinners never settle.
  await tester.pump();
  return calls;
}

Finder _exportButton() => find.byKey(const ValueKey('csvExportButton'));

@Dependencies([CsvExportController])
void main() {
  testWidgets('CE01: loading shows a spinner', (tester) async {
    await _pump(tester, null);

    expect(find.text('Export data'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CE02: empty says so and offers no export', (tester) async {
    await _pump(tester, const CsvExportState.empty());

    expect(find.text('There are no transactions to export.'), findsOneWidget);
    expect(_exportButton(), findsNothing);
  });

  testWidgets('CE03: ready shows the full range and exports on tap', (
    tester,
  ) async {
    final calls = await _pump(tester, _full);

    expect(
      find.text(
        'Export your transactions to a CSV file. '
        'You choose where to save it.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'The file is not encrypted. Anyone who has it can read your '
        'transactions.',
      ),
      findsOneWidget,
    );
    expect(find.text('Jan 2, 2024 – Mar 4, 2026'), findsOneWidget);
    expect(find.text('Use full range'), findsNothing);

    await tester.tap(_exportButton());
    await tester.pump();

    expect(calls, [('export', 'Food')]);
  });

  testWidgets('CE04: a narrowed range offers the full range back', (
    tester,
  ) async {
    final calls = await _pump(tester, _ready(rangeStart: DateTime(2025, 5, 6)));

    expect(find.text('May 6, 2025 – Mar 4, 2026'), findsOneWidget);
    await tester.tap(find.text('Use full range'));
    await tester.pump();

    expect(calls, [('setRange', DateTime(2024, 1, 2), DateTime(2026, 3, 4))]);
  });

  testWidgets('CE05: the range tile opens a picker bounded by the data', (
    tester,
  ) async {
    // Wide enough for the picker's own header in the test font.
    await _pump(tester, _full, size: const Size(800, 1000));

    await tester.tap(find.byKey(const ValueKey('csvExportRangeTile')));
    await tester.pumpAndSettle();

    final picker = tester.widget<DateRangePickerDialog>(
      find.byType(DateRangePickerDialog),
    );
    expect(picker.firstDate, DateTime(2024, 1, 2));
    expect(picker.lastDate, DateTime(2026, 3, 4));
    expect(
      picker.initialDateRange,
      DateTimeRange(start: DateTime(2024, 1, 2), end: DateTime(2026, 3, 4)),
    );
  });

  testWidgets('CE06: exporting disables the controls', (tester) async {
    final calls = await _pump(
      tester,
      _ready(status: CsvExportStatus.exporting),
    );

    expect(tester.widget<FilledButton>(_exportButton()).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('csvExportRangeTile')));
    await tester.pump();
    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(calls, isEmpty);
  });

  testWidgets('CE07: done shows the row count', (tester) async {
    await _pump(
      tester,
      _ready(status: CsvExportStatus.done, exportedCount: 12),
    );

    expect(find.text('Exported 12 transactions'), findsOneWidget);
  });

  testWidgets('CE08: failed shows the failure message', (tester) async {
    await _pump(tester, _ready(status: CsvExportStatus.failed));

    expect(find.text("Couldn't export. Please try again."), findsOneWidget);
  });

  testWidgets('CE09: 2x text scale lays out without overflow', (tester) async {
    await _pump(
      tester,
      _ready(
        rangeStart: DateTime(2025, 5, 6),
        status: CsvExportStatus.done,
        exportedCount: 12,
      ),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Exported 12 transactions'), 200);
    expect(tester.takeException(), isNull);
    expect(_exportButton(), findsOneWidget);
  });
}
