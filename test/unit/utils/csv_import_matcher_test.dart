// Unit tests for `CsvImportMatcher`: account tiers and category label
// matching across en / zh_TW / zh_CN, with real `AppLocalizations`.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/core/utils/fortune_city_csv_parser.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/account_type.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/csv_import.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/seed/first_run_seed.dart';
import 'package:ledgerly/features/settings/csv_import/csv_import_matcher.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

import '../../support/test_app.dart';

const _hkd = Currency(code: 'HKD', decimals: 2);
const _usd = Currency(code: 'USD', decimals: 2);

final _labelSets = [
  lookupAppLocalizations(const Locale('en')),
  lookupAppLocalizations(const Locale('zh', 'TW')),
  lookupAppLocalizations(const Locale('zh', 'CN')),
];

var _line = 1;

CsvImportRow _row({
  String account = 'Cash',
  String category = '食物',
  Currency currency = _hkd,
  String? memo,
}) => CsvImportRow(
  line: ++_line,
  account: account,
  category: category,
  amountMinorUnits: 100,
  currency: currency,
  recordedAt: DateTime(2026, 10, 30, 10, 39),
  memo: memo,
);

Category _cat(
  int id, {
  String? l10nKey,
  String? customName,
  CategoryType type = CategoryType.expense,
  int? sortOrder,
  bool isArchived = false,
}) => Category(
  id: id,
  icon: 'category',
  color: 0,
  type: type,
  l10nKey: l10nKey,
  customName: customName,
  sortOrder: sortOrder ?? id,
  isArchived: isArchived,
);

AccountType _type(
  int id, {
  String? l10nKey,
  String? customName,
  bool isArchived = false,
}) => AccountType(
  id: id,
  l10nKey: l10nKey,
  customName: customName,
  icon: 'wallet',
  color: 0,
  sortOrder: id,
  isArchived: isArchived,
);

