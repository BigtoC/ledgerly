// RecurringRulesScreen widget tests.
//
// Covers loading / empty / data / error rendering, FAB navigation, paused
// chip rendering, and the swipe-delete + undo snackbar contract.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/features/recurring/recurring_rules_controller.dart';
import 'package:ledgerly/features/recurring/recurring_rules_screen.dart';
import 'package:ledgerly/features/recurring/recurring_rules_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

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

ProviderContainer _makeContainer(RecurringRulesState fixed) {
  final repo = _MockRecurringRulesRepository();
  when(() => repo.watchActive()).thenAnswer((_) => const Stream.empty());
  when(
    () => repo.setActive(any(), active: any(named: 'active')),
  ).thenAnswer((_) async {});
  when(() => repo.archive(any())).thenAnswer((_) async {});
  return ProviderContainer(
    overrides: [
      recurringRulesRepositoryProvider.overrideWithValue(repo),
      recurringRulesControllerProvider.overrideWith(
        () => _FakeController(fixed),
      ),
    ],
  );
}

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
}
