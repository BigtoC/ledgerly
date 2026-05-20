// Resolves a [Category] to its user-facing display name.
//
// PRD.md → Default Categories: "customName ?? l10n_key". Seeded rows with
// a live `l10nKey` are mapped to the matching `AppLocalizations` entry.
// Custom rows (`l10nKey == null`) always use `customName` directly — user
// input is not localized (PRD → Internationalization). Unknown
// l10n-keys fall back to the raw key so orphaned rows still render
// something.

import '../../../data/models/category.dart';
import '../../../l10n/app_localizations.dart';

/// Resolves [category] to a display name using [l10n].
String categoryDisplayName(Category category, AppLocalizations l10n) {
  final custom = category.customName;
  if (custom != null && custom.trim().isNotEmpty) return custom;

  final key = category.l10nKey;
  if (key == null) return '';

  return categoryDisplayNameForKey(key, l10n);
}

/// Resolves a seeded `category.*` l10n key to its localized display name.
/// Used by chart widgets where only the key string is available (the
/// controller serializes labels without an `AppLocalizations` instance).
/// Unknown keys fall through to the raw string so orphaned rows still
/// render something.
String categoryDisplayNameForKey(String key, AppLocalizations l10n) {
  return switch (key) {
    'category.food' => l10n.categoryFood,
    'category.drinks' => l10n.categoryDrinks,
    'category.transportation' => l10n.categoryTransportation,
    'category.shopping' => l10n.categoryShopping,
    'category.housing' => l10n.categoryHousing,
    'category.entertainment' => l10n.categoryEntertainment,
    'category.medical' => l10n.categoryMedical,
    'category.education' => l10n.categoryEducation,
    'category.personal' => l10n.categoryPersonal,
    'category.travel' => l10n.categoryTravel,
    'category.threeC' => l10n.categoryThreeC,
    'category.miscellaneous' => l10n.categoryMiscellaneous,
    'category.other' => l10n.categoryOther,
    'category.income.salary' => l10n.categoryIncomeSalary,
    'category.income.freelance' => l10n.categoryIncomeFreelance,
    'category.income.investment' => l10n.categoryIncomeInvestment,
    'category.income.gift' => l10n.categoryIncomeGift,
    'category.income.other' => l10n.categoryIncomeOther,
    _ => key,
  };
}
