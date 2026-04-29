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
  String get txCurrencyChangeConfirmBody => '切換到此帳戶會改變幣別,目前輸入的金額將被清除。';

  @override
  String get txKeypadClear => '清除金額';

  @override
  String get txKeypadBackspace => '退格';

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
  String get txCurrencyPickerChangeConfirmBody => '更換幣別將清除已輸入的金額。';

  @override
  String accountsBalanceMore(int count) {
    return '+$count 個更多';
  }

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
  String get txCurrencyChangeConfirmBody => '切换到此账户会改变币种,当前输入的金额将被清除。';

  @override
  String get txKeypadClear => '清除金额';

  @override
  String get txKeypadBackspace => '退格';

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
  String get txCurrencyPickerChangeConfirmBody => '更换币种将清除已输入的金额。';

  @override
  String accountsBalanceMore(int count) {
    return '+$count 个更多';
  }

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
  String get txCurrencyChangeConfirmBody => '切換到此帳戶會改變幣別,目前輸入的金額將被清除。';

  @override
  String get txKeypadClear => '清除金額';

  @override
  String get txKeypadBackspace => '退格';

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
  String get txCurrencyPickerChangeConfirmBody => '更換幣別將清除已輸入的金額。';

  @override
  String accountsBalanceMore(int count) {
    return '+$count 個更多';
  }

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
}
