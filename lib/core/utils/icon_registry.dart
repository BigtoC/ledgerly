// lib/core/utils/icon_registry.dart
import 'package:flutter/widgets.dart' show IconData;
import 'package:material_symbols_icons/symbols.dart';

/// -----------------------------------------------------------------------
/// ICON REGISTRY — stable string keys → Material Symbols `IconData`.
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
/// Keys are snake_case strings that match the canonical `Symbols.*` Dart
/// identifier (e.g. the key `'restaurant'` resolves to `Symbols.restaurant`).
/// Unknown / null / empty keys fall back to `Symbols.category` (see PRD.md
/// → Icon & Color Registry, lines 816-823).
///
/// Adding a key:
///   1. Append to [kIconRegistry] below. Never remove a key — if a seeded
///      row still references it, removing orphans the DB.
///   2. If the glyph is not in `material_symbols_icons ^4.2803.0`, bump
///      the package pin in `pubspec.yaml` in a separate PR.
/// -----------------------------------------------------------------------

/// Fallback icon returned by [iconForKey] on an unknown, null, or empty key.
const IconData kFallbackIcon = Symbols.category;

/// Stable-key → [IconData] map. See header for the add/remove policy.
///
/// Every seeded `categories.icon` and `account_types.icon` value in the
/// Stream B seed contract (docs/plans/m2-core-utilities/stream-b-icons-colors.md
/// §4.3, §4.4) must resolve through this map.
const Map<String, IconData> kIconRegistry = <String, IconData>{
  // Expense category roots (PRD.md 459-477).
  'restaurant': Symbols.restaurant,
  'local_cafe': Symbols.local_cafe,
  'directions_car': Symbols.directions_car,
  'shopping_bag': Symbols.shopping_bag,
  'home': Symbols.home,
  'movie': Symbols.movie,
  'medical_services': Symbols.medical_services,
  'school': Symbols.school,
  'self_care': Symbols.self_care,
  'flight': Symbols.flight,
  'devices': Symbols.devices,
  'more_horiz': Symbols.more_horiz,
  'category': Symbols.category,

  // Income category roots (PRD.md 479-491).
  'payments': Symbols.payments,
  'work': Symbols.work,
  'trending_up': Symbols.trending_up,
  'redeem': Symbols.redeem,
  'savings': Symbols.savings,

  // Default account types (PRD.md 497-500).
  'wallet': Symbols.wallet,
  // 'trending_up' above is shared with the Investment account type.
};

/// Resolves an icon string [key] to an [IconData].
///
/// Unknown / `null` / empty keys fall back to [kFallbackIcon]
/// (`Symbols.category`). Never throws — a corrupted row in the DB should
/// still render *something*.
IconData iconForKey(String? key) {
  if (key == null || key.isEmpty) return kFallbackIcon;
  return kIconRegistry[key] ?? kFallbackIcon;
}
