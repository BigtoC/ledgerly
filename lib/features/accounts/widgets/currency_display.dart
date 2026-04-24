// Resolves a [Currency] to a user-facing display name.
//
// PRD → currencies: `name_l10n_key` is the SSOT for seeded currency
// names; `custom_name` overrides. Unknown / missing keys fall back to
// the ISO code so orphaned rows still render.

import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';

String currencyDisplayName(Currency currency, AppLocalizations l10n) {
  final custom = currency.customName;
  if (custom != null && custom.trim().isNotEmpty) return custom;

  // MVP ships ~11 fiats. Token i18n is Phase 2 — fall back to the ISO
  // code when a `nameL10nKey` is absent or not yet mapped.
  return switch (currency.nameL10nKey) {
    _ => currency.code,
  };
}
