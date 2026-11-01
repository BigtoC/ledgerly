// RecurringRuleFormScreen widget tests.
//
// These cover the screen's projection of [RecurringRuleFormState]
// (titles, frequency-conditional fields, the edit-mode pending notice and
// the form-error banner) and how the screen handles the save and delete
// outcomes a fake controller returns. They do NOT exercise the real
// controller, repository or use case — those are covered by controller,
// repository and use-case unit tests respectively.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/account.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/domain/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/ui/features/recurring/view_models/recurring_rule_form_controller.dart';
import 'package:ledgerly/ui/features/recurring/views/recurring_rule_form_screen.dart';
import 'package:ledgerly/ui/features/recurring/view_models/recurring_rule_form_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

const _genericError = 'Something went wrong. Please try again.';

const _editState = RecurringRuleFormState(
  currency: _usd,
  isEdit: true,
  memo: 'Netflix',
  amountMinorUnits: 1599,
  categoryId: 1,
  accountId: 1,
  dayOfMonth: 15,
);

class _FakeFormController extends RecurringRuleFormController {
  _FakeFormController(
    this._initial, {
    this.saveOutcome = const SaveRecurringRuleOutcome.rejected(),
    this.archiveOutcome = const ArchiveRecurringRuleOutcome.ok(),
  });
  final RecurringRuleFormState _initial;
  final SaveRecurringRuleOutcome saveOutcome;
  final ArchiveRecurringRuleOutcome archiveOutcome;

  @override
  Future<RecurringRuleFormState> build({int? ruleId}) async {
    return _initial;
  }

  @override
  Future<SaveRecurringRuleOutcome> save() async => saveOutcome;

  @override
  Future<ArchiveRecurringRuleOutcome> deleteRule() async => archiveOutcome;
}

@Dependencies([RecurringRuleFormController, categoriesByType])
Widget _wrap(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RecurringRuleFormScreen(),
    ),
  );
}

