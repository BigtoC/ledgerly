import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/period_selector.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
    ThemeData? theme,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: theme ?? lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  PeriodSelector selector({
    PeriodType period = PeriodType.week,
    bool isAtCurrent = false,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
    ValueChanged<PeriodType>? onPeriodChanged,
  }) => PeriodSelector(
    period: period,
    anchorDate: DateTime(2026, 5, 18),
    isAtCurrent: isAtCurrent,
    locale: 'en',
    onPrevious: onPrevious ?? () {},
    onNext: onNext ?? () {},
    onPeriodChanged: onPeriodChanged ?? (_) {},
  );

  Color? textColor(WidgetTester tester, Finder finder) => tester
      .widget<RichText>(
        find.descendant(of: finder, matching: find.byType(RichText)).first,
      )
      .text
      .style
      ?.color;

  BoxDecoration segmentDecoration(WidgetTester tester, String label) =>
      tester
              .widget<DecoratedBox>(
                find
                    .ancestor(
                      of: find.text(label),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .decoration
          as BoxDecoration;

  group('formatPeriodLabel', () {
    setUpAll(() => initializeDateFormatting('en'));

    test('formats each period for en', () {
      final anchor = DateTime(2026, 5, 18);
      expect(formatPeriodLabel(PeriodType.day, anchor, 'en'), 'May 18, 2026');
      expect(
        formatPeriodLabel(PeriodType.week, anchor, 'en'),
        'May 18–May 24, 2026',
      );
      expect(
        formatPeriodLabel(PeriodType.month, DateTime(2026, 5), 'en'),
        'May 2026',
      );
      expect(formatPeriodLabel(PeriodType.year, DateTime(2026), 'en'), '2026');
    });
  });

  group('period track', () {
    testWidgets('one segment per period with selected button semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, selector());

      for (final label in ['Day', 'Week', 'Month', 'Year']) {
        expect(
          tester.getSemantics(find.text(label)),
          isSemantics(
            label: label,
            isButton: true,
            hasSelectedState: true,
            isSelected: label == 'Week',
            hasTapAction: true,
          ),
        );
      }
      expect(find.byType(SegmentedButton<PeriodType>), findsNothing);
      handle.dispose();
    });

    testWidgets('tapping a segment picks that period', (tester) async {
      PeriodType? picked;
      await pump(tester, selector(onPeriodChanged: (p) => picked = p));

      await tester.tap(find.text('Day'));
      await tester.pump();
      expect(picked, PeriodType.day);

      await tester.tap(find.text('Year'));
      await tester.pump();
      expect(picked, PeriodType.year);
    });

    testWidgets('selected segment: thumb fill + shadow, fg text; '
        'unselected: transparent, fg2 text', (tester) async {
      await pump(tester, selector());
      await tester.pump(AnalysisMotion.standardDuration);
      const c = AnalysisColors.light;

      final on = segmentDecoration(tester, 'Week');
      expect(on.color, c.thumb);
      expect(on.boxShadow, c.thumbShadow);
      expect(on.borderRadius, BorderRadius.circular(22));
      expect(textColor(tester, find.text('Week')), c.fg);

      final off = segmentDecoration(tester, 'Day');
      expect(off.color, const Color(0x00000000));
      expect(off.boxShadow ?? const <BoxShadow>[], isEmpty);
      expect(textColor(tester, find.text('Day')), c.fg2);

      final label = tester.widget<Text>(find.text('Week'));
      expect(label.style?.fontSize, 14);
      expect(label.style?.fontWeight, FontWeight.w500);
      // The design sets no letter spacing; Material's 0.25 must not leak in.
      final rendered = tester
          .widget<RichText>(
            find.descendant(
              of: find.text('Week'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
      expect(rendered.letterSpacing, 0);
    });

    testWidgets('track geometry: padding 8 16 0, inset 3, gap 2, height 44', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pump(tester, selector());

      final day = tester.getRect(
        find
            .ancestor(of: find.text('Day'), matching: find.byType(DecoratedBox))
            .first,
      );
      final week = tester.getRect(
        find
            .ancestor(
              of: find.text('Week'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final year = tester.getRect(
        find
            .ancestor(
              of: find.text('Year'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final top = tester.getTopLeft(find.byType(PeriodSelector)).dy;

      expect(day.height, 44);
      expect(day.left, 16 + 3);
      expect(day.top - top, 8 + 3);
      expect(year.right, 390 - 16 - 3);
      expect(week.left - day.right, 2);
      expect(week.width, closeTo(day.width, 0.01));
    });

    testWidgets('track uses the dark tokens in the dark theme', (tester) async {
      await pump(tester, selector(), theme: darkTheme);
      await tester.pump(AnalysisMotion.standardDuration);
      const c = AnalysisColors.dark;
      expect(segmentDecoration(tester, 'Week').color, c.thumb);
      expect(textColor(tester, find.text('Day')), c.fg2);
    });
  });

  group('period navigator', () {
    testWidgets('label 18/24 w500 fg; prev/next call back', (tester) async {
      var prev = 0, next = 0;
      await pump(
        tester,
        selector(onPrevious: () => prev++, onNext: () => next++),
      );

      final label = find.text('May 18–May 24, 2026');
      expect(label, findsOneWidget);
      final style = tester.widget<Text>(label).style!;
      expect(style.fontSize, 18);
      expect(style.height! * style.fontSize!, closeTo(24, 0.001));
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, AnalysisColors.light.fg);
      expect(tester.getSize(label).height, 24);

      await tester.tap(find.byTooltip('Previous period'));
      await tester.pump();
      expect(prev, 1);

      await tester.tap(find.byTooltip('Next period'));
      await tester.pump();
      expect(next, 1);
    });

    testWidgets('chevrons are 48×48 with 24 icons in fg', (tester) async {
      await pump(tester, selector());
      for (final icon in [Icons.chevron_left, Icons.chevron_right]) {
        final button = find.ancestor(
          of: find.byIcon(icon),
          matching: find.byType(IconButton),
        );
        expect(tester.getSize(button), const Size(48, 48));
        expect(tester.getSize(find.byIcon(icon)), const Size(24, 24));
        expect(textColor(tester, find.byIcon(icon)), AnalysisColors.light.fg);
      }
    });

    testWidgets('next is disabled at the current period, drawn in off', (
      tester,
    ) async {
      var next = 0;
      await pump(tester, selector(isAtCurrent: true, onNext: () => next++));

      await tester.tap(find.byTooltip('Next period'));
      await tester.pump();
      expect(next, 0);
      expect(
        textColor(tester, find.byIcon(Icons.chevron_right)),
        AnalysisColors.light.off,
      );
      expect(
        textColor(tester, find.byIcon(Icons.chevron_left)),
        AnalysisColors.light.fg,
      );
    });

    testWidgets('caption shows only at the current period', (tester) async {
      const captions = {
        PeriodType.day: 'Today',
        PeriodType.week: 'This week',
        PeriodType.month: 'This month',
        PeriodType.year: 'This year',
      };
      for (final MapEntry(key: period, value: caption) in captions.entries) {
        await pump(tester, selector(period: period, isAtCurrent: true));
        final found = find.text(caption);
        expect(found, findsOneWidget, reason: '$period at current');
        final style = tester.widget<Text>(found).style!;
        expect(style.fontSize, 12);
        expect(style.height! * style.fontSize!, closeTo(16, 0.001));
        expect(style.color, AnalysisColors.light.fg3);
        expect(tester.getSize(found).height, 16);

        await pump(tester, selector(period: period));
        expect(find.text(caption), findsNothing, reason: '$period in past');
      }
    });

    testWidgets('caption sits 2 below the label', (tester) async {
      await pump(tester, selector(isAtCurrent: true));
      final label = tester.getRect(find.text('May 18–May 24, 2026'));
      final caption = tester.getRect(find.text('This week'));
      expect(caption.top - label.bottom, 2);
    });
  });

  testWidgets('2× text scale: segments and label grow, nothing overflows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(tester, selector(isAtCurrent: true), textScale: 2);

    expect(tester.takeException(), isNull);
    final segment = find
        .ancestor(of: find.text('Month'), matching: find.byType(DecoratedBox))
        .first;
    expect(tester.getSize(segment).height, greaterThanOrEqualTo(44));
    // The 18/24 label renders at 36/48 per line and wraps rather than clips.
    expect(
      tester.getSize(find.text('May 18–May 24, 2026')).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.getSize(find.text('This week')).height, 32);
  });
}
