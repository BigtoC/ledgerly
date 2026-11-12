// test/unit/utils/icon_registry_test.dart
//
// Tests for `lib/core/utils/icon_registry.dart`. Covers:
//   - Task B-5: unknown / null / empty keys fall back to Icons.category
//     (the PRD.md 816-823 contract).
//   - Task B-6: every key in the Stream B seed contract (§4.3, §4.4)
//     resolves to a non-fallback IconData. A missing seed key means
//     M3 seed would render the fallback glyph for that row.
//   - Task B-7: keys are snake_case, map values are IconData.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/core/utils/icon_registry.dart';

void main() {
  group('iconForKey fallback', () {
    test('unknown key returns Icons.category (PRD 816-823 contract)', () {
      expect(iconForKey('this_key_does_not_exist'), Icons.category);
    });

    test('null returns Icons.category', () {
      expect(iconForKey(null), Icons.category);
    });

    test('empty string returns Icons.category', () {
      expect(iconForKey(''), Icons.category);
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
        // `Icons.category` (the fallback). That is only acceptable when
        // the key itself is 'category'.
        if (key != 'category') {
          expect(
            icon,
            isNot(Icons.category),
            reason:
                'Seed contract key "$key" is missing from kIconRegistry — '
                'M3 seed would render the fallback glyph for this row.',
          );
        } else {
          expect(icon, Icons.category);
        }
      });
    }
  });

  group('icon groups (issue #103)', () {
    test('groups appear in picker order', () {
      expect(kIconGroups.keys.toList(), <IconGroup>[
        IconGroup.food,
        IconGroup.drinks,
        IconGroup.transport,
        IconGroup.shopping,
        IconGroup.entertainment,
        IconGroup.home,
        IconGroup.electronics,
        IconGroup.medical,
        IconGroup.income,
        IconGroup.other,
      ]);
    });

    test('every registry key sits in exactly one group', () {
      final List<String> grouped = kIconGroups.values
          .expand((List<String> keys) => keys)
          .toList();
      expect(grouped.toSet().length, grouped.length, reason: 'duplicate key');
      expect(grouped.toSet(), kIconRegistry.keys.toSet());
    });

    test('existing keys keep their groups', () {
      expect(kIconGroups[IconGroup.food], contains('restaurant'));
      expect(kIconGroups[IconGroup.drinks], contains('local_cafe'));
      expect(kIconGroups[IconGroup.transport], contains('directions_car'));
      expect(kIconGroups[IconGroup.transport], contains('flight'));
      expect(kIconGroups[IconGroup.shopping], contains('shopping_bag'));
      expect(kIconGroups[IconGroup.shopping], contains('self_care'));
      expect(kIconGroups[IconGroup.entertainment], contains('movie'));
      expect(kIconGroups[IconGroup.home], contains('home'));
      expect(kIconGroups[IconGroup.electronics], contains('devices'));
      expect(kIconGroups[IconGroup.medical], contains('medical_services'));
      expect(
        kIconGroups[IconGroup.income],
        containsAll(<String>[
          'payments',
          'work',
          'trending_up',
          'redeem',
          'savings',
          'wallet',
        ]),
      );
      expect(
        kIconGroups[IconGroup.other],
        containsAll(<String>['school', 'more_horiz', 'category']),
      );
    });

    test('new keys resolve to the Icons.* glyph they are named after', () {
      const Map<String, IconData> added = <String, IconData>{
        'local_grocery_store': Icons.local_grocery_store,
        'soup_kitchen': Icons.soup_kitchen,
        'rice_bowl': Icons.rice_bowl,
        'icecream': Icons.icecream,
        'bakery_dining': Icons.bakery_dining,
        'set_meal': Icons.set_meal,
        'wine_bar': Icons.wine_bar,
        'emoji_food_beverage': Icons.emoji_food_beverage,
        'local_drink': Icons.local_drink,
        'directions_bus': Icons.directions_bus,
        'local_taxi': Icons.local_taxi,
        'local_gas_station': Icons.local_gas_station,
        'receipt_long': Icons.receipt_long,
        'local_parking': Icons.local_parking,
        'build': Icons.build,
        'content_cut': Icons.content_cut,
        'face_retouching_natural': Icons.face_retouching_natural,
        'card_giftcard': Icons.card_giftcard,
        'music_note': Icons.music_note,
        'checkroom': Icons.checkroom,
        'people': Icons.people,
        'design_services': Icons.design_services,
        'sports_esports': Icons.sports_esports,
        'confirmation_number': Icons.confirmation_number,
        'casino': Icons.casino,
        'landscape': Icons.landscape,
        'celebration': Icons.celebration,
        'menu_book': Icons.menu_book,
        'sports_baseball': Icons.sports_baseball,
        'fitness_center': Icons.fitness_center,
        'bolt': Icons.bolt,
        'favorite': Icons.favorite,
        'yard': Icons.yard,
        'smartphone': Icons.smartphone,
        'photo_camera': Icons.photo_camera,
        'laptop': Icons.laptop,
        'desktop_windows': Icons.desktop_windows,
        'local_hospital': Icons.local_hospital,
        'medication': Icons.medication,
        'monitor_heart': Icons.monitor_heart,
        'healing': Icons.healing,
        'monetization_on': Icons.monetization_on,
        'volunteer_activism': Icons.volunteer_activism,
        'local_offer': Icons.local_offer,
        'pets': Icons.pets,
        'star': Icons.star,
      };
      for (final MapEntry<String, IconData> entry in added.entries) {
        expect(iconForKey(entry.key), entry.value, reason: entry.key);
      }
    });
  });

  group('icon group colours (issue #103)', () {
    test('each group uses its seeded category colour', () {
      // Mirrors the seeded categories in lib/data/seed/first_run_seed.dart.
      expect(kIconGroupColors, <IconGroup, int>{
        IconGroup.food: CategoryPaletteIndex.red60,
        IconGroup.drinks: CategoryPaletteIndex.green40,
        IconGroup.transport: CategoryPaletteIndex.cyan70,
        IconGroup.shopping: CategoryPaletteIndex.purple30,
        IconGroup.entertainment: CategoryPaletteIndex.orange70,
        IconGroup.home: CategoryPaletteIndex.green80,
        IconGroup.electronics: CategoryPaletteIndex.blue30,
        IconGroup.medical: CategoryPaletteIndex.red50,
        IconGroup.income: CategoryPaletteIndex.yellow80,
        IconGroup.other: CategoryPaletteIndex.neutralVariant50,
      });
    });
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
