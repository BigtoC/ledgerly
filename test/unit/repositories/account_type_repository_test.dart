// Tests for `AccountTypeRepository` (M3 Stream B §6.2).
//
// Uses the shared in-memory harness at `_harness/test_app_database.dart`.
// Every case maps to a row in the §6.2 Test Plan table (AT01..AT22).
//
// Because the Phase 1 harness does not yet ship
// `TestRepoBundle.seedMinimalRepositoryFixtures()`, this file seeds the
// required currency rows directly via `CurrencyRepository.upsert`. The
// two sibling fixtures exercised below are the seeded `accountType.cash`
// row and a user-account row (the latter is inserted via
// `customStatement` so we can exercise the `delete → in-use` branch
// without depending on Stream B's `AccountRepository`).

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/account_type.dart';
import 'package:ledgerly/data/models/currency.dart';
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

/// Inserts one active account of type [accountTypeId] using `USD`.
/// Used by the archive-vs-delete tests (AT11..AT13) so we can gate
/// `AccountTypeRepository.delete` against a real referencing row.
Future<int> _insertAccountRaw(
  AppDatabase db, {
  required int accountTypeId,
  bool archived = false,
}) async {
  await db.customStatement(
    'INSERT INTO accounts (name, account_type_id, currency, '
    'opening_balance_minor_units, is_archived) VALUES (?, ?, ?, 0, ?)',
    <Object?>['Wallet', accountTypeId, 'USD', archived ? 1 : 0],
  );
  final rows = await db
      .customSelect(
        'SELECT id FROM accounts WHERE account_type_id = ? '
        'ORDER BY id DESC LIMIT 1',
        variables: [Variable<int>(accountTypeId)],
      )
      .get();
  return rows.first.read<int>('id');
}

Future<void> _deleteAccountRaw(AppDatabase db, int accountId) async {
  await db.customStatement('DELETE FROM accounts WHERE id = ?', <Object?>[
    accountId,
  ]);
}

