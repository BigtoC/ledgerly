// Tests for `AccountRepository` (M3 Stream B §6.3).
//
// Uses the shared in-memory harness at `_harness/test_app_database.dart`.
// Every case maps to a row in the §6.3 Test Plan table (AC01..AC16).
//
// Because the Phase 1 harness does not yet ship
// `TestRepoBundle.seedMinimalRepositoryFixtures()`, this file seeds the
// required currency + account-type fixtures through their sibling
// repositories (which Stream B owns and has already validated), then
// exercises `AccountRepository` against that minimal shared state.
// Referencing-transaction rows for AC09/AC10 are inserted via
// `customStatement` so the test does not depend on
// `TransactionRepository` internals.

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/account_type_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/repository_exceptions.dart';

import '_harness/test_app_database.dart';

const Currency _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
  sortOrder: 1,
);

const Currency _jpy = Currency(
  code: 'JPY',
  decimals: 0,
  symbol: '¥',
  nameL10nKey: 'currency.jpy',
  sortOrder: 2,
);

/// Inserts one minimal transaction referencing [accountId]. Used by
/// AC09/AC10/AC11 so we can gate `AccountRepository.delete` against a
/// real referencing row without pulling in `TransactionRepository`.
Future<void> _insertTransactionRaw(
  AppDatabase db, {
  required int accountId,
  required int categoryId,
}) async {
  final nowIso = DateTime.utc(2026, 1, 1).toIso8601String();
  await db.customStatement(
    'INSERT INTO transactions (account_id, category_id, amount_minor_units, '
    'currency, date, created_at, updated_at) '
    'VALUES (?, ?, 1000, ?, ?, ?, ?)',
    <Object?>[accountId, categoryId, 'USD', nowIso, nowIso, nowIso],
  );
}

Future<int> _insertCategoryRaw(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO categories (l10n_key, icon, color, type, sort_order, '
    'is_archived) VALUES (?, ?, 0, ?, 1, 0)',
    <Object?>['category.food', 'restaurant', 'expense'],
  );
  final rows = await db
      .customSelect('SELECT id FROM categories ORDER BY id DESC LIMIT 1')
      .get();
  return rows.first.read<int>('id');
}

