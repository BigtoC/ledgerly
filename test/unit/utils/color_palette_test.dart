// test/unit/utils/color_palette_test.dart
//
// Tests for `lib/core/utils/color_palette.dart`. Covers:
//   - Task B-1: palette is non-empty.
//   - Task B-2: indices resolve to the PRD-specified MD3 baseline hexes.
//   - Task B-3: `colorForIndex` clamps out-of-range / negative indices to
//     the neutral-grey fallback instead of throwing.
//   - Task B-4: append-only golden test — the first N palette entries are
//     frozen and must never change hex. Adding new colours is allowed,
//     but only at the END. See `color_palette.dart` header for the rule.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/color_palette.dart';

void main() {
  group('kCategoryColorPalette', () {
    test('exposes at least one MD3 baseline colour', () {
      expect(kCategoryColorPalette, isNotEmpty);
    });

    test('palette indices resolve to PRD-specified MD3 baseline hexes', () {
      // PRD.md 459-491, 497-500 — MD3 baseline hexes.
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.red60].toARGB32(),
        0xFFF55E57,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.green40].toARGB32(),
        0xFF006C35,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.cyan70].toARGB32(),
        0xFF00BBDF,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.purple30].toARGB32(),
        0xFF5629A4,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.green80].toARGB32(),
        0xFF80DA88,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.orange70].toARGB32(),
        0xFFFF8D41,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.red50].toARGB32(),
        0xFFDB372D,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.blue30].toARGB32(),
        0xFF04409F,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.neutralVariant50].toARGB32(),
        0xFF79747E,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.yellow80].toARGB32(),
        0xFFFCBD00,
      );
      expect(
        kCategoryColorPalette[CategoryPaletteIndex.neutralVariant70].toARGB32(),
        0xFFAEA9B4,
      );
    });
  });

  group('colorForIndex', () {
    test('returns the entry at a valid index', () {
      expect(colorForIndex(0), kCategoryColorPalette[0]);
      expect(
        colorForIndex(kCategoryColorPalette.length - 1),
        kCategoryColorPalette.last,
      );
    });

    test('out-of-range index clamps to Neutral Variant 50 (grey fallback)', () {
      final Color fallback =
          kCategoryColorPalette[CategoryPaletteIndex.neutralVariant50];
      expect(colorForIndex(-1), fallback);
      expect(colorForIndex(9999), fallback);
      expect(colorForIndex(kCategoryColorPalette.length), fallback);
    });
  });

  group('palette is append-only (GOLDEN — see color_palette.dart header)', () {
    // PRD.md 453-506 + Stream B plan §4.1. Editing this list is a CONTRACT
    // CHANGE — every user's seeded category/account-type colour is keyed
    // to a specific index. Only append new hexes; never reorder / remove.
    const List<int> goldenHexes = <int>[
      0xFFF55E57, // 0  Red 60
      0xFF006C35, // 1  Green 40
      0xFF00BBDF, // 2  Cyan 70
      0xFF5629A4, // 3  Purple 30
      0xFF80DA88, // 4  Green 80
      0xFFFF8D41, // 5  Orange 70
      0xFFDB372D, // 6  Red 50
      0xFF04409F, // 7  Blue 30
      0xFF79747E, // 8  Neutral Variant 50
      0xFFFCBD00, // 9  Yellow 80
      0xFFAEA9B4, // 10 Neutral Variant 70
    ];

    test('first N indices match the frozen golden list', () {
      expect(
        kCategoryColorPalette.length,
        greaterThanOrEqualTo(goldenHexes.length),
        reason:
            'Palette shrunk — an existing index was removed. This breaks '
            'every user DB referencing that index.',
      );
      for (int i = 0; i < goldenHexes.length; i++) {
        expect(
          kCategoryColorPalette[i].toARGB32(),
          goldenHexes[i],
          reason:
              'Palette index $i changed hex. Palette is APPEND-ONLY; new '
              'colours must go at the END. See color_palette.dart header.',
        );
      }
    });
  });
}
