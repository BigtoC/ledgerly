// AccountsController unit tests (plan §3.3, §6, §7).
//
// Covers:
//   - State transitions: loading → data on first joint emission of
//     accounts + default + per-account balance streams.
//   - Per-account balance projection + re-emission when the balance
//     stream fires.
//   - Default-account id propagates into `AccountsData.defaultAccountId`
//     and flips when `userPreferences.setDefaultAccountId` writes.
//   - Archive command writes via the repository.
//   - Archive refuses to leave the user with zero active accounts.
//   - Delete refuses to operate on the current default account.
//   - `setDefault` delegates to `UserPreferencesRepository`.
//
// Repositories mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/accounts/accounts_controller.dart';
import 'package:ledgerly/features/accounts/accounts_state.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

Account _a({
  required int id,
  required String name,
  int accountTypeId = 1,
  Currency currency = _usd,
  int openingBalanceMinorUnits = 0,
  int? sortOrder,
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: accountTypeId,
  currency: currency,
  openingBalanceMinorUnits: openingBalanceMinorUnits,
  sortOrder: sortOrder,
  isArchived: isArchived,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_a(id: 0, name: '_'));
  });

  group('AccountsController', () {
    late _MockAccountRepository accountRepo;
    late _MockUserPreferencesRepository prefs;
    late StreamController<List<Account>> accountsCtrl;
    late StreamController<int?> defaultCtrl;
    final balanceCtrls = <int, StreamController<int>>{};

    setUp(() {
      accountRepo = _MockAccountRepository();
      prefs = _MockUserPreferencesRepository();
      accountsCtrl = StreamController<List<Account>>.broadcast();
      defaultCtrl = StreamController<int?>.broadcast();
      balanceCtrls.clear();

      when(
        () => accountRepo.watchAll(includeArchived: true),
      ).thenAnswer((_) => accountsCtrl.stream);
      when(
        () => prefs.watchDefaultAccountId(),
      ).thenAnswer((_) => defaultCtrl.stream);
      when(() => accountRepo.watchIsReferenced(any())).thenAnswer((inv) {
        final id = inv.positionalArguments.first as int;
        final balance = balanceCtrls.putIfAbsent(
          id,
          () => StreamController<int>.broadcast(),
        );
        return balance.stream.asyncMap((_) => accountRepo.isReferenced(id));
      });
      when(
        () => accountRepo.isReferenced(any()),
      ).thenAnswer((_) async => false);
      when(() => accountRepo.watchBalanceMinorUnits(any())).thenAnswer((inv) {
        final id = inv.positionalArguments.first as int;
        final c = balanceCtrls.putIfAbsent(
          id,
          () => StreamController<int>.broadcast(),
        );
        return c.stream;
      });
    });

    tearDown(() async {
      await accountsCtrl.close();
      await defaultCtrl.close();
      for (final c in balanceCtrls.values) {
        await c.close();
      }
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(accountRepo),
          userPreferencesRepositoryProvider.overrideWithValue(prefs),
        ],
      );
    }

    Future<AccountsState> waitForData(ProviderContainer c) async {
      for (var i = 0; i < 200; i++) {
        final s = c.read(accountsControllerProvider);
        if (s is AsyncData<AccountsState> && s.value is AccountsData) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('AccountsController never produced data');
    }

    test(
      'A01: starts loading, transitions to data on joint first emit',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(accountsControllerProvider, (_, _) {});

        expect(
          container.read(accountsControllerProvider),
          isA<AsyncLoading<AccountsState>>(),
        );

        await Future<void>.delayed(Duration.zero);
        accountsCtrl.add([_a(id: 1, name: 'Cash')]);
        defaultCtrl.add(1);
        await Future<void>.delayed(Duration.zero);
        balanceCtrls[1]!.add(0);

        final state = await waitForData(container) as AccountsData;
        expect(state.active, hasLength(1));
        expect(state.active.single.account.id, 1);
        expect(state.defaultAccountId, 1);
      },
    );

    test(
      'A02: balance stream emission propagates to AccountWithBalance',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(accountsControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        accountsCtrl.add([_a(id: 1, name: 'Cash'), _a(id: 2, name: 'Savings')]);
        defaultCtrl.add(null);
        await Future<void>.delayed(Duration.zero);
        balanceCtrls[1]!.add(12345);
        balanceCtrls[2]!.add(0);

        final state = await waitForData(container) as AccountsData;
        final byId = {
          for (final r in state.active) r.account.id: r.balanceMinorUnits,
        };
        expect(byId[1], 12345);
        expect(byId[2], 0);

        // Re-emission flows through.
        balanceCtrls[1]!.add(99999);
        await Future<void>.delayed(Duration.zero);
        final state2 =
            container.read(accountsControllerProvider).value! as AccountsData;
        final byId2 = {
          for (final r in state2.active) r.account.id: r.balanceMinorUnits,
        };
        expect(byId2[1], 99999);
      },
    );

    test('A03: archived accounts land in archived bucket', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(accountsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      accountsCtrl.add([
        _a(id: 1, name: 'Cash'),
        _a(id: 2, name: 'OldCard', isArchived: true),
      ]);
      defaultCtrl.add(1);
      await Future<void>.delayed(Duration.zero);
      balanceCtrls[1]!.add(0);
      balanceCtrls[2]!.add(-500);

      final state = await waitForData(container) as AccountsData;
      expect(state.active.map((r) => r.account.id), [1]);
      expect(state.archived.map((r) => r.account.id), [2]);
      expect(state.archived.single.balanceMinorUnits, -500);
    });

    test('A04: setDefault writes via UserPreferencesRepository', () async {
      when(() => prefs.setDefaultAccountId(7)).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(accountsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      accountsCtrl.add([_a(id: 7, name: 'Target')]);
      defaultCtrl.add(null);
      await Future<void>.delayed(Duration.zero);
      balanceCtrls[7]!.add(0);
      await waitForData(container);

      await container.read(accountsControllerProvider.notifier).setDefault(7);

      verify(() => prefs.setDefaultAccountId(7)).called(1);
    });

    test('A05: archive delegates to repository', () async {
      when(() => accountRepo.archive(2)).thenAnswer((_) async {});
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(accountsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      accountsCtrl.add([_a(id: 1, name: 'Cash'), _a(id: 2, name: 'Spare')]);
      defaultCtrl.add(1);
      await Future<void>.delayed(Duration.zero);
      balanceCtrls[1]!.add(0);
      balanceCtrls[2]!.add(0);
      await waitForData(container);

      await container.read(accountsControllerProvider.notifier).archive(2);

      verify(() => accountRepo.archive(2)).called(1);
    });

    test(
      'A06: archive refuses to leave user with zero active accounts',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(accountsControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        accountsCtrl.add([_a(id: 1, name: 'Cash')]);
        defaultCtrl.add(99);
        await Future<void>.delayed(Duration.zero);
        balanceCtrls[1]!.add(0);
        await waitForData(container);

        expect(
          () => container.read(accountsControllerProvider.notifier).archive(1),
          throwsA(
            isA<AccountsOperationException>().having(
              (e) => e.kind,
              'kind',
              AccountsOperationError.lastActiveAccount,
            ),
          ),
        );
        verifyNever(() => accountRepo.archive(any()));
      },
    );

    test('A06b: archive refuses the current default account', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(accountsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      accountsCtrl.add([_a(id: 1, name: 'Cash'), _a(id: 2, name: 'Spare')]);
      defaultCtrl.add(1);
      await Future<void>.delayed(Duration.zero);
      balanceCtrls[1]!.add(0);
      balanceCtrls[2]!.add(0);
      await waitForData(container);

      expect(
        () => container.read(accountsControllerProvider.notifier).archive(1),
        throwsA(
          isA<AccountsOperationException>().having(
            (e) => e.kind,
            'kind',
            AccountsOperationError.defaultAccount,
          ),
        ),
      );
      verifyNever(() => accountRepo.archive(any()));
    });

    test('A07: delete refuses the current default account', () async {
      when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(accountsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      accountsCtrl.add([_a(id: 1, name: 'Cash'), _a(id: 2, name: 'Spare')]);
      defaultCtrl.add(1);
      await Future<void>.delayed(Duration.zero);
      balanceCtrls[1]!.add(0);
      balanceCtrls[2]!.add(0);
      await waitForData(container);

      expect(
        () => container.read(accountsControllerProvider.notifier).delete(1),
        throwsA(
          isA<AccountsOperationException>().having(
            (e) => e.kind,
            'kind',
            AccountsOperationError.defaultAccount,
          ),
        ),
      );
      verifyNever(() => accountRepo.delete(any()));
    });

    test(
      'A08: affordance hints — single active row → archiveBlocked',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(accountsControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        accountsCtrl.add([
          _a(id: 1, name: 'Cash'),
          _a(id: 2, name: 'OldCard', isArchived: true),
        ]);
        defaultCtrl.add(1);
        await Future<void>.delayed(Duration.zero);
        balanceCtrls[1]!.add(0);
        balanceCtrls[2]!.add(0);

        final state = await waitForData(container) as AccountsData;
        expect(
          state.active.single.affordance,
          AccountRowAffordance.archiveBlocked,
        );
      },
    );

    test(
      'A09: affordance — referenced zero-opening account stays archive',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(accountsControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        when(() => accountRepo.isReferenced(2)).thenAnswer((_) async => true);
        accountsCtrl.add([
          _a(id: 1, name: 'Cash'),
          _a(id: 2, name: 'Spare', openingBalanceMinorUnits: 0),
        ]);
        defaultCtrl.add(1);
        await Future<void>.delayed(Duration.zero);
        balanceCtrls[1]!.add(0);
        balanceCtrls[2]!.add(0);

        final state = await waitForData(container) as AccountsData;
        final spare = state.active
            .firstWhere((r) => r.account.id == 2)
            .affordance;
        expect(spare, AccountRowAffordance.archive);
      },
    );

    test('A10: affordance — multiple active, opening!=0 → archive', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(accountsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      accountsCtrl.add([
        _a(id: 1, name: 'Cash'),
        _a(id: 2, name: 'Funded', openingBalanceMinorUnits: 5000),
      ]);
      defaultCtrl.add(1);
      await Future<void>.delayed(Duration.zero);
      balanceCtrls[1]!.add(0);
      balanceCtrls[2]!.add(5000);

      final state = await waitForData(container) as AccountsData;
      final funded = state.active
          .firstWhere((r) => r.account.id == 2)
          .affordance;
      expect(funded, AccountRowAffordance.archive);
    });

    test('A11: unarchive writes isArchived=false via save', () async {
      final stored = _a(id: 9, name: 'Old', isArchived: true);
      when(() => accountRepo.getById(9)).thenAnswer((_) async => stored);
      when(() => accountRepo.save(any())).thenAnswer((inv) async => 9);
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(accountsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      accountsCtrl.add([_a(id: 1, name: 'Cash'), stored]);
      defaultCtrl.add(1);
      await Future<void>.delayed(Duration.zero);
      balanceCtrls[1]!.add(0);
      balanceCtrls[9]!.add(0);
      await waitForData(container);

      await container.read(accountsControllerProvider.notifier).unarchive(9);

      final captured =
          verify(() => accountRepo.save(captureAny())).captured.single
              as Account;
      expect(captured.id, 9);
      expect(captured.isArchived, isFalse);
    });
  });
}