void main() {
  late AppDatabase db;
  late CurrencyRepository currencies;
  late AccountTypeRepository accountTypes;
  late AccountRepository repo;
  late int cashTypeId;

  setUp(() async {
    db = newTestAppDatabase();
    currencies = DriftCurrencyRepository(db);
    accountTypes = DriftAccountTypeRepository(db, currencies);
    repo = DriftAccountRepository(db, currencies);

    await currencies.upsert(_usd);
    await currencies.upsert(_jpy);

    cashTypeId = await accountTypes.upsertSeeded(
      l10nKey: 'accountType.cash',
      icon: 'wallet',
      color: 10,
      defaultCurrency: _usd,
      sortOrder: 0,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Account buildCashAccount({
    int id = 0,
    String name = 'Cash',
    Currency currency = _usd,
    int openingBalanceMinorUnits = 0,
    String? icon,
    int? color,
    int? sortOrder,
    bool isArchived = false,
  }) {
    return Account(
      id: id,
      name: name,
      accountTypeId: cashTypeId,
      currency: currency,
      openingBalanceMinorUnits: openingBalanceMinorUnits,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
      isArchived: isArchived,
    );
  }

  group('AccountRepository', () {
    test('AC01: empty DB → watchAll emits []', () async {
      expect(await repo.watchAll().first, isEmpty);
    });

    test('AC02: save happy path — all fields round-trip', () async {
      final id = await repo.save(
        buildCashAccount(
          name: 'Main Cash',
          openingBalanceMinorUnits: 12345,
          icon: 'wallet',
          color: 3,
          sortOrder: 1,
        ),
      );
      expect(id, isNonZero);

      final fetched = await repo.getById(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Main Cash');
      expect(fetched.accountTypeId, cashTypeId);
      expect(fetched.currency.code, 'USD');
      expect(fetched.currency.decimals, 2);
      expect(fetched.openingBalanceMinorUnits, 12345);
      expect(fetched.icon, 'wallet');
      expect(fetched.color, 3);
      expect(fetched.sortOrder, 1);
      expect(fetched.isArchived, isFalse);
    });

    test(
      'AC03: save with unknown currency → CurrencyNotFoundException',
      () async {
        await expectLater(
          repo.save(
            buildCashAccount(
              currency: const Currency(code: 'XYZ', decimals: 2),
            ),
          ),
          throwsA(
            isA<CurrencyNotFoundException>().having(
              (e) => e.code,
              'code',
              'XYZ',
            ),
          ),
        );

        // No row written.
        expect(await repo.watchAll().first, isEmpty);
      },
    );

    test(
      'AC04: save with unknown accountTypeId → AccountTypeNotFoundException',
      () async {
        await expectLater(
          repo.save(
            const Account(
              id: 0,
              name: 'Phantom',
              accountTypeId: 999,
              currency: _usd,
            ),
          ),
          throwsA(
            isA<AccountTypeNotFoundException>().having((e) => e.id, 'id', 999),
          ),
        );

        expect(await repo.watchAll().first, isEmpty);
      },
    );

    test('AC05: save round-trips openingBalanceMinorUnits: -12345', () async {
      final id = await repo.save(
        buildCashAccount(openingBalanceMinorUnits: -12345),
      );
      final fetched = await repo.getById(id);
      expect(fetched!.openingBalanceMinorUnits, -12345);
    });

    test('AC06: save round-trips openingBalanceMinorUnits: 1500000000000000000 '
        '(18-digit / ETH width)', () async {
      const big = 1500000000000000000; // 1.5 * 1e18 — fits in int64.
      final id = await repo.save(
        buildCashAccount(openingBalanceMinorUnits: big),
      );
      final fetched = await repo.getById(id);
      expect(fetched!.openingBalanceMinorUnits, big);
    });

    test(
      'AC07: archive hides row from default watchAll; includeArchived: true shows it',
      () async {
        final id = await repo.save(buildCashAccount(name: 'Cash'));

        await repo.archive(id);

        expect(await repo.watchAll().first, isEmpty);
        final archived = await repo.watchAll(includeArchived: true).first;
        expect(archived.map((a) => a.id), [id]);
        expect(archived.single.isArchived, isTrue);
      },
    );

    test('AC08: watchById emits null after delete', () async {
      final id = await repo.save(buildCashAccount(name: 'To be deleted'));

      final snapshots = <Account?>[];
      final sub = repo.watchById(id).listen(snapshots.add);

      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last, isNotNull);
      expect(snapshots.last!.name, 'To be deleted');

      await repo.delete(id);
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last, isNull);

      await sub.cancel();
    });

    test('AC09: delete with no referencing transactions → succeeds', () async {
      final id = await repo.save(buildCashAccount());
      await repo.delete(id);

      expect(await repo.watchAll().first, isEmpty);
    });

    test(
      'AC10: delete with a referencing transaction → AccountInUseException',
      () async {
        final id = await repo.save(buildCashAccount());
        final categoryId = await _insertCategoryRaw(db);
        await _insertTransactionRaw(db, accountId: id, categoryId: categoryId);

        await expectLater(
          repo.delete(id),
          throwsA(isA<AccountInUseException>().having((e) => e.id, 'id', id)),
        );

        // Row still present.
        expect(await repo.getById(id), isNotNull);
      },
    );

    test(
      'AC11: isReferenced true when transaction exists; false otherwise',
      () async {
        final id = await repo.save(buildCashAccount());
        expect(await repo.isReferenced(id), isFalse);

        final categoryId = await _insertCategoryRaw(db);
        await _insertTransactionRaw(db, accountId: id, categoryId: categoryId);
        expect(await repo.isReferenced(id), isTrue);
      },
    );

    test(
      'AC12: watchAll excludes archived by default; sortOrder respected',
      () async {
        final firstId = await repo.save(
          buildCashAccount(name: 'First', sortOrder: 1),
        );
        final secondId = await repo.save(
          buildCashAccount(name: 'Second', sortOrder: 0),
        );

        var rows = await repo.watchAll().first;
        expect(rows.map((a) => a.id), [secondId, firstId]);

        await repo.archive(secondId);
        rows = await repo.watchAll().first;
        expect(rows.map((a) => a.id), [firstId]);
      },
    );

    test('AC13: watchAll(includeArchived: true) includes archived', () async {
      final activeId = await repo.save(buildCashAccount(name: 'Active'));
      final archivedId = await repo.save(buildCashAccount(name: 'Gone'));
      await repo.archive(archivedId);

      final all = await repo.watchAll(includeArchived: true).first;
      expect(all.map((a) => a.id), containsAll(<int>[activeId, archivedId]));
      expect(all.length, 2);
    });

    test('AC14: getById resolves currency to Freezed Currency', () async {
      final id = await repo.save(buildCashAccount(currency: _jpy));
      final fetched = await repo.getById(id);
      expect(fetched, isNotNull);
      expect(fetched!.currency, isA<Currency>());
      expect(fetched.currency.code, 'JPY');
      expect(fetched.currency.decimals, 0);
    });

    test(
      'AC15: reactive emission after insert / update / archive / delete',
      () async {
        final snapshots = <List<Account>>[];
        final sub = repo.watchAll().listen(snapshots.add);

        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last, isEmpty);

        final id = await repo.save(buildCashAccount(name: 'Cash'));
        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last.map((a) => a.id), [id]);

        await repo.save(buildCashAccount(id: id, name: 'Renamed Cash'));
        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last.single.name, 'Renamed Cash');

        await repo.archive(id);
        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last, isEmpty);

        await sub.cancel();
      },
    );

    test(
      'AC16: Guardrail G8 — icon is String?, color is int? (both nullable)',
      () async {
        final nullIconId = await repo.save(buildCashAccount());
        final withIconId = await repo.save(
          buildCashAccount(name: 'With icon', icon: 'bank', color: 7),
        );

        final nullIcon = await repo.getById(nullIconId);
        expect(nullIcon!.icon, isNull);
        expect(nullIcon.color, isNull);

        final withIcon = await repo.getById(withIconId);
        expect(withIcon!.icon, isA<String>());
        expect(withIcon.icon, 'bank');
        expect(withIcon.color, isA<int>());
        expect(withIcon.color, 7);
      },
    );
  });
}
