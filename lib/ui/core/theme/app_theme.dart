// `lightTheme` and `darkTheme` per PRD -> Theme (lines 891-899).
//
// The knob allowlist here is deliberately small: the M2 shell ships the
// bare minimum so M5 slices don't have to unpick shell defaults. Per-widget
// theme overrides (AppBar, FAB, BottomNav, Dialog, InputDecoration, etc.)
// are M5's responsibility.
//
// A Riverpod `themeModeProvider` that watches `user_preferences` and rebuilds
// MaterialApp on theme change lands in M4 (`app/app.dart`, `app/bootstrap.dart`).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'analysis_colors.dart';
import 'color_schemes.dart';

ThemeData _base(ColorScheme scheme, AnalysisColors analysisColors) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    typography: Typography.material2021(platform: defaultTargetPlatform),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
    extensions: <ThemeExtension<dynamic>>[analysisColors],
  );
}

/// Light-mode `ThemeData` consumed by `MaterialApp.theme`.
final ThemeData lightTheme = _base(lightColorScheme, AnalysisColors.light);

/// Dark-mode `ThemeData` consumed by `MaterialApp.darkTheme`.
final ThemeData darkTheme = _base(darkColorScheme, AnalysisColors.dark);
