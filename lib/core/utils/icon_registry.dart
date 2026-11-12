// lib/core/utils/icon_registry.dart
import 'package:material_ui/material_ui.dart' show IconData, Icons;

import 'color_palette.dart';

/// -----------------------------------------------------------------------
/// ICON REGISTRY — stable string keys → Material Icons `IconData`.
/// -----------------------------------------------------------------------
/// `categories.icon` and `account_types.icon` are string keys. The UI
/// resolves them to real [IconData] at render time via [iconForKey].
///
/// Why indirect:
///   * `IconData` is not stable across Flutter / Material updates; storing
///     raw codepoints would orphan rows on every package bump.
///   * Keys are portable across backup/restore and across future icon
///     font swaps.
///
/// Keys are snake_case strings that match the canonical `Icons.*` Dart
/// identifier (e.g. the key `'restaurant'` resolves to `Icons.restaurant`).
/// Unknown / null / empty keys fall back to `Icons.category` (see PRD.md
/// → Icon & Color Registry, lines 816-823).
///
/// Adding a key:
///   1. Append to [kIconRegistry] below and place it in [kIconGroups].
///      Never remove a key — if a seeded row still references it,
///      removing orphans the DB.
///   2. Use only icons from Flutter's built-in `Icons` class — they use the
///      MaterialIcons font bundled with Flutter and are always available.
/// -----------------------------------------------------------------------

/// Stable-key → [IconData] map. See header for the add/remove policy.
///
/// Every seeded `categories.icon` and `account_types.icon` value in the
/// Stream B seed contract (docs/plans/m2-core-utilities/stream-b-icons-colors.md
/// §4.3, §4.4) must resolve through this map.
const Map<String, IconData> kIconRegistry = <String, IconData>{
  // Expense category roots (PRD.md 459-477).
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'directions_car': Icons.directions_car,
  'shopping_bag': Icons.shopping_bag,
  'home': Icons.home,
  'movie': Icons.movie,
  'medical_services': Icons.medical_services,
  'school': Icons.school,
  'self_care': Icons.spa,
  'flight': Icons.flight,
  'devices': Icons.devices,
  'more_horiz': Icons.more_horiz,
  'category': Icons.category,

  // Income category roots (PRD.md 479-491).
  'payments': Icons.payments,
  'work': Icons.work,
  'trending_up': Icons.trending_up,
  'redeem': Icons.redeem,
  'savings': Icons.savings,

  // Default account types (PRD.md 497-500).
  'wallet': Icons.wallet,
  // 'trending_up' above is shared with the Investment account type and the
  // Investment expense category.

  // Picker additions (issue #103).
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

/// Sections of the category icon picker, in display order.
enum IconGroup {
  food,
  drinks,
  transport,
  shopping,
  entertainment,
  home,
  electronics,
  medical,
  income,
  other,
}

/// Picker layout: each [IconGroup] → the registry keys shown under it, in
/// order. Every key in [kIconRegistry] belongs to exactly one group, so a
/// key added above must also be placed here.
const Map<IconGroup, List<String>> kIconGroups = <IconGroup, List<String>>{
  IconGroup.food: <String>[
    'restaurant',
    'local_grocery_store',
    'soup_kitchen',
    'rice_bowl',
    'icecream',
    'bakery_dining',
    'set_meal',
  ],
  IconGroup.drinks: <String>[
    'local_cafe',
    'wine_bar',
    'emoji_food_beverage',
    'local_drink',
  ],
  IconGroup.transport: <String>[
    'directions_bus',
    'flight',
    'directions_car',
    'local_taxi',
    'local_gas_station',
    'receipt_long',
    'local_parking',
    'build',
  ],
  IconGroup.shopping: <String>[
    'shopping_bag',
    'content_cut',
    'face_retouching_natural',
    'card_giftcard',
    'music_note',
    'checkroom',
    'people',
    'design_services',
    'self_care',
  ],
  IconGroup.entertainment: <String>[
    'sports_esports',
    'confirmation_number',
    'casino',
    'landscape',
    'celebration',
    'menu_book',
    'sports_baseball',
    'fitness_center',
    'movie',
  ],
  IconGroup.home: <String>['home', 'bolt', 'favorite', 'yard'],
  IconGroup.electronics: <String>[
    'smartphone',
    'photo_camera',
    'laptop',
    'desktop_windows',
    'devices',
  ],
  IconGroup.medical: <String>[
    'local_hospital',
    'medication',
    'monitor_heart',
    'healing',
    'medical_services',
  ],
  IconGroup.income: <String>[
    'payments',
    'work',
    'trending_up',
    'redeem',
    'savings',
    'monetization_on',
    'volunteer_activism',
    'wallet',
  ],
  IconGroup.other: <String>[
    'local_offer',
    'pets',
    'star',
    'school',
    'more_horiz',
    'category',
  ],
};

/// Palette index each [IconGroup] is drawn in, matching the seeded
/// category of the same name (`lib/data/seed/first_run_seed.dart`).
const Map<IconGroup, int> kIconGroupColors = <IconGroup, int>{
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
};

/// Resolves an icon string [key] to an [IconData].
///
/// Unknown / `null` / empty keys fall back to `Icons.category`. Never
/// throws — a corrupted row in the DB should still render *something*.
IconData iconForKey(String? key) => kIconRegistry[key] ?? Icons.category;
