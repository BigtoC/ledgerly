// AccountsController unit tests (plan §3.3, §6, §7).
//
// Covers:
//   - State transitions: loading → data on first joint emission of
//     accounts + default + per-account balance streams.
//   - Per-account balance projection + re-emission when the balance
//     stream fires.
//   - Default-account id propagates into `AccountsData.defaultAccountId`
//     and flips when `userPreferences.setDefaultAccountId` writes.
//   - Every command returns a sealed outcome and never throws. One test
//     per outcome variant:
//     - `setDefault`: ok, failed.
//     - `archive`: ok, isDefault, lastActive (refuses to leave the user
//       with zero active accounts), hasActiveRecurringRule, failed.
//     - `unarchive`: ok, ok without a write when the row is gone, failed.
//     - `delete`: ok, isDefault, inUse, failed.
//
// Repositories mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/repository_exceptions.dart';
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
  int openingBalanceMinorUnits = 0,
  bool isArchived = false,
}) => Account(
  id: id,
  name: name,
  accountTypeId: 1,
  currency: _usd,
  openingBalanceMinorUnits: openingBalanceMinorUnits,
  isArchived: isArchived,
);

@Dependencies([AccountsController])
void main() {
  setUpAll(() {
    registerFallbackValue(_a(id: 0, name: '_'));
  });

  group('AccountsController', () {
    late _MockAccountRepository accountRepo;
    late _MockUserPreferencesRepository prefs;
    late StreamController<List<Account>> accountsCtrl;
    late StreamController<int?> defaultCtrl;
    final balanceCtrls = <int, StreamController<Map<String, int>>>{};

    setUp(() {
      accountRepo = _MockAccountRepository();
      prefs = _MockUserPreferencesRepository();
      accountsCtrl = StreamController<List<Account>>.broadcast();
      defaultCtrl = StreamController<int?>.broadcast();
      balanceCtrls.clear();

      when(() => accountRepo.watchAll(includeArchived: true))
          .thenAnswer((_) => accountsCtrl.stream);
      when(() => prefs.watchDefaultAccountId())
          .thenAnswer((_) => defaultCtrl.stream);
      when(() => accountRepo.watchIsReferenced(any())).thenAnswer((inv) {
        final id = inv.positionalArguments.first as int;
        final balance = balanceCtrls.putIfAbsent(
          id,
          () => StreamController<Map<String, int>>.broadcast(),
        );
        return balance.stream.asyncMap((_) => accountRepo.isReferenced(id));
      });
      when(() => accountRepo.isReferenced(any()))
          .thenAnswer((_) async => false);
      when(() => accountRepo.watchBalanceByCurrency(any())).thenAnswer((inv) {
        final id = inv.positionalArguments.first as int;
        final c = balanceCtrls.putIfAbsent(
          id,
          () => StreamController<Map<String, int>>.broadcast(),
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

    @Dependencies([AccountsController])
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

    /// A container whose controller already holds [rows] as data, with
    /// [defaultId] as the default account.
    @Dependencies([AccountsController])
    Future<ProviderContainer> containerWithData(
      List<Account> rows, {
      int? defaultId,
    }) async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(accountsControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      accountsCtrl.add(rows);
      defaultCtrl.add(defaultId);
      await Future<void>.delayed(Duration.zero);
      for (final a in rows) {
        balanceCtrls[a.id]!.add({});
      }
      await waitForData(container);
      return container;
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
        balanceCtrls[1]!.add({});

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
        balanceCtrls[1]!.add({'USD': 12345});
        balanceCtrls[2]!.add({});

        final state = await waitForData(container) as AccountsData;
        final byId = {
          for (final r in state.active) r.account.id: r.balancesByCurrency,
        };
        expect(byId[1], {'USD': 12345});
        expect(byId[2], <String, int>{});

        // Re-emission flows through.
        balanceCtrls[1]!.add({'USD': 99999});
        await Future<void>.delayed(Duration.zero);
        final state2 =
            container.read(accountsControllerProvider).value! as AccountsData;
        final byId2 = {
          for (final r in state2.active) r.account.id: r.balancesByCurrency,
        };
        expect(byId2[1], {'USD': 99999});
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
      balanceCtrls[1]!.add({});
      balanceCtrls[2]!.add({'USD': -500});

      final state = await waitForData(container) as AccountsData;
      expect(state.active.map((r) => r.account.id), [1]);
      expect(state.archived.map((r) => r.account.id), [2]);
      expect(state.archived.single.balancesByCurrency, {'USD': -500});
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
      balanceCtrls[7]!.add({});
      await waitForData(container);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .setDefault(7);

      expect(outcome, const SetDefaultAccountOutcome.ok());
      verify(() => prefs.setDefaultAccountId(7)).called(1);
    });

    test('A04b: setDefault returns failed when the write throws', () async {
      when(() => prefs.setDefaultAccountId(7))
          .thenThrow(StateError('disk full'));
      final container = await containerWithData([_a(id: 7, name: 'Target')]);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .setDefault(7);

      expect(outcome, const SetDefaultAccountOutcome.failed());
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
      balanceCtrls[1]!.add({});
      balanceCtrls[2]!.add({});
      await waitForData(container);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .archive(2);

      expect(outcome, const ArchiveAccountOutcome.ok());
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
        balanceCtrls[1]!.add({});
        await waitForData(container);

        final outcome = await container
            .read(accountsControllerProvider.notifier)
            .archive(1);

        expect(outcome, const ArchiveAccountOutcome.lastActive());
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
      balanceCtrls[1]!.add({});
      balanceCtrls[2]!.add({});
      await waitForData(container);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .archive(1);

      expect(outcome, const ArchiveAccountOutcome.isDefault());
      verifyNever(() => accountRepo.archive(any()));
    });

    test('A06c: archive maps AccountHasRecurringRuleException to '
        'hasActiveRecurringRule', () async {
      when(() => accountRepo.archive(2))
          .thenThrow(const AccountHasRecurringRuleException(2));
      final container = await containerWithData([
        _a(id: 1, name: 'Cash'),
        _a(id: 2, name: 'Spare'),
      ], defaultId: 1);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .archive(2);

      expect(outcome, const ArchiveAccountOutcome.hasActiveRecurringRule());
    });

    test('A06d: archive returns failed on any other error', () async {
      when(() => accountRepo.archive(2)).thenThrow(StateError('db closed'));
      final container = await containerWithData([
        _a(id: 1, name: 'Cash'),
        _a(id: 2, name: 'Spare'),
      ], defaultId: 1);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .archive(2);

      expect(outcome, const ArchiveAccountOutcome.failed());
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
      balanceCtrls[1]!.add({});
      balanceCtrls[2]!.add({});
      await waitForData(container);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .delete(1);

      expect(outcome, const DeleteAccountOutcome.isDefault());
      verifyNever(() => accountRepo.delete(any()));
    });

    test('A07b: delete returns ok after the repository deletes', () async {
      when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
      when(() => accountRepo.delete(2)).thenAnswer((_) async {});
      final container = await containerWithData([
        _a(id: 1, name: 'Cash'),
        _a(id: 2, name: 'Spare'),
      ], defaultId: 1);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .delete(2);

      expect(outcome, const DeleteAccountOutcome.ok());
      verify(() => accountRepo.delete(2)).called(1);
    });

    test('A07c: delete maps AccountInUseException to inUse', () async {
      when(() => prefs.getDefaultAccountId()).thenAnswer((_) async => 1);
      when(() => accountRepo.delete(2))
          .thenThrow(const AccountInUseException(2));
      final container = await containerWithData([
        _a(id: 1, name: 'Cash'),
        _a(id: 2, name: 'Spare'),
      ], defaultId: 1);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .delete(2);

      expect(outcome, const DeleteAccountOutcome.inUse());
    });

    test('A07d: delete returns failed on any other error', () async {
      when(() => prefs.getDefaultAccountId())
          .thenThrow(StateError('corrupt preference'));
      final container = await containerWithData([
        _a(id: 1, name: 'Cash'),
        _a(id: 2, name: 'Spare'),
      ], defaultId: 1);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .delete(2);

      expect(outcome, const DeleteAccountOutcome.failed());
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
        balanceCtrls[1]!.add({});
        balanceCtrls[2]!.add({});

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
        balanceCtrls[1]!.add({});
        balanceCtrls[2]!.add({});

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
      balanceCtrls[1]!.add({});
      balanceCtrls[2]!.add({'USD': 5000});

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
      balanceCtrls[1]!.add({});
      balanceCtrls[9]!.add({});
      await waitForData(container);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .unarchive(9);

      expect(outcome, const UnarchiveAccountOutcome.ok());
      final captured =
          verify(() => accountRepo.save(captureAny())).captured.single
              as Account;
      expect(captured.id, 9);
      expect(captured.isArchived, isFalse);
    });

    test(
      'A11b: unarchive of a row that is gone is ok and writes nothing',
      () async {
        when(() => accountRepo.getById(9)).thenAnswer((_) async => null);
        final container = await containerWithData([
          _a(id: 1, name: 'Cash'),
        ], defaultId: 1);

        final outcome = await container
            .read(accountsControllerProvider.notifier)
            .unarchive(9);

        expect(outcome, const UnarchiveAccountOutcome.ok());
        verifyNever(() => accountRepo.save(any()));
      },
    );

    test('A11c: unarchive returns failed when the save throws', () async {
      final stored = _a(id: 9, name: 'Old', isArchived: true);
      when(() => accountRepo.getById(9)).thenAnswer((_) async => stored);
      when(() => accountRepo.save(any()))
          .thenThrow(const AccountRepositoryException('Account 9 not found'));
      final container = await containerWithData([
        _a(id: 1, name: 'Cash'),
        stored,
      ], defaultId: 1);

      final outcome = await container
          .read(accountsControllerProvider.notifier)
          .unarchive(9);

      expect(outcome, const UnarchiveAccountOutcome.failed());
    });
  });
}
