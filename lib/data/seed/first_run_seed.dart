// First-run seed routine.
//
// See `docs/plans/m3-repositories-seed/stream-c-preferences-seed-migration.md`
// §2 for the full specification.
//
// Orchestrates the six seed steps inside a single Drift transaction so a
// mid-step failure rolls back every write and leaves the DB empty again
// (risk-4 guardrail, Stream C plan §9.1):
//
//   Step 0 — Idempotency gate (`preferences.getFirstRunComplete()`).
//   Step 1 — Seed 11 currencies (Stream C plan §2.3 Step 1 + §12 Q6).
//   Step 2 — Resolve `default_currency` from `LocaleService.deviceLocale`.
//   Step 3 — Seed 18 default categories (13 expense + 5 income).
//   Step 4 — Seed 2 default account types (Cash, Investment).
//   Step 5 — Seed 1 Cash account at the resolved default currency.
//   Step 6 — Seed 8 `user_preferences` keys (incl. `default_account_id`
//            wired to the Cash account's row id per §12 Q2).
//   Step 7 — `markFirstRunComplete()` — runs LAST inside the transaction.
//
// Layer-boundary rule (Stream C plan §2.1): this file lives in
// `lib/data/seed/` (not in `lib/data/repositories/`). It calls the sibling
// repository interfaces only — no DAO imports. Drift's `db.transaction`
// hook makes every repository call on the same zone use the transactional
// executor, which is the standard Drift pattern for cross-repo atomicity.

import 'package:flutter/material.dart' show ThemeMode;

import '../../core/utils/color_palette.dart';
import '../database/app_database.dart' show AppDatabase;
import '../models/account.dart';
import '../models/category.dart';
import '../models/currency.dart';
import '../repositories/account_repository.dart';
import '../repositories/account_type_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/currency_repository.dart';
import '../repositories/user_preferences_repository.dart';
import '../services/locale_service.dart';

/// Generic seed-phase failure. Non-domain-specific — sibling repository
/// exceptions (currency, category, …) still surface as their concrete
/// typed exceptions. This is only used for "seed invariant violated"
/// conditions that are not themselves a repository error.
class FirstRunSeedException implements Exception {
  const FirstRunSeedException(this.message);
  final String message;

  @override
  String toString() => 'FirstRunSeedException: $message';
}

// ---------- Seed row data ----------
//
// Kept as top-level constants so tests can probe them directly. The list
// order doubles as the `sort_order` assignment — index 0 → `sortOrder 0`.

/// 11 seeded currencies (Stream C plan §2.3 Step 1, §12 Q6).
const List<Currency> _kSeededCurrencies = <Currency>[
  Currency(
    code: 'USD',
    decimals: 2,
    symbol: r'$',
    nameL10nKey: 'currency.usd',
    sortOrder: 0,
  ),
  Currency(
    code: 'EUR',
    decimals: 2,
    symbol: '€',
    nameL10nKey: 'currency.eur',
    sortOrder: 1,
  ),
  Currency(
    code: 'JPY',
    decimals: 0,
    symbol: '¥',
    nameL10nKey: 'currency.jpy',
    sortOrder: 2,
  ),
  Currency(
    code: 'TWD',
    decimals: 2,
    symbol: r'NT$',
    nameL10nKey: 'currency.twd',
    sortOrder: 3,
  ),
  Currency(
    code: 'CNY',
    decimals: 2,
    symbol: '¥',
    nameL10nKey: 'currency.cny',
    sortOrder: 4,
  ),
  Currency(
    code: 'HKD',
    decimals: 2,
    symbol: r'HK$',
    nameL10nKey: 'currency.hkd',
    sortOrder: 5,
  ),
  Currency(
    code: 'GBP',
    decimals: 2,
    symbol: '£',
    nameL10nKey: 'currency.gbp',
    sortOrder: 6,
  ),
  Currency(
    code: 'CAD',
    decimals: 2,
    symbol: r'CA$',
    nameL10nKey: 'currency.cad',
    sortOrder: 7,
  ),
  Currency(
    code: 'SGD',
    decimals: 2,
    symbol: r'S$',
    nameL10nKey: 'currency.sgd',
    sortOrder: 8,
  ),
  Currency(
    code: 'AUD',
    decimals: 2,
    symbol: r'A$',
    nameL10nKey: 'currency.aud',
    sortOrder: 9,
  ),
  Currency(
    code: 'NZD',
    decimals: 2,
    symbol: r'NZ$',
    nameL10nKey: 'currency.nzd',
    sortOrder: 10,
  ),
];

