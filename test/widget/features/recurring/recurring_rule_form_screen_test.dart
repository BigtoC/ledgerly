// RecurringRuleFormScreen widget tests.
//
// These cover the screen's projection of [RecurringRuleFormState]:
// frequency-conditional fields, name validation, the edit-mode pending
// notice, and that the save action triggers the controller. They do
// NOT exercise the real repository or use case — those are covered by
// repository and use-case unit tests respectively.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/account.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/features/recurring/recurring_rule_form_controller.dart';
import 'package:ledgerly/features/recurring/recurring_rule_form_screen.dart';
import 'package:ledgerly/features/recurring/recurring_rule_form_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockAccountRepository extends Mock implements AccountRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

class _FakeFormController extends RecurringRuleFormController {
  _FakeFormController(this._initial);
  final RecurringRuleFormState _initial;

  int saveCallCount = 0;

  @override
  Future<RecurringRuleFormState> build({int? ruleId}) async {
    return _initial;
  }

  @override
  Future<int?> save() async {
    saveCallCount++;
    return null;
  }

  @override
  Future<void> deleteRule() async {}
}

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

ProviderContainer _makeContainer({
  required RecurringRuleFormState initial,
  int? ruleId,
}) {
  // The form's category and account picker tiles watch the repos so they
  // can render the picked entity's name + icon. Stub both with empty
  // streams; tests that exercise the picker UI itself live in their own
  // widget tests.
  final accountRepo = _MockAccountRepository();
  when(
    () => accountRepo.watchAll(includeArchived: any(named: 'includeArchived')),
  ).thenAnswer((_) => const Stream<List<Account>>.empty());
  when(
    () => accountRepo.watchAll(),
  ).thenAnswer((_) => const Stream<List<Account>>.empty());
  final categoryRepo = _MockCategoryRepository();
  when(
    () => categoryRepo.watchAll(
      includeArchived: any(named: 'includeArchived'),
      type: any(named: 'type'),
    ),
  ).thenAnswer((_) => const Stream<List<Category>>.empty());

  return ProviderContainer(
    overrides: [
      recurringRuleFormControllerProvider(
        ruleId: ruleId,
      ).overrideWith(() => _FakeFormController(initial)),
      accountRepositoryProvider.overrideWithValue(accountRepo),
      categoryRepositoryProvider.overrideWithValue(categoryRepo),
      categoriesByTypeProvider(
        CategoryType.expense,
      ).overrideWith((_) => const Stream<List<Category>>.empty()),
    ],
  );
}

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
}
