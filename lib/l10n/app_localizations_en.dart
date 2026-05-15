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
  String get navAnalysis => 'Analysis';

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
  String get homeSummaryTodayExpense => 'Expense';

  @override
  String get homeSummaryTodayIncome => 'Income';

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
      'Switching to this account changes the currency. The current amount or calculation will be cleared.';

  @override
  String get txKeypadClear => 'Clear amount';

  @override
  String get txKeypadBackspace => 'Backspace';

  @override
  String get txKeypadAdd => 'Add';

  @override
  String get txKeypadSubtract => 'Subtract';

  @override
  String get txKeypadMultiply => 'Multiply';

  @override
  String get txKeypadDivide => 'Divide';

  @override
  String get homeEmptyDayMessage => 'No transaction';

  @override
  String get homeJumpToToday => 'Jump to today';

  @override
  String get homeSummaryMultiCurrencyNote => 'Multiple currencies';

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

  @override
  String get txCurrencyLabel => 'Currency';

  @override
  String get txCurrencyPickerTitle => 'Pick currency';

  @override
  String get txCurrencySearchHint => 'Search currencies';

  @override
  String get txCurrencyChangeConfirmAction => 'Change and Clear';

  @override
  String txAmountPlaceholderInCurrency(String code) {
    return 'Enter amount in $code';
  }

  @override
  String get txCurrencyPickerNoResults => 'No currencies found';

  @override
  String get txCurrencyPickerChangeConfirmBody =>
      'Changing the currency will clear the current amount or calculation.';

  @override
  String accountsBalanceMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more',
      one: '+$count more',
    );
    return '$_temp0';
  }

  @override
  String get shoppingListCardTitle => 'Shopping list';

  @override
  String get shoppingListViewAll => 'View all';

  @override
  String get shoppingListEmptyBody => 'No upcoming expenses saved';

  @override
  String get shoppingListEmptyCta => 'Add to shopping list';

  @override
  String shoppingListItemsMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
      one: '$count more',
    );
    return '$_temp0';
  }

  @override
  String get shoppingListScreenTitle => 'Shopping list';

  @override
  String get shoppingListDeleteUndoSnackbar => 'Draft deleted';

  @override
  String get shoppingListDeleteAction => 'Delete';

  @override
  String get shoppingListScreenEmptyBody => 'No upcoming expenses saved';

  @override
  String get shoppingListScreenEmptyCta => 'Add to shopping list';

  @override
  String get shoppingListScreenRetry => 'Retry';

  @override
  String get currencyUsd => 'US Dollar';

  @override
  String get currencyEur => 'Euro';

  @override
  String get currencyJpy => 'Japanese Yen';

  @override
  String get currencyTwd => 'New Taiwan Dollar';

  @override
  String get currencyCny => 'Chinese Yuan';

  @override
  String get currencyHkd => 'Hong Kong Dollar';

  @override
  String get currencyGbp => 'British Pound';

  @override
  String get currencyCad => 'Canadian Dollar';

  @override
  String get currencySgd => 'Singapore Dollar';

  @override
  String get currencyAud => 'Australian Dollar';

  @override
  String get currencyNzd => 'New Zealand Dollar';

  @override
  String get shoppingListEditDraftTitle => 'Edit Draft';

  @override
  String get shoppingListAddToListAction => 'Add to shopping list';

  @override
  String get shoppingListSaveDraftAction => 'Save draft';

  @override
  String get shoppingListSaveToTransactionAction => 'Save to transaction';

  @override
  String get shoppingListArchivedAccountWarning =>
      'Account is archived — replace before converting';

  @override
  String get shoppingListArchivedCategoryWarning =>
      'Category is archived — replace before converting';

  @override
  String get shoppingListSaveFailedSnackbar => 'Failed to save draft';

  @override
  String get shoppingListConvertFailedSnackbar => 'Failed to convert draft';

  @override
  String get shoppingListDraftNotFoundSnackbar => 'Draft not found';

  @override
  String get shoppingListSavedDraftSnackbar => 'Draft saved';

  @override
  String get shoppingListConvertedSnackbar => 'Draft converted to transaction';

  @override
  String get manageAccountsTitle => 'Manage accounts';

  @override
  String get manageAccountsCreateCta => 'Create account';

  @override
  String manageAccountsSetDefaultSuccess(String name) {
    return '$name is now the default account.';
  }

  @override
  String get manageAccountsSetDefaultFailed =>
      'Couldn\'t change default account. Try again.';

  @override
  String get manageAccountsLoadError => 'Couldn\'t load accounts.';

  @override
  String manageAccountsTileSubtitleMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' +$count more',
      one: ' +1 more',
    );
    return '$_temp0';
  }

  @override
  String get manageAccountsTileSubtitleAddCta => 'Add an account';

  @override
  String get manageAccountsBodyEmpty =>
      'No accounts yet. Create one to get started.';

  @override
  String get analysisPlaceholderTitle => 'Analysis is coming in Phase 2';

  @override
  String get analysisPlaceholderBody =>
      'Charts and summaries will appear here once Phase 2 lands.';

  @override
  String get analysisTitle => 'Analysis';

  @override
  String get analysisSearchHint => 'Search transactions…';

  @override
  String get analysisSearchPrompt => 'Search memos to find past transactions';

  @override
  String get analysisNoResults => 'No transactions found';

  @override
  String analysisTransactionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString transactions',
      one: '$countString transaction',
    );
    return '$_temp0';
  }

  @override
  String get analysisSearchTotal => 'Total';

  @override
  String get analysisErrorMessage => 'Something went wrong while searching';

  @override
  String get settingsRecurringTile => 'Recurring transactions';

  @override
  String get recurringRulesTitle => 'Recurring transactions';

  @override
  String get recurringEmptyHeading => 'No recurring rules yet';

  @override
  String get recurringEmptyBody =>
      'Set up a rule for rent, subscriptions, or any expense that repeats. Ledgerly will create a pending transaction for you on the due date.';

  @override
  String get recurringEmptyCta => 'Create rule';

  @override
  String get recurringFabNew => 'New rule';

  @override
  String get recurringRulesLoadError => 'Couldn\'t load your rules.';

  @override
  String get recurringRulesLoadRetry => 'Retry';

  @override
  String recurringTileNextDue(String date) {
    return 'Next: $date';
  }

  @override
  String get recurringTilePaused => 'Paused';

  @override
  String get recurringSwipePause => 'Pause';

  @override
  String get recurringSwipeResume => 'Resume';

  @override
  String get recurringSwipeDelete => 'Delete';

  @override
  String recurringPausedSnack(String ruleName) {
    return 'Paused — $ruleName';
  }

  @override
  String recurringResumedSnack(String ruleName, String date) {
    return 'Resumed — $ruleName, next due $date. Missed periods are not generated on resume.';
  }

  @override
  String get recurringDeletedSnack => 'Rule deleted';

  @override
  String get recurringFormCreateTitle => 'New rule';

  @override
  String get recurringFormEditTitle => 'Edit rule';

  @override
  String get recurringFormNamePlaceholder => 'Rule name';

  @override
  String get recurringFrequencyDaily => 'Daily';

  @override
  String get recurringFrequencyWeekly => 'Weekly';

  @override
  String get recurringFrequencyMonthly => 'Monthly';

  @override
  String get recurringFrequencyYearly => 'Yearly';

  @override
  String get recurringDailyHelper =>
      'Generates one pending transaction every day from today.';

  @override
  String get recurringDayOfMonthHint =>
      'If the month is shorter, the rule uses the last day of that month.';

  @override
  String get recurringFieldRequired => 'Required';

  @override
  String get recurringSaveCreate => 'Create';

  @override
  String get recurringSaveUpdate => 'Save';

  @override
  String get recurringSavedCreate => 'Rule created';

  @override
  String get recurringSavedUpdate => 'Rule updated';

  @override
  String get recurringDeleteRule => 'Delete rule';

  @override
  String get recurringDeleteConfirm =>
      'Delete this rule? Pending items already generated will remain in Pending Transactions.';

  @override
  String recurringEditWillNotAffectPending(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return 'You have $countString pending item(s) from this rule. Edits below won\'t change them — approve or skip them on Home.';
  }

  @override
  String get recurringRuleHasError =>
      'This rule had a problem on the last sync.';

  @override
  String get recurringSavedButGenerationFailed =>
      'Saved — but the first run hit an issue. We\'ll retry on the next launch.';

  @override
  String get homePendingSectionTitle => 'Pending';

  @override
  String get homePendingApprove => 'Approve';

  @override
  String get homePendingSkip => 'Skip once';

  @override
  String homePendingApprovedSnack(String ruleName) {
    return 'Approved — $ruleName';
  }

  @override
  String get homePendingSkippedSnack => 'Skipped this occurrence';

  @override
  String get homePendingLoadError => 'Couldn\'t load pending items.';

  @override
  String homePendingShowMore(int count) {
    return 'Show $count more';
  }

  @override
  String get homePendingShowFewer => 'Show fewer';

  @override
  String get approximatelyPrefix => 'approximately';

  @override
  String get convertedTotalLabel => 'total';

  @override
  String get homeSummaryUnconvertedHeader => 'Unconverted';
}