/// Seeded category row template. Kept internal — callers only see the
/// repo-side effect.
class _SeededCategory {
  const _SeededCategory({
    required this.l10nKey,
    required this.icon,
    required this.color,
    required this.type,
    required this.sortOrder,
  });
  final String l10nKey;
  final String icon;
  final int color;
  final CategoryType type;
  final int sortOrder;
}

/// 18 seeded categories (13 expense + 5 income). Icon keys reconcile
/// against the canonical Stream B registry (`directions_car` for
/// transportation, `savings` for income.other — Stream C plan §2.3 Step 3
/// "reconcile with Stream B" clause).
const List<_SeededCategory> _kSeededCategories = <_SeededCategory>[
  // Expense categories (PRD 464–476).
  _SeededCategory(
    l10nKey: 'category.food',
    icon: 'restaurant',
    color: CategoryPaletteIndex.red60,
    type: CategoryType.expense,
    sortOrder: 0,
  ),
  _SeededCategory(
    l10nKey: 'category.drinks',
    icon: 'local_cafe',
    color: CategoryPaletteIndex.green40,
    type: CategoryType.expense,
    sortOrder: 1,
  ),
  _SeededCategory(
    l10nKey: 'category.transportation',
    icon: 'directions_car',
    color: CategoryPaletteIndex.cyan70,
    type: CategoryType.expense,
    sortOrder: 2,
  ),
  _SeededCategory(
    l10nKey: 'category.shopping',
    icon: 'shopping_bag',
    color: CategoryPaletteIndex.purple30,
    type: CategoryType.expense,
    sortOrder: 3,
  ),
  _SeededCategory(
    l10nKey: 'category.housing',
    icon: 'home',
    color: CategoryPaletteIndex.green80,
    type: CategoryType.expense,
    sortOrder: 4,
  ),
  _SeededCategory(
    l10nKey: 'category.entertainment',
    icon: 'movie',
    color: CategoryPaletteIndex.orange70,
    type: CategoryType.expense,
    sortOrder: 5,
  ),
  _SeededCategory(
    l10nKey: 'category.medical',
    icon: 'medical_services',
    color: CategoryPaletteIndex.red50,
    type: CategoryType.expense,
    sortOrder: 6,
  ),
  _SeededCategory(
    l10nKey: 'category.education',
    icon: 'school',
    color: CategoryPaletteIndex.purple30,
    type: CategoryType.expense,
    sortOrder: 7,
  ),
  _SeededCategory(
    l10nKey: 'category.personal',
    icon: 'self_care',
    color: CategoryPaletteIndex.green80,
    type: CategoryType.expense,
    sortOrder: 8,
  ),
  _SeededCategory(
    l10nKey: 'category.travel',
    icon: 'flight',
    color: CategoryPaletteIndex.cyan70,
    type: CategoryType.expense,
    sortOrder: 9,
  ),
  _SeededCategory(
    l10nKey: 'category.threeC',
    icon: 'devices',
    color: CategoryPaletteIndex.blue30,
    type: CategoryType.expense,
    sortOrder: 10,
  ),
  _SeededCategory(
    l10nKey: 'category.miscellaneous',
    icon: 'category',
    color: CategoryPaletteIndex.neutralVariant50,
    type: CategoryType.expense,
    sortOrder: 11,
  ),
  _SeededCategory(
    l10nKey: 'category.other',
    icon: 'more_horiz',
    color: CategoryPaletteIndex.neutralVariant50,
    type: CategoryType.expense,
    sortOrder: 12,
  ),
  // Income categories (PRD 486–490).
  _SeededCategory(
    l10nKey: 'category.income.salary',
    icon: 'payments',
    color: CategoryPaletteIndex.yellow80,
    type: CategoryType.income,
    sortOrder: 13,
  ),
  _SeededCategory(
    l10nKey: 'category.income.freelance',
    icon: 'work',
    color: CategoryPaletteIndex.yellow80,
    type: CategoryType.income,
    sortOrder: 14,
  ),
  _SeededCategory(
    l10nKey: 'category.income.investment',
    icon: 'trending_up',
    color: CategoryPaletteIndex.yellow80,
    type: CategoryType.income,
    sortOrder: 15,
  ),
  _SeededCategory(
    l10nKey: 'category.income.gift',
    icon: 'redeem',
    color: CategoryPaletteIndex.yellow80,
    type: CategoryType.income,
    sortOrder: 16,
  ),
  _SeededCategory(
    l10nKey: 'category.income.other',
    icon: 'savings',
    color: CategoryPaletteIndex.yellow80,
    type: CategoryType.income,
    sortOrder: 17,
  ),
];