Account _account(
  int id,
  String name,
  int accountTypeId, {
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: accountTypeId,
  currency: _hkd,
  sortOrder: id,
  isArchived: isArchived,
);

/// Seeded income categories the income marker needs, plus the given ones.
final _salary = _cat(
  90,
  l10nKey: 'category.income.salary',
  type: CategoryType.income,
);
final _otherIncome = _cat(
  91,
  l10nKey: 'category.income.other',
  type: CategoryType.income,
);

final _cashType = _type(1, l10nKey: 'accountType.cash');
final _investmentType = _type(2, l10nKey: 'accountType.investment');

CsvImportMatch _match(
  List<CsvImportRow> rows, {
  List<Category> categories = const [],
  List<Account> accounts = const [],
  List<AccountType>? accountTypes,
  String defaultCurrencyCode = 'HKD',
  List<AppLocalizations>? labelSets,
}) => CsvImportMatcher.resolve(
  rows: rows,
  categories: [...categories, _salary, _otherIncome],
  accounts: accounts,
  accountTypes: accountTypes ?? [_cashType, _investmentType],
  labelSets: labelSets ?? _labelSets,
  defaultCurrencyCode: defaultCurrencyCode,
);

CsvAccountMatch _accountEntry(CsvImportMatch match, String value) =>
    match.accounts.singleWhere((e) => e.csvValue == value);

CsvCategoryMatch _categoryEntry(CsvImportMatch match, String value) =>
    match.categories.singleWhere((e) => e.csvValue == value);

void main() {
  group('sample export on a fresh en_US install', () {
    late List<CsvImportRow> rows;
    late List<Category> categories;
    late List<Account> accounts;
    late List<AccountType> accountTypes;
    late CsvImportMatch match;

    setUpAll(() async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await runTestSeed(db);
      final currencies = DriftCurrencyRepository(db);
      categories = await DriftCategoryRepository(db)
          .watchAll(includeArchived: true)
          .first;
      accounts = await DriftAccountRepository(
        db,
        currencies,
      ).watchAll(includeArchived: true).first;
      accountTypes = await DriftAccountTypeRepository(
        db,
        currencies,
      ).watchAll(includeArchived: true).first;

      final parsed = parseFortuneCityCsv(
        File('test/data/import_fortune_city_data.csv').readAsBytesSync(),
      );
      rows = [
        for (final r in parsed.rows)
          CsvImportRow(
            line: r.line,
            account: r.account,
            category: r.category,
            amountMinorUnits: 100,
            currency: _hkd,
            recordedAt: r.recordedAt,
            memo: r.memo,
          ),
      ];
      match = CsvImportMatcher.resolve(
        rows: rows,
        categories: categories,
        accounts: accounts,
        accountTypes: accountTypes,
        labelSets: _labelSets,
        defaultCurrencyCode: 'HKD',
      );
    });

    int categoryId(String l10nKey) =>
        categories.singleWhere((c) => c.l10nKey == l10nKey).id;

    test('every category value resolves as the spec table says', () {
      final expected = <String, (int, CategoryResolution)>{
        '食物': (26, CategoryResolution.existing(categoryId('category.food'))),
        '交通': (
          24,
          CategoryResolution.existing(categoryId('category.transportation')),
        ),
        '飲品': (11, CategoryResolution.existing(categoryId('category.drinks'))),
        '收入': (
          10,
          CategoryResolution.incomeByNote(
            salaryCategoryId: categoryId('category.income.salary'),
            otherCategoryId: categoryId('category.income.other'),
          ),
        ),
        '理財': (
          8,
          CategoryResolution.existing(categoryId('category.investment')),
        ),
        '娛樂': (
          6,
          CategoryResolution.existing(categoryId('category.entertainment')),
        ),
        '醫藥': (5, CategoryResolution.existing(categoryId('category.medical'))),
        '3C': (3, CategoryResolution.existing(categoryId('category.threeC'))),
        '居家': (2, CategoryResolution.existing(categoryId('category.housing'))),
        '消費': (2, CategoryResolution.existing(categoryId('category.shopping'))),
        '其他': (1, CategoryResolution.existing(categoryId('category.other'))),
        '還款': (
          3,
          const CategoryResolution.create(
            name: '還款',
            type: CategoryType.expense,
          ),
        ),
        '個人護理': (
          2,
          const CategoryResolution.create(
            name: '個人護理',
            type: CategoryType.expense,
          ),
        ),
        '休閒': (
          2,
          const CategoryResolution.create(
            name: '休閒',
            type: CategoryType.expense,
          ),
        ),
      };

      expect(match.categories, hasLength(14));
      for (final entry in expected.entries) {
        final got = _categoryEntry(match, entry.key);
        expect(got.rowCount, entry.value.$1, reason: entry.key);
        expect(got.resolution, entry.value.$2, reason: entry.key);
        expect(
          got.isNew,
          entry.value.$2 is CreateCategoryResolution,
          reason: entry.key,
        );
      }
    });

    test('one 收入 row is Salary (note 薪資), nine are Other income', () {
      final income = _categoryEntry(match, '收入');
      expect(income.salaryRowCount, 1);
      expect(income.rowCount - income.salaryRowCount, 9);
    });

    test('Cash is tier 1, Investment is tier 2b, Credit Card is tier 3', () {
      final seededCash = accounts.singleWhere(
        (a) => a.name == kSeededCashAccountName,
      );
      final investmentType = accountTypes.singleWhere(
        (t) => t.l10nKey == 'accountType.investment',
      );

      final cash = _accountEntry(match, 'Cash');
      expect(cash.tier, CsvAccountTier.name);
      expect(cash.rowCount, 46);
      expect(cash.resolution, AccountResolution.existing(seededCash.id));
      expect(cash.isNew, isFalse);

      final investment = _accountEntry(match, 'Investment');
      expect(investment.tier, CsvAccountTier.typeWithoutAccount);
      expect(investment.rowCount, 3);
      expect(investment.matchedType, investmentType);
      expect(
        investment.resolution,
        AccountResolution.createAccount(
          name: 'Investment',
          accountTypeId: investmentType.id,
          currencyCode: 'HKD',
        ),
      );
      expect(investment.isNew, isTrue);

      final creditCard = _accountEntry(match, 'Credit Card');
      expect(creditCard.tier, CsvAccountTier.none);
      expect(creditCard.rowCount, 56);
      expect(creditCard.resolution, isNull);
      expect(creditCard.matchedType, isNull);
      expect(creditCard.createAccountOption, isNull);
      expect(
        creditCard.createTypeAndAccountOption,
        const AccountResolution.createTypeAndAccount(
          name: 'Credit Card',
          currencyCode: 'HKD',
        ),
      );
      expect(creditCard.options, [seededCash]);
    });

    test('salaryNotes holds the Salary label of every locale and 薪资', () {
      expect(match.salaryNotes, {'Salary', '薪資', '工资', '薪资'});
    });

    test('the result does not depend on the order of the label sets', () {
      final reordered = CsvImportMatcher.resolve(
        rows: rows,
        categories: categories,
        accounts: accounts,
        accountTypes: accountTypes,
        labelSets: _labelSets.reversed.toList(),
        defaultCurrencyCode: 'HKD',
      );
      expect(reordered, match);
    });
  });

  group('categories', () {
    test('income marker in every locale; Salary only by the note', () {
      final match = _match([
        _row(category: '收入', memo: '薪資'),
        _row(category: '收入', memo: '工资'),
        _row(category: '收入', memo: ' Salary '),
        _row(category: '收入', memo: '午餐'),
        _row(category: '收入', memo: ''),
        _row(category: '收入'),
        _row(category: 'Income', memo: 'salary'),
      ]);

      final zh = _categoryEntry(match, '收入');
      expect(
        zh.resolution,
        CategoryResolution.incomeByNote(
          salaryCategoryId: _salary.id,
          otherCategoryId: _otherIncome.id,
        ),
      );
      expect(zh.rowCount, 6);
      expect(zh.salaryRowCount, 3);
      expect(zh.isNew, isFalse);

      final en = _categoryEntry(match, 'Income');
      expect(en.resolution, zh.resolution);
      expect(en.salaryRowCount, 1);
    });

    test('薪资, the Simplified form of 薪資, is a Salary note too', () {
      final match = _match([_row(category: '收入', memo: '薪资')]);
      expect(_categoryEntry(match, '收入').salaryRowCount, 1);
    });

    test('a retired, archived category.personal still matches its labels', () {
      final personal = _cat(5, l10nKey: 'category.personal', isArchived: true);
      final match = _match(
        [
          _row(category: '個人'),
          _row(category: '个人'),
          _row(category: 'personal'),
        ],
        categories: [personal],
      );
      for (final value in ['個人', '个人', 'personal']) {
        expect(
          _categoryEntry(match, value).resolution,
          CategoryResolution.existing(personal.id),
          reason: value,
        );
      }
    });

    test('English "Investment" prefers the expense category', () {
      final expense = _cat(17, l10nKey: 'category.investment');
      final income = _cat(
        14,
        l10nKey: 'category.income.investment',
        type: CategoryType.income,
      );
      final match = _match(
        [_row(category: 'Investment'), _row(category: '投資')],
        categories: [income, expense],
      );
      expect(
        _categoryEntry(match, 'Investment').resolution,
        CategoryResolution.existing(expense.id),
      );
      // 投資 is only the income label.
      expect(
        _categoryEntry(match, '投資').resolution,
        CategoryResolution.existing(income.id),
      );
    });

    test('custom names match, and a seeded label beats a custom one', () {
      final food = _cat(1, l10nKey: 'category.food');
      final customFood = _cat(30, customName: '食物', sortOrder: 0);
      final repayment = _cat(31, customName: '還款');
      final match = _match(
        [_row(category: '食物'), _row(category: '還款')],
        categories: [customFood, food, repayment],
      );
      expect(
        _categoryEntry(match, '食物').resolution,
        CategoryResolution.existing(food.id),
      );
      expect(
        _categoryEntry(match, '還款').resolution,
        CategoryResolution.existing(repayment.id),
      );
    });

    test('a renamed seeded category still matches its l10n labels', () {
      final food = _cat(1, l10nKey: 'category.food', customName: 'Meals');
      final match = _match(
        [_row(category: '食物'), _row(category: 'meals')],
        categories: [food],
      );
      expect(
        _categoryEntry(match, '食物').resolution,
        CategoryResolution.existing(food.id),
      );
      expect(
        _categoryEntry(match, 'meals').resolution,
        CategoryResolution.existing(food.id),
      );
    });

    test('archived matches are used; active wins a tie', () {
      final archivedLeisure = _cat(40, customName: '休閒', isArchived: true);
      final archivedHobby = _cat(41, customName: 'Hobby', isArchived: true);
      final hobby = _cat(42, customName: 'hobby');
      final match = _match(
        [_row(category: '休閒'), _row(category: 'HOBBY')],
        categories: [archivedLeisure, archivedHobby, hobby],
      );
      expect(
        _categoryEntry(match, '休閒').resolution,
        CategoryResolution.existing(archivedLeisure.id),
      );
      expect(
        _categoryEntry(match, 'HOBBY').resolution,
        CategoryResolution.existing(hobby.id),
      );
    });

    test('ties go to the lowest sortOrder, then the lowest id', () {
      final match = _match(
        [_row(category: 'Pets'), _row(category: 'Kids')],
        categories: [
          _cat(50, customName: 'Pets', sortOrder: 9),
          _cat(51, customName: 'Pets', sortOrder: 3),
          _cat(53, customName: 'Kids', sortOrder: 1),
          _cat(52, customName: 'Kids', sortOrder: 1),
        ],
      );
      expect(
        _categoryEntry(match, 'Pets').resolution,
        const CategoryResolution.existing(51),
      );
      expect(
        _categoryEntry(match, 'Kids').resolution,
        const CategoryResolution.existing(52),
      );
    });

    test('an unmatched value becomes a new expense category', () {
      final match = _match([_row(category: '個人護理')]);
      final entry = _categoryEntry(match, '個人護理');
      expect(
        entry.resolution,
        const CategoryResolution.create(
          name: '個人護理',
          type: CategoryType.expense,
        ),
      );
      expect(entry.isNew, isTrue);
    });
  });

  group('accounts', () {
    test('tier 1 matches one active account by normalized name', () {
      final cash = _account(1, 'Cash', _cashType.id);
      final match = _match([_row(account: ' cash ')], accounts: [cash]);
      final entry = _accountEntry(match, ' cash ');
      expect(entry.tier, CsvAccountTier.name);
      expect(entry.resolution, AccountResolution.existing(cash.id));
      expect(entry.isNew, isFalse);
    });

    test('tier 1b: several active accounts share the name', () {
      final match = _match(
        [_row(account: 'Wallet')],
        accounts: [
          _account(1, 'Wallet', _cashType.id),
          _account(2, 'wallet', _investmentType.id),
        ],
      );
      final entry = _accountEntry(match, 'Wallet');
      expect(entry.tier, CsvAccountTier.ambiguousName);
      expect(entry.resolution, isNull);
      expect(entry.matchedType, isNull);
    });

    test('tier 2 matches the only active account of a type label', () {
      final purse = _account(1, 'My purse', _cashType.id);
      final match = _match([_row(account: '現金')], accounts: [purse]);
      final entry = _accountEntry(match, '現金');
      expect(entry.tier, CsvAccountTier.type);
      expect(entry.matchedType, _cashType);
      expect(entry.resolution, AccountResolution.existing(purse.id));
      expect(entry.isNew, isFalse);
    });

    test('tier 2 also matches a custom type name', () {
      final cardType = _type(3, customName: 'Credit Card');
      final visa = _account(1, 'HSBC Visa', cardType.id);
      final match = _match(
        [_row(account: 'Credit Card')],
        accounts: [visa],
        accountTypes: [_cashType, cardType],
      );
      final entry = _accountEntry(match, 'Credit Card');
      expect(entry.tier, CsvAccountTier.type);
      expect(entry.resolution, AccountResolution.existing(visa.id));
    });

    test('tier 2b creates an account when the type has no active one', () {
      final archived = _account(
        1,
        'Old broker',
        _investmentType.id,
        isArchived: true,
      );
      final match = _match([_row(account: '投资')], accounts: [archived]);
      final entry = _accountEntry(match, '投资');
      expect(entry.tier, CsvAccountTier.typeWithoutAccount);
      expect(
        entry.resolution,
        AccountResolution.createAccount(
          name: '投资',
          accountTypeId: _investmentType.id,
          currencyCode: 'HKD',
        ),
      );
      expect(entry.isNew, isTrue);
      expect(entry.createAccountOption, entry.resolution);
    });

    test('tier 2c: several active accounts have the matched type', () {
      final match = _match(
        [_row(account: '现金')],
        accounts: [
          _account(1, 'Purse', _cashType.id),
          _account(2, 'Piggy bank', _cashType.id),
        ],
      );
      final entry = _accountEntry(match, '现金');
      expect(entry.tier, CsvAccountTier.ambiguousType);
      expect(entry.resolution, isNull);
      expect(entry.matchedType, _cashType);
      expect(
        entry.createAccountOption,
        AccountResolution.createAccount(
          name: '现金',
          accountTypeId: _cashType.id,
          currencyCode: 'HKD',
        ),
      );
    });

    test('tier 3: no account or type matches', () {
      final match = _match([_row(account: 'Credit Card')]);
      final entry = _accountEntry(match, 'Credit Card');
      expect(entry.tier, CsvAccountTier.none);
      expect(entry.resolution, isNull);
      expect(entry.createAccountOption, isNull);
    });

    test('archived types never match', () {
      final brokerage = _type(3, customName: 'Brokerage', isArchived: true);
      final match = _match(
        [_row(account: 'Brokerage')],
        accountTypes: [_cashType, brokerage],
      );
      expect(_accountEntry(match, 'Brokerage').tier, CsvAccountTier.none);
    });

    test('an archived same-name account is an option, never a match', () {
      final cash = _account(1, 'Cash', _cashType.id);
      final archivedCard = _account(
        2,
        'Credit Card',
        _cashType.id,
        isArchived: true,
      );
      final archivedOther = _account(3, 'Old', _cashType.id, isArchived: true);
      final match = _match(
        [_row(account: 'credit card')],
        accounts: [archivedOther, archivedCard, cash],
      );
      final entry = _accountEntry(match, 'credit card');
      expect(entry.tier, CsvAccountTier.none);
      expect(entry.resolution, isNull);
      expect(entry.options, [cash, archivedCard]);
    });

    test('a created account takes the most frequent currency', () {
      final match = _match([
        _row(account: 'A', currency: _hkd),
        _row(account: 'A', currency: _hkd),
        _row(account: 'A', currency: _usd),
        _row(account: 'B', currency: _hkd),
        _row(account: 'B', currency: _usd),
      ], defaultCurrencyCode: 'USD');
      expect(_accountEntry(match, 'A').currencyCode, 'HKD');
      // A tie goes to the default currency when it is tied...
      expect(_accountEntry(match, 'B').currencyCode, 'USD');

      final noDefault = _match([
        _row(account: 'B', currency: _usd),
        _row(account: 'B', currency: _hkd),
      ], defaultCurrencyCode: 'JPY');
      // ...otherwise to the alphabetically first code.
      expect(_accountEntry(noDefault, 'B').currencyCode, 'HKD');
    });
  });
}
