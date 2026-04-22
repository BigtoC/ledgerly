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
}
