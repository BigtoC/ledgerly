// Pins the Analysis redesign theme tokens to the spec's "Theme tokens"
// table (docs/superpowers/specs/2026-11-02-analysis-redesign-design.md),
// whose values come from docs/design/analysis-redesign/Main.dc.html.

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/ui/core/theme/analysis_colors.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';

Map<String, Color> _tokens(AnalysisColors c) => <String, Color>{
  'bg': c.bg,
  'card': c.card,
  'line': c.line,
  'outline': c.outline,
  'track': c.track,
  'thumb': c.thumb,
  'fg': c.fg,
  'fg2': c.fg2,
  'fg3': c.fg3,
  'off': c.off,
  'sel': c.sel,
  'onBg': c.onBg,
  'onFg': c.onFg,
  'exp': c.exp,
  'expText': c.expText,
  'expTint': c.expTint,
  'inc': c.inc,
  'incText': c.incText,
  'incTint': c.incTint,
};

void main() {
  group('AnalysisColors tokens', () {
    test('light values match the spec table', () {
      expect(_tokens(AnalysisColors.light), <String, Color>{
        'bg': const Color(0xFFF3F3F3),
        'card': const Color(0xFFFFFFFF),
        'line': const Color(0xFFE3E3E3),
        'outline': const Color(0xFFC4C4C4),
        'track': const Color(0xFFEAEAEA),
        'thumb': const Color(0xFFFFFFFF),
        'fg': const Color(0xFF1B1B1B),
        'fg2': const Color(0xFF474747),
        'fg3': const Color(0xFF5E5E5E),
        'off': const Color(0xFFBDBDBD),
        'sel': const Color(0xFFF0F0F0),
        'onBg': const Color(0xFF1B1B1B),
        'onFg': const Color(0xFFFFFFFF),
        'exp': const Color(0xFFFF4081),
        'expText': const Color(0xFFC2185B),
        'expTint': const Color(0xFFFFF0F5),
        'inc': const Color(0xFF43A047),
        'incText': const Color(0xFF1B5E20),
        'incTint': const Color(0xFFEFF7EF),
      });
    });

    test('dark values match the spec table', () {
      expect(_tokens(AnalysisColors.dark), <String, Color>{
        'bg': const Color(0xFF131313),
        'card': const Color(0xFF1E1E1E),
        'line': const Color(0xFF2E2E2E),
        'outline': const Color(0xFF4A4A4A),
        'track': const Color(0xFF2A2A2A),
        'thumb': const Color(0xFF3D3D3D),
        'fg': const Color(0xFFE6E6E6),
        'fg2': const Color(0xFFC6C6C6),
        'fg3': const Color(0xFFA3A3A3),
        'off': const Color(0xFF555555),
        'sel': const Color(0xFF2C2C2C),
        'onBg': const Color(0xFFE6E6E6),
        'onFg': const Color(0xFF1B1B1B),
        'exp': const Color(0xFFFF4081),
        'expText': const Color(0xFFFF79A3),
        'expTint': const Color(0xFF35161F),
        'inc': const Color(0xFF66BB6A),
        'incText': const Color(0xFF81C784),
        'incTint': const Color(0xFF16271A),
      });
    });

    test('light thumb shadow is 0 1px 3px .12 + 0 1px 1px .06', () {
      expect(AnalysisColors.light.thumbShadow, const <BoxShadow>[
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.12),
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.06),
          offset: Offset(0, 1),
          blurRadius: 1,
        ),
      ]);
    });

    test('dark thumb shadow is 0 1px 2px .5', () {
      expect(AnalysisColors.dark.thumbShadow, const <BoxShadow>[
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.5),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ]);
    });
  });

  group('AnalysisColors theme wiring', () {
    test('lightTheme and darkTheme carry the extension', () {
      expect(
        lightTheme.extension<AnalysisColors>(),
        same(AnalysisColors.light),
      );
      expect(darkTheme.extension<AnalysisColors>(), same(AnalysisColors.dark));
    });

    testWidgets('of(context) reads the active theme', (tester) async {
      late AnalysisColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              resolved = AnalysisColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved, same(AnalysisColors.dark));
    });
  });

  group('AnalysisColors lerp and copyWith', () {
    test('lerp returns each endpoint at t = 0 and t = 1', () {
      final atStart = AnalysisColors.light.lerp(AnalysisColors.dark, 0);
      final atEnd = AnalysisColors.light.lerp(AnalysisColors.dark, 1);
      expect(_tokens(atStart), _tokens(AnalysisColors.light));
      expect(atStart.thumbShadow, AnalysisColors.light.thumbShadow);
      expect(_tokens(atEnd), _tokens(AnalysisColors.dark));
      expect(atEnd.thumbShadow, AnalysisColors.dark.thumbShadow);

      // The two shadow lists differ in length; neither direction may keep
      // a leftover zero-sized shadow at an endpoint.
      final reverseStart = AnalysisColors.dark.lerp(AnalysisColors.light, 0);
      final reverseEnd = AnalysisColors.dark.lerp(AnalysisColors.light, 1);
      expect(reverseStart.thumbShadow, AnalysisColors.dark.thumbShadow);
      expect(reverseEnd.thumbShadow, AnalysisColors.light.thumbShadow);
    });

    test('lerp with a non-AnalysisColors other returns this', () {
      expect(AnalysisColors.light.lerp(null, 0.5), same(AnalysisColors.light));
    });

    test('copyWith replaces only the given token', () {
      final copy = AnalysisColors.light.copyWith(fg: const Color(0xFF000000));
      expect(copy.fg, const Color(0xFF000000));
      expect(
        Map.of(_tokens(copy))..remove('fg'),
        Map.of(_tokens(AnalysisColors.light))..remove('fg'),
      );
      expect(copy.thumbShadow, AnalysisColors.light.thumbShadow);
    });
  });

  group('AnalysisMotion', () {
    test('standard, emphasized and search-expand values', () {
      expect(AnalysisMotion.standardCurve, const Cubic(0.2, 0.6, 0.2, 1));
      expect(
        AnalysisMotion.standardDuration,
        const Duration(milliseconds: 200),
      );
      expect(AnalysisMotion.emphasizedCurve, const Cubic(0.16, 1, 0.3, 1));
      expect(
        AnalysisMotion.emphasizedDuration,
        const Duration(milliseconds: 360),
      );
      expect(
        AnalysisMotion.searchExpandDuration,
        const Duration(milliseconds: 280),
      );
    });
  });

  group('analysisText', () {
    test('maps the CSS line height to half-leading height', () {
      final style = analysisText(
        size: 13,
        lineHeight: 18,
        weight: FontWeight.w500,
        color: AnalysisColors.light.fg2,
      );
      expect(style.fontSize, 13);
      expect(style.height, 18 / 13);
      expect(style.leadingDistribution, TextLeadingDistribution.even);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, AnalysisColors.light.fg2);
      expect(style.fontFeatures, isNull);
    });

    test('defaults to w400', () {
      final style = analysisText(
        size: 16,
        lineHeight: 24,
        color: AnalysisColors.light.fg,
      );
      expect(style.fontWeight, FontWeight.w400);
    });

    test('tabular adds tabular figures', () {
      final style = analysisText(
        size: 22,
        lineHeight: 28,
        weight: FontWeight.w700,
        color: AnalysisColors.light.fg,
        tabular: true,
      );
      expect(style.fontFeatures, const <FontFeature>[
        FontFeature.tabularFigures(),
      ]);
    });

    test('sets letter spacing to 0', () {
      final style = analysisText(
        size: 13,
        lineHeight: 18,
        color: AnalysisColors.light.fg,
      );
      expect(style.letterSpacing, 0);
    });

    testWidgets('renders with letter spacing 0 under the Material theme', (
      tester,
    ) async {
      // Scaffold's Material sets an ambient bodyMedium (letter spacing 0.25)
      // that the Text would otherwise inherit.
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Text(
              'Total',
              style: analysisText(
                size: 13,
                lineHeight: 18,
                color: AnalysisColors.light.fg,
              ),
            ),
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Total'),
      );
      expect(paragraph.text.style!.letterSpacing, 0);
    });
  });
}
