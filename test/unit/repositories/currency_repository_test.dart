// Tests for `CurrencyRepository` (M3 Stream B §6.1).
//
// Uses the shared in-memory harness at `_harness/test_app_database.dart`.
// Every case has a direct row in the §6.1 Test Plan table (CR01–CR11).

import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/repository_exceptions.dart';

import '_harness/test_app_database.dart';

// Sample seed rows that many cases rely on. Kept local (not shared) so
// each test case is readable top-to-bottom.
const Currency _usd = Currency(
  code: 'USD',
  decimals: 2,
  symbol: r'$',
  nameL10nKey: 'currency.usd',
  sortOrder: 1,
);

const Currency _eth = Currency(
  code: 'ETH',
  decimals: 18,
  symbol: 'Ξ',
  nameL10nKey: 'currency.eth',
  isToken: true,
  sortOrder: 100,
);

void main() {
  late AppDatabase db;
  late CurrencyRepository repo;

  setUp(() {
    db = newTestAppDatabase();
    repo = DriftCurrencyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CurrencyRepository', () {
    test('CR01: empty DB → watchAll emits []', () async {
      expect(await repo.watchAll().first, isEmpty);
    });

    test('CR02: after upsert(USD) → watchAll emits [USD]', () async {
      final stream = repo.watchAll();
      final future = stream.take(2).toList();

      await repo.upsert(_usd);

      final snapshots = await future;
      expect(snapshots.first, isEmpty);
      expect(snapshots.last.length, 1);
      expect(snapshots.last.single.code, 'USD');
      expect(snapshots.last.single.decimals, 2);
      expect(snapshots.last.single.symbol, r'$');
      expect(snapshots.last.single.nameL10nKey, 'currency.usd');
      expect(snapshots.last.single.isToken, isFalse);
    });

    test(
      'CR03: watchAll(includeTokens: false) filters isToken == true',
      () async {
        await repo.upsert(_usd);
        await repo.upsert(_eth);

        final fiatsOnly = await repo.watchAll().first;
        expect(fiatsOnly.map((c) => c.code), ['USD']);

        final all = await repo.watchAll(includeTokens: true).first;
        expect(all.map((c) => c.code), containsAll(<String>['USD', 'ETH']));
        expect(all.length, 2);
      },
    );

    test(
      'CR04: getByCode(USD) returns a Freezed Currency with decimals == 2',
      () async {
        await repo.upsert(_usd);

        final found = await repo.getByCode('USD');
        expect(found, isNotNull);
        expect(found, isA<Currency>());
        expect(found!.code, 'USD');
        expect(found.decimals, 2);
        expect(found.symbol, r'$');
        expect(found.nameL10nKey, 'currency.usd');
        expect(found.isToken, isFalse);
        expect(found.sortOrder, 1);
      },
    );

    test('CR05: getByCode(unregistered) returns null', () async {
      expect(await repo.getByCode('XYZ'), isNull);
    });

    test('CR06: upsert(USD) twice is idempotent', () async {
      await repo.upsert(_usd);
      await repo.upsert(_usd);

      final rows = await repo.watchAll().first;
      expect(rows.length, 1);
      expect(rows.single.code, 'USD');
    });

    test('CR07: upsert with mismatched decimals throws '
        'CurrencyDecimalsMismatchException', () async {
      await repo.upsert(_usd);

      await expectLater(
        repo.upsert(_usd.copyWith(decimals: 4)),
        throwsA(
          isA<CurrencyDecimalsMismatchException>()
              .having((e) => e.code, 'code', 'USD')
              .having((e) => e.existingDecimals, 'existingDecimals', 2)
              .having((e) => e.attemptedDecimals, 'attemptedDecimals', 4),
        ),
      );

      // Row untouched.
      final row = await repo.getByCode('USD');
      expect(row!.decimals, 2);
    });

    test(
      'CR08: upsert updates symbol / nameL10nKey on an existing code',
      () async {
        await repo.upsert(_usd);
        await repo.upsert(_usd.copyWith(symbol: r'US$'));

        final row = await repo.getByCode('USD');
        expect(row!.symbol, r'US$');
        expect(row.decimals, 2); // Unchanged.
      },
    );

    test('CR08b: upsert preserves customName on an existing code', () async {
      await repo.upsert(_usd);
      await repo.updateCustomName('USD', 'My Dollar');

      // Re-run upsert — must not stomp the user rename.
      await repo.upsert(_usd.copyWith(symbol: r'US$'));

      final row = await repo.getByCode('USD');
      expect(row!.customName, 'My Dollar');
      expect(row.symbol, r'US$');
    });

    test('CR09: upsert preserves sortOrder when new value is null', () async {
      await repo.upsert(_usd); // sortOrder == 1
      await repo.upsert(_usd.copyWith(sortOrder: null));

      final row = await repo.getByCode('USD');
      expect(row!.sortOrder, 1);
    });

    test('CR10: return type is the Freezed Currency model', () async {
      await repo.upsert(_usd);

      final byCode = await repo.getByCode('USD');
      expect(byCode, isA<Currency>());

      final watched = await repo.watchAll().first;
      expect(watched.single, isA<Currency>());
    });

    group('CR11: updateCustomName', () {
      test('writes only custom_name, leaves other columns untouched', () async {
        await repo.upsert(_usd);
        await repo.updateCustomName('USD', 'Dollar');

        final row = await repo.getByCode('USD');
        expect(row!.customName, 'Dollar');
        expect(row.code, 'USD');
        expect(row.decimals, 2);
        expect(row.symbol, r'$');
        expect(row.nameL10nKey, 'currency.usd');
        expect(row.isToken, isFalse);
        expect(row.sortOrder, 1);
      });

      test('null clears the override', () async {
        await repo.upsert(_usd);
        await repo.updateCustomName('USD', 'Dollar');
        await repo.updateCustomName('USD', null);

        final row = await repo.getByCode('USD');
        expect(row!.customName, isNull);
      });

      test('empty / whitespace-only normalizes to null', () async {
        await repo.upsert(_usd);
        await repo.updateCustomName('USD', '   ');
        expect((await repo.getByCode('USD'))!.customName, isNull);

        await repo.updateCustomName('USD', '');
        expect((await repo.getByCode('USD'))!.customName, isNull);
      });

      test('unknown code throws CurrencyNotFoundException', () async {
        await expectLater(
          repo.updateCustomName('XYZ', 'anything'),
          throwsA(
            isA<CurrencyNotFoundException>().having(
              (e) => e.code,
              'code',
              'XYZ',
            ),
          ),
        );
      });
    });

    test('watchAll emits on upsert / updateCustomName (reactive)', () async {
      await repo.upsert(_usd);

      final snapshots = <List<Currency>>[];
      final sub = repo.watchAll().listen(snapshots.add);

      // Give the stream a tick to emit the initial snapshot.
      await Future<void>.delayed(Duration.zero);
      expect(snapshots, isNotEmpty);
      expect(snapshots.last.single.customName, isNull);

      await repo.updateCustomName('USD', 'Dollar');
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last.single.customName, 'Dollar');

      await sub.cancel();
    });
  });
}
