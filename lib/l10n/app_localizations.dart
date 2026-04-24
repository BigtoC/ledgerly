import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// Application title shown on the launcher and in the app bar.
  ///
  /// In en, this message translates to:
  /// **'Ledgerly'**
  String get appTitle;

  /// PRD 656. Bottom-nav tab 1 label.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// PRD 656. Bottom-nav tab 2 label.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// PRD 656. Bottom-nav tab 3 label.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Primary CTA label reused across Add/Edit forms (transactions, categories, accounts, settings).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Form dismiss / confirm-discard dialog negative action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Swipe action and confirm-delete dialog positive action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// PRD 737. List swipe action for categories/accounts that have transactions (archive-instead-of-delete).
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get commonArchive;

  /// Row overflow action and Add/Edit screen title when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// PRD 695. Undo snackbar action after delete.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// PRD 689. Confirm-discard dialog positive action when abandoning unsaved form edits.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// Create affordance label (accounts, categories).
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// Modal close affordance (picker sheet).
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// PRD 683. Expense/income segmented control — expense option.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionTypeExpense;

  /// PRD 683. Expense/income segmented control — income option.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionTypeIncome;

  /// PRD 695. Home screen empty-state title shown on first run.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get homeEmptyTitle;

  /// PRD 666. Home screen empty-state primary CTA.
  ///
  /// In en, this message translates to:
  /// **'Log first transaction'**
  String get homeEmptyCta;

  /// PRD 657. Home FAB semantics label (a11y).
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get homeFabLabel;

  /// PRD 672. Home summary strip — today expense row label.
  ///
  /// In en, this message translates to:
  /// **'Today expense'**
  String get homeSummaryTodayExpense;

  /// PRD 672. Home summary strip — today income row label.
  ///
  /// In en, this message translates to:
  /// **'Today income'**
  String get homeSummaryTodayIncome;

  /// PRD 672. Home summary strip — month net row label.
  ///
  /// In en, this message translates to:
  /// **'Month net'**
  String get homeSummaryMonthNet;

  /// PRD 690, 696. Generic save-failure snackbar.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorSnackbarGeneric;

  /// PRD 464. Seeded expense category — Food. DB l10n_key: category.food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// PRD 464. Seeded expense category — Drinks. DB l10n_key: category.drinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get categoryDrinks;

  /// PRD 466. Seeded expense category — Transportation. DB l10n_key: category.transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryTransportation;

  /// PRD 467. Seeded expense category — Shopping. DB l10n_key: category.shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// PRD 468. Seeded expense category — Housing. DB l10n_key: category.housing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// PRD 469. Seeded expense category — Entertainment. DB l10n_key: category.entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// PRD 470. Seeded expense category — Medical. DB l10n_key: category.medical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get categoryMedical;

  /// PRD 471. Seeded expense category — Education. DB l10n_key: category.education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// PRD 472. Seeded expense category — Personal. DB l10n_key: category.personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// PRD 473. Seeded expense category — Travel. DB l10n_key: category.travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// PRD 474. Seeded expense category — 3C (consumer electronics; phone/computer/gadgets). DB l10n_key: category.threeC.
  ///
  /// In en, this message translates to:
  /// **'3C'**
  String get categoryThreeC;

  /// PRD 475. Seeded expense category — Miscellaneous. DB l10n_key: category.miscellaneous.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous'**
  String get categoryMiscellaneous;

  /// PRD 476. Seeded expense category — Other. DB l10n_key: category.other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// PRD 485. Seeded income category — Salary. DB l10n_key: category.income.salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categoryIncomeSalary;

  /// PRD 486. Seeded income category — Freelance. DB l10n_key: category.income.freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get categoryIncomeFreelance;

  /// PRD 487. Seeded income category — Investment (distinct from the accountType.investment row). DB l10n_key: category.income.investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get categoryIncomeInvestment;

  /// PRD 488. Seeded income category — Gift. DB l10n_key: category.income.gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get categoryIncomeGift;

  /// PRD 489. Seeded income category — Other Income. DB l10n_key: category.income.other.
  ///
  /// In en, this message translates to:
  /// **'Other Income'**
  String get categoryIncomeOther;

  /// PRD 499. Seeded account type — Cash. DB l10n_key: accountType.cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// PRD 500. Seeded account type — Investment (distinct from the category.income.investment row). DB l10n_key: accountType.investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get accountTypeInvestment;

  /// PRD 527, 547. Default splash 'Enter' button label.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get splashEnter;

  /// M4 placeholder. First-run splash prompt to set the start date.
  ///
  /// In en, this message translates to:
  /// **'Set start date'**
  String get splashSetStartDate;

  /// PRD 526, 546. Splash default display text. {date} is formatted locale-aware via intl (yMMMMd).
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String splashSinceDate(DateTime date);

  /// PRD 551. Day-counter secondary label on splash.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get splashDayCountLabel;

  /// PRD 544. Settings section header for the splash group.
  ///
  /// In en, this message translates to:
  /// **'Splash screen'**
  String get settingsSplashSection;

  /// PRD 544. Toggle label for enabling the splash screen.
  ///
  /// In en, this message translates to:
  /// **'Show splash screen'**
  String get settingsSplashEnabled;

  /// PRD 545. Date-picker label for the splash start date.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get settingsSplashStartDate;

  /// PRD 546. Free-text field label for the splash display text template.
  ///
  /// In en, this message translates to:
  /// **'Display text'**
  String get settingsSplashDisplayText;

  /// PRD 547. Free-text field label for the splash button label.
  ///
  /// In en, this message translates to:
  /// **'Button label'**
  String get settingsSplashButtonLabel;

  /// PRD 728. AppBar title for the Categories management screen (Settings → Manage Categories).
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get categoriesManageTitle;

  /// PRD 728, 733. FAB label and inline empty-section CTA to open the category form sheet in Add mode.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoriesAddCta;

  /// PRD 731. Section header for the expense category group on the management screen.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get categoriesSectionExpense;

  /// PRD 731. Section header for the income category group on the management screen.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoriesSectionIncome;

  /// PRD 732. Category form sheet — display name text field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoriesFormNameLabel;

  /// PRD 732. Category form sheet — icon picker label.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoriesFormIconLabel;

  /// PRD 732. Category form sheet — color picker label.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoriesFormColorLabel;

  /// PRD 732. Category form sheet — expense/income segmented control label.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get categoriesFormTypeLabel;

  /// PRD 293-294, 735-737. Inline hint shown beneath the disabled type toggle in Edit mode — category type is immutable once transactions reference the row.
  ///
  /// In en, this message translates to:
  /// **'Type cannot change after first use'**
  String get categoriesFormTypeLockedHint;

  /// PRD 695, 737. SnackBar text shown after archiving a category; pairs with commonUndo as the action label.
  ///
  /// In en, this message translates to:
  /// **'Category archived'**
  String get categoriesArchiveUndoSnackbar;

  /// PRD 737. Confirm-delete dialog title — unused custom categories only.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get categoriesDeleteConfirmTitle;

  /// PRD 737. Confirm-delete dialog body — unused custom categories only.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get categoriesDeleteConfirmBody;

  /// PRD 683, 715. Category picker sheet title when opened for an expense transaction.
  ///
  /// In en, this message translates to:
  /// **'Pick expense category'**
  String get categoriesPickerTitleExpense;

  /// PRD 683, 715. Category picker sheet title when opened for an income transaction.
  ///
  /// In en, this message translates to:
  /// **'Pick income category'**
  String get categoriesPickerTitleIncome;

  /// PRD 715. Empty-state CTA inside the picker sheet; closes the sheet and resolves null so the caller decides the next step (per wave-0 §2.3 and categories-plan §5).
  ///
  /// In en, this message translates to:
  /// **'No categories yet — Create one'**
  String get categoriesPickerEmptyCta;

  /// PRD 680. AppBar title for the Accounts list screen.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsListTitle;

  /// PRD 680. FAB label and empty-state CTA to open the account form in Add mode.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsAddCta;

  /// PRD 703. Accounts list empty-state title shown when every account is archived.
  ///
  /// In en, this message translates to:
  /// **'No active accounts'**
  String get accountsEmptyTitle;

  /// PRD 703. Primary CTA on the Accounts empty state — mirrors PRD's 'Create account' label when no active account exists.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get accountsEmptyCta;

  /// Accounts plan §4. Section header for the collapsible archived-accounts group beneath the active list.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get accountsArchivedSectionLabel;

  /// Accounts plan §4, §6. Row overflow / swipe action to mark the account as the default account.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get accountsSetDefaultAction;

  /// Accounts plan §4, §6. Badge shown on the currently-default account tile.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get accountsDefaultBadge;

  /// Accounts plan §4, §7. Swipe action label when the account is referenced by at least one transaction and therefore cannot be deleted.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get accountsArchiveAction;

  /// Accounts plan §4, §7. Swipe action label when the account is custom, unreferenced, and has zero opening balance.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountsDeleteAction;

  /// Accounts plan §7. SnackBar text shown after archiving an account; pairs with commonUndo as the action label.
  ///
  /// In en, this message translates to:
  /// **'Account archived'**
  String get accountsArchiveUndoSnackbar;

  /// Accounts plan §7. Confirm-delete dialog title — unused custom accounts only.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get accountsDeleteConfirmTitle;

  /// Accounts plan §7. Confirm-delete dialog body — unused custom accounts only.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get accountsDeleteConfirmBody;

  /// Accounts plan §7. Tooltip / snackbar shown when the user tries to archive the last remaining active account.
  ///
  /// In en, this message translates to:
  /// **'Cannot archive the only active account'**
  String get accountsArchiveLastActiveBlocked;

  /// Accounts plan §7. Dialog title shown when the user tries to delete the currently-default account; prompts them to choose a new default first.
  ///
  /// In en, this message translates to:
  /// **'Change default account'**
  String get accountsDeleteDefaultBlockedTitle;

  /// Accounts plan §7. Dialog body — cannot delete the default account until a different default is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose another default account before deleting this one.'**
  String get accountsDeleteDefaultBlockedBody;

  /// PRD 643. AppBar title for /accounts/new (Add mode).
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get accountsFormAddTitle;

  /// PRD 644. AppBar title for /accounts/:id (Edit mode).
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountsFormEditTitle;

  /// Accounts plan §5. Account form — display-name text field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountsFormName;

  /// Accounts plan §5. Account form — account-type picker label.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountsFormType;

  /// Accounts plan §5. Account form — currency picker label.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountsFormCurrency;

  /// Accounts plan §5. Account form — opening balance numeric field label.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountsFormOpeningBalance;

  /// Accounts plan §5. Account form — icon picker label.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get accountsFormIcon;

  /// Accounts plan §5. Account form — color picker label.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get accountsFormColor;

  /// Accounts plan §5. Placeholder shown on the account-type picker trigger when no type is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick account type'**
  String get accountsFormPickType;

  /// Accounts plan §5. Placeholder shown on the currency picker trigger when no currency is selected.
  ///
  /// In en, this message translates to:
  /// **'Pick currency'**
  String get accountsFormPickCurrency;

  /// Accounts plan §5. Recoverable not-found state shown when /accounts/:id targets a row that has been deleted.
  ///
  /// In en, this message translates to:
  /// **'This account no longer exists.'**
  String get accountsFormNotFound;

  /// Accounts plan §5. Title for the account-type picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Pick account type'**
  String get accountsTypePickerTitle;

  /// Accounts plan §5. Inline CTA at the bottom of the account-type picker — opens a nested form to create a custom account type.
  ///
  /// In en, this message translates to:
  /// **'Create new account type'**
  String get accountsTypeCreateInlineCta;

  /// Accounts plan §5. Title for the nested 'create account type' form launched from the picker sheet.
  ///
  /// In en, this message translates to:
  /// **'New account type'**
  String get accountsTypeFormTitle;

  /// Accounts plan §5. Inline account-type form — display-name text field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountsTypeFormName;

  /// Accounts plan §5. Inline account-type form — default-currency picker label.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get accountsTypeFormDefaultCurrency;

  /// Accounts plan §5, §8. Title for the currency picker sheet opened from the account form.
  ///
  /// In en, this message translates to:
  /// **'Pick currency'**
  String get accountsCurrencyPickerTitle;

  /// Settings plan §5. Section header for theme + language group.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// Settings plan §5. Section header for default-account + default-currency group.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// Settings plan §5. Section header grouping Manage Categories (wallets/ankr-key are Phase 2).
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get settingsSectionDataManagement;

  /// Settings plan §3.2. Label for the theme-mode selector.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// Settings plan §3.2. Theme-mode option — light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Settings plan §3.2. Theme-mode option — dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Settings plan §3.2. Theme-mode option — follow system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Settings plan §3.2. Label for the language selector.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// Settings plan §3.2. Language selector — follow system locale (null).
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// Settings plan §3.2. Language option — English.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Settings plan §3.2. Language option — Traditional Chinese (zh_TW).
  ///
  /// In en, this message translates to:
  /// **'繁體中文 (Traditional Chinese)'**
  String get settingsLanguageZhTw;

  /// Settings plan §3.2. Language option — Simplified Chinese (zh_CN).
  ///
  /// In en, this message translates to:
  /// **'简体中文 (Simplified Chinese)'**
  String get settingsLanguageZhCn;

  /// Settings plan §3.2, §7. Label for the default-account tile.
  ///
  /// In en, this message translates to:
  /// **'Default account'**
  String get settingsDefaultAccountLabel;

  /// Settings plan §3.2, §7. Subtitle shown on the default-account tile when no default has been picked.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsDefaultAccountEmpty;

  /// Settings plan §7. Title for the default-account picker bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Pick default account'**
  String get settingsDefaultAccountPickerTitle;

  /// Settings plan §7. CTA shown when no active accounts exist — routes to /accounts/new.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get settingsDefaultAccountCreateCta;

  /// Settings plan §3.2, §8. Label for the default-currency tile.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get settingsDefaultCurrencyLabel;

  /// Settings plan §8. Title for the default-currency picker bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Pick default currency'**
  String get settingsDefaultCurrencyPickerTitle;

  /// Settings plan §3.2, §5. ListTile label that navigates to /settings/categories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get settingsManageCategories;

  /// Settings plan §6. Hint text under the splash display-text field explaining the template variables. Square brackets here are a visual stand-in for the literal '{date}' / '{days}' template tokens — gen_l10n parses curly braces as MessageFormat placeholders, so the copy uses bracketed forms to stay a plain string.
  ///
  /// In en, this message translates to:
  /// **'Use [date] and [days] as placeholders'**
  String get settingsSplashDisplayTextHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
