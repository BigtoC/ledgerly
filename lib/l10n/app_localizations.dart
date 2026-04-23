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
