// Seeded MD3 [ColorScheme] definitions for light + dark, per PRD -> Theme
// (lines 891-899). Both schemes derive from a single seed color so any
// future accent / tertiary adjustments flow from one knob.
//
// Splash visuals (sun background, rainbow gradient) are intentionally
// independent of this scheme; see PRD 899 and the Splash M5 slice.

import 'package:flutter/material.dart';

/// MD3 Baseline — Green 40 (`#006C35`). Reused from the category palette
/// (Stream B / PRD 464) so the shell seed coincides with a palette-registered
/// hex and no second MD3 color index is introduced at the shell level.
final Color _seed = Colors.grey[800]!;
const Color _primary = Colors.pinkAccent;
const Color _secondary = Colors.blueAccent;

/// Derived from `_seed` via `ColorScheme.fromSeed`; consumed by
/// `lightTheme` in `app_theme.dart` and nowhere else at shell level.
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: _seed,
  primary: _primary,
  secondary: _secondary,
  brightness: Brightness.light,
);

/// Derived from `_seed` via `ColorScheme.fromSeed`; consumed by
/// `darkTheme` in `app_theme.dart` and nowhere else at shell level.
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: _seed,
  primary: _primary,
  secondary: _secondary,
  brightness: Brightness.dark,
);
