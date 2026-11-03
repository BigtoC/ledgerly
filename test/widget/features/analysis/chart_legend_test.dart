import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/core/utils/icon_registry.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/chart_legend.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _colors = AnalysisColors.light;

List<ChartSlice> _twelveSlices() => List.generate(
  12,
  (i) => ChartSlice(
    label: 'Slice $i',
    currencyCode: 'USD',
    totalMinorUnits: 1200 - i * 100,
    colorIndex: i % kCategoryColorPalette.length,
    iconKey: '',
    selectionKey: SelectedSlice.category(i + 1),
  ),
);

// Yellow 80 is light (luminance > 0.35), Blue 30 is dark.
const _slices = [
  ChartSlice(
    label: 'Transport',
    currencyCode: 'USD',
    totalMinorUnits: 2500,
    fraction: 0.25,
    colorIndex: CategoryPaletteIndex.blue30,
    iconKey: 'car',
    selectionKey: SelectedSlice.category(2),
  ),
  ChartSlice(
    label: 'category.food',
    currencyCode: 'USD',
    totalMinorUnits: 7500,
    fraction: 0.75,
    colorIndex: CategoryPaletteIndex.yellow80,
    iconKey: 'restaurant',
    selectionKey: SelectedSlice.category(1),
  ),
];

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  theme: lightTheme,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: app!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _pump(
  WidgetTester tester, {
  List<ChartSlice> slices = _slices,
  int? selected,
  ValueChanged<int?>? onSelectSlice,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    _wrap(
      ChartLegend(
        slices: slices,
        currenciesByCode: const {'USD': _usd},
        locale: 'en',
        selectedSliceIndex: selected,
        onSelectSlice: onSelectSlice,
      ),
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

Finder _row(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(AnimatedContainer))
    .first;

TextStyle _style(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

List<double> _fades(String label) => find
    .descendant(of: _row(label), matching: find.byType(AnimatedOpacity))
    .evaluate()
    .map((e) => (e.widget as AnimatedOpacity).opacity)
    .toList();

void main() {
  testWidgets('lists every slice as a ranked row, with no card', (
    tester,
  ) async {
    await _pump(tester, slices: _twelveSlices());

    for (var i = 0; i < 12; i++) {
      expect(
        find.descendant(
          of: find.byType(ChartLegend),
          matching: find.text('Slice $i'),
        ),
        findsOneWidget,
      );
    }
    expect(find.byType(Card), findsNothing);
    expect(find.text('View all'), findsNothing);
  });

  testWidgets('rows are sorted by amount, largest first', (tester) async {
    await _pump(tester);
    expect(
      tester.getTopLeft(find.text('Food')).dy,
      lessThan(tester.getTopLeft(find.text('Transport')).dy),
    );
  });

  testWidgets('tapping a row reports its original slice index', (tester) async {
    int? selectedIndex;
    await _pump(
      tester,
      slices: _twelveSlices(),
      onSelectSlice: (idx) => selectedIndex = idx,
    );
    await tester.ensureVisible(find.text('Slice 11'));
    await tester.tap(find.text('Slice 11'));
    expect(selectedIndex, 11);
  });

  testWidgets('row chrome, label, amount, share bar and percentage', (
    tester,
  ) async {
    await _pump(tester);

    final row = tester.widget<AnimatedContainer>(_row('Food'));
    // Padding 10 8 inside the row.
    final rowRect = tester.getRect(_row('Food'));
    expect(tester.getTopLeft(find.text('Food')).dy, rowRect.top + 10);
    expect(
      tester
          .getTopLeft(
            find
                .ancestor(
                  of: find.byIcon(iconForKey('restaurant')),
                  matching: find.byType(Container),
                )
                .first,
          )
          .dx,
      rowRect.left + 8,
    );
    expect(
      tester
          .getTopRight(
            find.descendant(
              of: _row('Food'),
              matching: find.byIcon(Icons.chevron_right),
            ),
          )
          .dx,
      rowRect.right - 8,
    );
    final deco = row.decoration! as BoxDecoration;
    expect(deco.borderRadius, BorderRadius.circular(14));
    expect(deco.color!.a, 0);

    final label = _style(tester, 'Food');
    expect(label.fontSize, 15);
    expect(label.height, 20 / 15);
    expect(label.fontWeight, FontWeight.w500);
    expect(label.color, _colors.fg);
    final amount = _style(tester, r'$75.00');
    expect(amount.fontSize, 15);
    expect(amount.fontWeight, FontWeight.w500);
    expect(amount.fontFeatures, const [FontFeature.tabularFigures()]);

    expect(find.text('75.0%'), findsOneWidget);
    final pct = _style(tester, '75.0%');
    expect(pct.fontSize, 12);
    expect(pct.height, 16 / 12);
    expect(pct.color, _colors.fg3);
    expect(tester.getSize(find.text('75.0%')).width, greaterThanOrEqualTo(40));

    final bar = tester.widget<AnimatedFractionallySizedBox>(
      find.descendant(
        of: _row('Food'),
        matching: find.byType(AnimatedFractionallySizedBox),
      ),
    );
    expect(bar.widthFactor, 0.75);
    expect(bar.duration, AnalysisMotion.emphasizedDuration);
    expect(bar.curve, AnalysisMotion.emphasizedCurve);

    final chevron = tester.widget<Icon>(
      find.descendant(
        of: _row('Food'),
        matching: find.byIcon(Icons.chevron_right),
      ),
    );
    expect(chevron.size, 18);
    expect(chevron.color, _colors.fg3);
  });

  testWidgets('leading circle uses the slice colour and luminance ink', (
    tester,
  ) async {
    await _pump(tester);

    final food = tester.widget<Icon>(find.byIcon(iconForKey('restaurant')));
    expect(food.size, 18);
    expect(food.color, const Color(0xFF1B1B1B));
    final transport = tester.widget<Icon>(find.byIcon(iconForKey('car')));
    expect(transport.color, const Color(0xFFFFFFFF));

    final circle = find.ancestor(
      of: find.byIcon(iconForKey('restaurant')),
      matching: find.byType(Container),
    );
    expect(tester.getSize(circle.first), const Size(36, 36));
    final deco =
        tester.widget<Container>(circle.first).decoration! as BoxDecoration;
    expect(deco.color, colorForIndex(CategoryPaletteIndex.yellow80));
    expect(deco.shape, BoxShape.circle);
  });

  testWidgets('currency slices show the code in the circle', (tester) async {
    await _pump(
      tester,
      slices: const [
        ChartSlice(
          label: 'JPY',
          currencyCode: 'USD',
          totalMinorUnits: 100,
          fraction: 1,
          colorIndex: 5,
          iconKey: '',
          selectionKey: SelectedSlice.currency('JPY'),
        ),
      ],
    );
    // Label in the row plus the code in the circle.
    expect(find.text('JPY'), findsNWidgets(2));
    final code = tester
        .renderObjectList<RenderParagraph>(find.text('JPY'))
        .map((p) => p.text.style!)
        .firstWhere((s) => s.fontSize == 10);
    expect(code.fontWeight, FontWeight.w700);
    expect(code.letterSpacing, 0.3);
  });

  testWidgets('currency code takes the higher-contrast ink; icons on the '
      'same fill keep the luminance rule (plan D24)', (tester) async {
    ChartSlice currency(String code, int colorIndex) => ChartSlice(
      label: code,
      currencyCode: 'USD',
      totalMinorUnits: 100,
      fraction: 0.5,
      colorIndex: colorIndex,
      iconKey: '',
      selectionKey: SelectedSlice.currency(code),
    );
    await _pump(
      tester,
      slices: [
        currency('AAA', CategoryPaletteIndex.red60),
        currency('BBB', CategoryPaletteIndex.neutralVariant50),
        const ChartSlice(
          label: 'Transport',
          currencyCode: 'USD',
          totalMinorUnits: 100,
          fraction: 0.5,
          colorIndex: CategoryPaletteIndex.red60,
          iconKey: 'car',
          selectionKey: SelectedSlice.category(2),
        ),
      ],
    );

    Color? codeInk(String code) => tester
        .renderObjectList<RenderParagraph>(find.text(code))
        .map((p) => p.text.style!)
        .firstWhere((s) => s.fontSize == 10)
        .color;
    // Red 60: #1B1B1B gives 5.43:1, white only 3.17:1.
    expect(codeInk('AAA'), const Color(0xFF1B1B1B));
    // Neutral Variant 50: white gives 4.55:1, #1B1B1B only 3.78:1.
    expect(codeInk('BBB'), const Color(0xFFFFFFFF));
    // Icons need only 3:1 and keep luminance > 0.35, so white on Red 60.
    expect(
      tester.widget<Icon>(find.byIcon(iconForKey('car'))).color,
      const Color(0xFFFFFFFF),
    );
  });

  testWidgets('selected row gets the sel fill and a bold label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, selected: 1, onSelectSlice: (_) {});

    final deco =
        tester.widget<AnimatedContainer>(_row('Food')).decoration!
            as BoxDecoration;
    expect(deco.color, _colors.sel);
    expect(_style(tester, 'Food').fontWeight, FontWeight.w700);
    expect(_style(tester, 'Transport').fontWeight, FontWeight.w500);
    expect(
      tester.getSemantics(find.text('Food')),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.text('Transport')),
      isSemantics(isButton: true, hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('with a selection only the circle and bar fill fade', (
    tester,
  ) async {
    await _pump(tester, selected: 1);

    expect(_fades('Food'), [1, 1]);
    expect(_fades('Transport'), [0.35, 0.35]);
    for (final text in ['Transport', r'$25.00', '25.0%']) {
      final faded = find.ancestor(
        of: find.text(text),
        matching: find.byWidgetPredicate(
          (w) =>
              (w is AnimatedOpacity && w.opacity < 1) ||
              (w is Opacity && w.opacity < 1),
        ),
      );
      expect(faded, findsNothing, reason: '$text must not fade');
    }
    expect(_style(tester, 'Transport').color, _colors.fg);
  });

  testWidgets('no selection: nothing fades', (tester) async {
    await _pump(tester);
    expect(_fades('Food'), [1, 1]);
    expect(_fades('Transport'), [1, 1]);
  });

  testWidgets('mixed currencies hide the share bar and percentage', (
    tester,
  ) async {
    await _pump(
      tester,
      slices: const [
        ChartSlice(
          label: 'USD',
          currencyCode: 'USD',
          totalMinorUnits: 100,
          colorIndex: 1,
          iconKey: '',
          selectionKey: SelectedSlice.currency('USD'),
        ),
      ],
    );
    expect(find.byType(AnimatedFractionallySizedBox), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('rows keep the Material ink ripple over the whole row', (
    tester,
  ) async {
    await _pump(tester, selected: 1, onSelectSlice: (_) {});
    for (final label in ['Food', 'Transport']) {
      // Inside the row container, so the ripple paints above the sel fill.
      final ink = find.descendant(
        of: _row(label),
        matching: find.byType(InkWell),
      );
      expect(ink, findsOneWidget, reason: label);
      expect(tester.getSize(ink), tester.getSize(_row(label)));
      final inkWell = tester.widget<InkWell>(ink);
      expect(inkWell.borderRadius, BorderRadius.circular(14));
      expect(inkWell.overlayColor, isNull);
      expect(inkWell.splashColor, isNull);
      expect(inkWell.highlightColor, isNull);
    }
  });

  testWidgets('a pressed row highlights clipped to its 14 radius', (
    tester,
  ) async {
    await _pump(tester, onSelectSlice: (_) {});
    final row = tester.getRect(_row('Food'));
    final gesture = await tester.startGesture(row.center);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      Material.of(tester.element(find.text('Food'))) as RenderObject,
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          Offset.zero & row.size,
          const Radius.circular(14),
        ),
      ),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('rows take keyboard focus and activate with Enter', (
    tester,
  ) async {
    int? picked = -1;
    await _pump(tester, onSelectSlice: (i) => picked = i);
    // Food ranks first; its original slice index is 1.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(picked, 1);
  });

  group('long amount on a 360 phone', () {
    const longLabel = 'Transport and commuting costs';
    ChartSlice slice(int minorUnits) => ChartSlice(
      label: longLabel,
      currencyCode: 'USD',
      totalMinorUnits: minorUnits,
      fraction: 1,
      colorIndex: CategoryPaletteIndex.blue30,
      iconKey: 'car',
      selectionKey: const SelectedSlice.category(2),
    );

    Future<void> pumpPhone(
      WidgetTester tester,
      double textScale,
      int minorUnits,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(tester, slices: [slice(minorUnits)], textScale: textScale);
    }

    // Row content box: 8 list inset + 8 row padding on each side; the
    // amount sits left of the 12 gap and the 18 chevron.
    double amountSlotRight(WidgetTester tester) =>
        tester.getRect(_row(longLabel)).right - 8 - 12 - 18;

    RenderParagraph paragraph(WidgetTester tester, String text) =>
        tester.renderObject<RenderParagraph>(find.text(text));

    testWidgets('shows in full at 1x', (tester) async {
      await pumpPhone(tester, 1, 123456789);
      expect(tester.takeException(), isNull);
      expect(paragraph(tester, r'$1,234,567.89').didExceedMaxLines, isFalse);
    });

    testWidgets('at 2x the label ellipsizes first; the amount stays 1:1', (
      tester,
    ) async {
      await pumpPhone(tester, 2, 1234);
      expect(tester.takeException(), isNull);
      const amount = r'$12.34';
      expect(paragraph(tester, longLabel).didExceedMaxLines, isTrue);
      expect(paragraph(tester, amount).didExceedMaxLines, isFalse);
      // Unscaled: 20 px line height doubled.
      expect(tester.getRect(find.text(amount)).height, 40);
      expect(
        tester.getRect(find.text(amount)).right,
        lessThanOrEqualTo(amountSlotRight(tester)),
      );
      // Same 15/20 metrics: the unscaled amount shares the label's line.
      expect(
        tester.getRect(find.text(amount)).top,
        tester.getRect(find.text(longLabel)).top,
      );
    });

    testWidgets('at 2x a too-long amount scales down, never ellipsizes', (
      tester,
    ) async {
      await pumpPhone(tester, 2, 123456789);
      expect(tester.takeException(), isNull);
      const amount = r'$1,234,567.89';
      expect(find.text(amount), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(amount)).overflow,
        isNot(TextOverflow.ellipsis),
      );
      expect(paragraph(tester, amount).didExceedMaxLines, isFalse);
      final amountRect = tester.getRect(find.text(amount));
      final labelRect = tester.getRect(find.text(longLabel));
      expect(amountRect.right, lessThanOrEqualTo(amountSlotRight(tester)));
      // The label keeps its minimal width and the 8 gap.
      expect(labelRect.width, greaterThanOrEqualTo(40));
      expect(amountRect.left, greaterThanOrEqualTo(labelRect.right + 8));
      expect(paragraph(tester, longLabel).didExceedMaxLines, isTrue);
      // Shrunk below the 40 px line it would take at 2x.
      expect(amountRect.height, lessThan(40));
      // The shrunk amount stays centred on the label's line instead of
      // riding up to its top.
      expect(amountRect.center.dy, closeTo(labelRect.center.dy, 0.5));
    });
  });

  testWidgets('rows grow at 2x text scale', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text('Food')).height, 40);
    expect(tester.getSize(find.text('75.0%')).height, 32);
  });
}
