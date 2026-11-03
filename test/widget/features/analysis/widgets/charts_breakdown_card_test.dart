import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/charts_breakdown_card.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/dimension_toggle.dart';

const _colors = AnalysisColors.light;

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

Future<void> _pumpCard(
  WidgetTester tester, {
  CategoryType type = CategoryType.expense,
  ValueChanged<ChartDimension>? onDimensionChanged,
  Widget child = const SizedBox(key: ValueKey('body'), height: 10),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    _wrap(
      ChartsBreakdownCard(
        type: type,
        dimension: ChartDimension.category,
        onDimensionChanged: onDimensionChanged ?? (_) {},
        child: child,
      ),
      textScale: textScale,
    ),
  );
  await tester.pumpAndSettle();
}

TextStyle _style(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  group('ChartsBreakdownCard', () {
    testWidgets('card chrome: radius 20, card fill, 1px line, no shadow', (
      tester,
    ) async {
      await _pumpCard(tester);
      final card = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ChartsBreakdownCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final deco = card.decoration! as BoxDecoration;
      expect(deco.color, _colors.card);
      expect(deco.borderRadius, BorderRadius.circular(20));
      expect(deco.border, Border.all(color: _colors.line));
      expect(deco.boxShadow, isNull);
      expect(card.padding, const EdgeInsets.fromLTRB(0, 16, 0, 8));
    });

    testWidgets('title by type, chips under it, then the body', (tester) async {
      await _pumpCard(tester);
      expect(find.text('Expense breakdown'), findsOneWidget);
      final title = _style(tester, 'Expense breakdown');
      expect(title.fontSize, 16);
      expect(title.height, 24 / 16);
      expect(title.fontWeight, FontWeight.w500);
      expect(title.color, _colors.fg);

      final cardLeft = tester.getTopLeft(find.byType(ChartsBreakdownCard)).dx;
      // 1px border + 16 header padding.
      expect(
        tester.getTopLeft(find.text('Expense breakdown')).dx,
        cardLeft + 17,
      );
      // 1px border + 16 card padding.
      expect(
        tester.getTopLeft(find.text('Expense breakdown')).dy,
        tester.getTopLeft(find.byType(ChartsBreakdownCard)).dy + 17,
      );
      // 4 dp gap between the title and the chips.
      expect(
        tester.getTopLeft(find.byType(DimensionChips)).dy,
        tester.getBottomLeft(find.text('Expense breakdown')).dy + 4,
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('body'))).dy,
        tester.getBottomLeft(find.byType(DimensionChips)).dy,
      );
      // The body spans the card's full inner width.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('body'))).dx,
        cardLeft + 1,
      );

      await _pumpCard(tester, type: CategoryType.income);
      expect(find.text('Income breakdown'), findsOneWidget);
    });

    testWidgets('chips report the picked dimension', (tester) async {
      ChartDimension? picked;
      await _pumpCard(tester, onDimensionChanged: (d) => picked = d);
      await tester.tap(find.text('Currency'));
      expect(picked, ChartDimension.currency);
    });

    testWidgets('title grows at 2x text scale', (tester) async {
      await _pumpCard(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text('Expense breakdown')).height, 48);
    });

    testWidgets('title ends in an ellipsis on a 360 phone at 2x', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpCard(tester, textScale: 2);
      expect(tester.takeException(), isNull);

      final title = find.text('Expense breakdown');
      expect(tester.widget<Text>(title).overflow, TextOverflow.ellipsis);
      // Inside the 1 px border and the 16 header padding on each side.
      final card = tester.getRect(find.byType(ChartsBreakdownCard));
      expect(tester.getRect(title).left, card.left + 17);
      expect(tester.getRect(title).right, lessThanOrEqualTo(card.right - 17));
      expect(tester.getSize(title).height, 48);
    });
  });

  group('BreakdownEmptyState', () {
    Future<void> pumpEmpty(
      WidgetTester tester,
      CategoryType type, {
      double textScale = 1,
      String? accountName,
    }) => tester.pumpWidget(
      _wrap(
        BreakdownEmptyState(type: type, accountName: accountName),
        textScale: textScale,
      ),
    );

    testWidgets('expense copy points to Income', (tester) async {
      await pumpEmpty(tester, CategoryType.expense);
      expect(find.text('No expense in this period'), findsOneWidget);
      expect(
        find.text('Switch to Income or pick another period.'),
        findsOneWidget,
      );
      final title = _style(tester, 'No expense in this period');
      expect(title.fontSize, 15);
      expect(title.height, 20 / 15);
      expect(title.fontWeight, FontWeight.w500);
      expect(title.color, _colors.fg);
      final sub = _style(tester, 'Switch to Income or pick another period.');
      expect(sub.fontSize, 13);
      expect(sub.height, 18 / 13);
      expect(sub.color, _colors.fg2);
    });

    testWidgets('income copy points to Expense', (tester) async {
      await pumpEmpty(tester, CategoryType.income);
      expect(find.text('No income in this period'), findsOneWidget);
      expect(
        find.text('Switch to Expense or pick another period.'),
        findsOneWidget,
      );
    });

    testWidgets('with an account filter the copy names the account', (
      tester,
    ) async {
      await pumpEmpty(tester, CategoryType.expense, accountName: 'Travel card');
      expect(
        find.text('No expense on Travel card in this period'),
        findsOneWidget,
      );
      expect(find.text('Pick another account or period.'), findsOneWidget);
      expect(find.textContaining('Switch to'), findsNothing);
      final title = _style(tester, 'No expense on Travel card in this period');
      expect(title.fontSize, 15);
      expect(title.fontWeight, FontWeight.w500);
      expect(title.color, _colors.fg);
      final sub = _style(tester, 'Pick another account or period.');
      expect(sub.fontSize, 13);
      expect(sub.color, _colors.fg2);

      await pumpEmpty(tester, CategoryType.income, accountName: 'Travel card');
      expect(
        find.text('No income on Travel card in this period'),
        findsOneWidget,
      );
      expect(find.text('Pick another account or period.'), findsOneWidget);
    });

    testWidgets('48 dp track circle with a 22 dp chart icon', (tester) async {
      await pumpEmpty(tester, CategoryType.expense);
      final icon = tester.widget<Icon>(find.byIcon(Icons.bar_chart));
      expect(icon.size, 22);
      expect(icon.color, _colors.fg2);
      final circle = find
          .ancestor(
            of: find.byIcon(Icons.bar_chart),
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(circle), const Size(48, 48));
      final deco =
          tester.widget<Container>(circle).decoration! as BoxDecoration;
      expect(deco.color, _colors.track);
      expect(deco.shape, BoxShape.circle);

      // Padding 32 above the circle; 8 between the circle and the title.
      final top = tester.getTopLeft(find.byType(BreakdownEmptyState)).dy;
      expect(tester.getTopLeft(circle).dy, top + 32);
      expect(
        tester.getTopLeft(find.text('No expense in this period')).dy,
        tester.getBottomLeft(circle).dy + 8,
      );
    });

    testWidgets('copy wraps instead of overflowing at 2x', (tester) async {
      await pumpEmpty(tester, CategoryType.expense, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.text('No expense in this period')).height,
        greaterThanOrEqualTo(40),
      );
    });
  });
}