/// Hosts the form as a child route of a 'LIST' page so the screen's
/// `GoRouter.of(context)` resolves and a pop lands on 'LIST'.
@Dependencies([RecurringRuleFormController, categoriesByType])
Widget _wrapRouted(ProviderContainer container, {int? ruleId}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/form',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('LIST')),
            routes: [
              GoRoute(
                path: 'form',
                builder: (_, _) => RecurringRuleFormScreen(ruleId: ruleId),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

ProviderContainer _makeContainer({
  required RecurringRuleFormState initial,
  int? ruleId,
  SaveRecurringRuleOutcome saveOutcome =
      const SaveRecurringRuleOutcome.rejected(),
  ArchiveRecurringRuleOutcome archiveOutcome =
      const ArchiveRecurringRuleOutcome.ok(),
}) {
  // The form's category and account picker tiles watch the repos so they
  // can render the picked entity's name + icon. Stub both with empty
  // streams; tests that exercise the picker UI itself live in their own
  // widget tests.
  final accountRepo = _MockAccountRepository();
  when(
    () => accountRepo.watchAll(includeArchived: any(named: 'includeArchived')),
  ).thenAnswer((_) => const Stream<List<Account>>.empty());
  when(() => accountRepo.watchAll())
      .thenAnswer((_) => const Stream<List<Account>>.empty());
  final categoryRepo = _MockCategoryRepository();
  when(
    () => categoryRepo.watchAll(
      includeArchived: any(named: 'includeArchived'),
      type: any(named: 'type'),
    ),
  ).thenAnswer((_) => const Stream<List<Category>>.empty());

  return ProviderContainer(
    overrides: [
      recurringRuleFormControllerProvider(ruleId: ruleId).overrideWith(
        () => _FakeFormController(
          initial,
          saveOutcome: saveOutcome,
          archiveOutcome: archiveOutcome,
        ),
      ),
      accountRepositoryProvider.overrideWithValue(accountRepo),
      categoryRepositoryProvider.overrideWithValue(categoryRepo),
      categoriesByTypeProvider(CategoryType.expense)
          .overrideWith((_) => const Stream<List<Category>>.empty()),
    ],
  );
}

/// Pushes the test viewport tall enough that the bottom-fixed
/// `CalculatorKeypad` doesn't push frequency-specific fields offstage.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400 * 3, 1200 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

@Dependencies([RecurringRuleFormController, categoriesByType])
void main() {
  testWidgets('RFS01: create-mode app bar title and Create action label', (
    tester,
  ) async {
    final container = _makeContainer(
      initial: const RecurringRuleFormState(currency: _usd),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('New rule'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('RFS02: edit-mode app bar title and Save action label', (
    tester,
  ) async {
    final container = _makeContainer(
      initial: const RecurringRuleFormState(
        currency: _usd,
        isEdit: true,
        memo: 'Netflix',
        amountMinorUnits: 1599,
        categoryId: 1,
        accountId: 1,
        dayOfMonth: 15,
      ),
      ruleId: 1,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RecurringRuleFormScreen(ruleId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit rule'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('RFS03: weekly frequency renders weekday chips', (tester) async {
    _useTallViewport(tester);
    final container = _makeContainer(
      initial: const RecurringRuleFormState(
        currency: _usd,
        frequency: 'weekly',
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNWidgets(7));
    expect(find.text('Mo'), findsOneWidget);
    expect(find.text('Su'), findsOneWidget);
  });

  testWidgets('RFS04: monthly frequency shows the day-of-month hint', (
    tester,
  ) async {
    _useTallViewport(tester);
    final container = _makeContainer(
      initial: const RecurringRuleFormState(
        currency: _usd,
        frequency: 'monthly',
        dayOfMonth: 15,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'If the month is shorter, the rule uses the last day of that month.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('RFS05: daily helper text is shown when frequency=daily', (
    tester,
  ) async {
    _useTallViewport(tester);
    final container = _makeContainer(
      initial: const RecurringRuleFormState(currency: _usd, frequency: 'daily'),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(
      find.text('Generates one pending transaction every day from today.'),
      findsOneWidget,
    );
  });

  testWidgets('RFS06: edit mode with pending items renders the inline notice', (
    tester,
  ) async {
    final container = _makeContainer(
      initial: const RecurringRuleFormState(
        currency: _usd,
        isEdit: true,
        memo: 'Netflix',
        amountMinorUnits: 1599,
        categoryId: 1,
        accountId: 1,
        dayOfMonth: 15,
        pendingItemCount: 2,
      ),
      ruleId: 1,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RecurringRuleFormScreen(ruleId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Localized notice mentions count + Home guidance.
    expect(find.textContaining('pending item'), findsOneWidget);
  });

  testWidgets('RFS07: error banner is rendered when formError is set', (
    tester,
  ) async {
    final container = _makeContainer(
      initial: const RecurringRuleFormState(
        currency: _usd,
        formError: RecurringFormError.archivedRef('Category 1 is archived'),
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('Category 1 is archived'), findsOneWidget);
  });

  testWidgets('RFS08: yearly frequency renders a month dropdown', (
    tester,
  ) async {
    _useTallViewport(tester);
    final container = _makeContainer(
      initial: const RecurringRuleFormState(
        currency: _usd,
        frequency: 'yearly',
        monthOfYear: 6,
        dayOfMonth: 15,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    // Frequency dropdown ('Yearly') + month dropdown.
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(
      find.text(
        'If the month is shorter, the rule uses the last day of that month.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('RFS09: failed delete shows the generic error and stays open', (
    tester,
  ) async {
    _useTallViewport(tester);
    final container = _makeContainer(
      initial: _editState,
      ruleId: 1,
      archiveOutcome: const ArchiveRecurringRuleOutcome.failed(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapRouted(container, ruleId: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete rule'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete rule'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(_genericError), findsOneWidget);
    expect(find.text('Rule deleted'), findsNothing);
    expect(find.text('Edit rule'), findsOneWidget);
  });

  testWidgets('RFS10: failed save shows the generic error and stays open', (
    tester,
  ) async {
    final container = _makeContainer(
      initial: _editState,
      ruleId: 1,
      saveOutcome: const SaveRecurringRuleOutcome.failed(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrapRouted(container, ruleId: 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(_genericError), findsOneWidget);
    expect(find.text('Edit rule'), findsOneWidget);
  });

  testWidgets(
    'RFS11: saved with a generation failure says so and closes the form',
    (tester) async {
      final container = _makeContainer(
        initial: _editState,
        ruleId: 1,
        saveOutcome: const SaveRecurringRuleOutcome.saved(1, true),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrapRouted(container, ruleId: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Saved — but the first run hit an issue. We'll retry on the next "
          'launch.',
        ),
        findsOneWidget,
      );
      expect(find.text('LIST'), findsOneWidget);
      expect(find.text('Edit rule'), findsNothing);
    },
  );
}
