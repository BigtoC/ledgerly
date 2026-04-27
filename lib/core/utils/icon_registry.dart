// lib/core/utils/icon_registry.dart
import 'package:flutter/material.dart' show IconData, Icons;

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
///   1. Append to [kIconRegistry] below. Never remove a key — if a seeded
///      row still references it, removing orphans the DB.
///   2. Use only icons from Flutter's built-in `Icons` class — they use the
///      MaterialIcons font bundled with Flutter and are always available.
/// -----------------------------------------------------------------------

/// Fallback icon returned by [iconForKey] on an unknown, null, or empty key.
const IconData kFallbackIcon = Icons.category;

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
  // 'trending_up' above is shared with the Investment account type.
};

/// Resolves an icon string [key] to an [IconData].
///
/// Unknown / `null` / empty keys fall back to [kFallbackIcon]
/// (`Icons.category`). Never throws — a corrupted row in the DB should
/// still render *something*.
IconData iconForKey(String? key) {
  if (key == null || key.isEmpty) return kFallbackIcon;
  return kIconRegistry[key] ?? kFallbackIcon;
}
