// RecurringRulesController unit tests.
//
// Mirrors the ShoppingListController pattern: stream driven by a mocked
// repository, deletion flows asserted via fake-async timers and Mocktail.
// Commands return outcomes and never throw, so failures are asserted on
// the returned outcome; only the timer-driven delete commit reports
// through an effect.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/recurring_rule.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/ui/features/recurring/view_models/recurring_rules_controller.dart';
import 'package:ledgerly/ui/features/recurring/view_models/recurring_rules_state.dart';

class _MockRecurringRulesRepository extends Mock
    implements RecurringRulesRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

RecurringRule _rule({
  required int id,
  String name = 'Netflix',
  bool isActive = true,
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
  isArchived: false,
  nextDueDate: DateTime(2026, 6, 15),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

@Dependencies([RecurringRulesController])
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

    @Dependencies([RecurringRulesController])
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

    test('RRC04: pauseRule calls setActive(active: false) → ok', () async {
      when(() => repo.setActive(any(), active: any(named: 'active')))
          .thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      rulesCtrl.add([_rule(id: 1)]);
      await waitFor(container, (s) => s is RecurringRulesData);

      final outcome = await container
          .read(recurringRulesControllerProvider.notifier)
          .pauseRule(1);

      verify(() => repo.setActive(1, active: false)).called(1);
      expect(outcome, const PauseRecurringRuleOutcome.ok());
    });

    test('RRC04b: pauseRule returns failed when setActive throws', () async {
      when(() => repo.setActive(any(), active: any(named: 'active')))
          .thenThrow(StateError('disk full'));

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      rulesCtrl.add([_rule(id: 1)]);
      await waitFor(container, (s) => s is RecurringRulesData);

      final outcome = await container
          .read(recurringRulesControllerProvider.notifier)
          .pauseRule(1);

      expect(outcome, const PauseRecurringRuleOutcome.failed());
    });

    test('RRC05: resumeRule calls setActive(active: true) → ok', () async {
      final resumedRule = _rule(id: 1, isActive: true);
      when(() => repo.setActive(any(), active: any(named: 'active')))
          .thenAnswer((_) async {});
      when(() => repo.getById(1)).thenAnswer((_) async => resumedRule);

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      rulesCtrl.add([_rule(id: 1, isActive: false)]);
      await waitFor(container, (s) => s is RecurringRulesData);

      final outcome = await container
          .read(recurringRulesControllerProvider.notifier)
          .resumeRule(1);

      verify(() => repo.setActive(1, active: true)).called(1);
      verify(() => repo.getById(1)).called(1);
      expect(outcome, ResumeRecurringRuleOutcome.ok(resumedRule.nextDueDate));
    });

    test('RRC05b: resumeRule returns failed when setActive throws', () async {
      when(() => repo.setActive(any(), active: any(named: 'active')))
          .thenThrow(StateError('disk full'));

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      rulesCtrl.add([_rule(id: 1, isActive: false)]);
      await waitFor(container, (s) => s is RecurringRulesData);

      final outcome = await container
          .read(recurringRulesControllerProvider.notifier)
          .resumeRule(1);

      expect(outcome, const ResumeRecurringRuleOutcome.failed());
      verifyNever(() => repo.getById(any()));
    });

    test('RRC05c: resumeRule returns ok without a date when only the re-read '
        'fails', () async {
      when(() => repo.setActive(any(), active: any(named: 'active')))
          .thenAnswer((_) async {});
      when(() => repo.getById(1)).thenThrow(StateError('db closed'));

      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(recurringRulesControllerProvider, (_, _) {});

      rulesCtrl.add([_rule(id: 1, isActive: false)]);
      await waitFor(container, (s) => s is RecurringRulesData);

      final outcome = await container
          .read(recurringRulesControllerProvider.notifier)
          .resumeRule(1);

      // The rule was resumed, so the outcome must not say it failed.
      expect(outcome, const ResumeRecurringRuleOutcome.ok(null));
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

        final outcome = await container
            .read(recurringRulesControllerProvider.notifier)
            .deleteRule(1);
        expect(outcome, const DeleteRecurringRuleOutcome.pending());

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

        notifier.undoDelete(1);
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

    test(
      'RRC07b: undoDelete for another rule leaves the pending delete alone',
      () {
        fakeAsync((async) {
          when(() => repo.archive(any())).thenAnswer((_) async {});

          final container = makeContainer();
          addTearDown(container.dispose);
          container.listen(recurringRulesControllerProvider, (_, _) {});

          rulesCtrl.add([_rule(id: 1), _rule(id: 2, name: 'Rent')]);
          async.flushMicrotasks();

          final notifier = container.read(
            recurringRulesControllerProvider.notifier,
          );
          // ignore: unawaited_futures
          notifier.deleteRule(1);
          async.flushMicrotasks();

          // A stale Undo for a rule that is no longer pending.
          notifier.undoDelete(2);
          async.flushMicrotasks();

          final state =
              container.read(recurringRulesControllerProvider).value!
                  as RecurringRulesData;
          expect(state.pendingDelete?.ruleId, 1);
          expect(state.rules.map((r) => r.id), [2]);

          async.elapse(kUndoWindow + const Duration(seconds: 1));
          async.flushMicrotasks();

          verify(() => repo.archive(1)).called(1);
        });
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

    test('RRC09: deleteRule returns notStarted when the prior commit fails, '
        'without firing the effect', () async {
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
      // commit the prior, which throws → the second delete never starts.
      await notifier.deleteRule(1);
      await waitFor(
        container,
        (s) => s is RecurringRulesData && s.pendingDelete?.ruleId == 1,
      );

      final outcome = await notifier.deleteRule(2);
      await pump();

      expect(outcome, const DeleteRecurringRuleOutcome.notStarted());
      // The outcome reports it; the widget shows the error, not the effect.
      expect(effectCaptured, isNull);
      // Rule 1 reappears after the failed commit; rule 2 was never hidden.
      final after = await waitFor(
        container,
        (s) => s is RecurringRulesData && s.rules.any((r) => r.id == 1),
      ) as RecurringRulesData;
      expect(after.rules.map((r) => r.id), [1, 2]);
      expect(after.pendingDelete, isNull);
    });

    test('RRC09b: a delete still committing the prior rule when the screen '
        'closes opens no undo window', () {
      fakeAsync((async) {
        final priorCommit = Completer<void>();
        when(() => repo.archive(1)).thenAnswer((_) => priorCommit.future);

        final container = makeContainer();
        addTearDown(container.dispose);
        final sub = container.listen(
          recurringRulesControllerProvider,
          (_, _) {},
        );
        rulesCtrl.add([_rule(id: 1), _rule(id: 2, name: 'Rent')]);
        async.flushMicrotasks();

        final notifier = container.read(
          recurringRulesControllerProvider.notifier,
        );
        // ignore: unawaited_futures
        notifier.deleteRule(1);
        async.flushMicrotasks();
        DeleteRecurringRuleOutcome? outcome;
        notifier.deleteRule(2).then((o) => outcome = o);
        async.flushMicrotasks();
        verify(() => repo.archive(1)).called(1);

        // The screen closes while rule 1's commit is in flight.
        sub.close();
        // ignore: unawaited_futures
        container.pump();
        async.elapse(Duration.zero);
        priorCommit.complete();
        async.flushMicrotasks();

        expect(outcome, const DeleteRecurringRuleOutcome.notStarted());
        expect(async.pendingTimers, isEmpty);
      });
    });

    test(
      'RRC10: failed timer commit fires the effect and restores the row',
      () {
        fakeAsync((async) {
          when(() => repo.archive(any())).thenThrow(StateError('disk full'));

          final container = makeContainer();
          addTearDown(container.dispose);
          container.listen(recurringRulesControllerProvider, (_, _) {});

          rulesCtrl.add([_rule(id: 1)]);
          async.flushMicrotasks();

          final notifier = container.read(
            recurringRulesControllerProvider.notifier,
          );
          RecurringRulesEffect? effectCaptured;
          notifier.setEffectListener((effect) => effectCaptured = effect);

          // ignore: unawaited_futures
          notifier.deleteRule(1);
          async.flushMicrotasks();
          expect(effectCaptured, isNull);

          async.elapse(kUndoWindow + const Duration(seconds: 1));
          async.flushMicrotasks();

          expect(effectCaptured, isA<RecurringRulesDeleteFailedEffect>());
          final state =
              container.read(recurringRulesControllerProvider).value!
                  as RecurringRulesData;
          expect(state.rules.map((r) => r.id), [1]);
          expect(state.pendingDelete, isNull);
        });
      },
    );
  });
}
