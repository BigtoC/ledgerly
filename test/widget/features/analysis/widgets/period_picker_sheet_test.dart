// PeriodPickerSheet — the Analysis period picker (issue #73). Behaviour from
// docs/superpowers/specs/2026-11-03-analysis-period-picker-design.md, visual
// values from docs/design/analysis-redesign/Main.dc.html (pkShow markup, PK
// block in renderVals()). Acceptance criteria 2–7, 9 and 10.
//
// Past dates are fixed (2025 and earlier, with the first record on
// Jan 6, 2025); "today" cases build on DateTime.now().

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ledgerly/app/bootstrap.dart' show noProviderRetry;
import 'package:ledgerly/core/utils/date_helpers.dart';
import 'package:ledgerly/data/repositories/transaction_repository.dart'
    show DateBounds;
import 'package:ledgerly/domain/models/category.dart' show CategoryType;
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_range_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/period_picker_sheet.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

final _firstRecord = DateTime(2025, 1, 6);

/// [firstRecord] null = no transactions; [boundsLoading] keeps the date
/// bounds loading for the whole test.
@Dependencies([ChartsSelectionController])
ProviderContainer _container({
  required PeriodType period,
  required DateTime anchor,
  DateTime? firstRecord,
  bool noRecords = false,
  bool boundsLoading = false,
}) {
  final first = noRecords ? null : (firstRecord ?? _firstRecord);
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: [
      chartsDateBoundsProvider.overrideWith(
        (ref) => boundsLoading
            ? const Stream<DateBounds?>.empty()
            : Stream.value(first == null ? null : (first: first, last: first)),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(chartsSelectionControllerProvider.notifier)
    ..setPeriod(period)
    ..setAnchor(anchor);
  return container;
}

@Dependencies([chartsDateBounds, ChartsSelectionController])
Future<void> _open(
  WidgetTester tester,
  ProviderContainer container, {
  double textScale = 1,
  ThemeData? theme,
  Locale? locale,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const PeriodPickerSheet(),
              ),
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    ),
  );
  // Let the date bounds load before the picker opens.
  await tester.pump();
  await tester.pump();
  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();
}

@Dependencies([ChartsSelectionController])
ChartsSelection _selection(ProviderContainer container) =>
    container.read(chartsSelectionControllerProvider);

@Dependencies([chartsDateBounds, ChartsSelectionController])
Finder _sheet() => find.byType(PeriodPickerSheet);

Finder _label(String label) => find.bySemanticsLabel(label);

Matcher _cell({bool selected = false, bool enabled = true}) => isSemantics(
  isButton: true,
  hasSelectedState: true,
  isSelected: selected,
  hasEnabledState: true,
  isEnabled: enabled,
);