/// Seeded account-type row template. Defaults the sort_order to the
/// appearance order.
class _SeededAccountType {
  const _SeededAccountType({
    required this.l10nKey,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });
  final String l10nKey;
  final String icon;
  final int color;
  final int sortOrder;
}

/// 2 seeded account types (PRD 500–501).
const List<_SeededAccountType> _kSeededAccountTypes = <_SeededAccountType>[
  _SeededAccountType(
    l10nKey: 'accountType.cash',
    icon: 'wallet',
    color: CategoryPaletteIndex.neutralVariant70,
    sortOrder: 0,
  ),
  _SeededAccountType(
    l10nKey: 'accountType.investment',
    icon: 'trending_up',
    color: CategoryPaletteIndex.neutralVariant70,
    sortOrder: 1,
  ),
];

/// Seed identifier for the Cash account type — used to look up the row id
/// after `upsertSeeded` so it can be wired into the Cash account.
const String kSeededCashAccountTypeL10nKey = 'accountType.cash';

/// Seed literal for the Cash account's `name` column. The `accounts` table
/// has no `l10n_key` column (PRD 343), so the name is an English literal
/// that the user renames at will (Stream C plan §12 Q1).
const String kSeededCashAccountName = 'Cash';

/// Runs the first-run seed.
///
/// Idempotent: if `preferences.getFirstRunComplete()` returns `true`, this
/// function returns immediately without entering the transaction.
///
/// Atomic: the six write steps run inside one `db.transaction` so a
/// mid-step failure rolls back every write, including
/// `markFirstRunComplete()`. The next launch re-enters the seed and
/// either succeeds or leaves the DB empty again — there is no
/// "partially seeded, flagged complete" state.
///
/// Throws whatever the sibling repositories throw on a failing step
/// (`CurrencyNotFoundException`, `CurrencyDecimalsMismatchException`, …)
/// plus [FirstRunSeedException] for seed-invariant violations.
Future<void> runFirstRunSeed({
  required AppDatabase db,
  required CurrencyRepository currencies,
  required CategoryRepository categories,
  required AccountTypeRepository accountTypes,
  required AccountRepository accounts,
  required UserPreferencesRepository preferences,
  required LocaleService localeService,
}) async {
  // Step 0 — idempotency gate (runs outside the transaction).
  if (await preferences.getFirstRunComplete()) {
    return;
  }

  // Resolve the locale → currency mapping BEFORE opening the transaction.
  // The device locale read is synchronous and has no DB interaction;
  // every step in the transaction sees the same value.
  final localeCurrencyCode = _defaultCurrencyForLocale(
    localeService.deviceLocale,
  );

  await db.transaction(() async {
    // Step 1 — currencies.
    await _seedCurrencies(currencies);

    // Step 2 — resolve the locale currency into a Currency domain model.
    final localeCurrency = await currencies.getByCode(localeCurrencyCode);
    if (localeCurrency == null) {
      // Would only fire if Step 1 silently dropped a row — defensive.
      throw FirstRunSeedException(
        'Seed expected currency $localeCurrencyCode to exist after Step 1',
      );
    }

    // Step 3 — categories.
    await _seedCategories(categories);

    // Step 4 — account types. Returns the Cash account-type's row id so
    // Step 5 can reuse it.
    final cashAccountTypeId = await _seedAccountTypes(
      accountTypes,
      localeCurrency,
    );

    // Step 5 — one Cash account. Returns its row id so Step 6 can wire
    // `default_account_id` without re-reading the DB.
    final cashAccountId = await _seedCashAccount(
      accounts,
      cashAccountTypeId,
      localeCurrency,
    );

    // Step 6 — user_preferences (excluding the first-run flag).
    await _seedPreferences(
      preferences,
      defaultCurrency: localeCurrency,
      defaultAccountId: cashAccountId,
    );

    // Step 7 — idempotency flag last. Rolled back with the rest of the
    // transaction if any previous step threw.
    await preferences.markFirstRunComplete();
  });
}

// ---------- Step helpers ----------

Future<void> _seedCurrencies(CurrencyRepository currencies) async {
  for (final c in _kSeededCurrencies) {
    await currencies.upsert(c);
  }
}

Future<void> _seedCategories(CategoryRepository categories) async {
  for (final c in _kSeededCategories) {
    await categories.upsertSeeded(
      l10nKey: c.l10nKey,
      icon: c.icon,
      color: c.color,
      type: c.type,
      sortOrder: c.sortOrder,
    );
  }
}

