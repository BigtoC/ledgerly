// Standing regression guard for the M2 Stream C ARB key inventory.
//
// Parses all four source ARB files as JSON and asserts the invariants
// documented in `docs/plans/m2-core-utilities/stream-c-theme-l10n.md`
// §8.6 assertions (1–4):
//
//   1. Every key present in `app_en.arb` (excluding `@`-prefixed metadata)
//      is present in `app_zh_TW.arb` AND `app_zh_CN.arb`.
//   2. No key is present in `app_zh_TW.arb` or `app_zh_CN.arb` that is
//      absent from `app_en.arb`.
//   3. `app_zh.arb` contains exactly one non-metadata key: `appTitle`
//      (CLAUDE.md pin: removing or expanding this breaks `flutter pub get`).
//   4. `app_en.arb` contains all stream-owned keys from the plan §5.2–§5.5
//      inventory, plus `appTitle`.
//
// This test runs under `dart test` (pure VM) — no Flutter binding, no
// widget pumps — so it stays fast and is the first thing CI can reject a
// rogue ARB edit against.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _l10nDir = 'l10n';

/// Non-metadata keys defined by plan §5.2–§5.5 plus `appTitle`.
/// Order mirrors the plan tables so a diff against this list maps 1:1 to
/// the §5 inventory rows.
const Set<String> _expectedEnKeys = <String>{
  // M0-seeded.
  'appTitle',

  // §5.2 Group S — Shell / Nav / Common.
  'navHome',
  'navAccounts',
  'navSettings',
  'commonSave',
  'commonCancel',
  'commonDelete',
  'commonArchive',
  'commonEdit',
  'commonUndo',
  'commonDiscard',
  'commonAdd',
  'commonDone',
  'transactionTypeExpense',
  'transactionTypeIncome',
  'homeEmptyTitle',
  'homeEmptyCta',
  'homeFabLabel',
  'homeSummaryTodayExpense',
  'homeSummaryTodayIncome',
  'homeSummaryMonthNet',
  'errorSnackbarGeneric',

  // §5.3 Group P — Splash + splash-settings.
  'splashEnter',
  'splashSetStartDate',
  'splashSinceDate',
  'splashDayCountLabel',
  'settingsSplashSection',
  'settingsSplashEnabled',
  'settingsSplashStartDate',
  'settingsSplashDisplayText',
  'settingsSplashButtonLabel',

  // §5.4 Group C — Seeded expense categories.
  'categoryFood',
  'categoryDrinks',
  'categoryTransportation',
  'categoryShopping',
  'categoryHousing',
  'categoryEntertainment',
  'categoryMedical',
  'categoryEducation',
  'categoryPersonal',
  'categoryTravel',
  'categoryThreeC',
  'categoryMiscellaneous',
  'categoryOther',

  // §5.4 Group C — Seeded income categories.
  'categoryIncomeSalary',
  'categoryIncomeFreelance',
  'categoryIncomeInvestment',
  'categoryIncomeGift',
  'categoryIncomeOther',

  // §5.5 Group A — Seeded account types.
  'accountTypeCash',
  'accountTypeInvestment',

  // M5 Wave 1 — Categories slice UI keys
  // (docs/plans/m5-ui-feature-slices/wave-1/categories-plan.md §3.2).
  'categoriesManageTitle',
  'categoriesAddCta',
  'categoriesSectionExpense',
  'categoriesSectionIncome',
  'categoriesFormNameLabel',
  'categoriesFormIconLabel',
  'categoriesFormColorLabel',
  'categoriesFormTypeLabel',
  'categoriesFormTypeLockedHint',
  'categoriesArchiveUndoSnackbar',
  'categoriesDeleteConfirmTitle',
  'categoriesDeleteConfirmBody',
  'categoriesPickerTitleExpense',
  'categoriesPickerTitleIncome',
  'categoriesPickerEmptyCta',

  // M5 Wave 1 — Accounts slice UI keys
  // (docs/plans/m5-ui-feature-slices/wave-1/accounts-plan.md §3.2).
  'accountsListTitle',
  'accountsAddCta',
  'accountsEmptyTitle',
  'accountsEmptyCta',
  'accountsArchivedSectionLabel',
  'accountsSetDefaultAction',
  'accountsDefaultBadge',
  'accountsArchiveAction',
  'accountsDeleteAction',
  'accountsArchiveUndoSnackbar',
  'accountsDeleteConfirmTitle',
  'accountsDeleteConfirmBody',
  'accountsArchiveLastActiveBlocked',
  'accountsDeleteDefaultBlockedTitle',
  'accountsDeleteDefaultBlockedBody',
  'accountsFormAddTitle',
  'accountsFormEditTitle',
  'accountsFormName',
  'accountsFormType',
  'accountsFormCurrency',
  'accountsFormOpeningBalance',
  'accountsFormIcon',
  'accountsFormColor',
  'accountsFormPickType',
  'accountsFormPickCurrency',
  'accountsFormNotFound',
  'accountsTypePickerTitle',
  'accountsTypeCreateInlineCta',
  'accountsTypeFormTitle',
  'accountsTypeFormName',
  'accountsTypeFormDefaultCurrency',
  'accountsCurrencyPickerTitle',
};

