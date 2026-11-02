// Analysis redesign theme tokens, motion and text helper.
//
// Values come from docs/design/analysis-redesign/Main.dc.html (LIGHT / DARK)
// via the spec's "Theme tokens" table
// (docs/superpowers/specs/2026-11-02-analysis-redesign-design.md). The
// shell's nav / navIndicator tokens are reference only and not included.

import 'package:flutter/material.dart';

/// Exact Analysis-screen colours, registered on `lightTheme` / `darkTheme`.
@immutable
class AnalysisColors extends ThemeExtension<AnalysisColors> {
  const AnalysisColors({
    required this.bg,
    required this.card,
    required this.line,
    required this.outline,
    required this.track,
    required this.thumb,
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.off,
    required this.sel,
    required this.onBg,
    required this.onFg,
    required this.exp,
    required this.expText,
    required this.expTint,
    required this.inc,
    required this.incText,
    required this.incTint,
    required this.thumbShadow,
  });

  static const AnalysisColors light = AnalysisColors(
    bg: Color(0xFFF3F3F3),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE3E3E3),
    outline: Color(0xFFC4C4C4),
    track: Color(0xFFEAEAEA),
    thumb: Color(0xFFFFFFFF),
    fg: Color(0xFF1B1B1B),
    fg2: Color(0xFF474747),
    fg3: Color(0xFF5E5E5E),
    off: Color(0xFFBDBDBD),
    sel: Color(0xFFF0F0F0),
    onBg: Color(0xFF1B1B1B),
    onFg: Color(0xFFFFFFFF),
    exp: Color(0xFFFF4081),
    expText: Color(0xFFC2185B),
    expTint: Color(0xFFFFF0F5),
    inc: Color(0xFF43A047),
    incText: Color(0xFF1B5E20),
    incTint: Color(0xFFEFF7EF),
    // 0 1px 3px rgba(0,0,0,.12), 0 1px 1px rgba(0,0,0,.06)
    thumbShadow: <BoxShadow>[
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
    ],
  );

  static const AnalysisColors dark = AnalysisColors(
    bg: Color(0xFF131313),
    card: Color(0xFF1E1E1E),
    line: Color(0xFF2E2E2E),
    outline: Color(0xFF4A4A4A),
    track: Color(0xFF2A2A2A),
    thumb: Color(0xFF3D3D3D),
    fg: Color(0xFFE6E6E6),
    fg2: Color(0xFFC6C6C6),
    fg3: Color(0xFFA3A3A3),
    off: Color(0xFF555555),
    sel: Color(0xFF2C2C2C),
    onBg: Color(0xFFE6E6E6),
    onFg: Color(0xFF1B1B1B),
    exp: Color(0xFFFF4081),
    expText: Color(0xFFFF79A3),
    expTint: Color(0xFF35161F),
    inc: Color(0xFF66BB6A),
    incText: Color(0xFF81C784),
    incTint: Color(0xFF16271A),
    // 0 1px 2px rgba(0,0,0,.5)
    thumbShadow: <BoxShadow>[
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.5),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
  );

  /// The active theme's tokens; both app themes register them.
  static AnalysisColors of(BuildContext context) =>
      Theme.of(context).extension<AnalysisColors>()!;

  final Color bg;
  final Color card;
  final Color line;
  final Color outline;
  final Color track;
  final Color thumb;
  final Color fg;
  final Color fg2;
  final Color fg3;
  final Color off;
  final Color sel;
  final Color onBg;
  final Color onFg;
  final Color exp;
  final Color expText;
  final Color expTint;
  final Color inc;
  final Color incText;
  final Color incTint;
  final List<BoxShadow> thumbShadow;

  @override
  AnalysisColors copyWith({
    Color? bg,
    Color? card,
    Color? line,
    Color? outline,
    Color? track,
    Color? thumb,
    Color? fg,
    Color? fg2,
    Color? fg3,
    Color? off,
    Color? sel,
    Color? onBg,
    Color? onFg,
    Color? exp,
    Color? expText,
    Color? expTint,
    Color? inc,
    Color? incText,
    Color? incTint,
    List<BoxShadow>? thumbShadow,
  }) {
    return AnalysisColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      line: line ?? this.line,
      outline: outline ?? this.outline,
      track: track ?? this.track,
      thumb: thumb ?? this.thumb,
      fg: fg ?? this.fg,
      fg2: fg2 ?? this.fg2,
      fg3: fg3 ?? this.fg3,
      off: off ?? this.off,
      sel: sel ?? this.sel,
      onBg: onBg ?? this.onBg,
      onFg: onFg ?? this.onFg,
      exp: exp ?? this.exp,
      expText: expText ?? this.expText,
      expTint: expTint ?? this.expTint,
      inc: inc ?? this.inc,
      incText: incText ?? this.incText,
      incTint: incTint ?? this.incTint,
      thumbShadow: thumbShadow ?? this.thumbShadow,
    );
  }

  @override
  AnalysisColors lerp(ThemeExtension<AnalysisColors>? other, double t) {
    if (other is! AnalysisColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AnalysisColors(
      bg: c(bg, other.bg),
      card: c(card, other.card),
      line: c(line, other.line),
      outline: c(outline, other.outline),
      track: c(track, other.track),
      thumb: c(thumb, other.thumb),
      fg: c(fg, other.fg),
      fg2: c(fg2, other.fg2),
      fg3: c(fg3, other.fg3),
      off: c(off, other.off),
      sel: c(sel, other.sel),
      onBg: c(onBg, other.onBg),
      onFg: c(onFg, other.onFg),
      exp: c(exp, other.exp),
      expText: c(expText, other.expText),
      expTint: c(expTint, other.expTint),
      inc: c(inc, other.inc),
      incText: c(incText, other.incText),
      incTint: c(incTint, other.incTint),
      // lerpList pads the shorter list with zero-sized shadows, so return
      // the exact lists at the endpoints.
      thumbShadow: t == 0
          ? thumbShadow
          : t == 1
          ? other.thumbShadow
          : BoxShadow.lerpList(thumbShadow, other.thumbShadow, t)!,
    );
  }
}

/// Shared Analysis motion: `cubic-bezier(.2,.6,.2,1)` 200 ms for state
/// colour changes, `cubic-bezier(.16,1,.3,1)` 360 ms for bar heights and
/// share-bar widths, and 280 ms on the emphasized curve for the search
/// field expanding.
abstract final class AnalysisMotion {
  static const Curve standardCurve = Cubic(0.2, 0.6, 0.2, 1);
  static const Duration standardDuration = Duration(milliseconds: 200);
  static const Curve emphasizedCurve = Cubic(0.16, 1, 0.3, 1);
  static const Duration emphasizedDuration = Duration(milliseconds: 360);
  static const Duration searchExpandDuration = Duration(milliseconds: 280);
}

/// A design text style: CSS `font-size` / `line-height` in logical pixels,
/// with half-leading like CSS, and tabular figures for amounts.
TextStyle analysisText({
  required double size,
  required double lineHeight,
  FontWeight weight = FontWeight.w400,
  required Color color,
  bool tabular = false,
}) {
  return TextStyle(
    fontSize: size,
    height: lineHeight / size,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: weight,
    color: color,
    fontFeatures: tabular
        ? const <FontFeature>[FontFeature.tabularFigures()]
        : null,
  );
}
