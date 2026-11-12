// AccountFilterButton — the app-bar account filter pill. Visual values
// from docs/design/analysis-redesign/Main.dc.html (lines 20-27,
// accPillStyle).

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/analysis/charts/views/account_filter_button.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? accountName,
  VoidCallback? onPressed,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? lightTheme,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: AccountFilterButton(
            accountName: accountName,
            onPressed: onPressed ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder get _pill => find.byKey(const ValueKey('accountFilterPill'));

BoxDecoration _border(WidgetTester tester) =>
    tester
            .widget<Container>(
              find.ancestor(of: _pill, matching: find.byType(Container)).first,
            )
            .foregroundDecoration!
        as BoxDecoration;

Color? _fill(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(_pill).decoration! as BoxDecoration)
        .color;

Color? _iconColor(WidgetTester tester) => tester
    .widget<RichText>(
      find.descendant(
        of: find.byIcon(Icons.expand_more),
        matching: find.byType(RichText),
      ),
    )
    .text
    .style
    ?.color;

void main() {
  testWidgets('inactive: "All accounts", transparent, outline border, fg2', (
    tester,
  ) async {
    await _pump(tester);
    const colors = AnalysisColors.light;

    final label = tester.widget<Text>(find.text('All accounts'));
    expect(label.style?.fontSize, 13);
    expect(label.style!.height! * 13, closeTo(18, 0.001));
    expect(label.style?.fontWeight, FontWeight.w500);
    expect(label.style?.letterSpacing, 0);
    expect(label.style?.color, colors.fg2);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(label.maxLines, 1);

    expect(_fill(tester)!.a, 0);
    final border = _border(tester);
    expect(border.border, Border.all(color: colors.outline));
    expect(border.borderRadius, BorderRadius.circular(16));
    expect(tester.getSize(find.byIcon(Icons.expand_more)), const Size(16, 16));
    expect(_iconColor(tester), colors.fg2);
    // No wallet icon.
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('active: account name, sel fill, fg2 border, fg text', (
    tester,
  ) async {
    for (final (theme, colors) in [
      (lightTheme, AnalysisColors.light),
      (darkTheme, AnalysisColors.dark),
    ]) {
      await _pump(tester, accountName: 'Travel card', theme: theme);
      await tester.pump(const Duration(milliseconds: 300));

      final label = tester.widget<Text>(find.text('Travel card'));
      expect(label.style?.color, colors.fg);
      expect(_fill(tester), colors.sel);
      expect(_border(tester).border, Border.all(color: colors.fg2));
      expect(_iconColor(tester), colors.fg);
    }
  });

  testWidgets('the fill transitions over 200 ms on the standard curve', (
    tester,
  ) async {
    await _pump(tester);
    final pill = tester.widget<AnimatedContainer>(_pill);
    expect(pill.duration, AnalysisMotion.standardDuration);
    expect(pill.curve, AnalysisMotion.standardCurve);
  });

  testWidgets('44 hit target, 32 pill, padding 0 8 0 12, gap 4', (
    tester,
  ) async {
    await _pump(tester);

    final pill = tester.getRect(_pill);
    expect(pill.height, 32);
    final target = tester.getRect(find.byType(AccountFilterButton));
    expect(target.height, 44);
    // Button padding 0 2.
    expect(target.width, pill.width + 4);
    final label = tester.getRect(find.text('All accounts'));
    final icon = tester.getRect(find.byIcon(Icons.expand_more));
    // 1 px border, then 12 / 8 padding.
    expect(label.left - pill.left, 13);
    expect(pill.right - icon.right, 9);
    expect(icon.left - label.right, 4);
    expect(label.center.dy, pill.center.dy);
  });

  testWidgets('a long name ellipsizes inside the 150 max width', (
    tester,
  ) async {
    await _pump(
      tester,
      accountName: 'A very long credit card account name that never fits',
    );

    expect(tester.getSize(_pill).width, 150);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics: button, "Account filter: <label>", tap hint', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await _pump(tester, accountName: 'Travel card', onPressed: () => taps++);

    final node = tester.getSemantics(
      find.bySemanticsLabel('Account filter: Travel card'),
    );
    expect(
      node,
      isSemantics(
        label: 'Account filter: Travel card',
        isButton: true,
        hasTapAction: true,
        onTapHint: 'Filter by account',
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Account filter: Travel card'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('a press on the 44 target outside the pill still opens it', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, onPressed: () => taps++);

    final target = tester.getRect(find.byType(AccountFilterButton));
    await tester.tapAt(target.topCenter + const Offset(0, 2));
    expect(taps, 1);
    await tester.tap(_pill);
    expect(taps, 2);
  });

  testWidgets('ripple and focus ink are clipped to the pill (D16)', (
    tester,
  ) async {
    var taps = 0;
    await _pump(tester, onPressed: () => taps++);

    final ink = tester.widget<InkWell>(
      find.descendant(of: _pill, matching: find.byType(InkWell)),
    );
    expect(ink.borderRadius, BorderRadius.circular(16));
    expect(
      tester.getSize(
        find.descendant(of: _pill, matching: find.byType(InkWell)),
      ),
      Size(tester.getSize(_pill).width - 2, 30),
    );

    // Keyboard focus reaches the button and Enter activates it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      Focus.of(
        tester.element(find.descendant(of: _pill, matching: find.byType(Text))),
      ).hasPrimaryFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a narrow slot hides the button instead of overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 20,
              child: AccountFilterButton(accountName: null, onPressed: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(_pill, findsNothing);
    expect(
      tester.renderObject<RenderBox>(find.byType(AccountFilterButton)).size,
      const Size(20, 0),
    );
  });
}
