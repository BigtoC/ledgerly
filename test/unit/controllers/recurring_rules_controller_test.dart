// RecurringRulesController unit tests.
//
// Mirrors the ShoppingListController pattern: stream driven by a mocked
// repository, deletion flows asserted via fake-async timers and Mocktail.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/features/recurring/recurring_rules_controller.dart';
import 'package:ledgerly/features/recurring/recurring_rules_state.dart';

class _MockRecurringRulesRepository extends Mock
    implements RecurringRulesRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

RecurringRule _rule({
  required int id,
  String name = 'Netflix',
  bool isActive = true,
  bool isArchived = false,
}) => RecurringRule(
  id: id,
  name: name,
  amountMinorUnits: 1599,
  currency: _usd,
  categoryId: 1,
  accountId: 1,
  frequency: 'monthly',
  dayOfMonth: 15,
  isActive: isActive,
  isArchived: isArchived,
  nextDueDate: DateTime(2026, 6, 15),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  group('RecurringRulesController', () {
    late _MockRecurringRulesRepository repo;
    late StreamController<List<RecurringRule>> rulesCtrl;

    setUp(() {
      repo = _MockRecurringRulesRepository();
      rulesCtrl = StreamController<List<RecurringRule>>.broadcast();
      when(() => repo.watchActive()).thenAnswer((_) => rulesCtrl.stream);
    });

    tearDown(() async {
      await rulesCtrl.close();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [recurringRulesRepositoryProvider.overrideWithValue(repo)],
      );
    }

    Future<RecurringRulesState> waitFor(
      ProviderContainer c,
      bool Function(RecurringRulesState) accept,
    ) async {
      for (var i = 0; i < 200; i++) {
        final s = c.read(recurringRulesControllerProvider);
        if (s is AsyncData<RecurringRulesState> && accept(s.value)) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError(
        'RecurringRulesController never produced expected state',
      );
    }

    Future<void> pump() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('RRC01: loading → data when stream emits rules', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      expect(
        container.read(recurringRulesControllerProvider),
        isA<AsyncLoading<RecurringRulesState>>(),
      );

      await Future<void>.delayed(Duration.zero);
      rulesCtrl.add([_rule(id: 1)]);

      final state = await waitFor(container, (s) => s is RecurringRulesData);
      final data = state as RecurringRulesData;
      expect(data.rules, hasLength(1));
      expect(data.pendingDelete, isNull);
    });

    test('RRC02: loading → empty when stream emits empty list', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      rulesCtrl.add(const []);

      final state = await waitFor(container, (s) => s is RecurringRulesEmpty);
      expect(state, isA<RecurringRulesEmpty>());
    });

    test('RRC03: stream error becomes RecurringRulesError', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      rulesCtrl.addError(StateError('boom'), StackTrace.current);

      final state = await waitFor(container, (s) => s is RecurringRulesError);
      expect((state as RecurringRulesError).error, isA<StateError>());
    });

    test('RRC04: pauseRule calls setActive(active: false)', () async {
      when(
        () => repo.setActive(any(), active: any(named: 'active')),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      rulesCtrl.add([_rule(id: 1)]);
      await waitFor(container, (s) => s is RecurringRulesData);

      await container
          .read(recurringRulesControllerProvider.notifier)
          .pauseRule(1);

      verify(() => repo.setActive(1, active: false)).called(1);
    });

    test('RRC05: resumeRule calls setActive(active: true)', () async {
      when(
        () => repo.setActive(any(), active: any(named: 'active')),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      rulesCtrl.add([_rule(id: 1, isActive: false)]);
      await waitFor(container, (s) => s is RecurringRulesData);

      await container
          .read(recurringRulesControllerProvider.notifier)
          .resumeRule(1);

      verify(() => repo.setActive(1, active: true)).called(1);
    });

    test(
      'RRC06: deleteRule hides row immediately and starts undo window',
      () async {
        when(() => repo.archive(any())).thenAnswer((_) async {});

        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(recurringRulesControllerProvider, (_, _) {});

        rulesCtrl.add([_rule(id: 1), _rule(id: 2, name: 'Rent')]);
        await waitFor(container, (s) => s is RecurringRulesData);

        // ignore: unawaited_futures
        container.read(recurringRulesControllerProvider.notifier).deleteRule(1);

        final state = await waitFor(
          container,
          (s) =>
              s is RecurringRulesData &&
              s.pendingDelete != null &&
              s.rules.length == 1 &&
              s.rules.first.id == 2,
        );
        expect((state as RecurringRulesData).pendingDelete?.ruleId, 1);
        verifyNever(() => repo.archive(any()));
      },
    );

    test(
      'RRC07: undoDelete cancels the timer; repo.archive never called',
      () async {
        when(() => repo.archive(any())).thenAnswer((_) async {});

        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(recurringRulesControllerProvider, (_, _) {});

        rulesCtrl.add([_rule(id: 1), _rule(id: 2, name: 'Rent')]);
        await waitFor(container, (s) => s is RecurringRulesData);

        final notifier = container.read(
          recurringRulesControllerProvider.notifier,
        );
        // ignore: unawaited_futures
        notifier.deleteRule(1);
        await waitFor(
          container,
          (s) => s is RecurringRulesData && s.pendingDelete != null,
        );

        await notifier.undoDelete();
        await pump();

        // The hidden row reappears; repo.archive must not have run.
        final restored = await waitFor(
          container,
          (s) =>
              s is RecurringRulesData &&
              s.pendingDelete == null &&
              s.rules.length == 2,
        );
        expect(restored, isA<RecurringRulesData>());
        verifyNever(() => repo.archive(any()));
      },
    );

    test('RRC08: timer expiry calls repo.archive', () {
      fakeAsync((async) {
        when(() => repo.archive(any())).thenAnswer((_) async {});

        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(recurringRulesControllerProvider, (_, _) {});

        rulesCtrl.add([_rule(id: 1)]);
        async.flushMicrotasks();

        // ignore: unawaited_futures
        container.read(recurringRulesControllerProvider.notifier).deleteRule(1);
        async.flushMicrotasks();

        async.elapse(kUndoWindow + const Duration(seconds: 1));
        async.flushMicrotasks();

        verify(() => repo.archive(1)).called(1);
      });
    });

    test('RRC09: failed delete fires effect and restores row', () async {
      when(() => repo.archive(any())).thenThrow(StateError('disk full'));

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      rulesCtrl.add([_rule(id: 1), _rule(id: 2, name: 'Rent')]);
      await waitFor(container, (s) => s is RecurringRulesData);

      final notifier = container.read(
        recurringRulesControllerProvider.notifier,
      );
      RecurringRulesEffect? effectCaptured;
      notifier.setEffectListener((effect) => effectCaptured = effect);

      // Trigger first deletion → start timer. Then a SECOND deletion will
      // commit the prior, which throws → effect fires.
      // ignore: unawaited_futures
      notifier.deleteRule(1);
      await waitFor(
        container,
        (s) => s is RecurringRulesData && s.pendingDelete?.ruleId == 1,
      );

      // ignore: unawaited_futures
      notifier.deleteRule(2);
      await pump();

      expect(effectCaptured, isA<RecurringRulesDeleteFailedEffect>());
      // Rule 1 must reappear after the failed commit.
      final after = await waitFor(
        container,
        (s) => s is RecurringRulesData && s.rules.any((r) => r.id == 1),
      );
      expect(after, isA<RecurringRulesData>());
    });
  });
}
