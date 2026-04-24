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
  String get commonArchive => 'Archive';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonDone => 'Done';

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
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'Ledgerly';

  @override
  String get navHome => '首页';

  @override
  String get navAccounts => '账户';

  @override
  String get navSettings => '设置';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonArchive => '归档';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonUndo => '撤销';

  @override
  String get commonDiscard => '放弃';

  @override
  String get commonAdd => '添加';

  @override
  String get commonDone => '完成';

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
  String get homeSummaryTodayExpense => '今日支出';

  @override
  String get homeSummaryTodayIncome => '今日收入';

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
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'Ledgerly';

  @override
  String get navHome => '首頁';

  @override
  String get navAccounts => '帳戶';

  @override
  String get navSettings => '設定';

  @override
  String get commonSave => '儲存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '刪除';

  @override
  String get commonArchive => '封存';

  @override
  String get commonEdit => '編輯';

  @override
  String get commonUndo => '復原';

  @override
  String get commonDiscard => '捨棄';

  @override
  String get commonAdd => '新增';

  @override
  String get commonDone => '完成';

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
  String get homeSummaryTodayExpense => '今日支出';

  @override
  String get homeSummaryTodayIncome => '今日收入';

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
}