Map<String, dynamic> _readArb(String fileName) {
  final file = File('$_l10nDir/$fileName');
  expect(
    file.existsSync(),
    isTrue,
    reason:
        '$fileName is missing from /$_l10nDir — CLAUDE.md pin requires '
        'all four ARB files (including the minimal app_zh.arb fallback) '
        'to stay present.',
  );
  final raw = file.readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// Returns only non-metadata keys (drops both `@@locale` and any `@foo`
/// description/placeholder block).
Set<String> _translationKeys(Map<String, dynamic> arb) {
  return arb.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  group('ARB audit (plan §8.6)', () {
    late Map<String, dynamic> en;
    late Map<String, dynamic> zh;
    late Map<String, dynamic> zhTw;
    late Map<String, dynamic> zhCn;

    setUpAll(() {
      en = _readArb('app_en.arb');
      zh = _readArb('app_zh.arb');
      zhTw = _readArb('app_zh_TW.arb');
      zhCn = _readArb('app_zh_CN.arb');
    });

    test('(1) every EN key is present in zh_TW and zh_CN', () {
      final enKeys = _translationKeys(en);
      final zhTwKeys = _translationKeys(zhTw);
      final zhCnKeys = _translationKeys(zhCn);

      final missingInTw = enKeys.difference(zhTwKeys);
      final missingInCn = enKeys.difference(zhCnKeys);

      expect(
        missingInTw,
        isEmpty,
        reason:
            'app_zh_TW.arb is missing keys present in app_en.arb: '
            '$missingInTw',
      );
      expect(
        missingInCn,
        isEmpty,
        reason:
            'app_zh_CN.arb is missing keys present in app_en.arb: '
            '$missingInCn',
      );
    });

    test('(2) zh_TW and zh_CN do not contain keys absent from EN', () {
      final enKeys = _translationKeys(en);
      final zhTwKeys = _translationKeys(zhTw);
      final zhCnKeys = _translationKeys(zhCn);

      final extraInTw = zhTwKeys.difference(enKeys);
      final extraInCn = zhCnKeys.difference(enKeys);

      expect(
        extraInTw,
        isEmpty,
        reason:
            'app_zh_TW.arb has keys absent from app_en.arb '
            '(template-arb-file is app_en.arb): $extraInTw',
      );
      expect(
        extraInCn,
        isEmpty,
        reason:
            'app_zh_CN.arb has keys absent from app_en.arb '
            '(template-arb-file is app_en.arb): $extraInCn',
      );
    });

    test('(3) app_zh.arb contains exactly one non-metadata key: appTitle', () {
      final zhKeys = _translationKeys(zh);
      expect(
        zhKeys,
        equals(<String>{'appTitle'}),
        reason:
            'CLAUDE.md pin: app_zh.arb is the Chinese base-fallback '
            'required by flutter_localizations codegen and must contain '
            'only appTitle. Anything else risks rendering unreviewed '
            'English copy to users on unspecified Chinese locales.',
      );
    });

    test('(4) app_en.arb carries every stream-owned key from §5.2–§5.5', () {
      final enKeys = _translationKeys(en);

      final missing = _expectedEnKeys.difference(enKeys);
      final unexpected = enKeys.difference(_expectedEnKeys);

      expect(
        missing,
        isEmpty,
        reason:
            'app_en.arb is missing stream-owned keys from plan §5: '
            '$missing',
      );
      expect(
        unexpected,
        isEmpty,
        reason:
            'app_en.arb has keys not in plan §5 — either the plan '
            'needs an update or the ARB drifted: $unexpected',
      );
    });
  });
}
