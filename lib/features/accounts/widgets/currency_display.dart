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

  // MVP ships 11 seeded fiats. Token i18n is Phase 2 — fall back to the
  // ISO code when a `nameL10nKey` is absent or not yet mapped.
  // Switch arms must match `nameL10nKey` DB values from first_run_seed.dart.
  return switch (currency.nameL10nKey) {
    'currency.usd' => l10n.currencyUsd,
    'currency.eur' => l10n.currencyEur,
    'currency.jpy' => l10n.currencyJpy,
    'currency.twd' => l10n.currencyTwd,
    'currency.cny' => l10n.currencyCny,
    'currency.hkd' => l10n.currencyHkd,
    'currency.gbp' => l10n.currencyGbp,
    'currency.cad' => l10n.currencyCad,
    'currency.sgd' => l10n.currencySgd,
    'currency.aud' => l10n.currencyAud,
    'currency.nzd' => l10n.currencyNzd,
    _ => currency.code,
  };
}
