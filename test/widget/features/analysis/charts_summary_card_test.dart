// ChartsSummaryCard — the Analysis summary card: Expense / Income tiles
// that double as the chart-type toggle, a ratio bar, and the period's net
// (spec § 5, acceptance criteria 2 and 3).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_net_total_providers.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_selection_controller.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/selected_slice.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_summary_card.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../support/text_scale.dart';

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');
const _c = AnalysisColors.light;

const _expenseTile = ValueKey('summaryTile.expense');
const _incomeTile = ValueKey('summaryTile.income');
const _ratioTrack = ValueKey('summaryRatio.track');
const _ratioExpense = ValueKey('summaryRatio.expense');
const _ratioIncome = ValueKey('summaryRatio.income');

ChartsNetTotal _totals({
  int? expense = 2000,
  int? income = 750,
  int? net = -1250,
  List<String> excluded = const [],
}) => ChartsNetTotal(
  currency: _usd,
  expenseMinorUnits: expense,
  incomeMinorUnits: income,
  netMinorUnits: net,
  excludedCurrencyCodes: excluded,
);

/// A phone window: 360 dp wide, so the card is 328 inside the page's 16 dp
/// gutters.
const _phone = Size(360, 800);

/// Pumps the card at [width] with the provider fixed to [totals]; returns
/// the container so a test can drive or read the selection. With
/// [surface], the test window takes that size and the card fills it minus
/// the 16 dp page gutters.
@Dependencies([chartsNetTotal, ChartsSelectionController])
Future<ProviderContainer> _pump(
  WidgetTester tester,
  ChartsNetTotal? totals, {
  double width = 358,
  double textScale = 1,
  ThemeData? theme,
  Size? surface,
  Locale? locale,
}) async {
  if (surface != null) {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    width = surface.width - 32;
  }
  final container = ProviderContainer(
    overrides: [chartsNetTotalProvider.overrideWithValue(totals)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: textScaleBuilder(textScale),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: const ChartsSummaryCard()),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}

BoxDecoration _decorationOf(WidgetTester tester, Key key) =>
    tester.widget<AnimatedContainer>(find.byKey(key)).decoration!
        as BoxDecoration;

Color? _textColor(WidgetTester tester, Finder finder) =>
    tester.widget<Text>(finder).style?.color;

Finder _inTile(Key tile, String text) =>
    find.descendant(of: find.byKey(tile), matching: find.text(text));

/// The net label sits at the row start on one 2× line (40), cut off with an
/// ellipsis, and ends at least 12 before [amount].
void _expectEllipsizedLabel(
  WidgetTester tester,
  String label,
  Rect card,
  Rect amount,
) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
  final rect = tester.getRect(find.text(label));
  expect(paragraph.maxLines, 1);
  expect(paragraph.overflow, TextOverflow.ellipsis);
  expect(paragraph.didExceedMaxLines, isTrue);
  expect(rect.height, 40);
  expect(rect.left, card.left + 13 + 4);
  expect(rect.right + 12, lessThanOrEqualTo(amount.left + 0.01));
}

