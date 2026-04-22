// lib/core/utils/color_palette.dart
import 'package:flutter/material.dart' show Color;

/// -----------------------------------------------------------------------
/// APPEND-ONLY PALETTE — DO NOT REORDER. DO NOT REMOVE. DO NOT INSERT.
/// -----------------------------------------------------------------------
/// `categories.color` and `account_types.color` are integer indices into
/// [kCategoryColorPalette]. Reordering this list would retroactively remap
/// every user's category and account-type colours. Removing an entry would
/// orphan existing DB rows. Inserting at the middle does both.
///
/// Rules (enforced by code review, by the golden test in
/// `test/unit/utils/color_palette_test.dart`, and by
/// `docs/plans/implementation-plan.md` §9 risk #3):
///
///   1. New palette colours go at the END of the list. Always.
///   2. Existing indices never change meaning. A colour associated with
///      index 4 must stay at index 4 across every app version, forever.
///   3. Deprecating a colour means leaving it in place; new seeds must
///      pick a different index.
///   4. The corresponding [CategoryPaletteIndex] constant is added at the
///      same time as the list entry, with the same ordinal.
///
/// Source: Material Design 3 baseline palette
/// https://m3.material.io/styles/color/static/baseline
/// Cited by PRD.md → "Color Source — MD3 Baseline" (lines 453-457).
/// -----------------------------------------------------------------------

/// Ordered, append-only MD3 baseline palette. Treat as `const`.
const List<Color> kCategoryColorPalette = <Color>[
  Color(0xFFB3251E), // 0  Red 60
  Color(0xFF006C35), // 1  Green 40
  Color(0xFF00BBDF), // 2  Cyan 70
  Color(0xFF5629A4), // 3  Purple 30
  Color(0xFF80DA88), // 4  Green 80
  Color(0xFFFF8D41), // 5  Orange 70
  Color(0xFFDB372D), // 6  Red 50
  Color(0xFF04409F), // 7  Blue 30
  Color(0xFF79747E), // 8  Neutral Variant 50
  Color(0xFFFCBD00), // 9  Yellow 80
  Color(0xFFAEA9B4), // 10 Neutral Variant 70
];

/// Named indices for readability at the seed call site and in reviews.
///
/// M3 seed code SHOULD use these constants instead of bare ints so the
/// diff clearly communicates which colour is intended.
///
/// Append new names at the END and match the list above by ordinal.
abstract final class CategoryPaletteIndex {
  static const int red60 = 0;
  static const int green40 = 1;
  static const int cyan70 = 2;
  static const int purple30 = 3;
  static const int green80 = 4;
  static const int orange70 = 5;
  static const int red50 = 6;
  static const int blue30 = 7;
  static const int neutralVariant50 = 8;
  static const int yellow80 = 9;
  static const int neutralVariant70 = 10;
}

/// Resolves a palette index to a concrete [Color].
///
/// Out-of-range or negative indices clamp to
/// [CategoryPaletteIndex.neutralVariant50] (grey 50) as a safe, visually
/// neutral fallback. An unknown index in the wild usually means a corrupt
/// restore or a forward-compat DB from a future app version — we render
/// *something* rather than throwing.
Color colorForIndex(int index) {
  if (index < 0 || index >= kCategoryColorPalette.length) {
    return kCategoryColorPalette[CategoryPaletteIndex.neutralVariant50];
  }
  return kCategoryColorPalette[index];
}