void main() {
  late AppDatabase db;
  late CurrencyRepository currencies;
  late AccountTypeRepository repo;

  setUp(() async {
    db = newTestAppDatabase();
    currencies = DriftCurrencyRepository(db);
    repo = DriftAccountTypeRepository(db, currencies);
    // Every test relies on USD being available. JPY is seeded in a few
    // tests that exercise default-currency resolution.
    await currencies.upsert(_usd);
  });

  tearDown(() async {
    await db.close();
  });

  group('AccountTypeRepository', () {
    test('AT01: empty DB → watchAll emits []', () async {
      expect(await repo.watchAll().first, isEmpty);
    });

    test('AT02: save(Cash seeded) → watchAll emits [Cash]', () async {
      final id = await repo.save(
        const AccountType(
          id: 0,
          l10nKey: 'accountType.cash',
          icon: 'wallet',
          color: 10,
          defaultCurrency: _usd,
          sortOrder: 1,
        ),
      );
      expect(id, isNonZero);

      final rows = await repo.watchAll().first;
      expect(rows.length, 1);
      final row = rows.single;
      expect(row.l10nKey, 'accountType.cash');
      expect(row.icon, 'wallet');
      expect(row.color, 10);
      expect(row.defaultCurrency?.code, 'USD');
      expect(row.defaultCurrency?.decimals, 2);
    });

    test(
      'AT03: save with unknown defaultCurrency → CurrencyNotFoundException',
      () async {
        await expectLater(
          repo.save(
            const AccountType(
              id: 0,
              l10nKey: 'accountType.cash',
              icon: 'wallet',
              color: 10,
              defaultCurrency: Currency(code: 'XYZ', decimals: 2),
              sortOrder: 1,
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
        expect(await repo.watchAll().first, isEmpty);
      },
    );

    test(
      'AT04: save with defaultCurrency == null → row with NULL default',
      () async {
        final id = await repo.save(
          const AccountType(
            id: 0,
            l10nKey: 'accountType.custom',
            icon: 'folder',
            color: 4,
            sortOrder: 3,
          ),
        );
        final fetched = await repo.getById(id);
        expect(fetched, isNotNull);
        expect(fetched!.defaultCurrency, isNull);
      },
    );

    test('AT05: rename writes customName; l10nKey preserved', () async {
      final id = await repo.save(
        const AccountType(
          id: 0,
          l10nKey: 'accountType.cash',
          icon: 'wallet',
          color: 10,
          defaultCurrency: _usd,
        ),
      );

      await repo.rename(id: id, customName: 'Wallet');

      final found = await repo.getByL10nKey('accountType.cash');
      expect(found, isNotNull);
      expect(found!.id, id);
      expect(found.customName, 'Wallet');
      expect(found.l10nKey, 'accountType.cash');
    });

    test('AT06: second rename does not disturb l10nKey', () async {
      final id = await repo.save(
        const AccountType(
          id: 0,
          l10nKey: 'accountType.cash',
          icon: 'wallet',
          color: 10,
          defaultCurrency: _usd,
        ),
      );

      await repo.rename(id: id, customName: 'Wallet');
      await repo.rename(id: id, customName: 'My Cash');

      final found = await repo.getByL10nKey('accountType.cash');
      expect(found!.customName, 'My Cash');
      expect(found.l10nKey, 'accountType.cash');
    });

    test(
      'AT07: rename on nonexistent id → AccountTypeNotFoundException',
      () async {
        await expectLater(
          repo.rename(id: 999, customName: 'No such row'),
          throwsA(
            isA<AccountTypeNotFoundException>().having((e) => e.id, 'id', 999),
          ),
        );
      },
    );

    test(
      'AT08: archive marks archived; default watchAll excludes archived',
      () async {
        final id = await repo.save(
          const AccountType(
            id: 0,
            l10nKey: 'accountType.cash',
            icon: 'wallet',
            color: 10,
            defaultCurrency: _usd,
          ),
        );

        await repo.archive(id);

        final active = await repo.watchAll().first;
        expect(active, isEmpty);
      },
    );

    test(
      'AT09: watchAll(includeArchived: true) returns archived rows',
      () async {
        final id = await repo.save(
          const AccountType(
            id: 0,
            l10nKey: 'accountType.cash',
            icon: 'wallet',
            color: 10,
            defaultCurrency: _usd,
          ),
        );
        await repo.archive(id);

        final all = await repo.watchAll(includeArchived: true).first;
        expect(all.map((r) => r.id), [id]);
        expect(all.single.isArchived, isTrue);
      },
    );

    test('AT10: delete with no referencing accounts → succeeds', () async {
      final id = await repo.save(
        // Custom (user-added) row with l10nKey null — matches the
        // "unused custom rows may be deleted" rule.
        const AccountType(
          id: 0,
          icon: 'folder',
          color: 2,
          defaultCurrency: _usd,
        ),
      );
      await repo.delete(id);

      final rows = await repo.watchAll().first;
      expect(rows, isEmpty);
    });

    test(
      'AT11: delete with referencing account → AccountTypeInUseException',
      () async {
        final id = await repo.save(
          const AccountType(
            id: 0,
            l10nKey: 'accountType.cash',
            icon: 'wallet',
            color: 10,
            defaultCurrency: _usd,
          ),
        );
        await _insertAccountRaw(db, accountTypeId: id);

        await expectLater(
          repo.delete(id),
          throwsA(
            isA<AccountTypeInUseException>().having((e) => e.id, 'id', id),
          ),
        );

        // Row still present.
        expect(await repo.getById(id), isNotNull);
      },
    );

    test(
      'AT12: delete with archived referencing account → still throws',
      () async {
        final typeId = await repo.save(
          const AccountType(
            id: 0,
            l10nKey: 'accountType.cash',
            icon: 'wallet',
            color: 10,
            defaultCurrency: _usd,
          ),
        );
        await _insertAccountRaw(db, accountTypeId: typeId, archived: true);

        await expectLater(
          repo.delete(typeId),
          throwsA(isA<AccountTypeInUseException>()),
        );
      },
    );

    test('AT13: isReferenced matches delete predicate', () async {
      final typeId = await repo.save(
        const AccountType(
          id: 0,
          l10nKey: 'accountType.cash',
          icon: 'wallet',
          color: 10,
          defaultCurrency: _usd,
        ),
      );
      expect(await repo.isReferenced(typeId), isFalse);

      final accountId = await _insertAccountRaw(db, accountTypeId: typeId);
      expect(await repo.isReferenced(typeId), isTrue);

      await _deleteAccountRaw(db, accountId);
      expect(await repo.isReferenced(typeId), isFalse);
    });

    test(
      'AT14: getById resolves defaultCurrency to Freezed Currency',
      () async {
        await currencies.upsert(_jpy);

        final id = await repo.save(
          const AccountType(
            id: 0,
            l10nKey: 'accountType.cash',
            icon: 'wallet',
            color: 10,
            defaultCurrency: _jpy,
          ),
        );

        final fetched = await repo.getById(id);
        expect(fetched, isNotNull);
        expect(fetched!.defaultCurrency, isA<Currency>());
        expect(fetched.defaultCurrency!.code, 'JPY');
        expect(fetched.defaultCurrency!.decimals, 0);
      },
    );

    test(
      'AT15: reactive emission after insert / update / delete / archive',
      () async {
        final snapshots = <List<AccountType>>[];
        final sub = repo.watchAll().listen(snapshots.add);

        await Future<void>.delayed(Duration.zero);
        // Initial empty snapshot.
        expect(snapshots.last, isEmpty);

        final id = await repo.save(
          const AccountType(
            id: 0,
            l10nKey: 'accountType.cash',
            icon: 'wallet',
            color: 10,
            defaultCurrency: _usd,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last.map((r) => r.id), [id]);

        await repo.rename(id: id, customName: 'Wallet');
        await Future<void>.delayed(Duration.zero);
        expect(snapshots.last.single.customName, 'Wallet');

        await repo.archive(id);
        await Future<void>.delayed(Duration.zero);
        // Archived rows dropped from the default stream.
        expect(snapshots.last, isEmpty);

        await sub.cancel();
      },
    );

    test('AT16: Guardrail G8 — icon is String, color is int', () async {
      final id = await repo.save(
        const AccountType(
          id: 0,
          l10nKey: 'accountType.cash',
          icon: 'wallet',
          color: 10,
          defaultCurrency: _usd,
        ),
      );
      final fetched = await repo.getById(id);
      expect(fetched!.icon, isA<String>());
      expect(fetched.color, isA<int>());
    });

    test('AT17: upsertSeeded inserts once and returns the row id', () async {
      final id = await repo.upsertSeeded(
        l10nKey: 'accountType.cash',
        icon: 'wallet',
        color: 10,
        defaultCurrency: _usd,
        sortOrder: 0,
      );
      expect(id, isNonZero);

      final fetched = await repo.getByL10nKey('accountType.cash');
      expect(fetched, isNotNull);
      expect(fetched!.id, id);
      expect(fetched.icon, 'wallet');
      expect(fetched.color, 10);
      expect(fetched.defaultCurrency?.code, 'USD');
    });

    test(
      'AT18: re-running upsertSeeded is idempotent and preserves customName',
      () async {
        final firstId = await repo.upsertSeeded(
          l10nKey: 'accountType.cash',
          icon: 'wallet',
          color: 10,
          defaultCurrency: _usd,
          sortOrder: 0,
        );

        // User rename.
        await repo.rename(id: firstId, customName: 'My Wallet');
        // User archive.
        await repo.archive(firstId);

        // Re-run seed with new icon/color.
        final secondId = await repo.upsertSeeded(
          l10nKey: 'accountType.cash',
          icon: 'money',
          color: 20,
          defaultCurrency: _usd,
          sortOrder: 1,
        );

        expect(secondId, firstId);

        final fetched = await repo.getByL10nKey('accountType.cash');
        expect(fetched, isNotNull);
        expect(fetched!.id, firstId);
        expect(fetched.icon, 'money');
        expect(fetched.color, 20);
        expect(fetched.sortOrder, 1);
        // Preserved user state.
        expect(fetched.customName, 'My Wallet');
        expect(fetched.isArchived, isTrue);

        // No duplicate rows created.
        final allRows = await repo.watchAll(includeArchived: true).first;
        expect(allRows.length, 1);
      },
    );

    test('AT21: save preserves stored l10nKey on update', () async {
      final id = await repo.save(
        const AccountType(
          id: 0,
          l10nKey: 'accountType.cash',
          icon: 'wallet',
          color: 10,
          defaultCurrency: _usd,
        ),
      );

      // Caller attempts to mutate l10nKey via `save`.
      await repo.save(
        AccountType(
          id: id,
          l10nKey: 'accountType.wallet',
          icon: 'wallet',
          color: 11,
          defaultCurrency: _usd,
        ),
      );

      final fetched = await repo.getById(id);
      // Stored l10nKey wins.
      expect(fetched!.l10nKey, 'accountType.cash');
      // Other mutable fields updated.
      expect(fetched.color, 11);
      // Key-based lookup unchanged.
      expect(await repo.getByL10nKey('accountType.cash'), isNotNull);
      expect(await repo.getByL10nKey('accountType.wallet'), isNull);
    });

    test('AT22: upsertSeeded with unregistered defaultCurrency → '
        'CurrencyNotFoundException; nothing written', () async {
      await expectLater(
        repo.upsertSeeded(
          l10nKey: 'accountType.future',
          icon: 'help',
          color: 3,
          defaultCurrency: const Currency(
            code: 'XYZ',
            decimals: 2,
            nameL10nKey: 'currency.xyz',
          ),
          sortOrder: 9,
        ),
        throwsA(
          isA<CurrencyNotFoundException>().having((e) => e.code, 'code', 'XYZ'),
        ),
      );

      // Guardrail: row was not written.
      expect(await repo.getByL10nKey('accountType.future'), isNull);
      expect(await repo.watchAll(includeArchived: true).first, isEmpty);
    });
  });
}
