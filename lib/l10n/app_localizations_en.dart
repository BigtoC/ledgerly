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
}
