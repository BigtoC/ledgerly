// RecurringRulesScreen widget tests.
//
// Covers loading / empty / data / error rendering, FAB navigation, paused
// chip rendering, the pause / resume failure snackbars, and the
// swipe-delete + undo snackbar contract (including a delete that cannot
// start and a stale Undo).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/domain/models/recurring_rule.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/ui/features/recurring/view_models/recurring_rules_controller.dart';
import 'package:ledgerly/ui/features/recurring/views/recurring_rules_screen.dart';
import 'package:ledgerly/ui/features/recurring/view_models/recurring_rules_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockRecurringRulesRepository extends Mock
    implements RecurringRulesRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

const _genericError = 'Something went wrong. Please try again.';

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

class _FakeController extends RecurringRulesController {
  _FakeController(this._fixed);
  final RecurringRulesState _fixed;

  @override
  Stream<RecurringRulesState> build() async* {
    yield _fixed;
  }
}

class _StubRouter {
  static GoRouter build(Widget home) {
    return GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/settings/recurring/new',
          builder: (_, _) => const Scaffold(body: Text('NEW_RECURRING')),
        ),
        GoRoute(
          path: '/settings/recurring/:id',
          builder: (ctx, state) =>
              Scaffold(body: Text('EDIT_${state.pathParameters['id']}')),
        ),
      ],
    );
  }
}

@Dependencies([RecurringRulesController])
Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _StubRouter.build(const RecurringRulesScreen()),
    ),
  );
}

/// Stubs [repo]'s writes to succeed. Pass a [repo] and re-stub a write
/// with `thenThrow` after this call to make that command fail.
ProviderContainer _makeContainer(
  RecurringRulesState fixed, {
  _MockRecurringRulesRepository? repo,
}) {
  final r = repo ?? _MockRecurringRulesRepository();
  when(() => r.watchActive()).thenAnswer((_) => const Stream.empty());
  when(() => r.setActive(any(), active: any(named: 'active')))
      .thenAnswer((_) async {});
  when(() => r.archive(any())).thenAnswer((_) async {});
  return ProviderContainer(
    overrides: [
      recurringRulesRepositoryProvider.overrideWithValue(r),
      recurringRulesControllerProvider.overrideWith(
        () => _FakeController(fixed),
      ),
    ],
  );
}

@Dependencies([RecurringRulesController])
void main() {
  testWidgets('RRS01: shows loading indicator in loading state', (
    tester,
  ) async {
    final container = _makeContainer(const RecurringRulesState.loading());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('RRS02: empty state CTA navigates to /settings/recurring/new', (
    tester,
  ) async {
    final container = _makeContainer(const RecurringRulesState.empty());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('No recurring rules yet'), findsOneWidget);
    await tester.tap(find.text('Create rule'));
    await tester.pumpAndSettle();
    expect(find.text('NEW_RECURRING'), findsOneWidget);
  });

  testWidgets('RRS03: data state renders rule names', (tester) async {
    final container = _makeContainer(
      RecurringRulesState.data(
        rules: [
          _rule(id: 1),
          _rule(id: 2, name: 'Rent'),
        ],
        pendingDelete: null,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
  });

  testWidgets('RRS04: paused rule renders the Paused chip', (tester) async {
    final container = _makeContainer(
      RecurringRulesState.data(
        rules: [_rule(id: 1, isActive: false)],
        pendingDelete: null,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('RRS05: tile tap navigates to /settings/recurring/:id', (
    tester,
  ) async {
    final container = _makeContainer(
      RecurringRulesState.data(rules: [_rule(id: 7)], pendingDelete: null),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Netflix'));
    await tester.pumpAndSettle();
    expect(find.text('EDIT_7'), findsOneWidget);
  });

  testWidgets('RRS06: FAB is the new-rule entry point on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = _makeContainer(const RecurringRulesState.empty());
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('RRS07: error state shows retry button', (tester) async {
    final container = _makeContainer(
      RecurringRulesState.error(StateError('boom'), StackTrace.current),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your rules."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('RRS08: failed pause shows the generic error snackbar', (
    tester,
  ) async {
    final repo = _MockRecurringRulesRepository();
    final container = _makeContainer(
      RecurringRulesState.data(rules: [_rule(id: 1)], pendingDelete: null),
      repo: repo,
    );
    addTearDown(container.dispose);
    when(() => repo.setActive(any(), active: any(named: 'active')))
        .thenThrow(StateError('disk full'));

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Netflix'), const Offset(300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(_genericError), findsOneWidget);
    expect(find.text('Paused — Netflix'), findsNothing);
  });

  testWidgets('RRS09: failed resume shows the generic error snackbar', (
    tester,
  ) async {
    final repo = _MockRecurringRulesRepository();
    final container = _makeContainer(
      RecurringRulesState.data(
        rules: [_rule(id: 1, isActive: false)],
        pendingDelete: null,
      ),
      repo: repo,
    );
    addTearDown(container.dispose);
    when(() => repo.setActive(any(), active: any(named: 'active')))
        .thenThrow(StateError('disk full'));

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Netflix'), const Offset(300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(_genericError), findsOneWidget);
    expect(find.textContaining('Resumed'), findsNothing);
  });

  testWidgets('RRS10: swipe-delete shows Undo, and Undo cancels the delete', (
    tester,
  ) async {
    final repo = _MockRecurringRulesRepository();
    final container = _makeContainer(
      RecurringRulesState.data(rules: [_rule(id: 1)], pendingDelete: null),
      repo: repo,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Netflix'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Rule deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump(kUndoWindow);
    await tester.pumpAndSettle();

    verifyNever(() => repo.archive(any()));
  });

  testWidgets(
    'RRS11: a delete that cannot start shows the error and no "Rule deleted"',
    (tester) async {
      final repo = _MockRecurringRulesRepository();
      final container = _makeContainer(
        RecurringRulesState.data(
          rules: [
            _rule(id: 1),
            _rule(id: 2, name: 'Rent'),
          ],
          pendingDelete: null,
        ),
        repo: repo,
      );
      addTearDown(container.dispose);
      when(() => repo.archive(1)).thenThrow(StateError('disk full'));

      await tester.pumpWidget(_wrap(container));
      await tester.pumpAndSettle();

      await tester.drag(find.text('Netflix'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Rule deleted'), findsOneWidget);

      // Deleting Rent commits Netflix's pending delete first, which fails,
      // so Rent's delete never starts.
      await tester.drag(find.text('Rent'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_genericError), findsOneWidget);
      expect(find.text('Rule deleted'), findsNothing);

      // Nothing is queued behind the error either.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Rule deleted'), findsNothing);
    },
  );

  testWidgets('RRS12: a stale Undo cannot cancel a newer pending delete', (
    tester,
  ) async {
    final repo = _MockRecurringRulesRepository();
    final container = _makeContainer(
      RecurringRulesState.data(
        rules: [
          _rule(id: 1),
          _rule(id: 2, name: 'Rent'),
        ],
        pendingDelete: null,
      ),
      repo: repo,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Netflix'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    final staleUndo = tester
        .widget<SnackBarAction>(find.byType(SnackBarAction))
        .onPressed;

    // Deleting Rent commits Netflix's delete and makes Rent pending.
    await tester.drag(find.text('Rent'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    verify(() => repo.archive(1)).called(1);

    staleUndo();
    await tester.pump(kUndoWindow);
    await tester.pumpAndSettle();

    verify(() => repo.archive(2)).called(1);
  });
}
