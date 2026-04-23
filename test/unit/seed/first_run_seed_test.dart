// Tests for `runFirstRunSeed` (M3 Stream C §6.2).
//
// Uses the shared in-memory harness at
// `../repositories/_harness/test_app_database.dart`. Every case has a
// direct row in the §6.2 Test Plan table.

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/data/seed/first_run_seed.dart';
import 'package:ledgerly/data/services/locale_service.dart';

import '../repositories/_harness/test_app_database.dart';

/// Stable-stub [LocaleService] — returns a fixed string regardless of the
/// host locale. Prevents CI flakes across macOS / Linux / Windows.
class _FakeLocaleService implements LocaleService {
  const _FakeLocaleService(this._locale);
  final String _locale;

  @override
  String get deviceLocale => _locale;
}

/// Bundles real `Drift*Repository` instances against an in-memory DB.
class _SeedHarness {
  _SeedHarness._(
    this.db,
    this.currencies,
    this.categories,
    this.accountTypes,
    this.accounts,
    this.preferences,
  );

  factory _SeedHarness.fresh() {
    final db = newTestAppDatabase();
    final currencies = DriftCurrencyRepository(db);
    final categories = DriftCategoryRepository(db);
    final accountTypes = DriftAccountTypeRepository(db, currencies);
    final accounts = DriftAccountRepository(db, currencies);
    final preferences = DriftUserPreferencesRepository(db);
    return _SeedHarness._(
      db,
      currencies,
      categories,
      accountTypes,
      accounts,
      preferences,
    );
  }

  final AppDatabase db;
  final CurrencyRepository currencies;
  final CategoryRepository categories;
  final AccountTypeRepository accountTypes;
  final AccountRepository accounts;
  final UserPreferencesRepository preferences;

  Future<void> seed(String locale) => runFirstRunSeed(
    db: db,
    currencies: currencies,
    categories: categories,
    accountTypes: accountTypes,
    accounts: accounts,
    preferences: preferences,
    localeService: _FakeLocaleService(locale),
  );

  Future<void> close() => db.close();
}

