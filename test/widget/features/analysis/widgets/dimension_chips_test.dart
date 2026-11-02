import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/view_models/charts_state.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/dimension_toggle.dart';

Future<void> _pump(
  WidgetTester tester, {
  ChartDimension dimension = ChartDimension.category,
  ValueChanged<ChartDimension>? onChanged,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: DimensionChips(
          dimension: dimension,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pump(AnalysisMotion.standardDuration);
}

Finder _pill(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(AnimatedContainer))
    .first;

BoxDecoration _fill(WidgetTester tester, String label) =>
    tester.widget<AnimatedContainer>(_pill(label)).decoration! as BoxDecoration;

BoxDecoration _border(WidgetTester tester, String label) =>
    tester
            .widget<Container>(
              find
                  .ancestor(of: _pill(label), matching: find.byType(Container))
                  .first,
            )
            .foregroundDecoration!
        as BoxDecoration;

Color? _textColor(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label)).text.style?.color;

void main() {
  const colors = AnalysisColors.light;

  testWidgets('shows the three dimensions as chips', (tester) async {
    await _pump(tester);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.byType(SegmentedButton<ChartDimension>), findsNothing);
  });

  testWidgets('tapping a chip switches the dimension', (tester) async {
    ChartDimension? picked;
    await _pump(tester, onChanged: (d) => picked = d);
    await tester.tap(find.text('Account'));
    expect(picked, ChartDimension.account);
  });

  testWidgets('chips are buttons that expose selected state', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, dimension: ChartDimension.currency);
    expect(
      tester.getSemantics(find.text('Currency')),
      isSemantics(
        label: 'Currency',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Category')),
      isSemantics(
        label: 'Category',
        isButton: true,
        hasSelectedState: true,
        isSelected: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('selected chip is filled with onBg; others are outlined', (
    tester,
  ) async {
    await _pump(tester);

    expect(_fill(tester, 'Category').color, colors.onBg);
    expect(_border(tester, 'Category').border, Border.all(color: colors.onBg));
    expect(_textColor(tester, 'Category'), colors.onFg);

    expect(_fill(tester, 'Account').color!.a, 0);
    expect(
      _border(tester, 'Account').border,
      Border.all(color: colors.outline),
    );
    expect(_textColor(tester, 'Account'), colors.fg2);

    expect(_fill(tester, 'Account').borderRadius, BorderRadius.circular(16));
    final label = tester
        .renderObject<RenderParagraph>(find.text('Account'))
        .text
        .style!;
    expect(label.fontSize, 14);
    expect(label.height, 20 / 14);
    expect(label.fontWeight, FontWeight.w500);
  });

  testWidgets('pill is 32 high inside a 44-high hit target', (tester) async {
    await _pump(tester);
    expect(tester.getSize(_pill('Category')).height, 32);
    final target = find
        .ancestor(of: _pill('Category'), matching: find.byType(GestureDetector))
        .first;
    expect(tester.getSize(target).height, 44);
    // 14 padding + 1 border on each side of the label.
    expect(
      tester.getSize(_pill('Category')).width,
      tester.getSize(find.text('Category')).width + 30,
    );
  });

  testWidgets('chips grow instead of clipping at 2x text scale', (
    tester,
  ) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    // 20 px line height doubled, plus the 1 px border top and bottom.
    expect(tester.getSize(_pill('Category')).height, 42);
    expect(tester.getSize(find.text('Category')).height, 40);
  });
}
