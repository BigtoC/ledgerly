// test/unit/utils/icon_registry_test.dart
//
// Tests for `lib/core/utils/icon_registry.dart`. Covers:
//   - Task B-5: unknown / null / empty keys fall back to Symbols.category
//     (the PRD.md 816-823 contract).
//   - Task B-6: every key in the Stream B seed contract (§4.3, §4.4)
//     resolves to a non-fallback IconData. A missing seed key means
//     M3 seed would render the fallback glyph for that row.
//   - Task B-7: keys are snake_case, map values are IconData.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/icon_registry.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  group('iconForKey fallback', () {
    test('unknown key returns Symbols.category (PRD 816-823 contract)', () {
      expect(iconForKey('this_key_does_not_exist'), Symbols.category);
    });

    test('null returns Symbols.category', () {
      expect(iconForKey(null), Symbols.category);
    });

    test('empty string returns Symbols.category', () {
      expect(iconForKey(''), Symbols.category);
    });

    test('kFallbackIcon is exposed as Symbols.category', () {
      expect(kFallbackIcon, Symbols.category);
    });
  });

  group('iconForKey resolves every key in the seed contract (§4.3, §4.4)', () {
    // Source: docs/plans/m2-core-utilities/stream-b-icons-colors.md §4.3/§4.4.
    // Keeping this list inline (not importing from a shared constant) is
    // intentional — the test is the contract boundary; diverging from the
    // map means the test must change too, which forces review.
    const List<String> seededKeys = <String>[
      // Expense categories (PRD 459-477).
      'restaurant',
      'local_cafe',
      'directions_car',
      'shopping_bag',
      'home',
      'movie',
      'medical_services',
      'school',
      'self_care',
      'flight',
      'devices',
      'more_horiz',
      'category',
      // Income categories (PRD 479-491).
      'payments',
      'work',
      'trending_up',
      'redeem',
      'savings',
      // Default account types (PRD 497-500).
      'wallet',
      // 'trending_up' is shared with the Investment account type — already
      // covered above.
    ];

    for (final String key in seededKeys) {
      test('"$key" resolves to a non-fallback IconData', () {
        final IconData icon = iconForKey(key);
        // If the key is missing from `kIconRegistry`, `iconForKey` returns
        // `Symbols.category` (the fallback). That is only acceptable when
        // the key itself is 'category'.
        if (key != 'category') {
          expect(
            icon,
            isNot(Symbols.category),
            reason:
                'Seed contract key "$key" is missing from kIconRegistry — '
                'M3 seed would render the fallback glyph for this row.',
          );
        } else {
          expect(icon, Symbols.category);
        }
      });
    }
  });

  group('registry hygiene', () {
    test('registry keys are snake_case and values are IconData', () {
      for (final MapEntry<String, IconData> entry in kIconRegistry.entries) {
        expect(
          entry.key,
          matches(RegExp(r'^[a-z][a-z0-9_]*$')),
          reason: 'Icon registry keys must be snake_case.',
        );
        expect(entry.value, isA<IconData>());
      }
    });
  });
}
