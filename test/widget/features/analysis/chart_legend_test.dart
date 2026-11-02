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

  testWidgets('rows grow at 2x text scale', (tester) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text('Food')).height, 40);
    expect(tester.getSize(find.text('75.0%')).height, 32);
  });
}
