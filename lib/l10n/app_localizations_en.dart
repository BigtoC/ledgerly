// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ledgerly';

  @override
  String get navHome => 'Home';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get categoriesArchiveAction => 'Archive';

  @override
  String get homeEditAction => 'Edit';

  @override
  String get commonUndo => 'Undo';

  @override
  String get txDiscardAction => 'Discard';

  @override
  String get txKeypadDone => 'Done';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get homeEmptyTitle => 'No transactions yet';

  @override
  String get homeEmptyCta => 'Log first transaction';

  @override
  String get homeFabLabel => 'Add transaction';

  @override
  String get homeSummaryTodayExpense => 'Today expense';

  @override
  String get homeSummaryTodayIncome => 'Today income';

  @override
  String get homeSummaryMonthNet => 'Month net';

  @override
  String get errorSnackbarGeneric => 'Something went wrong. Please try again.';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryDrinks => 'Drinks';

  @override
  String get categoryTransportation => 'Transportation';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryMedical => 'Medical';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryThreeC => '3C';

  @override
  String get categoryMiscellaneous => 'Miscellaneous';

  @override
  String get categoryOther => 'Other';

  @override
  String get categoryIncomeSalary => 'Salary';

  @override
  String get categoryIncomeFreelance => 'Freelance';

  @override
  String get categoryIncomeInvestment => 'Investment';

  @override
  String get categoryIncomeGift => 'Gift';

  @override
  String get categoryIncomeOther => 'Other Income';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeInvestment => 'Investment';

  @override
  String get splashEnter => 'Enter';

  @override
  String get splashSetStartDate => 'Set start date';

  @override
  String splashSinceDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Since $dateString';
  }

  @override
  String get splashDayCountLabel => 'days';

  @override
  String get settingsSplashSection => 'Splash screen';

  @override
  String get settingsSplashEnabled => 'Show splash screen';

  @override
  String get settingsSplashStartDate => 'Start date';

  @override
  String get settingsSplashDisplayText => 'Display text';

  @override
  String get settingsSplashButtonLabel => 'Button label';

  @override
  String get settingsSplashPreviewCta => 'Preview splash screen';

  @override
  String get categoriesManageTitle => 'Manage categories';

  @override
  String get categoriesAddCta => 'Add category';

  @override
  String get categoriesSectionExpense => 'Expense';

  @override
  String get categoriesSectionIncome => 'Income';

  @override
  String get categoriesFormNameLabel => 'Name';

  @override
  String get categoriesFormIconLabel => 'Icon';

  @override
  String get categoriesFormColorLabel => 'Color';

  @override
  String get categoriesFormTypeLabel => 'Type';

  @override
  String get categoriesFormTypeLockedHint =>
      'Type cannot change after first use';

  @override
  String get categoriesArchiveUndoSnackbar => 'Category archived';

  @override
  String get categoriesDeleteConfirmTitle => 'Delete category?';

  @override
  String get categoriesDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get categoriesPickerTitleExpense => 'Pick expense category';

  @override
  String get categoriesPickerTitleIncome => 'Pick income category';

  @override
  String get categoriesPickerEmptyCta => 'No categories yet — Create one';

  @override
  String get accountsListTitle => 'Accounts';

  @override
  String get accountsAddCta => 'Add account';

  @override
  String get accountsEmptyTitle => 'No active accounts';

  @override
  String get accountsEmptyCta => 'Create account';

  @override
  String get accountsArchivedSectionLabel => 'Archived';

  @override
  String get accountsSetDefaultAction => 'Set as default';

  @override
  String get accountsDefaultBadge => 'Default';

  @override
  String get accountsArchiveAction => 'Archive';

  @override
  String get accountsDeleteAction => 'Delete';

  @override
  String get accountsArchiveUndoSnackbar => 'Account archived';

  @override
  String get accountsDeleteConfirmTitle => 'Delete account?';

  @override
  String get accountsDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get accountsArchiveLastActiveBlocked =>
      'Cannot archive the only active account';

  @override
  String get accountsDeleteDefaultBlockedTitle => 'Change default account';

  @override
  String get accountsDeleteDefaultBlockedBody =>
      'Choose another default account before deleting this one.';

  @override
  String get accountsFormAddTitle => 'New account';

  @override
  String get accountsFormEditTitle => 'Edit account';

  @override
  String get accountsFormName => 'Name';

  @override
  String get accountsFormType => 'Account type';

  @override
  String get accountsFormCurrency => 'Currency';

  @override
  String get accountsFormOpeningBalance => 'Opening balance';

  @override
  String get accountsFormIcon => 'Icon';

  @override
  String get accountsFormColor => 'Color';

  @override
  String get accountsFormPickType => 'Pick account type';

  @override
  String get accountsFormPickCurrency => 'Pick currency';

  @override
  String get accountsFormNotFound => 'This account no longer exists.';

  @override
  String get accountsTypePickerTitle => 'Pick account type';

  @override
  String get accountsTypeCreateInlineCta => 'Create new account type';

  @override
  String get accountsTypeFormTitle => 'New account type';

  @override
  String get accountsTypeFormName => 'Name';

  @override
  String get accountsTypeFormDefaultCurrency => 'Default currency';

  @override
  String get accountsCurrencyPickerTitle => 'Pick currency';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionDataManagement => 'Data management';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageZhTw => '繁體中文 (Traditional Chinese)';

  @override
  String get settingsLanguageZhCn => '简体中文 (Simplified Chinese)';

  @override
  String get settingsDefaultAccountLabel => 'Default account';

  @override
  String get settingsDefaultAccountEmpty => 'Not set';

  @override
  String get settingsDefaultAccountPickerTitle => 'Pick default account';

  @override
  String get settingsDefaultAccountCreateCta => 'Create account';

  @override
  String get settingsDefaultCurrencyLabel => 'Default currency';

  @override
  String get settingsDefaultCurrencyPickerTitle => 'Pick default currency';

  @override
  String get settingsManageCategories => 'Manage categories';

  @override
  String get settingsSplashDisplayTextHint =>
      'Use [date] and [days] as placeholders';

  @override
  String get txAddTitle => 'Add transaction';

  @override
  String get txEditTitle => 'Edit transaction';

  @override
  String get txCategoryLabel => 'Category';

  @override
  String get txCategoryEmpty => 'Select a category';

  @override
  String get txAccountLabel => 'Account';

  @override
  String get txAccountEmpty => 'No active accounts — create one first';

  @override
  String get txAccountPickerTitle => 'Pick account';

  @override
  String get txDateLabel => 'Date';

  @override
  String get txMemoLabel => 'Memo';

  @override
  String get txAmountRequired => 'Enter an amount';

  @override
  String get txCreateAccountCta => 'Create account';

  @override
  String get txTransactionNotFound => 'Transaction not found';

  @override
  String get txSaveFailedSnackbar =>
      'Couldn’t save transaction. Please try again.';

  @override
  String get txDeleteFailedSnackbar =>
      'Couldn’t delete transaction. Please try again.';

  @override
  String get txDeleteConfirmTitle => 'Delete this transaction?';

  @override
  String get txDeleteConfirmBody =>
      'This permanently removes the transaction. This cannot be undone.';

  @override
  String get txDiscardConfirmTitle => 'Discard changes?';

  @override
  String get txDiscardConfirmBody => 'Your unsaved edits will be lost.';

  @override
  String get txCurrencyChangeConfirmTitle => 'Switch currency?';

  @override
  String get txCurrencyChangeConfirmBody =>
      'Switching to this account changes the currency. The entered amount will be cleared.';

  @override
  String get txKeypadClear => 'Clear amount';

  @override
  String get txKeypadBackspace => 'Backspace';

  @override
  String get homeDayEmptyTitle => 'No transactions on this day';

  @override
  String get homeDaySkeletonLabel => 'Loading day';

  @override
  String get homeDeleteUndoSnackbar => 'Transaction deleted';

  @override
  String get homeDuplicateAction => 'Duplicate';

  @override
  String get homeDayLabelToday => 'Today';

  @override
  String get homeDayLabelYesterday => 'Yesterday';

  @override
  String get homeDayNavPrevLabel => 'Previous day';

  @override
  String get homeDayNavNextLabel => 'Next day';
}
