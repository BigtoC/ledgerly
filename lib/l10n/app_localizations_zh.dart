// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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

  @override
  String get chartsPeriodDay => 'Day';

  @override
  String get chartsPeriodWeek => 'Week';

  @override
  String get chartsPeriodMonth => 'Month';

  @override
  String get chartsPeriodYear => 'Year';

  @override
  String get chartsTypeExpense => 'Expense';

  @override
  String get chartsTypeIncome => 'Income';

  @override
  String get chartsDimensionCategory => 'Category';

  @override
  String get chartsDimensionAccount => 'Account';

  @override
  String get chartsDimensionCurrency => 'Currency';

  @override
  String get chartsNoData => 'No transactions yet';

  @override
  String get chartsMixedCurrencies => 'Showing original currency amounts';

  @override
  String get chartsRatesRequired => 'Waiting for exchange rates';

  @override
  String get chartsViewAll => 'View all';

  @override
  String get chartsTotal => 'Total';

  @override
  String get chartsOther => 'Other';

  @override
  String chartsOtherCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Other ($count items)',
      one: 'Other (1 item)',
    );
    return '$_temp0';
  }

  @override
  String get chartsAutoSwitchedToCurrency =>
      'Showing by currency — no exchange rates yet for category view.';

  @override
  String get chartsPieChart => 'Pie chart';

  @override
  String get chartsBarChart => 'Bar chart';

  @override
  String chartsExcludedCurrencies(String codes) {
    return 'Excluded: $codes — no exchange rate yet';
  }
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'Ledgerly';

  @override
  String get navHome => '首页';

  @override
  String get navAnalysis => '分析';

  @override
  String get navSettings => '设置';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get categoriesArchiveAction => '归档';

  @override
  String get homeEditAction => '编辑';

  @override
  String get commonUndo => '撤销';

  @override
  String get txDiscardAction => '放弃';

  @override
  String get txKeypadDone => '完成';

  @override
  String get transactionTypeExpense => '支出';

  @override
  String get transactionTypeIncome => '收入';

  @override
  String get homeEmptyTitle => '暂无交易记录';

  @override
  String get homeEmptyCta => '记录第一笔交易';

  @override
  String get homeFabLabel => '添加交易';

  @override
  String get homeSummaryTodayExpense => '支出';

  @override
  String get homeSummaryTodayIncome => '收入';

  @override
  String get homeSummaryMonthNet => '本月净额';

  @override
  String get errorSnackbarGeneric => '出错了，请重试。';

  @override
  String get categoryFood => '饮食';

  @override
  String get categoryDrinks => '饮料';

  @override
  String get categoryTransportation => '交通';

  @override
  String get categoryShopping => '购物';

  @override
  String get categoryHousing => '居住';

  @override
  String get categoryEntertainment => '娱乐';

  @override
  String get categoryMedical => '医疗';

  @override
  String get categoryEducation => '教育';

  @override
  String get categoryPersonal => '个人';

  @override
  String get categoryTravel => '旅游';

  @override
  String get categoryThreeC => '3C';

  @override
  String get categoryMiscellaneous => '杂项';

  @override
  String get categoryOther => '其他';

  @override
  String get categoryIncomeSalary => '工资';

  @override
  String get categoryIncomeFreelance => '自由职业';

  @override
  String get categoryIncomeInvestment => '投资';

  @override
  String get categoryIncomeGift => '馈赠';

  @override
  String get categoryIncomeOther => '其他收入';

  @override
  String get accountTypeCash => '现金';

  @override
  String get accountTypeInvestment => '投资';

  @override
  String get splashEnter => '进入';

  @override
  String get splashSetStartDate => '设置起始日期';

  @override
  String splashSinceDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '自 $dateString 起';
  }

  @override
  String get splashDayCountLabel => '天';

  @override
  String get settingsSplashSection => '启动页';

  @override
  String get settingsSplashEnabled => '显示启动页';

  @override
  String get settingsSplashStartDate => '起始日期';

  @override
  String get settingsSplashDisplayText => '显示文字';

  @override
  String get settingsSplashButtonLabel => '按钮文字';

  @override
  String get settingsSplashPreviewCta => '预览启动页';

  @override
  String get categoriesManageTitle => '管理分类';

  @override
  String get categoriesAddCta => '添加分类';

  @override
  String get categoriesSectionExpense => '支出';

  @override
  String get categoriesSectionIncome => '收入';

  @override
  String get categoriesFormNameLabel => '名称';

  @override
  String get categoriesFormIconLabel => '图标';

  @override
  String get categoriesFormColorLabel => '颜色';

  @override
  String get categoriesFormTypeLabel => '类型';

  @override
  String get categoriesFormTypeLockedHint => '使用后类型无法更改';

  @override
  String get categoriesArchiveUndoSnackbar => '已归档分类';

  @override
  String get categoriesDeleteConfirmTitle => '要删除分类吗？';

  @override
  String get categoriesDeleteConfirmBody => '此操作无法撤销。';

  @override
  String get categoriesPickerTitleExpense => '选择支出分类';

  @override
  String get categoriesPickerTitleIncome => '选择收入分类';

  @override
  String get categoriesPickerEmptyCta => '暂无分类 — 创建一个';

  @override
  String get accountsListTitle => '账户';

  @override
  String get accountsAddCta => '添加账户';

  @override
  String get accountsEmptyTitle => '没有使用中的账户';

  @override
  String get accountsEmptyCta => '创建账户';

  @override
  String get accountsArchivedSectionLabel => '已归档';

  @override
  String get accountsSetDefaultAction => '设为默认';

  @override
  String get accountsDefaultBadge => '默认';

  @override
  String get accountsArchiveAction => '归档';

  @override
  String get accountsDeleteAction => '删除';

  @override
  String get accountsArchiveUndoSnackbar => '已归档账户';

  @override
  String get accountsDeleteConfirmTitle => '要删除账户吗？';

  @override
  String get accountsDeleteConfirmBody => '此操作无法撤销。';

  @override
  String get accountsArchiveLastActiveBlocked => '无法归档唯一使用中的账户';

  @override
  String get accountsDeleteDefaultBlockedTitle => '请先更改默认账户';

  @override
  String get accountsDeleteDefaultBlockedBody => '删除前请先选择其他默认账户。';

  @override
  String get accountsFormAddTitle => '新账户';

  @override
  String get accountsFormEditTitle => '编辑账户';

  @override
  String get accountsFormName => '名称';

  @override
  String get accountsFormType => '账户类型';

  @override
  String get accountsFormCurrency => '币种';

  @override
  String get accountsFormOpeningBalance => '期初余额';

  @override
  String get accountsFormIcon => '图标';

  @override
  String get accountsFormColor => '颜色';

  @override
  String get accountsFormPickType => '选择账户类型';

  @override
  String get accountsFormPickCurrency => '选择币种';

  @override
  String get accountsFormNotFound => '此账户已不存在。';

  @override
  String get accountsTypePickerTitle => '选择账户类型';

  @override
  String get accountsTypeCreateInlineCta => '创建新的账户类型';

  @override
  String get accountsTypeFormTitle => '新账户类型';

  @override
  String get accountsTypeFormName => '名称';

  @override
  String get accountsTypeFormDefaultCurrency => '默认币种';

  @override
  String get accountsCurrencyPickerTitle => '选择币种';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionGeneral => '常规';

  @override
  String get settingsSectionDataManagement => '数据管理';

  @override
  String get settingsThemeLabel => '主题';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsLanguageLabel => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageZhTw => '繁體中文';

  @override
  String get settingsLanguageZhCn => '简体中文';

  @override
  String get settingsDefaultAccountLabel => '默认账户';

  @override
  String get settingsDefaultAccountEmpty => '未设置';

  @override
  String get settingsDefaultAccountPickerTitle => '选择默认账户';

  @override
  String get settingsDefaultAccountCreateCta => '创建账户';

  @override
  String get settingsDefaultCurrencyLabel => '默认币种';

  @override
  String get settingsDefaultCurrencyPickerTitle => '选择默认币种';

  @override
  String get settingsManageCategories => '管理分类';

  @override
  String get settingsSplashDisplayTextHint => '可使用 [date] 与 [days] 作为变量';

  @override
  String get txAddTitle => '新增交易';

  @override
  String get txEditTitle => '编辑交易';

  @override
  String get txCategoryLabel => '分类';

  @override
  String get txCategoryEmpty => '选择分类';

  @override
  String get txAccountLabel => '账户';

  @override
  String get txAccountEmpty => '目前没有可用账户——请先创建一个';

  @override
  String get txAccountPickerTitle => '选择账户';

  @override
  String get txDateLabel => '日期';

  @override
  String get txMemoLabel => '备注';

  @override
  String get txAmountRequired => '请输入金额';

  @override
  String get txCreateAccountCta => '创建账户';

  @override
  String get txTransactionNotFound => '找不到此笔交易';

  @override
  String get txSaveFailedSnackbar => '保存失败,请再试一次。';

  @override
  String get txDeleteFailedSnackbar => '删除失败,请再试一次。';

  @override
  String get txDeleteConfirmTitle => '要删除这笔交易吗?';

  @override
  String get txDeleteConfirmBody => '此交易将永久移除,且无法撤销。';

  @override
  String get txDiscardConfirmTitle => '舍弃编辑?';

  @override
  String get txDiscardConfirmBody => '尚未保存的更改将会丢失。';

  @override
  String get txCurrencyChangeConfirmTitle => '切换币种?';

  @override
  String get txCurrencyChangeConfirmBody => '切换此账户将更改货币。当前金额或计算结果将被清除。';

  @override
  String get txKeypadClear => '清除金额';

  @override
  String get txKeypadBackspace => '退格';

  @override
  String get txKeypadAdd => '加';

  @override
  String get txKeypadSubtract => '减';

  @override
  String get txKeypadMultiply => '乘';

  @override
  String get txKeypadDivide => '除';

  @override
  String get homeEmptyDayMessage => '无交易';

  @override
  String get homeJumpToToday => '跳至今天';

  @override
  String get homeSummaryMultiCurrencyNote => '多种币种';

  @override
  String get homeDaySkeletonLabel => '加载中的日期';

  @override
  String get homeDeleteUndoSnackbar => '交易已删除';

  @override
  String get homeDuplicateAction => '复制';

  @override
  String get homeDayLabelToday => '今天';

  @override
  String get homeDayLabelYesterday => '昨天';

  @override
  String get homeDayNavPrevLabel => '前一天';

  @override
  String get homeDayNavNextLabel => '后一天';

  @override
  String get txCurrencyLabel => '币种';

  @override
  String get txCurrencyPickerTitle => '选择币种';

  @override
  String get txCurrencySearchHint => '搜索币种';

  @override
  String get txCurrencyChangeConfirmAction => '更换并清除';

  @override
  String txAmountPlaceholderInCurrency(String code) {
    return '输入 $code 金额';
  }

  @override
  String get txCurrencyPickerNoResults => '未找到币种';

  @override
  String get txCurrencyPickerChangeConfirmBody => '更改货币将清除当前金额或计算结果。';

  @override
  String accountsBalanceMore(int count) {
    return '+$count 个更多';
  }

  @override
  String get shoppingListCardTitle => '购物清单';

  @override
  String get shoppingListViewAll => '查看全部';

  @override
  String get shoppingListEmptyBody => '暂无待支出';

  @override
  String get shoppingListEmptyCta => '加入购物清单';

  @override
  String shoppingListItemsMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有$count条',
    );
    return '$_temp0';
  }

  @override
  String get shoppingListScreenTitle => '购物清单';

  @override
  String get shoppingListDeleteUndoSnackbar => '草稿已删除';

  @override
  String get shoppingListDeleteAction => '删除';

  @override
  String get shoppingListScreenEmptyBody => '暂无待支出';

  @override
  String get shoppingListScreenEmptyCta => '加入购物清单';

  @override
  String get shoppingListScreenRetry => '重试';

  @override
  String get currencyUsd => '美元';

  @override
  String get currencyEur => '欧元';

  @override
  String get currencyJpy => '日元';

  @override
  String get currencyTwd => '新台币';

  @override
  String get currencyCny => '人民币';

  @override
  String get currencyHkd => '港元';

  @override
  String get currencyGbp => '英镑';

  @override
  String get currencyCad => '加拿大元';

  @override
  String get currencySgd => '新加坡元';

  @override
  String get currencyAud => '澳元';

  @override
  String get currencyNzd => '新西兰元';

  @override
  String get shoppingListEditDraftTitle => '编辑草稿';

  @override
  String get shoppingListAddToListAction => '加入购物清单';

  @override
  String get shoppingListSaveDraftAction => '保存草稿';

  @override
  String get shoppingListSaveToTransactionAction => '保存为交易';

  @override
  String get shoppingListArchivedAccountWarning => '账户已存档——转换前请先更换';

  @override
  String get shoppingListArchivedCategoryWarning => '类别已存档——转换前请先更换';

  @override
  String get shoppingListSaveFailedSnackbar => '草稿保存失败';

  @override
  String get shoppingListConvertFailedSnackbar => '草稿转换失败';

  @override
  String get shoppingListDraftNotFoundSnackbar => '找不到草稿';

  @override
  String get shoppingListSavedDraftSnackbar => '草稿已保存';

  @override
  String get shoppingListConvertedSnackbar => '草稿已转换为交易';

  @override
  String get manageAccountsTitle => '管理账户';

  @override
  String get manageAccountsCreateCta => '创建账户';

  @override
  String manageAccountsSetDefaultSuccess(String name) {
    return '$name 已设为默认账户。';
  }

  @override
  String get manageAccountsSetDefaultFailed => '无法更改默认账户，请重试。';

  @override
  String get manageAccountsLoadError => '无法加载账户。';

  @override
  String manageAccountsTileSubtitleMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' +$count 个',
      one: ' +1 个',
    );
    return '$_temp0';
  }

  @override
  String get manageAccountsTileSubtitleAddCta => '添加账户';

  @override
  String get manageAccountsBodyEmpty => '还没有账户，创建一个开始吧。';

  @override
  String get analysisPlaceholderTitle => '分析功能将在第二阶段推出';

  @override
  String get analysisPlaceholderBody => '图表和摘要将在第二阶段上线后显示。';

  @override
  String get analysisTitle => '分析';

  @override
  String get analysisSearchHint => '搜索交易记录…';

  @override
  String get analysisSearchPrompt => '搜索备注以查找过往交易';

  @override
  String get analysisNoResults => '未找到交易记录';

  @override
  String analysisTransactionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 笔交易';
  }

  @override
  String get analysisSearchTotal => '总计';

  @override
  String get analysisErrorMessage => '搜索时发生错误';

  @override
  String get settingsRecurringTile => '周期性交易';

  @override
  String get recurringRulesTitle => '周期性交易';

  @override
  String get recurringEmptyHeading => '还没有周期性规则';

  @override
  String get recurringEmptyBody =>
      '为房租、订阅或任何重复的支出设置一条规则，Ledgerly 会在到期日为你创建一笔待处理交易。';

  @override
  String get recurringEmptyCta => '创建规则';

  @override
  String get recurringFabNew => '新规则';

  @override
  String get recurringRulesLoadError => '无法加载规则。';

  @override
  String get recurringRulesLoadRetry => '重试';

  @override
  String recurringTileNextDue(String date) {
    return '下次：$date';
  }

  @override
  String get recurringTilePaused => '已暂停';

  @override
  String get recurringSwipePause => '暂停';

  @override
  String get recurringSwipeResume => '继续';

  @override
  String get recurringSwipeDelete => '删除';

  @override
  String recurringPausedSnack(String ruleName) {
    return '已暂停 — $ruleName';
  }

  @override
  String recurringResumedSnack(String ruleName, String date) {
    return '已恢复 — $ruleName，下次到期 $date。暂停期间错过的周期不会补生成。';
  }

  @override
  String get recurringDeletedSnack => '规则已删除';

  @override
  String get recurringFormCreateTitle => '新规则';

  @override
  String get recurringFormEditTitle => '编辑规则';

  @override
  String get recurringFormNamePlaceholder => '规则名称';

  @override
  String get recurringFrequencyDaily => '每日';

  @override
  String get recurringFrequencyWeekly => '每周';

  @override
  String get recurringFrequencyMonthly => '每月';

  @override
  String get recurringFrequencyYearly => '每年';

  @override
  String get recurringDailyHelper => '从今天起每天生成一笔待处理交易。';

  @override
  String get recurringDayOfMonthHint => '如果该月较短，规则会使用该月最后一天。';

  @override
  String get recurringFieldRequired => '必填';

  @override
  String get recurringSaveCreate => '创建';

  @override
  String get recurringSaveUpdate => '保存';

  @override
  String get recurringSavedCreate => '规则已创建';

  @override
  String get recurringSavedUpdate => '规则已更新';

  @override
  String get recurringDeleteRule => '删除规则';

  @override
  String get recurringDeleteConfirm => '删除此规则？已生成的待处理项目仍会保留在「待处理交易」中。';

  @override
  String recurringEditWillNotAffectPending(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '此规则目前有 $countString 笔待处理项目，以下编辑不会更改它们 — 请在主屏审核或跳过。';
  }

  @override
  String get recurringRuleHasError => '此规则上次同步时出现问题。';

  @override
  String get recurringSavedButGenerationFailed =>
      '已保存 — 但首次执行遇到问题，我们会在下次启动时重试。';

  @override
  String get homePendingSectionTitle => '待处理';

  @override
  String get homePendingApprove => '批准';

  @override
  String get homePendingSkip => '跳过此次';

  @override
  String homePendingApprovedSnack(String ruleName) {
    return '已批准 — $ruleName';
  }

  @override
  String get homePendingSkippedSnack => '已跳过此次';

  @override
  String get homePendingLoadError => '无法加载待处理项目。';

  @override
  String homePendingShowMore(int count) {
    return '再显示 $count 项';
  }

  @override
  String get homePendingShowFewer => '显示更少';

  @override
  String get approximatelyPrefix => '约';

  @override
  String get convertedTotalLabel => '总计';

  @override
  String get homeSummaryUnconvertedHeader => '未换算';

  @override
  String get chartsPeriodDay => '日';

  @override
  String get chartsPeriodWeek => '周';

  @override
  String get chartsPeriodMonth => '月';

  @override
  String get chartsPeriodYear => '年';

  @override
  String get chartsTypeExpense => '支出';

  @override
  String get chartsTypeIncome => '收入';

  @override
  String get chartsDimensionCategory => '类别';

  @override
  String get chartsDimensionAccount => '账户';

  @override
  String get chartsDimensionCurrency => '币种';

  @override
  String get chartsNoData => '暂无交易';

  @override
  String get chartsMixedCurrencies => '显示原始币种金额';

  @override
  String get chartsRatesRequired => '等待汇率数据';

  @override
  String get chartsViewAll => '查看全部';

  @override
  String get chartsTotal => '总计';

  @override
  String get chartsOther => '其他';

  @override
  String chartsOtherCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '其他（$count 项）',
      one: '其他（1 项）',
    );
    return '$_temp0';
  }

  @override
  String get chartsAutoSwitchedToCurrency => '改用币种视图 — 类别视图所需的汇率尚未就绪。';

  @override
  String get chartsPieChart => '饼图';

  @override
  String get chartsBarChart => '条形图';

  @override
  String chartsExcludedCurrencies(String codes) {
    return '已排除：$codes — 汇率尚未就绪';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'Ledgerly';

  @override
  String get navHome => '首頁';

  @override
  String get navAnalysis => '分析';

  @override
  String get navSettings => '設定';

  @override
  String get commonSave => '儲存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '刪除';

  @override
  String get categoriesArchiveAction => '封存';

  @override
  String get homeEditAction => '編輯';

  @override
  String get commonUndo => '復原';

  @override
  String get txDiscardAction => '捨棄';

  @override
  String get txKeypadDone => '完成';

  @override
  String get transactionTypeExpense => '支出';

  @override
  String get transactionTypeIncome => '收入';

  @override
  String get homeEmptyTitle => '尚無交易紀錄';

  @override
  String get homeEmptyCta => '記錄第一筆交易';

  @override
  String get homeFabLabel => '新增交易';

  @override
  String get homeSummaryTodayExpense => '支出';

  @override
  String get homeSummaryTodayIncome => '收入';

  @override
  String get homeSummaryMonthNet => '本月淨額';

  @override
  String get errorSnackbarGeneric => '發生錯誤，請再試一次。';

  @override
  String get categoryFood => '飲食';

  @override
  String get categoryDrinks => '飲料';

  @override
  String get categoryTransportation => '交通';

  @override
  String get categoryShopping => '購物';

  @override
  String get categoryHousing => '居住';

  @override
  String get categoryEntertainment => '娛樂';

  @override
  String get categoryMedical => '醫療';

  @override
  String get categoryEducation => '教育';

  @override
  String get categoryPersonal => '個人';

  @override
  String get categoryTravel => '旅遊';

  @override
  String get categoryThreeC => '3C';

  @override
  String get categoryMiscellaneous => '雜項';

  @override
  String get categoryOther => '其他';

  @override
  String get categoryIncomeSalary => '薪資';

  @override
  String get categoryIncomeFreelance => '接案';

  @override
  String get categoryIncomeInvestment => '投資';

  @override
  String get categoryIncomeGift => '餽贈';

  @override
  String get categoryIncomeOther => '其他收入';

  @override
  String get accountTypeCash => '現金';

  @override
  String get accountTypeInvestment => '投資';

  @override
  String get splashEnter => '進入';

  @override
  String get splashSetStartDate => '設定起始日期';

  @override
  String splashSinceDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '自 $dateString 起';
  }

  @override
  String get splashDayCountLabel => '天';

  @override
  String get settingsSplashSection => '啟動畫面';

  @override
  String get settingsSplashEnabled => '顯示啟動畫面';

  @override
  String get settingsSplashStartDate => '起始日期';

  @override
  String get settingsSplashDisplayText => '顯示文字';

  @override
  String get settingsSplashButtonLabel => '按鈕文字';

  @override
  String get settingsSplashPreviewCta => '預覽啟動畫面';

  @override
  String get categoriesManageTitle => '管理分類';

  @override
  String get categoriesAddCta => '新增分類';

  @override
  String get categoriesSectionExpense => '支出';

  @override
  String get categoriesSectionIncome => '收入';

  @override
  String get categoriesFormNameLabel => '名稱';

  @override
  String get categoriesFormIconLabel => '圖示';

  @override
  String get categoriesFormColorLabel => '顏色';

  @override
  String get categoriesFormTypeLabel => '類型';

  @override
  String get categoriesFormTypeLockedHint => '使用後類型無法變更';

  @override
  String get categoriesArchiveUndoSnackbar => '已封存分類';

  @override
  String get categoriesDeleteConfirmTitle => '要刪除分類嗎？';

  @override
  String get categoriesDeleteConfirmBody => '此操作無法復原。';

  @override
  String get categoriesPickerTitleExpense => '選擇支出分類';

  @override
  String get categoriesPickerTitleIncome => '選擇收入分類';

  @override
  String get categoriesPickerEmptyCta => '尚無分類 — 建立一個';

  @override
  String get accountsListTitle => '帳戶';

  @override
  String get accountsAddCta => '新增帳戶';

  @override
  String get accountsEmptyTitle => '沒有使用中的帳戶';

  @override
  String get accountsEmptyCta => '建立帳戶';

  @override
  String get accountsArchivedSectionLabel => '已封存';

  @override
  String get accountsSetDefaultAction => '設為預設';

  @override
  String get accountsDefaultBadge => '預設';

  @override
  String get accountsArchiveAction => '封存';

  @override
  String get accountsDeleteAction => '刪除';

  @override
  String get accountsArchiveUndoSnackbar => '已封存帳戶';

  @override
  String get accountsDeleteConfirmTitle => '要刪除帳戶嗎？';

  @override
  String get accountsDeleteConfirmBody => '此操作無法復原。';

  @override
  String get accountsArchiveLastActiveBlocked => '無法封存唯一的使用中帳戶';

  @override
  String get accountsDeleteDefaultBlockedTitle => '請先變更預設帳戶';

  @override
  String get accountsDeleteDefaultBlockedBody => '刪除前請先選擇其他預設帳戶。';

  @override
  String get accountsFormAddTitle => '新帳戶';

  @override
  String get accountsFormEditTitle => '編輯帳戶';

  @override
  String get accountsFormName => '名稱';

  @override
  String get accountsFormType => '帳戶類型';

  @override
  String get accountsFormCurrency => '幣別';

  @override
  String get accountsFormOpeningBalance => '期初餘額';

  @override
  String get accountsFormIcon => '圖示';

  @override
  String get accountsFormColor => '顏色';

  @override
  String get accountsFormPickType => '選擇帳戶類型';

  @override
  String get accountsFormPickCurrency => '選擇幣別';

  @override
  String get accountsFormNotFound => '此帳戶已不存在。';

  @override
  String get accountsTypePickerTitle => '選擇帳戶類型';

  @override
  String get accountsTypeCreateInlineCta => '建立新的帳戶類型';

  @override
  String get accountsTypeFormTitle => '新帳戶類型';

  @override
  String get accountsTypeFormName => '名稱';

  @override
  String get accountsTypeFormDefaultCurrency => '預設幣別';

  @override
  String get accountsCurrencyPickerTitle => '選擇幣別';

  @override
  String get settingsSectionAppearance => '外觀';

  @override
  String get settingsSectionGeneral => '一般';

  @override
  String get settingsSectionDataManagement => '資料管理';

  @override
  String get settingsThemeLabel => '主題';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsLanguageLabel => '語言';

  @override
  String get settingsLanguageSystem => '跟隨系統';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageZhTw => '繁體中文';

  @override
  String get settingsLanguageZhCn => '简体中文';

  @override
  String get settingsDefaultAccountLabel => '預設帳戶';

  @override
  String get settingsDefaultAccountEmpty => '尚未設定';

  @override
  String get settingsDefaultAccountPickerTitle => '選擇預設帳戶';

  @override
  String get settingsDefaultAccountCreateCta => '建立帳戶';

  @override
  String get settingsDefaultCurrencyLabel => '預設幣別';

  @override
  String get settingsDefaultCurrencyPickerTitle => '選擇預設幣別';

  @override
  String get settingsManageCategories => '管理分類';

  @override
  String get settingsSplashDisplayTextHint => '可使用 [date] 與 [days] 作為變數';

  @override
  String get txAddTitle => '新增交易';

  @override
  String get txEditTitle => '編輯交易';

  @override
  String get txCategoryLabel => '分類';

  @override
  String get txCategoryEmpty => '選擇分類';

  @override
  String get txAccountLabel => '帳戶';

  @override
  String get txAccountEmpty => '目前沒有可用帳戶——請先建立一個';

  @override
  String get txAccountPickerTitle => '選擇帳戶';

  @override
  String get txDateLabel => '日期';

  @override
  String get txMemoLabel => '備註';

  @override
  String get txAmountRequired => '請輸入金額';

  @override
  String get txCreateAccountCta => '建立帳戶';

  @override
  String get txTransactionNotFound => '找不到此筆交易';

  @override
  String get txSaveFailedSnackbar => '儲存失敗,請再試一次。';

  @override
  String get txDeleteFailedSnackbar => '刪除失敗,請再試一次。';

  @override
  String get txDeleteConfirmTitle => '要刪除這筆交易嗎?';

  @override
  String get txDeleteConfirmBody => '此交易將永久移除,且無法復原。';

  @override
  String get txDiscardConfirmTitle => '捨棄編輯?';

  @override
  String get txDiscardConfirmBody => '尚未儲存的變更將會遺失。';

  @override
  String get txCurrencyChangeConfirmTitle => '切換幣別?';

  @override
  String get txCurrencyChangeConfirmBody => '切換此帳戶將更改貨幣。目前金額或計算結果將被清除。';

  @override
  String get txKeypadClear => '清除金額';

  @override
  String get txKeypadBackspace => '退格';

  @override
  String get txKeypadAdd => '加';

  @override
  String get txKeypadSubtract => '減';

  @override
  String get txKeypadMultiply => '乘';

  @override
  String get txKeypadDivide => '除';

  @override
  String get homeEmptyDayMessage => '無交易';

  @override
  String get homeJumpToToday => '跳至今天';

  @override
  String get homeSummaryMultiCurrencyNote => '多種幣別';

  @override
  String get homeDaySkeletonLabel => '載入中的日期';

  @override
  String get homeDeleteUndoSnackbar => '交易已刪除';

  @override
  String get homeDuplicateAction => '複製';

  @override
  String get homeDayLabelToday => '今天';

  @override
  String get homeDayLabelYesterday => '昨天';

  @override
  String get homeDayNavPrevLabel => '前一天';

  @override
  String get homeDayNavNextLabel => '後一天';

  @override
  String get txCurrencyLabel => '幣別';

  @override
  String get txCurrencyPickerTitle => '選擇幣別';

  @override
  String get txCurrencySearchHint => '搜尋幣別';

  @override
  String get txCurrencyChangeConfirmAction => '更換並清除';

  @override
  String txAmountPlaceholderInCurrency(String code) {
    return '輸入 $code 金額';
  }

  @override
  String get txCurrencyPickerNoResults => '找不到幣別';

  @override
  String get txCurrencyPickerChangeConfirmBody => '更改貨幣將清除目前金額或計算結果。';

  @override
  String accountsBalanceMore(int count) {
    return '+$count 個更多';
  }

  @override
  String get shoppingListCardTitle => '購物清單';

  @override
  String get shoppingListViewAll => '查看全部';

  @override
  String get shoppingListEmptyBody => '尚無待支出';

  @override
  String get shoppingListEmptyCta => '加入購物清單';

  @override
  String shoppingListItemsMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '還有$count筆',
    );
    return '$_temp0';
  }

  @override
  String get shoppingListScreenTitle => '購物清單';

  @override
  String get shoppingListDeleteUndoSnackbar => '草稿已刪除';

  @override
  String get shoppingListDeleteAction => '刪除';

  @override
  String get shoppingListScreenEmptyBody => '尚無待支出';

  @override
  String get shoppingListScreenEmptyCta => '加入購物清單';

  @override
  String get shoppingListScreenRetry => '重試';

  @override
  String get currencyUsd => '美元';

  @override
  String get currencyEur => '歐元';

  @override
  String get currencyJpy => '日圓';

  @override
  String get currencyTwd => '新台幣';

  @override
  String get currencyCny => '人民幣';

  @override
  String get currencyHkd => '港幣';

  @override
  String get currencyGbp => '英鎊';

  @override
  String get currencyCad => '加拿大元';

  @override
  String get currencySgd => '新加坡元';

  @override
  String get currencyAud => '澳幣';

  @override
  String get currencyNzd => '紐西蘭元';

  @override
  String get shoppingListEditDraftTitle => '編輯草稿';

  @override
  String get shoppingListAddToListAction => '加入購物清單';

  @override
  String get shoppingListSaveDraftAction => '儲存草稿';

  @override
  String get shoppingListSaveToTransactionAction => '儲存為交易';

  @override
  String get shoppingListArchivedAccountWarning => '帳戶已封存——轉換前請先更換';

  @override
  String get shoppingListArchivedCategoryWarning => '類別已封存——轉換前請先更換';

  @override
  String get shoppingListSaveFailedSnackbar => '草稿儲存失敗';

  @override
  String get shoppingListConvertFailedSnackbar => '草稿轉換失敗';

  @override
  String get shoppingListDraftNotFoundSnackbar => '找不到草稿';

  @override
  String get shoppingListSavedDraftSnackbar => '草稿已儲存';

  @override
  String get shoppingListConvertedSnackbar => '草稿已轉換為交易';

  @override
  String get manageAccountsTitle => '管理帳戶';

  @override
  String get manageAccountsCreateCta => '建立帳戶';

  @override
  String manageAccountsSetDefaultSuccess(String name) {
    return '$name 已設為預設帳戶。';
  }

  @override
  String get manageAccountsSetDefaultFailed => '無法變更預設帳戶，請重試。';

  @override
  String get manageAccountsLoadError => '無法載入帳戶。';

  @override
  String manageAccountsTileSubtitleMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' +$count 個',
      one: ' +1 個',
    );
    return '$_temp0';
  }

  @override
  String get manageAccountsTileSubtitleAddCta => '新增帳戶';

  @override
  String get manageAccountsBodyEmpty => '還沒有帳戶，建立一個開始吧。';

  @override
  String get analysisPlaceholderTitle => '分析功能將在第二階段推出';

  @override
  String get analysisPlaceholderBody => '圖表和摘要將在第二階段上線後顯示。';

  @override
  String get analysisTitle => '分析';

  @override
  String get analysisSearchHint => '搜尋交易紀錄…';

  @override
  String get analysisSearchPrompt => '搜尋備註以尋找過往交易';

  @override
  String get analysisNoResults => '找不到交易紀錄';

  @override
  String analysisTransactionCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 筆交易';
  }

  @override
  String get analysisSearchTotal => '總計';

  @override
  String get analysisErrorMessage => '搜尋時發生錯誤';

  @override
  String get settingsRecurringTile => '週期性交易';

  @override
  String get recurringRulesTitle => '週期性交易';

  @override
  String get recurringEmptyHeading => '尚未建立週期性規則';

  @override
  String get recurringEmptyBody =>
      '為房租、訂閱或任何重複的支出設定一條規則，Ledgerly 會在到期日為你建立一筆待處理交易。';

  @override
  String get recurringEmptyCta => '建立規則';

  @override
  String get recurringFabNew => '新規則';

  @override
  String get recurringRulesLoadError => '無法載入規則。';

  @override
  String get recurringRulesLoadRetry => '重試';

  @override
  String recurringTileNextDue(String date) {
    return '下次：$date';
  }

  @override
  String get recurringTilePaused => '已暫停';

  @override
  String get recurringSwipePause => '暫停';

  @override
  String get recurringSwipeResume => '繼續';

  @override
  String get recurringSwipeDelete => '刪除';

  @override
  String recurringPausedSnack(String ruleName) {
    return '已暫停 — $ruleName';
  }

  @override
  String recurringResumedSnack(String ruleName, String date) {
    return '已恢復 — $ruleName，下次到期 $date。暫停期間錯過的週期不會補產生。';
  }

  @override
  String get recurringDeletedSnack => '規則已刪除';

  @override
  String get recurringFormCreateTitle => '新規則';

  @override
  String get recurringFormEditTitle => '編輯規則';

  @override
  String get recurringFormNamePlaceholder => '規則名稱';

  @override
  String get recurringFrequencyDaily => '每日';

  @override
  String get recurringFrequencyWeekly => '每週';

  @override
  String get recurringFrequencyMonthly => '每月';

  @override
  String get recurringFrequencyYearly => '每年';

  @override
  String get recurringDailyHelper => '從今天起每天產生一筆待處理交易。';

  @override
  String get recurringDayOfMonthHint => '若該月較短，規則會使用該月最後一天。';

  @override
  String get recurringFieldRequired => '必填';

  @override
  String get recurringSaveCreate => '建立';

  @override
  String get recurringSaveUpdate => '儲存';

  @override
  String get recurringSavedCreate => '規則已建立';

  @override
  String get recurringSavedUpdate => '規則已更新';

  @override
  String get recurringDeleteRule => '刪除規則';

  @override
  String get recurringDeleteConfirm => '刪除此規則？已產生的待處理項目仍會保留在「待處理交易」中。';

  @override
  String recurringEditWillNotAffectPending(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    return '此規則目前有 $countString 筆待處理項目，以下編輯不會更改它們 — 請在主畫面審核或略過。';
  }

  @override
  String get recurringRuleHasError => '此規則上次同步時發生問題。';

  @override
  String get recurringSavedButGenerationFailed =>
      '已儲存 — 但首次執行遇到問題，我們會在下次啟動時重試。';

  @override
  String get homePendingSectionTitle => '待處理';

  @override
  String get homePendingApprove => '核准';

  @override
  String get homePendingSkip => '略過此次';

  @override
  String homePendingApprovedSnack(String ruleName) {
    return '已核准 — $ruleName';
  }

  @override
  String get homePendingSkippedSnack => '已略過此次';

  @override
  String get homePendingLoadError => '無法載入待處理項目。';

  @override
  String homePendingShowMore(int count) {
    return '再顯示 $count 項';
  }

  @override
  String get homePendingShowFewer => '顯示較少';

  @override
  String get approximatelyPrefix => '約';

  @override
  String get convertedTotalLabel => '總計';

  @override
  String get homeSummaryUnconvertedHeader => '未換算';

  @override
  String get chartsPeriodDay => '日';

  @override
  String get chartsPeriodWeek => '週';

  @override
  String get chartsPeriodMonth => '月';

  @override
  String get chartsPeriodYear => '年';

  @override
  String get chartsTypeExpense => '支出';

  @override
  String get chartsTypeIncome => '收入';

  @override
  String get chartsDimensionCategory => '類別';

  @override
  String get chartsDimensionAccount => '帳戶';

  @override
  String get chartsDimensionCurrency => '幣別';

  @override
  String get chartsNoData => '尚無交易';

  @override
  String get chartsMixedCurrencies => '顯示原始幣別金額';

  @override
  String get chartsRatesRequired => '等待匯率資料';

  @override
  String get chartsViewAll => '查看全部';

  @override
  String get chartsTotal => '總計';

  @override
  String get chartsOther => '其他';

  @override
  String chartsOtherCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '其他（$count 項）',
      one: '其他（1 項）',
    );
    return '$_temp0';
  }

  @override
  String get chartsAutoSwitchedToCurrency => '改以幣別檢視 — 尚未取得類別檢視所需的匯率。';

  @override
  String get chartsPieChart => '圓餅圖';

  @override
  String get chartsBarChart => '長條圖';

  @override
  String chartsExcludedCurrencies(String codes) {
    return '已排除：$codes — 尚未取得匯率';
  }
}