void main() {
  group('defaultCurrencyForLocale', () {
    test('en_US → USD', () {
      expect(defaultCurrencyForLocale('en_US'), 'USD');
    });
    test('en_GB → GBP', () {
      expect(defaultCurrencyForLocale('en_GB'), 'GBP');
    });
    test('en_CA / en_AU / en_NZ → USD (kept unchanged per §12 Q6)', () {
      expect(defaultCurrencyForLocale('en_CA'), 'USD');
      expect(defaultCurrencyForLocale('en_AU'), 'USD');
      expect(defaultCurrencyForLocale('en_NZ'), 'USD');
    });
    test('bare en → USD', () {
      expect(defaultCurrencyForLocale('en'), 'USD');
    });

    test('zh_TW → TWD', () {
      expect(defaultCurrencyForLocale('zh_TW'), 'TWD');
    });
    test('zh_HK / zh_MO → HKD', () {
      expect(defaultCurrencyForLocale('zh_HK'), 'HKD');
      expect(defaultCurrencyForLocale('zh_MO'), 'HKD');
    });
    test('zh_CN / zh_SG → CNY', () {
      expect(defaultCurrencyForLocale('zh_CN'), 'CNY');
      expect(defaultCurrencyForLocale('zh_SG'), 'CNY');
    });
    test('bare zh → CNY', () {
      expect(defaultCurrencyForLocale('zh'), 'CNY');
    });

    test('ja_JP / bare ja → JPY', () {
      expect(defaultCurrencyForLocale('ja_JP'), 'JPY');
      expect(defaultCurrencyForLocale('ja'), 'JPY');
    });

    test('de_DE → USD (fallback; §12 Q6 drops de_* → EUR)', () {
      expect(defaultCurrencyForLocale('de_DE'), 'USD');
    });
    test('fr_FR → USD (fallback; §12 Q6 drops fr_* → EUR)', () {
      expect(defaultCurrencyForLocale('fr_FR'), 'USD');
    });
    test('unknown locale kl_GL → USD (global fallback)', () {
      expect(defaultCurrencyForLocale('kl_GL'), 'USD');
    });
    test('accepts BCP-47 "-" separators', () {
      expect(defaultCurrencyForLocale('zh-TW'), 'TWD');
      expect(defaultCurrencyForLocale('en-GB'), 'GBP');
    });
  });

  group('runFirstRunSeed — empty DB', () {
    late _SeedHarness h;

    setUp(() {
      h = _SeedHarness.fresh();
    });

    tearDown(() async {
      await h.close();
    });

    test('every step populates (locale en_US)', () async {
      await h.seed('en_US');

      // Row counts.
      final allCurrencies = await h.currencies
          .watchAll(includeTokens: false)
          .first;
      expect(allCurrencies, hasLength(11));

      final allCats = await h.categories.watchAll().first;
      expect(allCats, hasLength(18));
      expect(
        allCats.where((c) => c.type == CategoryType.expense),
        hasLength(13),
      );
      expect(allCats.where((c) => c.type == CategoryType.income), hasLength(5));

      final allAccountTypes = await h.accountTypes.watchAll().first;
      expect(allAccountTypes, hasLength(2));

      final allAccounts = await h.accounts.watchAll().first;
      expect(allAccounts, hasLength(1));

      // Preferences.
      expect(await h.preferences.getFirstRunComplete(), isTrue);
      expect(await h.preferences.getSplashEnabled(), isTrue);
      expect(await h.preferences.getThemeMode(), ThemeMode.system);
      expect(await h.preferences.getLocale(), isNull);
      expect(await h.preferences.getDefaultCurrency(), 'USD');
      expect(await h.preferences.getSplashDisplayText(), 'Since {date}');
      expect(await h.preferences.getSplashButtonLabel(), 'Enter');
      expect(await h.preferences.getSplashStartDate(), isNull);

      // default_account_id wired to the seeded Cash account.
      final cashAccount = allAccounts.single;
      expect(
        await h.preferences.getDefaultAccountId(),
        cashAccount.id,
        reason: 'Stream C §12 Q2: default_account_id == seeded Cash account id',
      );
    });

    test('seeded currencies include the 11-row fiat set with '
        'name_l10n_key and custom_name==null', () async {
      await h.seed('en_US');
      final all = await h.currencies.watchAll().first;
      final byCode = {for (final c in all) c.code: c};

      // Every code present (§12 Q6 added CAD/SGD/AUD/NZD).
      const expected = [
        'USD',
        'EUR',
        'JPY',
        'TWD',
        'CNY',
        'HKD',
        'GBP',
        'CAD',
        'SGD',
        'AUD',
        'NZD',
      ];
      for (final code in expected) {
        expect(byCode.containsKey(code), isTrue, reason: 'missing $code');
      }

      // §12 Q7: name_l10n_key = 'currency.<code>', custom_name null.
      for (final c in all) {
        expect(
          c.nameL10nKey,
          'currency.${c.code.toLowerCase()}',
          reason: '${c.code} should have lowercase nameL10nKey',
        );
        expect(c.customName, isNull, reason: '${c.code} customName');
        expect(c.isToken, isFalse, reason: '${c.code} should be fiat');
      }

      // Decimals: JPY=0; everything else=2.
      for (final c in all) {
        expect(c.decimals, c.code == 'JPY' ? 0 : 2);
      }
    });

    test('seeded categories match the §2.3 Step 3 l10n_key + sort_order '
        'table', () async {
      await h.seed('en_US');
      final all = await h.categories.watchAll().first;
      final byKey = {for (final c in all) c.l10nKey: c};

      const expectedKeys = <String>[
        'category.food',
        'category.drinks',
        'category.transportation',
        'category.shopping',
        'category.housing',
        'category.entertainment',
        'category.medical',
        'category.education',
        'category.personal',
        'category.travel',
        'category.threeC',
        'category.miscellaneous',
        'category.other',
        'category.income.salary',
        'category.income.freelance',
        'category.income.investment',
        'category.income.gift',
        'category.income.other',
      ];
      for (var i = 0; i < expectedKeys.length; i++) {
        final key = expectedKeys[i];
        final cat = byKey[key];
        expect(cat, isNotNull, reason: 'missing $key');
        expect(cat!.sortOrder, i, reason: '$key sortOrder should be $i');
        expect(cat.isArchived, isFalse);
      }
    });

    test('seeded account types have default_currency = '
        'the locale-resolved currency', () async {
      await h.seed('en_US');
      final types = await h.accountTypes.watchAll().first;
      for (final t in types) {
        expect(t.defaultCurrency?.code, 'USD');
        expect(t.color, 10); // neutralVariant70
      }
      final keys = types.map((t) => t.l10nKey).toSet();
      expect(keys, {'accountType.cash', 'accountType.investment'});
    });

    test('Cash account points at the Cash account-type; opening balance '
        'is integer 0 (G4)', () async {
      await h.seed('en_US');

      final cashType = await h.accountTypes.getByL10nKey('accountType.cash');
      expect(cashType, isNotNull);

      final accounts = await h.accounts.watchAll().first;
      final cash = accounts.single;
      expect(cash.name, 'Cash');
      expect(cash.accountTypeId, cashType!.id);
      expect(cash.currency.code, 'USD');
      expect(cash.openingBalanceMinorUnits, 0);
      expect(cash.openingBalanceMinorUnits, isA<int>());
      expect(cash.isArchived, isFalse);
    });

    test('default_account_id points at the seeded Cash account '
        '(§12 Q2)', () async {
      await h.seed('en_US');
      final accounts = await h.accounts.watchAll().first;
      final cashId = accounts.single.id;
      expect(await h.preferences.getDefaultAccountId(), cashId);
      expect(await h.preferences.getDefaultAccountId(), isNotNull);
    });
  });

  group('runFirstRunSeed — locale matrix', () {
    late _SeedHarness h;
    setUp(() {
      h = _SeedHarness.fresh();
    });
    tearDown(() async {
      await h.close();
    });

    test('locale zh_TW → default_currency == TWD', () async {
      await h.seed('zh_TW');
      expect(await h.preferences.getDefaultCurrency(), 'TWD');
      final types = await h.accountTypes.watchAll().first;
      expect(types.every((t) => t.defaultCurrency?.code == 'TWD'), isTrue);
      final cash = (await h.accounts.watchAll().first).single;
      expect(cash.currency.code, 'TWD');
    });

    test('locale zh_CN → default_currency == CNY', () async {
      await h.seed('zh_CN');
      expect(await h.preferences.getDefaultCurrency(), 'CNY');
    });

    test('locale zh_HK → default_currency == HKD', () async {
      await h.seed('zh_HK');
      expect(await h.preferences.getDefaultCurrency(), 'HKD');
    });

    test('bare zh → default_currency == CNY', () async {
      await h.seed('zh');
      expect(await h.preferences.getDefaultCurrency(), 'CNY');
    });

    test('locale ja_JP → default_currency == JPY', () async {
      await h.seed('ja_JP');
      expect(await h.preferences.getDefaultCurrency(), 'JPY');
    });

    test('locale en_GB → default_currency == GBP', () async {
      await h.seed('en_GB');
      expect(await h.preferences.getDefaultCurrency(), 'GBP');
    });

    test('locale de_DE → default_currency == USD (fallback)', () async {
      await h.seed('de_DE');
      expect(await h.preferences.getDefaultCurrency(), 'USD');
    });

    test('locale fr_FR → default_currency == USD (fallback)', () async {
      await h.seed('fr_FR');
      expect(await h.preferences.getDefaultCurrency(), 'USD');
    });

    test('unknown locale kl_GL → default_currency == USD '
        '(global fallback)', () async {
      await h.seed('kl_GL');
      expect(await h.preferences.getDefaultCurrency(), 'USD');
    });
  });

  group('runFirstRunSeed — idempotency', () {
    late _SeedHarness h;
    setUp(() {
      h = _SeedHarness.fresh();
    });
    tearDown(() async {
      await h.close();
    });

    test('runs twice → no duplicates, no side effects', () async {
      await h.seed('en_US');
      final afterFirst = {
        'currencies':
            (await h.currencies.watchAll(includeTokens: false).first).length,
        'categories': (await h.categories.watchAll().first).length,
        'accountTypes': (await h.accountTypes.watchAll().first).length,
        'accounts': (await h.accounts.watchAll().first).length,
      };
      expect(afterFirst['currencies'], 11);
      expect(afterFirst['categories'], 18);
      expect(afterFirst['accountTypes'], 2);
      expect(afterFirst['accounts'], 1);

      // Second call short-circuits on the Step 0 gate.
      await h.seed('en_US');

      final afterSecond = {
        'currencies':
            (await h.currencies.watchAll(includeTokens: false).first).length,
        'categories': (await h.categories.watchAll().first).length,
        'accountTypes': (await h.accountTypes.watchAll().first).length,
        'accounts': (await h.accounts.watchAll().first).length,
      };
      expect(afterSecond, afterFirst);
      expect(await h.preferences.getFirstRunComplete(), isTrue);
    });
  });

  group('runFirstRunSeed — transactional atomicity', () {
    test('step failure rolls back every write; first_run_completed '
        'stays false', () async {
      final db = newTestAppDatabase();
      addTearDown(() async => db.close());

      final currencies = DriftCurrencyRepository(db);
      final accountTypes = DriftAccountTypeRepository(db, currencies);
      final accounts = DriftAccountRepository(db, currencies);
      final preferences = DriftUserPreferencesRepository(db);
      // Failing category repository — throws on the 3rd upsertSeeded call.
      final categoriesWithFailure = _ThrowingCategoryRepository(
        DriftCategoryRepository(db),
        throwOnNthCall: 3,
      );

      try {
        await runFirstRunSeed(
          db: db,
          currencies: currencies,
          categories: categoriesWithFailure,
          accountTypes: accountTypes,
          accounts: accounts,
          preferences: preferences,
          localeService: const _FakeLocaleService('en_US'),
        );
        fail('expected the seed to rethrow the injected failure');
      } on _InjectedSeedFailure {
        // Expected.
      }

      // Every write inside the transaction rolled back.
      expect(
        (await currencies.watchAll(includeTokens: true).first),
        isEmpty,
        reason: 'Step 1 writes should have rolled back',
      );
      final catRepoForRead = DriftCategoryRepository(db);
      expect(
        await catRepoForRead.watchAll(includeArchived: true).first,
        isEmpty,
      );
      expect(await accountTypes.watchAll(includeArchived: true).first, isEmpty);
      expect(await accounts.watchAll(includeArchived: true).first, isEmpty);
      expect(
        await preferences.getFirstRunComplete(),
        isFalse,
        reason:
            'first_run_completed must stay unwritten so the next launch '
            'can retry the seed',
      );
    });
  });
}

