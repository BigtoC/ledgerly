import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_range_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/period_selector.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1,
    ThemeData? theme,
    Locale? locale,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: theme ?? lightTheme,
      locale: locale,
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
    ChartsRange? allTimeRange,
    String locale = 'en',
  }) => PeriodSelector(
    period: period,
    anchorDate: DateTime(2026, 5, 18),
    isAtCurrent: isAtCurrent,
    allTimeRange: allTimeRange,
    locale: locale,
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

      for (final label in ['Day', 'Week', 'Month', 'Year', 'All']) {
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

      await tester.tap(find.text('All'));
      await tester.pump();
      expect(picked, PeriodType.all);
    });

    testWidgets('pressing a segment ripples, clipped to its 22 radius', (
      tester,
    ) async {
      await pump(tester, selector());

      for (final label in ['Day', 'Week']) {
        final ink = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(ink, findsOneWidget, reason: label);
        expect(
          tester.widget<InkWell>(ink).borderRadius,
          BorderRadius.circular(22),
        );

        // The ink paints on a Material inside the segment, so the selected
        // thumb's fill does not hide it.
        final material = find
            .ancestor(of: find.text(label), matching: find.byType(Material))
            .first;
        final segment = find
            .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
            .first;
        expect(
          find.descendant(of: segment, matching: material),
          findsOneWidget,
          reason: label,
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.text(label)),
        );
        await tester.pump(const Duration(milliseconds: 200));
        final size = tester.getSize(segment);
        expect(
          tester.renderObject(material),
          paints..clipRRect(
            rrect: RRect.fromRectAndRadius(
              Offset.zero & size,
              const Radius.circular(22),
            ),
          ),
          reason: label,
        );
        await gesture.up();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('segments take keyboard focus; Enter picks the period', (
      tester,
    ) async {
      PeriodType? picked;
      await pump(tester, selector(onPeriodChanged: (p) => picked = p));

      // The segments come first in traversal order, before the chevrons.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final primary = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.ancestor(
          of: find.text('Week'),
          matching: find.byWidget(primary.widget),
        ),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked, PeriodType.week);
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
      expect(off.color, c.thumb.withValues(alpha: 0));
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

    testWidgets('a switching thumb fades in the thumb colour, never grey', (
      tester,
    ) async {
      await pump(tester, selector());
      await tester.pump(AnalysisMotion.standardDuration);
      const c = AnalysisColors.light;

      await pump(tester, selector(period: PeriodType.month));
      await tester.pump(AnalysisMotion.standardDuration ~/ 2);

      // Fading to transparent black would lerp the RGB towards grey.
      for (final label in ['Week', 'Month']) {
        final fill = segmentDecoration(tester, label).color!;
        expect(fill.a, inExclusiveRange(0, 1), reason: label);
        expect(fill.r, closeTo(c.thumb.r, 1e-6), reason: label);
        expect(fill.g, closeTo(c.thumb.g, 1e-6), reason: label);
        expect(fill.b, closeTo(c.thumb.b, 1e-6), reason: label);
      }
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
      final all = tester.getRect(
        find
            .ancestor(of: find.text('All'), matching: find.byType(DecoratedBox))
            .first,
      );
      final top = tester.getTopLeft(find.byType(PeriodSelector)).dy;

      expect(day.height, 44);
      expect(day.left, 16 + 3);
      expect(day.top - top, 8 + 3);
      expect(all.right, 390 - 16 - 3);
      expect(all.width, closeTo(day.width, 0.01));
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

    testWidgets('chevron tooltips follow the locale (zh_TW)', (tester) async {
      await pump(
        tester,
        selector(locale: 'zh-TW'),
        locale: const Locale('zh', 'TW'),
      );

      // The tooltips are the icon buttons' only screen-reader names.
      expect(find.byTooltip('上一個期間'), findsOneWidget);
      expect(find.byTooltip('下一個期間'), findsOneWidget);
      expect(find.byTooltip('Previous period'), findsNothing);
      expect(find.byTooltip('Next period'), findsNothing);
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

    group('on All', () {
      final range = (start: DateTime(2024, 3), end: DateTime(2026, 7));

      testWidgets('label "All time"; caption is the covered range, '
          '12/16 fg3', (tester) async {
        await pump(
          tester,
          selector(
            period: PeriodType.all,
            isAtCurrent: true,
            allTimeRange: range,
          ),
        );

        expect(find.text('All time'), findsOneWidget);
        // No "This …" caption: the range replaces it.
        expect(find.textContaining('This'), findsNothing);
        final caption = find.text('Mar 2024 – Jun 2026');
        expect(caption, findsOneWidget);
        final style = tester.widget<Text>(caption).style!;
        expect(style.fontSize, 12);
        expect(style.height! * style.fontSize!, closeTo(16, 0.001));
        expect(style.color, AnalysisColors.light.fg3);
      });

      testWidgets('the caption follows the locale', (tester) async {
        await pump(
          tester,
          selector(
            period: PeriodType.all,
            isAtCurrent: true,
            allTimeRange: range,
            locale: 'zh-TW',
          ),
          locale: const Locale('zh', 'TW'),
        );

        expect(find.text('全部時間'), findsOneWidget);
        expect(find.text('2024年3月 – 2026年6月'), findsOneWidget);
      });

      testWidgets('no caption without transactions (an empty range) or '
          'while the range loads', (tester) async {
        final empty = (start: DateTime(2026, 11), end: DateTime(2026, 11));
        for (final r in [empty, null]) {
          await pump(
            tester,
            selector(
              period: PeriodType.all,
              isAtCurrent: true,
              allTimeRange: r,
            ),
          );
          expect(find.text('All time'), findsOneWidget);
          final column = find.ancestor(
            of: find.text('All time'),
            matching: find.byType(Column),
          );
          expect(
            find.descendant(of: column.first, matching: find.byType(Text)),
            findsOneWidget,
            reason: '$r',
          );
        }
      });

      testWidgets('both chevrons are hidden; their 48 slots keep the label '
          'centred', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pump(
          tester,
          selector(
            period: PeriodType.all,
            isAtCurrent: true,
            allTimeRange: range,
          ),
        );

        expect(find.byType(IconButton), findsNothing);
        expect(find.byTooltip('Previous period'), findsNothing);
        expect(find.byTooltip('Next period'), findsNothing);
        final navigator = tester.getRect(find.byType(PeriodNavigator));
        final label = tester.getRect(find.text('All time'));
        expect(label.center.dx, closeTo(195, 0.01));
        // Padding 8 8 0 around a 48-high row (the label column is 42).
        expect(navigator.height, 8 + 48);
        // The label column spans the space between the two kept slots.
        final column = tester.getRect(
          find
              .ancestor(
                of: find.text('All time'),
                matching: find.byType(Column),
              )
              .first,
        );
        expect(column.left, 8 + 48 + 4);
        expect(column.right, 390 - 8 - 48 - 4);
      });
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

  testWidgets('2× text scale on All at 360 wide: five segments, label and '
      'range caption grow without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pump(
      tester,
      selector(
        period: PeriodType.all,
        isAtCurrent: true,
        allTimeRange: (start: DateTime(2024, 3), end: DateTime(2026, 7)),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    final all = find
        .ancestor(of: find.text('All'), matching: find.byType(DecoratedBox))
        .first;
    expect(tester.getSize(all).height, greaterThanOrEqualTo(44));
    expect(
      tester.getSize(find.text('All time')).height,
      greaterThanOrEqualTo(48),
    );
    final caption = tester.getRect(find.text('Mar 2024 – Jun 2026'));
    expect(caption.height, greaterThanOrEqualTo(32));
    // The caption stays between the two kept 48 slots.
    expect(caption.left, greaterThanOrEqualTo(8 + 48 + 4));
    expect(caption.right, lessThanOrEqualTo(360 - 8 - 48 - 4));
  });

  // Keep last: the loaded Roboto stays registered for the rest of the file.
  group('segment labels at phone width (Roboto)', () {
    setUpAll(() async {
      final root = Platform.environment['FLUTTER_ROOT']!;
      final loader = FontLoader('Roboto');
      for (final face in ['Regular', 'Medium']) {
        final bytes = File(
          '$root/bin/cache/artifacts/material_fonts/Roboto-$face.ttf',
        ).readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    });

    const labels = ['Day', 'Week', 'Month', 'Year', 'All'];

    Rect segmentRect(WidgetTester tester, String label) => tester.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
    );

    for (final width in [360.0, 390.0]) {
      testWidgets('2× at $width wide: each label is one line that fits its '
          'segment (plan D23)', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await pump(tester, selector(isAtCurrent: true), textScale: 2);

        expect(tester.takeException(), isNull);
        for (final label in labels) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          final lineTops = paragraph
              .getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: label.length),
              )
              .map((b) => b.top)
              .toSet();
          expect(lineTops, hasLength(1), reason: label);
          final text = tester.getRect(find.text(label));
          final segment = segmentRect(tester, label);
          expect(text.left, greaterThanOrEqualTo(segment.left), reason: label);
          expect(text.right, lessThanOrEqualTo(segment.right), reason: label);
        }
      });
    }

    testWidgets('1× at 360 wide: labels render at full size', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pump(tester, selector(isAtCurrent: true));

      for (final label in labels) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(
          tester.getRect(find.text(label)).width,
          closeTo(paragraph.size.width, 0.01),
          reason: label,
        );
        // 14 px Roboto Medium, one 20 px line, unscaled.
        expect(
          tester.getRect(find.text(label)).height,
          closeTo(paragraph.size.height, 0.01),
          reason: label,
        );
      }
    });
  });
}