/// Seeds the two default account types. Returns the row id of the
/// `accountType.cash` row so callers can wire the Cash account to it
/// without re-reading the DB.
Future<int> _seedAccountTypes(
  AccountTypeRepository accountTypes,
  Currency defaultCurrency,
) async {
  int? cashId;
  for (final t in _kSeededAccountTypes) {
    final id = await accountTypes.upsertSeeded(
      l10nKey: t.l10nKey,
      icon: t.icon,
      color: t.color,
      defaultCurrency: defaultCurrency,
      sortOrder: t.sortOrder,
    );
    if (t.l10nKey == kSeededCashAccountTypeL10nKey) {
      cashId = id;
    }
  }
  if (cashId == null) {
    throw const FirstRunSeedException(
      'Seed expected accountType.cash row id but none was captured',
    );
  }
  return cashId;
}

/// Seeds the single Cash account on an empty DB. On a re-run of the seed
/// (idempotency path — currently unreachable because Step 0 short-circuits,
/// but defensive) the account is deduplicated by `(accountTypeId, name)`:
/// if such a row exists, no insert happens.
///
/// Returns the Cash account's row id.
Future<int> _seedCashAccount(
  AccountRepository accounts,
  int cashAccountTypeId,
  Currency defaultCurrency,
) async {
  // Idempotency defense. The Step 0 gate makes this branch unreachable on
  // a "clean" re-run after `markFirstRunComplete` fired; it's here so a
  // partial-failure retry (Step 7 rolled back) still finds its Cash row
  // and does not duplicate.
  final existing = await accounts.watchAll(includeArchived: true).first;
  for (final a in existing) {
    if (a.accountTypeId == cashAccountTypeId &&
        a.name == kSeededCashAccountName) {
      return a.id;
    }
  }

  return accounts.save(
    Account(
      id: 0,
      name: kSeededCashAccountName,
      accountTypeId: cashAccountTypeId,
      currency: defaultCurrency,
      openingBalanceMinorUnits: 0,
      sortOrder: 0,
    ),
  );
}

Future<void> _seedPreferences(
  UserPreferencesRepository preferences, {
  required Currency defaultCurrency,
  required int defaultAccountId,
}) async {
  // Eight keys per Stream C plan §2.3 Step 6 / §12 Q2.
  await preferences.setThemeMode(ThemeMode.light);
  await preferences.setLocale(null);
  await preferences.setDefaultCurrency(defaultCurrency.code);
  await preferences.setDefaultAccountId(defaultAccountId);
  await preferences.setSplashEnabled(true);
  await preferences.setSplashStartDate(null);
  await preferences.setSplashDisplayText(kDefaultSplashDisplayText);
  await preferences.setSplashButtonLabel(kDefaultSplashButtonLabel);
}

// ---------- Locale → default currency ----------
//
// Visible for testing. The seed keeps the lookup policy as a
// top-level helper rather than extending `LocaleService` (Stream C plan
// §2.3 Step 2 decision + §5 Task C3).

/// Resolves the device locale to a seeded ISO 4217 code. Region-specific
/// mappings win over language-only fallbacks; language-only fallbacks
/// exist only for `en`, `zh`, `ja` (the three languages whose regional
/// mappings all collapse to the same default). Every other locale falls
/// through to the documented `USD` global fallback — language-prefix
/// fallbacks for `de_*`/`fr_*`/`es_*`/`it_*` → EUR were removed 2026-04-22
/// per the "language should not affect fiat" policy (§12 Q6).
String defaultCurrencyForLocale(String rawLocale) =>
    _defaultCurrencyForLocale(rawLocale);

String _defaultCurrencyForLocale(String rawLocale) {
  // BCP-47 accepts both `-` and `_`; normalise to `_`.
  final normalized = rawLocale.replaceAll('-', '_');

  // Exact-match fast path.
  switch (normalized) {
    case 'en_US':
    case 'en_CA':
    case 'en_AU':
    case 'en_NZ':
      return 'USD';
    case 'en_GB':
      return 'GBP';
    case 'zh_TW':
      return 'TWD';
    case 'zh_HK':
    case 'zh_MO':
      return 'HKD';
    case 'zh_CN':
    case 'zh_SG':
    case 'zh':
      return 'CNY';
    case 'ja_JP':
    case 'ja':
      return 'JPY';
  }

  // Language-only prefix fallback. Retained only for `en` / `zh` / `ja`
  // because their explicit regional mappings above all collapse to the
  // same default. `de` / `fr` / `es` / `it` are intentionally absent.
  final lang = normalized.split('_').first;
  switch (lang) {
    case 'en':
      return 'USD';
    case 'zh':
      return 'CNY';
    case 'ja':
      return 'JPY';
  }

  // Documented global fallback.
  return 'USD';
}
