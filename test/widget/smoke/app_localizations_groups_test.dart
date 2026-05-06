// Smoke test for the M2 Stream C ARB key inventory.
//
// Scope: builds a minimal `MaterialApp` with `AppLocalizations.delegate` for
// each supported target locale (`en`, `zh_TW`, `zh_CN`) and asserts that a
// representative sentinel getter from each key group (Shell/Nav, Splash,
// Categories, Account Types) resolves non-null. This guards against the ARB
// file existing but the corresponding getter being absent from the generated
// `AppLocalizations` class.
//
// Deliberately does NOT assert exact string content — translators rewrite
// copy and pinning literal strings here would make every translation review
// flip a test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Future<AppLocalizations> _localizationsFor(
  WidgetTester tester,
  Locale locale,
) async {
  late AppLocalizations captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          captured = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  return captured;
}

void main() {
  const locales = <Locale>[
    Locale('en'),
    Locale('zh', 'TW'),
    Locale('zh', 'CN'),
  ];

  group('Group S (Shell / Nav / Common) resolves for every target locale', () {
    for (final locale in locales) {
      testWidgets('$locale: nav + common + home keys non-null', (tester) async {
        final l10n = await _localizationsFor(tester, locale);

        // Nav sentinels.
        expect(l10n.navHome, isNotEmpty);
        expect(l10n.navAnalysis, isNotEmpty);
        expect(l10n.navSettings, isNotEmpty);

        // Common verbs (post Wave 4 §3.2: only keys used by ≥2 slices remain
        // under the `common*` prefix; singleton UI labels moved back to their
        // owning slice prefixes).
        expect(l10n.commonSave, isNotEmpty);
        expect(l10n.commonCancel, isNotEmpty);
        expect(l10n.commonDelete, isNotEmpty);
        expect(l10n.commonUndo, isNotEmpty);

        // Slice-owned action labels promoted out of `common*`.
        expect(l10n.categoriesArchiveAction, isNotEmpty);
        expect(l10n.homeEditAction, isNotEmpty);
        expect(l10n.txDiscardAction, isNotEmpty);
        expect(l10n.txKeypadDone, isNotEmpty);

        // Transaction type toggles.
        expect(l10n.transactionTypeExpense, isNotEmpty);
        expect(l10n.transactionTypeIncome, isNotEmpty);

        // Home shell strings.
        expect(l10n.homeEmptyTitle, isNotEmpty);
        expect(l10n.homeEmptyCta, isNotEmpty);
        expect(l10n.homeFabLabel, isNotEmpty);
        expect(l10n.homeSummaryTodayExpense, isNotEmpty);
        expect(l10n.homeSummaryTodayIncome, isNotEmpty);
        expect(l10n.homeSummaryMonthNet, isNotEmpty);

        // Error snackbar.
        expect(l10n.errorSnackbarGeneric, isNotEmpty);
      });
    }
  });

  group('Group C (seeded categories) resolves for every target locale', () {
    for (final locale in locales) {
      testWidgets('$locale: category sentinels non-null', (tester) async {
        final l10n = await _localizationsFor(tester, locale);

        // One sentinel per seeded expense family + every income category.
        expect(l10n.categoryFood, isNotEmpty);
        expect(l10n.categoryDrinks, isNotEmpty);
        expect(l10n.categoryTransportation, isNotEmpty);
        expect(l10n.categoryShopping, isNotEmpty);
        expect(l10n.categoryHousing, isNotEmpty);
        expect(l10n.categoryEntertainment, isNotEmpty);
        expect(l10n.categoryMedical, isNotEmpty);
        expect(l10n.categoryEducation, isNotEmpty);
        expect(l10n.categoryPersonal, isNotEmpty);
        expect(l10n.categoryTravel, isNotEmpty);
        expect(l10n.categoryThreeC, isNotEmpty);
        expect(l10n.categoryMiscellaneous, isNotEmpty);
        expect(l10n.categoryOther, isNotEmpty);

        expect(l10n.categoryIncomeSalary, isNotEmpty);
        expect(l10n.categoryIncomeFreelance, isNotEmpty);
        expect(l10n.categoryIncomeInvestment, isNotEmpty);
        expect(l10n.categoryIncomeGift, isNotEmpty);
        expect(l10n.categoryIncomeOther, isNotEmpty);
      });
    }
  });

  group(
    'Group A (account types) + Group P (splash) resolve for every locale',
    () {
      for (final locale in locales) {
        testWidgets('$locale: account types + splash ICU non-null', (
          tester,
        ) async {
          final l10n = await _localizationsFor(tester, locale);

          // Account types.
          expect(l10n.accountTypeCash, isNotEmpty);
          expect(l10n.accountTypeInvestment, isNotEmpty);

          // Splash defaults.
          expect(l10n.splashEnter, isNotEmpty);
          expect(l10n.splashDayCountLabel, isNotEmpty);

          // ICU placeholder — if the @placeholders block or the format is
          // wrong, generation produces a different method signature per locale
          // and this call does not compile.
          expect(l10n.splashSinceDate(DateTime.utc(2024, 1, 1)), isNotEmpty);

          // Splash settings group.
          expect(l10n.settingsSplashSection, isNotEmpty);
          expect(l10n.settingsSplashEnabled, isNotEmpty);
          expect(l10n.settingsSplashStartDate, isNotEmpty);
          expect(l10n.settingsSplashDisplayText, isNotEmpty);
          expect(l10n.settingsSplashButtonLabel, isNotEmpty);
        });
      }
    },
  );
}