@Dependencies([chartsNetTotal, ChartsSelectionController])
void main() {
  group('tiles (AC 2)', () {
    testWidgets('show both converted totals', (tester) async {
      await _pump(tester, _totals());

      expect(_inTile(_expenseTile, 'Expense'), findsOneWidget);
      expect(_inTile(_expenseTile, r'$20.00'), findsOneWidget);
      expect(_inTile(_incomeTile, 'Income'), findsOneWidget);
      expect(_inTile(_incomeTile, r'$7.50'), findsOneWidget);
    });

    testWidgets('the selected tile reports selected button semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, _totals());

      expect(
        tester.getSemantics(find.byKey(_expenseTile)),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.byKey(_incomeTile)),
        isSemantics(isButton: true, isSelected: false),
      );
      semantics.dispose();
    });

    testWidgets('tapping Income switches the chart type and clears the slice', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final container = await _pump(tester, _totals());
      final selection = container.read(
        chartsSelectionControllerProvider.notifier,
      );
      selection.toggleSlice(const SelectedSlice.category(1));
      await tester.pump();

      await tester.tap(find.byKey(_incomeTile));
      await tester.pump();

      final state = container.read(chartsSelectionControllerProvider);
      expect(state.type, CategoryType.income);
      expect(state.selectedSlice, isNull);
      expect(
        tester.getSemantics(find.byKey(_incomeTile)),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.byKey(_expenseTile)),
        isSemantics(isButton: true, isSelected: false),
      );
      semantics.dispose();
    });

    testWidgets(
      'tapping the selected tile keeps the type and clears the slice',
      (tester) async {
        final container = await _pump(tester, _totals());
        container
            .read(chartsSelectionControllerProvider.notifier)
            .toggleSlice(const SelectedSlice.category(1));
        await tester.pump();

        await tester.tap(find.byKey(_expenseTile));
        await tester.pump();

        final state = container.read(chartsSelectionControllerProvider);
        expect(state.type, CategoryType.expense);
        expect(state.selectedSlice, isNull);
      },
    );

    testWidgets('selected and unselected tiles use the design styles', (
      tester,
    ) async {
      final container = await _pump(tester, _totals());

      var expense = _decorationOf(tester, _expenseTile);
      var income = _decorationOf(tester, _incomeTile);
      expect(expense.color, _c.expTint);
      expect(expense.border, Border.all(color: _c.exp, width: 1.5));
      expect(expense.borderRadius, BorderRadius.circular(14));
      expect(income.color, _c.incTint.withValues(alpha: 0));
      expect(income.border, Border.all(color: _c.line, width: 1.5));
      expect(_textColor(tester, find.text('Expense')), _c.expText);
      expect(_textColor(tester, find.text('Income')), _c.fg2);

      container.read(chartsSelectionControllerProvider.notifier).toggleType();
      await tester.pump();
      await tester.pump(AnalysisMotion.standardDuration);

      expense = _decorationOf(tester, _expenseTile);
      income = _decorationOf(tester, _incomeTile);
      expect(income.color, _c.incTint);
      expect(income.border, Border.all(color: _c.inc, width: 1.5));
      expect(expense.color, _c.expTint.withValues(alpha: 0));
      expect(expense.border, Border.all(color: _c.line, width: 1.5));
      expect(_textColor(tester, find.text('Income')), _c.incText);
      expect(_textColor(tester, find.text('Expense')), _c.fg2);
    });

    testWidgets('switching tiles fades each tint, never through grey', (
      tester,
    ) async {
      final container = await _pump(tester, _totals());
      container.read(chartsSelectionControllerProvider.notifier).toggleType();
      await tester.pump();
      await tester.pump(AnalysisMotion.standardDuration ~/ 2);

      // Fading to transparent black would lerp the RGB towards grey.
      for (final (tile, tint) in [
        (_expenseTile, _c.expTint),
        (_incomeTile, _c.incTint),
      ]) {
        // The rendered box, not the AnimatedContainer's target decoration.
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byKey(tile),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final fill = (box.decoration as BoxDecoration).color!;
        expect(fill.a, inExclusiveRange(0, 1));
        expect(fill.r, closeTo(tint.r, 1e-6));
        expect(fill.g, closeTo(tint.g, 1e-6));
        expect(fill.b, closeTo(tint.b, 1e-6));
      }
    });

    testWidgets('dark theme uses the dark analysis colours', (tester) async {
      const dark = AnalysisColors.dark;
      await _pump(tester, _totals(net: 2005), theme: darkTheme);

      final expense = _decorationOf(tester, _expenseTile);
      expect(expense.color, dark.expTint);
      expect(expense.border, Border.all(color: dark.exp, width: 1.5));
      expect(
        _decorationOf(tester, _incomeTile).border,
        Border.all(color: dark.line, width: 1.5),
      );
      expect(_textColor(tester, find.text('Expense')), dark.expText);
      expect(_textColor(tester, find.text(r'+$20.05')), dark.incText);
      final card = tester.widget<Container>(
        find.byKey(const ValueKey('summaryCard')),
      );
      expect((card.decoration! as BoxDecoration).color, dark.card);
    });

    testWidgets('tiles animate on the standard 200 ms curve', (tester) async {
      await _pump(tester, _totals());

      final tile = tester.widget<AnimatedContainer>(find.byKey(_expenseTile));
      expect(tile.duration, AnalysisMotion.standardDuration);
      expect(tile.curve, AnalysisMotion.standardCurve);
      // The padding sits inside the InkWell so the ripple covers it.
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(InkWell).first,
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      );
    });

    testWidgets('label and amount use the design type scale', (tester) async {
      await _pump(tester, _totals());

      final label = tester.widget<Text>(find.text('Expense')).style!;
      expect(label.fontSize, 13);
      expect(label.height, 18 / 13);
      expect(label.fontWeight, FontWeight.w500);

      final amount = tester.widget<Text>(find.text(r'$20.00')).style!;
      expect(amount.fontSize, 18);
      expect(amount.height, 24 / 18);
      expect(amount.fontWeight, FontWeight.w500);
      expect(amount.color, _c.fg);
      expect(amount.fontFeatures, const [FontFeature.tabularFigures()]);

      // 8×8 dot, always in the type's fill colour, 6 before the label.
      final dot = tester.getRect(
        find.byKey(const ValueKey('summaryDot.income')),
      );
      expect(dot.size, const Size(8, 8));
      expect(tester.getTopLeft(find.text('Income')).dx - dot.right, 6);
    });

    testWidgets('long amounts shrink to fit their tile at 2× on a phone', (
      tester,
    ) async {
      await _pump(
        tester,
        _totals(expense: 123456789012, income: 98765432109, net: 0),
        surface: _phone,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);

      for (final (tile, text) in [
        (_expenseTile, r'$1,234,567,890.12'),
        (_incomeTile, r'$987,654,321.09'),
      ]) {
        final tileRect = tester.getRect(find.byKey(tile));
        final amountRect = tester.getRect(_inTile(tile, text));
        // The whole string is laid out (not clipped at the tile edge) and
        // drawn smaller than its laid-out width, i.e. it was scaled down.
        final paragraph = tester.renderObject<RenderParagraph>(
          _inTile(tile, text),
        );
        expect(
          paragraph.size.width,
          moreOrLessEquals(paragraph.getMaxIntrinsicWidth(double.infinity)),
        );
        expect(amountRect.width, lessThan(paragraph.size.width));
        // Inside the 1.5 border and the 14 horizontal padding.
        expect(amountRect.left, greaterThanOrEqualTo(tileRect.left + 15.5));
        expect(
          amountRect.right,
          lessThanOrEqualTo(tileRect.right - 15.5 + 0.01),
        );
      }
    });

    testWidgets('amounts that fit render 1:1 at 2× text scale', (tester) async {
      // Wide enough for the test font's square glyphs to fit unscaled.
      await _pump(tester, _totals(), width: 760, textScale: 2);

      expect(tester.takeException(), isNull);
      // Drawn (not just laid out) at the doubled line heights: amount 24,
      // label 18, net label 20, net 24.
      expect(tester.getRect(find.text(r'$20.00')).height, 48);
      // Labels may wrap (the test font is wide) but keep whole lines.
      expect(tester.getSize(find.text('Expense')).height % 36, 0);
      expect(tester.getSize(find.text('Net this week')).height % 40, 0);
      expect(tester.getRect(find.text(r'-$12.50')).height, 48);
      // Nothing is pushed out of the card.
      final card = tester.getRect(find.byKey(const ValueKey('summaryCard')));
      expect(
        tester.getRect(find.text(r'-$12.50')).right,
        lessThanOrEqualTo(card.right - 13 - 4),
      );
    });
  });

  group('press and focus feedback (D16)', () {
    testWidgets('a pressed tile shows an ink ripple clipped to its shape', (
      tester,
    ) async {
      await _pump(tester, _totals());

      for (final (tile, label) in [
        (_expenseTile, 'Expense'),
        (_incomeTile, 'Income'),
      ]) {
        // Hit target stays at least 44 dp.
        expect(
          tester.getSize(find.byKey(tile)).height,
          greaterThanOrEqualTo(44),
        );
        final ink = find.descendant(
          of: find.byKey(tile),
          matching: find.byType(InkWell),
        );
        expect(ink, findsOneWidget);
        // Inside the 1.5 border of the radius-14 tile.
        expect(
          tester.widget<InkWell>(ink).borderRadius,
          BorderRadius.circular(12.5),
        );
        // The ink paints on a Material inside the tile, above its tint.
        expect(
          find.descendant(
            of: find.byKey(tile),
            matching: find.byType(Material),
          ),
          findsOneWidget,
        );

        final material =
            Material.of(tester.element(_inTile(tile, label))) as RenderObject;
        expect(material, isNot(paints..rect()));
        final gesture = await tester.press(find.byKey(tile));
        await tester.pump(const Duration(milliseconds: 100));
        expect(material, paints..rect());
        await gesture.up();
        await tester.pump(const Duration(seconds: 1));
      }
    });

    testWidgets('tiles take keyboard focus and Enter activates them', (
      tester,
    ) async {
      final container = await _pump(tester, _totals());

      bool focused(String label) =>
          Focus.of(tester.element(find.text(label))).hasPrimaryFocus;

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused('Expense'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused('Income'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        container.read(chartsSelectionControllerProvider).type,
        CategoryType.income,
      );
    });
  });

  group('loading and unavailable totals', () {
    testWidgets('renders with dashes before the totals load', (tester) async {
      final container = await _pump(tester, null);

      expect(find.byKey(_expenseTile), findsOneWidget);
      expect(find.byKey(_incomeTile), findsOneWidget);
      expect(_inTile(_expenseTile, '—'), findsOneWidget);
      expect(_inTile(_incomeTile, '—'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));
      expect(tester.getSize(find.byKey(_ratioExpense)).width, 0);
      expect(tester.getSize(find.byKey(_ratioIncome)).width, 0);

      // Still the type toggle while loading.
      await tester.tap(find.byKey(_incomeTile));
      await tester.pump();
      expect(
        container.read(chartsSelectionControllerProvider).type,
        CategoryType.income,
      );
    });

    testWidgets('a type with no convertible currency shows a dash', (
      tester,
    ) async {
      await _pump(
        tester,
        _totals(expense: 400, income: null, net: -400, excluded: ['JPY']),
      );

      expect(_inTile(_expenseTile, r'$4.00'), findsOneWidget);
      expect(_inTile(_incomeTile, '—'), findsOneWidget);
      expect(find.text(r'-$4.00'), findsOneWidget);
      expect(find.text('Excluded: JPY — no exchange rate yet'), findsOneWidget);
    });

    testWidgets('names currencies left out for missing rates', (tester) async {
      await _pump(tester, _totals(excluded: ['EUR', 'JPY']));

      expect(
        find.text('Excluded: EUR, JPY — no exchange rate yet'),
        findsOneWidget,
      );
    });

    testWidgets('has no excluded line when every currency converted', (
      tester,
    ) async {
      await _pump(tester, _totals());

      expect(find.textContaining('Excluded'), findsNothing);
    });
  });

  group('ratio bar', () {
    testWidgets('segments split the width like flex-grow with a 3 px gap', (
      tester,
    ) async {
      await _pump(tester, _totals(expense: 3000, income: 1000, net: -2000));
      await tester.pump(AnalysisMotion.emphasizedDuration);

      final track = tester.getRect(find.byKey(_ratioTrack));
      final exp = tester.getRect(find.byKey(_ratioExpense));
      final inc = tester.getRect(find.byKey(_ratioIncome));
      final available = track.width - 3;
      expect(track.height, 6);
      expect(exp.width, moreOrLessEquals(available * 0.75));
      expect(inc.width, moreOrLessEquals(available * 0.25));
      expect(exp.left, track.left);
      expect(inc.left - exp.right, moreOrLessEquals(3));
      expect(exp.height, 6);
    });

    testWidgets('a zero side keeps the gap; the other side fills the rest', (
      tester,
    ) async {
      await _pump(tester, _totals(expense: 0, income: 500, net: 500));
      await tester.pump(AnalysisMotion.emphasizedDuration);

      final track = tester.getRect(find.byKey(_ratioTrack));
      expect(tester.getSize(find.byKey(_ratioExpense)).width, 0);
      expect(
        tester.getSize(find.byKey(_ratioIncome)).width,
        moreOrLessEquals(track.width - 3),
      );
    });

    testWidgets('both totals zero leave an empty track', (tester) async {
      await _pump(tester, _totals(expense: 0, income: 0, net: 0));
      await tester.pump(AnalysisMotion.emphasizedDuration);

      expect(tester.getSize(find.byKey(_ratioExpense)).width, 0);
      expect(tester.getSize(find.byKey(_ratioIncome)).width, 0);
      final track = tester.widget<Container>(find.byKey(_ratioTrack));
      expect((track.decoration! as BoxDecoration).color, _c.track);
    });

    testWidgets('segments use the type fills and animate for 360 ms', (
      tester,
    ) async {
      await _pump(tester, _totals());

      final exp = tester.widget<AnimatedContainer>(find.byKey(_ratioExpense));
      final inc = tester.widget<AnimatedContainer>(find.byKey(_ratioIncome));
      expect((exp.decoration! as BoxDecoration).color, _c.exp);
      expect((inc.decoration! as BoxDecoration).color, _c.inc);
      expect(
        (exp.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(3),
      );
      expect(exp.duration, AnalysisMotion.emphasizedDuration);
      expect(exp.curve, AnalysisMotion.standardCurve);
    });

    testWidgets('is hidden from screen readers', (tester) async {
      await _pump(tester, _totals());

      expect(
        find.ancestor(
          of: find.byKey(_ratioTrack),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('net row (AC 3)', () {
    testWidgets('the label follows the period', (tester) async {
      final container = await _pump(tester, _totals());
      final selection = container.read(
        chartsSelectionControllerProvider.notifier,
      );

      expect(find.text('Net this week'), findsOneWidget);
      for (final (period, label) in [
        (PeriodType.day, 'Net today'),
        (PeriodType.month, 'Net this month'),
        (PeriodType.year, 'Net this year'),
        (PeriodType.all, 'Net all time'),
        (PeriodType.week, 'Net this week'),
      ]) {
        selection.setPeriod(period);
        await tester.pump();
        expect(find.text(label), findsOneWidget);
      }
      final style = tester.widget<Text>(find.text('Net this week')).style!;
      expect(style.fontSize, 14);
      expect(style.height, 20 / 14);
      expect(style.color, _c.fg2);
    });

    testWidgets('a positive net is signed and uses incText', (tester) async {
      await _pump(tester, _totals(net: 2005));

      expect(_textColor(tester, find.text(r'+$20.05')), _c.incText);
      final style = tester.widget<Text>(find.text(r'+$20.05')).style!;
      expect(style.fontSize, 16);
      expect(style.height, 24 / 16);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.fontFeatures, const [FontFeature.tabularFigures()]);
    });

    testWidgets('a negative net uses expText', (tester) async {
      await _pump(tester, _totals(net: -1250));

      expect(_textColor(tester, find.text(r'-$12.50')), _c.expText);
    });

    testWidgets('a zero net uses fg', (tester) async {
      await _pump(tester, _totals(expense: 0, income: 0, net: 0));

      // Both tiles and the net read $0.00; the net is the one in fg with
      // 16 px text.
      final net = find.byWidgetPredicate(
        (w) => w is Text && w.data == r'$0.00' && w.style?.fontSize == 16,
      );
      expect(net, findsOneWidget);
      expect(_textColor(tester, net), _c.fg);
    });

    testWidgets('a long net shrinks beside its label at 2× on a phone', (
      tester,
    ) async {
      const text = r'-$1,234,567,890.12';
      await _pump(
        tester,
        _totals(expense: 123456789012, income: 0, net: -123456789012),
        surface: _phone,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byKey(const ValueKey('summaryCard')));
      final amount = tester.getRect(find.text(text));
      final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
      // The whole string is laid out, then drawn smaller to fit.
      expect(
        paragraph.size.width,
        moreOrLessEquals(paragraph.getMaxIntrinsicWidth(double.infinity)),
      );
      expect(amount.width, lessThan(paragraph.size.width));
      expect(amount.right, lessThanOrEqualTo(card.right - 13 - 4 + 0.01));

      // D2: the label ellipsized first, on one line, 12 before the amount.
      _expectEllipsizedLabel(tester, 'Net this week', card, amount);
    });

    testWidgets('a long zh_TW net keeps its label on one line at 2× on a '
        'phone', (tester) async {
      final text = find.text(r'-$1,234,567,890.12');
      await _pump(
        tester,
        _totals(expense: 123456789012, income: 0, net: -123456789012),
        surface: _phone,
        textScale: 2,
        locale: const Locale('zh', 'TW'),
      );
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byKey(const ValueKey('summaryCard')));
      final amount = tester.getRect(text);
      final paragraph = tester.renderObject<RenderParagraph>(text);
      expect(amount.width, lessThan(paragraph.size.width));
      expect(amount.right, lessThanOrEqualTo(card.right - 13 - 4 + 0.01));
      _expectEllipsizedLabel(tester, '本週淨額', card, amount);
    });

    testWidgets('the label ellipsizes before the amount shrinks', (
      tester,
    ) async {
      // At 2× the test font gives the label 28 dp and the amount 32 dp per
      // glyph: "-$0.50" (about 194) fits the 294 row only if the label
      // gives up most of its 364.
      await _pump(tester, _totals(net: -50), surface: _phone, textScale: 2);
      expect(tester.takeException(), isNull);

      final card = tester.getRect(find.byKey(const ValueKey('summaryCard')));
      final amount = tester.getRect(find.text(r'-$0.50'));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(r'-$0.50'),
      );
      expect(amount.width, moreOrLessEquals(paragraph.size.width));
      _expectEllipsizedLabel(tester, 'Net this week', card, amount);
    });

    testWidgets('shows a dash, not a zero, when no currency had a rate', (
      tester,
    ) async {
      await _pump(
        tester,
        _totals(expense: null, income: null, net: null, excluded: ['JPY']),
      );

      expect(find.text('—'), findsNWidgets(3));
      expect(find.text(r'$0.00'), findsNothing);
    });
  });

  group('card chrome', () {
    testWidgets('radius 20, card fill, 1 px line border, padding 12', (
      tester,
    ) async {
      await _pump(tester, _totals());

      final card = tester.widget<Container>(
        find.byKey(const ValueKey('summaryCard')),
      );
      final decoration = card.decoration! as BoxDecoration;
      expect(decoration.color, _c.card);
      expect(decoration.border, Border.all(color: _c.line));
      expect(decoration.borderRadius, BorderRadius.circular(20));
      expect(decoration.boxShadow, isNull);
      expect(card.padding, const EdgeInsets.all(12));

      // Tiles: two equal columns 8 apart; 12 between the card's rows.
      final cardRect = tester.getRect(
        find.byKey(const ValueKey('summaryCard')),
      );
      final expense = tester.getRect(find.byKey(_expenseTile));
      final income = tester.getRect(find.byKey(_incomeTile));
      expect(expense.left, cardRect.left + 13);
      expect(income.right, cardRect.right - 13);
      expect(expense.width, income.width);
      expect(income.left - expense.right, 8);
      expect(expense.height, income.height);
      final track = tester.getRect(find.byKey(_ratioTrack));
      expect(track.top - expense.bottom, 12);
      expect(track.left, cardRect.left + 13);
      expect(track.right, cardRect.right - 13);
      // Net row: 4 horizontal padding, 12 below the ratio bar (the taller
      // amount sets the row top; the label sits on its baseline).
      final netLabel = tester.getRect(find.text('Net this week'));
      final netAmount = tester.getRect(find.text(r'-$12.50'));
      expect(netLabel.left, cardRect.left + 13 + 4);
      expect(netAmount.top - track.bottom, 12);
      expect(netAmount.right, cardRect.right - 13 - 4);
      expect(netLabel.top, greaterThan(netAmount.top));
    });
  });
}
