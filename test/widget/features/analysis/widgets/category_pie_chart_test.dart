import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/category_pie_chart.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _colors = AnalysisColors.light;

// Slice 0 covers 75% of the ring, clockwise from 12 o'clock, so it owns
// the right, bottom and left; slice 1 owns the top-left quadrant.
const _slices = [
  ChartSlice(
    label: 'category.food',
    currencyCode: 'USD',
    totalMinorUnits: 7500,
    fraction: 0.75,
    colorIndex: 0,
    iconKey: '',
    selectionKey: SelectedSlice.category(1),
  ),
  ChartSlice(
    label: 'Transport',
    currencyCode: 'USD',
    totalMinorUnits: 2500,
    fraction: 0.25,
    colorIndex: 1,
    iconKey: '',
    selectionKey: SelectedSlice.category(2),
  ),
];

// Midway through the ring (centre hole 74, ring 26).
const _ringOffset = 87.0;

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
  home: Scaffold(body: Center(child: child)),
);

Future<void> _pump(
  WidgetTester tester, {
  List<ChartSlice> slices = _slices,
  int? selectedIndex,
  int? grandTotal = 10000,
  CategoryType type = CategoryType.expense,
  ChartDimension dimension = ChartDimension.category,
  double textScale = 1,
  ValueChanged<int?>? onSelectionChanged,
  String? accountName,
}) async {
  await tester.pumpWidget(
    _wrap(
      CategoryPieChart(
        slices: slices,
        currenciesByCode: const {'USD': _usd},
        locale: 'en',
        type: type,
        dimension: dimension,
        grandTotalMinorUnits: grandTotal,
        displayCurrencyCode: grandTotal == null ? null : 'USD',
        selectedIndex: selectedIndex,
        onSelectionChanged: onSelectionChanged,
        accountName: accountName,
      ),
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

Future<List<int?>> _pumpAndTap(
  WidgetTester tester, {
  required int? selectedIndex,
  required Offset fromCentre,
}) async {
  final reported = <int?>[];
  await _pump(
    tester,
    selectedIndex: selectedIndex,
    onSelectionChanged: reported.add,
  );
  await tester.tapAt(tester.getCenter(find.byType(PieChart)) + fromCentre);
  await tester.pumpAndSettle();
  return reported;
}

PieChartData _data(WidgetTester tester) =>
    tester.widget<PieChart>(find.byType(PieChart)).data;

TextStyle _style(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  group('geometry', () {
    testWidgets('200x200 donut with a 12 dp vertical margin', (tester) async {
      await _pump(tester);
      expect(tester.getSize(find.byType(PieChart)), const Size(200, 200));
      expect(tester.getSize(find.byType(CategoryPieChart)).height, 224);
    });

    testWidgets('ring 26 around a 74 hole, gaps per D6, no titles', (
      tester,
    ) async {
      await _pump(tester);
      final data = _data(tester);
      expect(data.centerSpaceRadius, 74);
      expect(data.sectionsSpace, 3.28);
      expect(data.startDegreeOffset, -90 - 1.08);
      for (final s in data.sections) {
        expect(s.radius, 26);
        expect(s.showTitle, isFalse);
      }
      final chart = tester.widget<PieChart>(find.byType(PieChart));
      expect(chart.duration, AnalysisMotion.standardDuration);
      expect(chart.curve, AnalysisMotion.standardCurve);
    });

    testWidgets('selection fades the others to 0x4D without growing', (
      tester,
    ) async {
      await _pump(tester, selectedIndex: 1);
      final sections = _data(tester).sections;
      expect(sections[0].color, colorForIndex(0).withAlpha(0x4D));
      expect(sections[1].color, colorForIndex(1));
      expect(sections.map((s) => s.radius), everyElement(26));
    });
  });

  group('centre', () {
    testWidgets('no selection: total label, grand total, slice count', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Total expense'), findsOneWidget);
      expect(find.text(r'$100.00'), findsOneWidget);
      expect(find.text('2 categories'), findsOneWidget);

      final top = _style(tester, 'Total expense');
      expect(top.fontSize, 12);
      expect(top.height, 16 / 12);
      expect(top.color, _colors.fg2);
      expect(top.fontWeight, FontWeight.w400);
      final amount = _style(tester, r'$100.00');
      expect(amount.fontSize, 17);
      expect(amount.height, 24 / 17);
      expect(amount.fontWeight, FontWeight.w500);
      expect(amount.color, _colors.fg);
      expect(amount.fontFeatures, const [FontFeature.tabularFigures()]);
      final sub = _style(tester, '2 categories');
      expect(sub.fontSize, 12);
      expect(sub.height, 16 / 12);
      expect(sub.color, _colors.fg3);
    });

    testWidgets('income type uses the income total label', (tester) async {
      await _pump(tester, type: CategoryType.income);
      expect(find.text('Total income'), findsOneWidget);
    });

    testWidgets('slice count follows the dimension', (tester) async {
      await _pump(tester, dimension: ChartDimension.account);
      expect(find.text('2 accounts'), findsOneWidget);
      await _pump(tester, dimension: ChartDimension.currency);
      expect(find.text('2 currencies'), findsOneWidget);
    });

    testWidgets('account filter: "<Account> expense" in fg2 (AC 5c)', (
      tester,
    ) async {
      await _pump(tester, accountName: 'Travel card');
      expect(find.text('Travel card expense'), findsOneWidget);
      expect(find.text('Total expense'), findsNothing);
      expect(find.text(r'$100.00'), findsOneWidget);
      final top = _style(tester, 'Travel card expense');
      expect(top.color, _colors.fg2);
      expect(top.fontWeight, FontWeight.w400);
      expect(top.fontSize, 12);

      await _pump(
        tester,
        accountName: 'Travel card',
        type: CategoryType.income,
      );
      expect(find.text('Travel card income'), findsOneWidget);
    });

    testWidgets('account filter with a slice selected: the slice label wins', (
      tester,
    ) async {
      await _pump(tester, accountName: 'Travel card', selectedIndex: 1);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Travel card expense'), findsNothing);
    });

    testWidgets('a long account name ellipsizes within 128', (tester) async {
      await _pump(
        tester,
        accountName: 'A very long account name that cannot fit',
      );
      final line = find.text(
        'A very long account name that cannot fit expense',
      );
      expect(tester.getSize(line).width, lessThanOrEqualTo(128));
      expect(
        tester.renderObject<RenderParagraph>(line).didExceedMaxLines,
        isTrue,
      );
    });

    testWidgets('selected slice: its label, total and share', (tester) async {
      await _pump(tester, selectedIndex: 0);
      // Seeded category keys resolve to their localized names.
      expect(find.text('Food'), findsOneWidget);
      expect(find.text(r'$75.00'), findsOneWidget);
      expect(find.text('75.0% of expense'), findsOneWidget);
      final top = _style(tester, 'Food');
      expect(top.color, _colors.fg);
      expect(top.fontWeight, FontWeight.w500);
    });

    testWidgets('income share line names income', (tester) async {
      await _pump(tester, selectedIndex: 1, type: CategoryType.income);
      expect(find.text('25.0% of income'), findsOneWidget);
    });

    testWidgets('mixed currencies: dash total, no share line', (tester) async {
      const mixed = [
        ChartSlice(
          label: 'USD',
          currencyCode: 'USD',
          totalMinorUnits: 7500,
          colorIndex: 0,
          iconKey: '',
          selectionKey: SelectedSlice.currency('USD'),
        ),
        ChartSlice(
          label: 'JPY',
          currencyCode: 'JPY',
          totalMinorUnits: 2500,
          colorIndex: 1,
          iconKey: '',
          selectionKey: SelectedSlice.currency('JPY'),
        ),
      ];
      await _pump(
        tester,
        slices: mixed,
        grandTotal: null,
        dimension: ChartDimension.currency,
      );
      expect(find.text('—'), findsOneWidget);
      expect(find.text('2 currencies'), findsOneWidget);

      await _pump(
        tester,
        slices: mixed,
        grandTotal: null,
        dimension: ChartDimension.currency,
        selectedIndex: 0,
      );
      expect(find.textContaining('of expense'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('clamps at 1.5x and keeps the amount within 128', (
      tester,
    ) async {
      // D2: on a phone width at 2x.
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        textScale: 2,
        grandTotal: 123456789012,
        slices: [_slices[0].copyWith(totalMinorUnits: 123456789012)],
      );
      expect(tester.takeException(), isNull);
      // 16 px line height at the 1.5x clamp.
      expect(tester.getSize(find.text('Total expense')).height, 24);
      expect(
        tester.getRect(find.text(r'$1,234,567,890.12')).width,
        lessThanOrEqualTo(128),
      );
      // Shrunk, never ellipsized.
      expect(
        tester
            .renderObject<RenderParagraph>(find.text(r'$1,234,567,890.12'))
            .didExceedMaxLines,
        isFalse,
      );
    });
  });

  group('taps', () {
    testWidgets('tapping a slice selects it', (tester) async {
      final reported = await _pumpAndTap(
        tester,
        selectedIndex: null,
        fromCentre: const Offset(0, _ringOffset),
      );
      expect(reported, [0]);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('tapping another slice moves the selection to it', (
      tester,
    ) async {
      final reported = await _pumpAndTap(
        tester,
        selectedIndex: 0,
        fromCentre: const Offset(-_ringOffset * 0.7, -_ringOffset * 0.7),
      );
      expect(reported, [1]);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('tapping the selected slice clears the selection', (
      tester,
    ) async {
      final reported = await _pumpAndTap(
        tester,
        selectedIndex: 0,
        fromCentre: const Offset(_ringOffset, 0),
      );
      expect(reported, [null]);
    }, variant: TargetPlatformVariant.mobile());

    testWidgets('tapping the centre hole clears the selection', (tester) async {
      final reported = await _pumpAndTap(
        tester,
        selectedIndex: 0,
        fromCentre: Offset.zero,
      );
      expect(reported, [null]);
    }, variant: TargetPlatformVariant.mobile());
  });
}