/// Domain-local sentinel for the injected-failure test.
class _InjectedSeedFailure implements Exception {
  const _InjectedSeedFailure();
  @override
  String toString() => '_InjectedSeedFailure';
}

/// Wraps a real [CategoryRepository] and throws on the N-th
/// `upsertSeeded` call. Used to prove transactional atomicity
/// (risk-4 guardrail, Stream C plan §9.1).
class _ThrowingCategoryRepository implements CategoryRepository {
  _ThrowingCategoryRepository(this._inner, {required this.throwOnNthCall});

  final CategoryRepository _inner;
  final int throwOnNthCall;
  int _calls = 0;

  @override
  Future<Category> upsertSeeded({
    required String l10nKey,
    required String icon,
    required int color,
    required CategoryType type,
    required int sortOrder,
  }) async {
    _calls++;
    if (_calls == throwOnNthCall) {
      throw const _InjectedSeedFailure();
    }
    return _inner.upsertSeeded(
      l10nKey: l10nKey,
      icon: icon,
      color: color,
      type: type,
      sortOrder: sortOrder,
    );
  }

  @override
  Stream<List<Category>> watchAll({
    CategoryType? type,
    bool includeArchived = false,
  }) => _inner.watchAll(type: type, includeArchived: includeArchived);

  @override
  Future<Category?> getById(int id) => _inner.getById(id);

  @override
  Future<Category?> getByL10nKey(String l10nKey) =>
      _inner.getByL10nKey(l10nKey);

  @override
  Future<Category> save(Category category) => _inner.save(category);

  @override
  Future<Category> rename(int id, String? customName) =>
      _inner.rename(id, customName);

  @override
  Future<Category> archive(int id) => _inner.archive(id);

  @override
  Future<bool> delete(int id) => _inner.delete(id);

  @override
  Future<bool> isReferenced(int id) => _inner.isReferenced(id);
}
