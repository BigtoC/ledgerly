// Resolves an [AccountType] to its user-facing display name.
//
// PRD → Default Account Types: "customName ?? l10n_key". Same pattern
// as `category_display.dart` in the Categories slice — seeded types
// (`accountType.cash`, `accountType.investment`) are mapped to their
// localized labels; custom rows fall back to `customName`. Unknown keys
// surface the raw key so orphaned rows still render something.

import '../../../data/models/account_type.dart';
import '../../../l10n/app_localizations.dart';

/// Resolves [type] to a display name using [l10n].
String accountTypeDisplayName(AccountType type, AppLocalizations l10n) {
  final custom = type.customName;
  if (custom != null && custom.trim().isNotEmpty) return custom;

  final key = type.l10nKey;
  if (key == null) return '';

  return switch (key) {
    'accountType.cash' => l10n.accountTypeCash,
    'accountType.investment' => l10n.accountTypeInvestment,
    _ => key,
  };
}