/// The fill/border box inside a day cell or the pill of a month/year cell.
ShapeDecoration _decoration(WidgetTester tester, String semanticsLabel) =>
    tester
            .widget<AnimatedContainer>(
              find
                  .descendant(
                    of: _label(semanticsLabel),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .decoration!
        as ShapeDecoration;

Color? _textColor(WidgetTester tester, Finder finder) => tester
    .widget<RichText>(
      find.descendant(of: finder, matching: find.byType(RichText)).first,
    )
    .text
    .style
    ?.color;

@Dependencies([chartsDateBounds, ChartsSelectionController])
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('zh_TW');
  });

  const light = AnalysisColors.light;

  group('Day (AC 2)', () {
    testWidgets('opens on the anchor month with the anchor selected', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 10, 21),
      );
      await _open(tester, c);

      expect(find.text('Choose a day'), findsOneWidget);
      expect(find.text('Selected: Oct 21, 2025'), findsOneWidget);
      expect(find.text('October 2025'), findsOneWidget);
      expect(
        tester.getSemantics(_label('October 21, 2025')),
        _cell(selected: true),
      );
      expect(tester.getSemantics(_label('October 14, 2025')), _cell());
    });

    testWidgets('weekday header is narrow and Monday first; blanks lead', (
      tester,
    ) async {
      // Oct 1, 2025 is a Wednesday: two blank cells before it.
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 10, 21),
      );
      await _open(tester, c);

      final header = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      final xs = <double>[];
      for (final (i, letter) in header.indexed) {
        final hits = find.descendant(of: _sheet(), matching: find.text(letter));
        // T and S appear twice; take them in order.
        final index = header.take(i).where((l) => l == letter).length;
        xs.add(tester.getCenter(hits.at(index)).dx);
      }
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]));
      }
      expect(tester.getCenter(_label('October 1, 2025')).dx, closeTo(xs[2], 1));
      expect(tester.getCenter(_label('October 6, 2025')).dx, closeTo(xs[0], 1));
    });

    testWidgets('tapping a day sets the anchor, clears the slice, keeps the '
        'rest and closes', (tester) async {
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 10, 21),
      );
      c.read(chartsSelectionControllerProvider.notifier)
        ..toggleType()
        ..setDimension(ChartDimension.currency)
        ..setAccountFilter(3)
        ..toggleSlice(const SelectedSlice.currency('USD'));
      await _open(tester, c);

      await tester.tap(_label('October 14, 2025'));
      await tester.pumpAndSettle();

      final s = _selection(c);
      expect(s.anchorDate, DateTime(2025, 10, 14));
      expect(s.selectedSlice, isNull);
      expect(s.type, CategoryType.income);
      expect(s.dimension, ChartDimension.currency);
      expect(s.accountFilterId, 3);
      expect(_sheet(), findsNothing);
    });

    testWidgets('selected day: onBg fill, onFg w500 text; others plain', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 10, 21),
      );
      await _open(tester, c);

      final selected = _decoration(tester, 'October 21, 2025');
      expect(selected.color, light.onBg);
      final text = tester
          .widget<RichText>(
            find.descendant(
              of: _label('October 21, 2025'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
      expect(text.color, light.onFg);
      expect(text.fontWeight, FontWeight.w500);
      expect(text.fontSize, 14);

      final other = _decoration(tester, 'October 14, 2025');
      expect(other.color, light.onBg.withValues(alpha: 0));
      expect((other.shape as StadiumBorder).side.color.a, 0);
      expect(_textColor(tester, _label('October 14, 2025')), light.fg);
    });

    testWidgets('cell is 44 high with a 40×40 circle', (tester) async {
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 10, 21),
      );
      await _open(tester, c);

      expect(tester.getSize(_label('October 14, 2025')).height, 44);
      final circle = find.descendant(
        of: _label('October 14, 2025'),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(circle), const Size(40, 40));
    });

    testWidgets("today has a 1px fg ring when it isn't selected", (
      tester,
    ) async {
      final now = DateTime.now();
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(now.year, now.month - 1, 1),
      );
      await _open(tester, c);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      final todayLabel = _Labels.day(now);
      final ring =
          (_decoration(tester, todayLabel).shape as StadiumBorder).side;
      expect(ring.color, light.fg);
      expect(ring.width, 1);
      expect(tester.getSemantics(_label(todayLabel)), _cell());
    });

    testWidgets('picking a month in Months opens Days for that month', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 10, 21),
      );
      await _open(tester, c);

      await tester.tap(_label('Choose month, showing October 2025'));
      await tester.pumpAndSettle();
      expect(find.text('2025'), findsOneWidget);
      expect(
        tester.getSemantics(_label('October 2025')),
        _cell(selected: true),
      );

      await tester.tap(_label('March 2025'));
      await tester.pumpAndSettle();
      expect(find.text('March 2025'), findsOneWidget);
      expect(tester.getSemantics(_label('March 3, 2025')), _cell());
      // Drilling down does not apply anything.
      expect(_selection(c).anchorDate, DateTime(2025, 10, 21));
    });
  });

  group('Week (AC 3)', () {
    testWidgets('one row per Monday-start week touching the month', (
      tester,
    ) async {
      // Oct 2025 starts on a Wednesday and ends on a Friday.
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 10, 15),
      );
      await _open(tester, c);

      expect(find.text('Choose a week'), findsOneWidget);
      expect(find.text('Selected: Oct 13–Oct 19, 2025'), findsOneWidget);
      expect(find.text('October 2025'), findsOneWidget);
      expect(find.text('Wk'), findsOneWidget);
      for (final (wk, range) in [
        (40, 'Sep 29–Oct 5, 2025'),
        (41, 'Oct 6–Oct 12, 2025'),
        (42, 'Oct 13–Oct 19, 2025'),
        (43, 'Oct 20–Oct 26, 2025'),
        (44, 'Oct 27–Nov 2, 2025'),
      ]) {
        expect(
          tester.getSemantics(_label('Week $wk, $range')),
          _cell(selected: wk == 42),
          reason: 'W$wk',
        );
        expect(find.text('W$wk'), findsOneWidget);
      }
      expect(find.text('W39'), findsNothing);
      expect(find.text('W45'), findsNothing);
    });

    testWidgets('neighbouring-month days are fg3; selected row is all onFg', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 10, 15),
      );
      await _open(tester, c);

      final first = _label('Week 40, Sep 29–Oct 5, 2025');
      Color? dayColor(Finder row, String day) => _textColor(
        tester,
        find.descendant(of: row, matching: find.text(day)),
      );
      expect(dayColor(first, '29'), light.fg3);
      expect(dayColor(first, '1'), light.fg);
      expect(dayColor(first, 'W40'), light.fg3);

      final selected = _label('Week 42, Oct 13–Oct 19, 2025');
      for (final label in ['W42', '13', '19']) {
        expect(dayColor(selected, label), light.onFg, reason: label);
      }
      final fill = tester.widget<Material>(
        find.descendant(of: selected, matching: find.byType(Material)).first,
      );
      expect(fill.color, light.onBg);
      expect(tester.getSize(selected).height, 44);
    });

    testWidgets('a selected row spanning two months fades none of its days', (
      tester,
    ) async {
      // Sep 29 – Oct 5 opens on September; Oct 1–5 are outside it.
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 9, 29),
      );
      await _open(tester, c);

      final row = _label('Week 40, Sep 29–Oct 5, 2025');
      for (final day in ['29', '1', '5']) {
        expect(
          _textColor(
            tester,
            find.descendant(of: row, matching: find.text(day)),
          ),
          light.onFg,
          reason: day,
        );
      }
    });

    testWidgets('tapping a row sets the anchor to its Monday', (tester) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 10, 15),
      );
      await _open(tester, c);

      await tester.tap(_label('Week 40, Sep 29–Oct 5, 2025'));
      await tester.pumpAndSettle();

      expect(_selection(c).anchorDate, DateTime(2025, 9, 29));
      expect(_sheet(), findsNothing);
    });

    testWidgets('week numbers are ISO 8601 across year ends', (tester) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2020, 12, 28),
      );
      await _open(tester, c);
      expect(
        tester.getSemantics(_label('Week 53, Dec 28–Jan 3, 2020')),
        _cell(selected: true),
      );

      c
          .read(chartsSelectionControllerProvider.notifier)
          .setAnchor(DateTime(2025, 12, 29));
      await tester.pumpWidget(const SizedBox());
      await _open(tester, c);
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W49'), findsOneWidget);
    });

    testWidgets('the current week has a 1px fg ring', (tester) async {
      final now = DateTime.now();
      final monday = DateHelpers.startOfWeek(now);
      // Open a month before the current week's month, then browse to it.
      final c = _container(
        period: PeriodType.week,
        // The 15th's Monday is always in the same month.
        anchor: DateTime(monday.year, monday.month - 1, 15),
      );
      await _open(tester, c);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      final row = find.bySemanticsLabel(
        RegExp('^Week ${DateHelpers.isoWeekNumber(monday)}, '),
      );
      final fill = tester.widget<Material>(
        find.descendant(of: row, matching: find.byType(Material)).first,
      );
      final side = (fill.shape! as StadiumBorder).side;
      expect(side.color, light.fg);
      expect(side.width, 1);
    });
  });

  group('Month and Year (AC 4)', () {
    testWidgets('Month: a 3-column grid of the anchor year; picks a month', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.month,
        anchor: DateTime(2025, 6, 1),
      );
      await _open(tester, c);

      expect(find.text('Choose a month'), findsOneWidget);
      expect(find.text('Selected: June 2025'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(tester.getSemantics(_label('June 2025')), _cell(selected: true));
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
      // Jan, Feb, Mar share a row; Apr starts the next one.
      final jan = tester.getTopLeft(_label('January 2025'));
      expect(tester.getTopLeft(_label('March 2025')).dy, jan.dy);
      expect(tester.getTopLeft(_label('April 2025')).dy, greaterThan(jan.dy));
      expect(tester.getSize(_label('January 2025')).height, 52);

      final pill = _decoration(tester, 'June 2025');
      expect(pill.color, light.onBg);
      expect((pill.shape as StadiumBorder).side.color, light.onBg);
      expect(
        (_decoration(tester, 'May 2025').shape as StadiumBorder).side.color,
        light.line,
      );

      await tester.tap(_label('March 2025'));
      await tester.pumpAndSettle();
      expect(_selection(c).anchorDate, DateTime(2025, 3, 1));
      expect(_sheet(), findsNothing);
    });

    testWidgets('Year: lists years from L to now and picks one', (
      tester,
    ) async {
      final now = DateTime.now();
      final c = _container(
        period: PeriodType.year,
        anchor: DateTime(2024, 1, 1),
        firstRecord: DateTime(2023, 5, 2),
      );
      await _open(tester, c);

      expect(find.text('Choose a year'), findsOneWidget);
      expect(find.text('2023 – ${now.year}'), findsOneWidget);
      expect(find.byTooltip('Previous year'), findsNothing);
      expect(find.byTooltip('Next year'), findsNothing);
      expect(_label('2022'), findsNothing);
      for (var y = 2023; y <= now.year; y++) {
        expect(tester.getSemantics(_label('$y')), _cell(selected: y == 2024));
      }
      expect(_label('${now.year + 1}'), findsNothing);
      expect(
        (_decoration(tester, '${now.year}').shape as StadiumBorder).side.color,
        light.fg,
      );

      await tester.tap(_label('2023'));
      await tester.pumpAndSettle();
      expect(_selection(c).anchorDate, DateTime(2023, 1, 1));
      expect(_sheet(), findsNothing);
    });
  });

  testWidgets('drilling on Week: Months, Years, a year, a month, its weeks '
      '(AC 5)', (tester) async {
    final now = DateTime.now();
    final c = _container(
      period: PeriodType.week,
      anchor: DateTime(2025, 9, 16),
    );
    await _open(tester, c);
    expect(find.text('September 2025'), findsOneWidget);

    await tester.tap(_label('Choose month, showing September 2025'));
    await tester.pumpAndSettle();
    expect(find.text('2025'), findsOneWidget);
    expect(
      tester.getSemantics(_label('September 2025')),
      _cell(selected: true),
    );
    expect(find.byTooltip('Previous year'), findsOneWidget);

    await tester.tap(_label('Choose year, showing 2025'));
    await tester.pumpAndSettle();
    expect(find.text('2025 – ${now.year}'), findsOneWidget);
    expect(find.byTooltip('Previous year'), findsNothing);

    await tester.tap(_label('2025'));
    await tester.pumpAndSettle();
    expect(find.text('2025'), findsOneWidget);
    expect(_label('March 2025'), findsOneWidget);

    await tester.tap(_label('March 2025'));
    await tester.pumpAndSettle();
    expect(find.text('March 2025'), findsOneWidget);
    expect(_label('Week 10, Mar 3–Mar 9, 2025'), findsOneWidget);
    expect(_label('Week 14, Mar 31–Apr 6, 2025'), findsOneWidget);
    // Nothing applied yet.
    expect(_selection(c).anchorDate, DateTime(2025, 9, 15));

    await tester.tap(_label('Week 10, Mar 3–Mar 9, 2025'));
    await tester.pumpAndSettle();
    expect(_selection(c).anchorDate, DateTime(2025, 3, 3));
    expect(_sheet(), findsNothing);
  });

  group('Now and dismiss (AC 6)', () {
    testWidgets('Now applies the current period and closes', (tester) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 9, 16),
      );
      await _open(tester, c);

      final now = find.text('This week');
      expect(_textColor(tester, now), light.expText);
      await tester.tap(now);
      await tester.pumpAndSettle();

      expect(_selection(c).anchorDate, DateHelpers.startOfWeek(DateTime.now()));
      expect(_sheet(), findsNothing);
    });

    testWidgets('Now is labelled for each period', (tester) async {
      for (final (period, label) in [
        (PeriodType.day, 'Today'),
        (PeriodType.month, 'This month'),
        (PeriodType.year, 'This year'),
      ]) {
        final c = _container(period: period, anchor: DateTime(2025, 6, 2));
        await _open(tester, c);
        expect(find.text(label), findsOneWidget, reason: '$period');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('the scrim changes nothing', (tester) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 9, 16),
      );
      c
          .read(chartsSelectionControllerProvider.notifier)
          .toggleSlice(const SelectedSlice.category(7));
      final before = _selection(c);
      await _open(tester, c);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(_selection(c), same(before));
    });

    testWidgets('back changes nothing', (tester) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 9, 16),
      );
      final before = _selection(c);
      await _open(tester, c);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_sheet(), findsNothing);
      expect(_selection(c), same(before));
    });

    testWidgets('state is dropped on close: the next open starts again', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 9, 16),
      );
      await _open(tester, c);
      await tester.tap(_label('Choose month, showing September 2025'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('September 2025'), findsOneWidget);
      expect(_label('Week 38, Sep 15–Sep 21, 2025'), findsOneWidget);
    });
  });

  group('Layout', () {
    testWidgets('header: Now sits flush right; the title takes the rest', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 9, 16),
      );
      await _open(tester, c);

      final now = tester.getRect(
        find.ancestor(
          of: find.text('This week'),
          matching: find.byType(TextButton),
        ),
      );
      expect(now.right, 390 - 16);
      final title = tester.getRect(find.text('Choose a week'));
      expect(title.left, 24);
      // Title column, gap 8, then the button.
      final column = tester.getRect(
        find
            .ancestor(
              of: find.text('Choose a week'),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(now.left - column.right, 8);
    });

    testWidgets('Days: the first row starts right under the 32 header', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 10, 21),
      );
      await _open(tester, c);
      // The 16-high letter is centred in the 32 header.
      final letter = tester.getTopLeft(
        find.descendant(of: _sheet(), matching: find.text('M')),
      );
      expect(tester.getTopLeft(_label('October 1, 2025')).dy - letter.dy, 24);
      // Row gap 2.
      expect(
        tester.getTopLeft(_label('October 6, 2025')).dy -
            tester.getBottomLeft(_label('October 5, 2025')).dy,
        2,
      );
    });

    testWidgets('Weeks: the first row starts right under the 32 header', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 10, 15),
      );
      await _open(tester, c);
      final letter = tester.getTopLeft(
        find.descendant(of: _sheet(), matching: find.text('M')),
      );
      final first = _label('Week 40, Sep 29–Oct 5, 2025');
      expect(tester.getTopLeft(first).dy - letter.dy, 24);
      // Row gap 4.
      expect(
        tester.getTopLeft(_label('Week 41, Oct 6–Oct 12, 2025')).dy -
            tester.getBottomLeft(first).dy,
        4,
      );
    });
  });

  group('Bounds (AC 7)', () {
    testWidgets('› is disabled on the current month; future days are off', (
      tester,
    ) async {
      final now = DateTime.now();
      final c = _container(period: PeriodType.day, anchor: now);
      await _open(tester, c);

      expect(
        tester.getSemantics(find.byTooltip('Next month')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      if (tomorrow.month == now.month) {
        final label = _Labels.day(tomorrow);
        expect(tester.getSemantics(_label(label)), _cell(enabled: false));
        expect(_textColor(tester, _label(label)), light.off);
        await tester.tap(_label(label));
        await tester.pumpAndSettle();
        expect(_sheet(), findsOneWidget);
      }
    });

    testWidgets('Weeks: weeks after the current week and days after today '
        'are off', (tester) async {
      final now = DateTime.now();
      final today = DateHelpers.startOfDay(now);
      final monday = DateHelpers.startOfWeek(now);
      final c = _container(period: PeriodType.week, anchor: now);
      await _open(tester, c);

      final current = find.bySemanticsLabel(
        RegExp('^Week ${DateHelpers.isoWeekNumber(monday)}, '),
      );
      expect(tester.getSemantics(current), _cell(selected: true));
      final next = DateTime(monday.year, monday.month, monday.day + 7);
      if (next.month == monday.month) {
        final row = find.bySemanticsLabel(
          RegExp('^Week ${DateHelpers.isoWeekNumber(next)}, '),
        );
        expect(tester.getSemantics(row), _cell(enabled: false));
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(_sheet(), findsOneWidget);
        expect(
          _textColor(
            tester,
            find.descendant(of: row, matching: find.text('${next.day}')),
          ),
          light.off,
        );
      }
      // The selected row never fades, even for its days after today.
      expect(
        _textColor(
          tester,
          find.descendant(of: current, matching: find.text('${today.day}')),
        ),
        light.onFg,
      );
    });

    testWidgets('months after the current month are off', (tester) async {
      final now = DateTime.now();
      final c = _container(period: PeriodType.month, anchor: now);
      await _open(tester, c);

      expect(
        tester.getSemantics(find.byTooltip('Next year')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      if (now.month < 12) {
        final next = _Labels.month(DateTime(now.year, now.month + 1));
        expect(tester.getSemantics(_label(next)), _cell(enabled: false));
      }
      expect(
        (_decoration(tester, _Labels.month(now)).shape as StadiumBorder)
            .side
            .color,
        light.onBg,
      );
    });

    testWidgets('cells before L are off and ‹ stops at L', (tester) async {
      final c = _container(
        period: PeriodType.week,
        anchor: DateTime(2025, 1, 15),
      );
      await _open(tester, c);

      expect(
        tester.getSemantics(find.byTooltip('Previous month')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      // Dec 30 – Jan 5 ends after Jan 1 (L), so it stays on.
      expect(
        tester.getSemantics(_label('Week 1, Dec 30–Jan 5, 2024')),
        _cell(),
      );

      await tester.tap(_label('Choose month, showing January 2025'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.byTooltip('Previous year')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
    });

    testWidgets('Days: the days of L month before the first record stay on', (
      tester,
    ) async {
      // L is the first of the first record's month, not the record's day.
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 1, 20),
      );
      await _open(tester, c);
      expect(tester.getSemantics(_label('January 1, 2025')), _cell());
    });

    testWidgets('an anchor stepped back before the first record opens '
        'enabled and selected', (tester) async {
      final c = _container(
        period: PeriodType.day,
        anchor: DateTime(2025, 1, 1),
      );
      // ‹ has no lower bound.
      c.read(chartsSelectionControllerProvider.notifier).previousPeriod();
      await _open(tester, c);

      expect(find.text('December 2024'), findsOneWidget);
      expect(
        tester.getSemantics(_label('December 31, 2024')),
        _cell(selected: true),
      );
      expect(tester.getSemantics(_label('December 1, 2024')), _cell());
      expect(
        tester.getSemantics(find.byTooltip('Previous month')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
    });

    testWidgets('Month: an anchor before the first record extends L', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.month,
        anchor: DateTime(2025, 1, 1),
      );
      c.read(chartsSelectionControllerProvider.notifier).previousPeriod();
      await _open(tester, c);

      expect(find.text('2024'), findsOneWidget);
      expect(
        tester.getSemantics(_label('December 2024')),
        _cell(selected: true),
      );
      expect(
        tester.getSemantics(_label('November 2024')),
        _cell(enabled: false),
      );
    });
  });

  group('Footnote', () {
    testWidgets('names the first record date', (tester) async {
      final c = _container(
        period: PeriodType.month,
        anchor: DateTime(2025, 6, 1),
      );
      await _open(tester, c);
      final note = find.text('Records start Jan 6, 2025.');
      expect(note, findsOneWidget);
      expect(_textColor(tester, note), light.fg3);
    });

    testWidgets('is omitted with no transactions; L is the anchor month', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.month,
        anchor: DateTime(2025, 6, 1),
        noRecords: true,
      );
      await _open(tester, c);
      expect(find.textContaining('Records start'), findsNothing);
      expect(tester.getSemantics(_label('June 2025')), _cell(selected: true));
      expect(tester.getSemantics(_label('May 2025')), _cell(enabled: false));
    });

    testWidgets('is omitted while the bounds load; L is the anchor month', (
      tester,
    ) async {
      final c = _container(
        period: PeriodType.month,
        anchor: DateTime(2025, 6, 1),
        boundsLoading: true,
      );
      await _open(tester, c);
      expect(find.textContaining('Records start'), findsNothing);
      expect(tester.getSemantics(_label('May 2025')), _cell(enabled: false));
    });
  });

  testWidgets('zh_TW shows localized weekday, month and picker strings '
      '(AC 10)', (tester) async {
    final c = _container(
      period: PeriodType.day,
      anchor: DateTime(2025, 10, 21),
    );
    await _open(tester, c, locale: const Locale('zh', 'TW'));

    expect(find.text('選擇日期'), findsOneWidget);
    expect(find.textContaining('已選：'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('2025年10月'), findsOneWidget);
    for (final day in ['一', '二', '三', '四', '五', '六', '日']) {
      expect(
        find.descendant(of: _sheet(), matching: find.text(day)),
        findsOneWidget,
        reason: day,
      );
    }
    expect(find.text('記錄始於 2025年1月6日。'), findsOneWidget);

    await tester.tap(_label('選擇月份，目前為 2025年10月'));
    await tester.pumpAndSettle();
    expect(find.text('6月'), findsOneWidget);
    expect(find.byTooltip('上一年'), findsOneWidget);
  });

  // Keep last: Roboto stays loaded for the rest of the file.
  group('2× text scale with Roboto (AC 9)', () {
    setUpAll(() async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      final loader = FontLoader('Roboto');
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        final bytes = File(
          '$root/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf',
        ).readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    });

    for (final (name, theme) in [('light', lightTheme), ('dark', darkTheme)]) {
      for (final (period, anchor) in [
        (PeriodType.day, DateTime(2025, 10, 21)),
        (PeriodType.week, DateTime(2025, 9, 16)),
        (PeriodType.month, DateTime(2025, 6, 1)),
        (PeriodType.year, DateTime(2025, 1, 1)),
      ]) {
        testWidgets('${period.name} in $name: no overflow, cells grow, the '
            'body scrolls', (tester) async {
          final c = _container(
            period: period,
            anchor: anchor,
            firstRecord: DateTime(2020, 3, 4),
          );
          await _open(tester, c, textScale: 2, theme: theme);
          expect(tester.takeException(), isNull);
          // No shrink-only scaling on the numbers.
          expect(
            find.descendant(of: _sheet(), matching: find.byType(FittedBox)),
            findsNothing,
          );

          // Text may wrap between words but never inside one, and the
          // cells' labels (numbers, W38, months, weekdays) stay on one line.
          final cellLabel = RegExp(r'^(W?\d{1,4}|[A-Z][a-z]{0,2}|Wk)$');
          for (final element
              in find
                  .descendant(of: _sheet(), matching: find.byType(RichText))
                  .evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            final text = paragraph.text.toPlainText();
            expect(
              paragraph.size.width + 0.01,
              greaterThanOrEqualTo(
                paragraph.getMinIntrinsicWidth(double.infinity),
              ),
              reason: '"$text" breaks inside a word',
            );
            if (cellLabel.hasMatch(text)) {
              expect(
                paragraph.getMaxIntrinsicWidth(double.infinity),
                lessThanOrEqualTo(paragraph.size.width + 0.01),
                reason: '"$text" wraps',
              );
            }
          }

          switch (period) {
            case PeriodType.day:
              final circle = find.descendant(
                of: _label('October 21, 2025'),
                matching: find.byType(AnimatedContainer),
              );
              final size = tester.getSize(circle);
              expect(size.height, greaterThanOrEqualTo(40));
              final text = find.descendant(
                of: circle,
                matching: find.text('21'),
              );
              expect(tester.getSize(text).width, lessThanOrEqualTo(size.width));
            case PeriodType.week:
              expect(
                tester.getSize(_label('Week 38, Sep 15–Sep 21, 2025')).height,
                greaterThanOrEqualTo(44),
              );
            case PeriodType.month:
            case PeriodType.year:
              final cell = period == PeriodType.month ? 'June 2025' : '2025';
              expect(
                tester.getSize(_label(cell)).height,
                greaterThanOrEqualTo(52),
              );
            case PeriodType.all:
              break;
          }

          final scrollable = find
              .descendant(of: _sheet(), matching: find.byType(Scrollable))
              .first;
          await tester.scrollUntilVisible(
            find.text('Records start Mar 4, 2020.'),
            100,
            scrollable: scrollable,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

/// Expected semantics labels, spelled the way the spec gives them.
abstract final class _Labels {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "October 21, 2026"
  static String day(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  /// "June 2026"
  static String month(DateTime d) => '${_months[d.month - 1]} ${d.year}';
}
