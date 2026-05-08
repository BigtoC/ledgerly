import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule.dart';
import 'package:ledgerly/data/models/recurring_rule_draft.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/data/use_cases/recurring_generation_use_case.dart';
import 'package:ledgerly/features/recurring/recurring_rule_form_controller.dart';
import 'package:ledgerly/features/recurring/recurring_rule_form_state.dart';

class _MockRecurringRulesRepository extends Mock
    implements RecurringRulesRepository {}

class _MockRecurringGenerationUseCase extends Mock
    implements RecurringGenerationUseCase {}

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

class _MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

class _MockPendingTransactionRepository extends Mock
    implements PendingTransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2, symbol: r'$');

RecurringRule _rule({
  int id = 1,
  String memo = 'Netflix',
  int amountMinorUnits = 1599,
  int categoryId = 10,
  int accountId = 20,
  String frequency = 'monthly',
  int? dayOfWeek,
  int? dayOfMonth = 15,
  int? monthOfYear,
}) => RecurringRule(
  id: id,
  name: memo,
  amountMinorUnits: amountMinorUnits,
  currency: _usd,
  categoryId: categoryId,
  accountId: accountId,
  memo: memo,
  frequency: frequency,
  dayOfWeek: dayOfWeek,
  dayOfMonth: dayOfMonth,
  monthOfYear: monthOfYear,
  isActive: true,
  isArchived: false,
  nextDueDate: DateTime(2026, 5, 15),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const RecurringRuleDraft(
        name: 'Fallback',
        amountMinorUnits: 100,
        currency: _usd,
        categoryId: 1,
        accountId: 1,
        frequency: 'daily',
      ),
    );
  });

  late _MockRecurringRulesRepository recurringRepo;
  late _MockRecurringGenerationUseCase generationUseCase;
  late _MockCurrencyRepository currencyRepo;
  late _MockUserPreferencesRepository prefs;
  late _MockPendingTransactionRepository pendingRepo;

  setUp(() {
    recurringRepo = _MockRecurringRulesRepository();
    generationUseCase = _MockRecurringGenerationUseCase();
    currencyRepo = _MockCurrencyRepository();
    prefs = _MockUserPreferencesRepository();
    pendingRepo = _MockPendingTransactionRepository();

    when(() => prefs.getDefaultCurrency()).thenAnswer((_) async => 'USD');
    when(() => currencyRepo.getByCode('USD')).thenAnswer((_) async => _usd);
    when(
      () => pendingRepo.countByRecurringRule(any()),
    ).thenAnswer((_) async => 0);
    when(
      () => generationUseCase.executeForRule(any(), clock: any(named: 'clock')),
    ).thenAnswer(
      (_) async => const RecurringGenerationOutcome(
        ruleId: 1,
        generated: 1,
        capped: false,
      ),
    );
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        recurringRulesRepositoryProvider.overrideWithValue(recurringRepo),
        recurringGenerationUseCaseProvider.overrideWithValue(generationUseCase),
        currencyRepositoryProvider.overrideWithValue(currencyRepo),
        userPreferencesRepositoryProvider.overrideWithValue(prefs),
        pendingTransactionRepositoryProvider.overrideWithValue(pendingRepo),
      ],
    );
  }

  Future<RecurringRuleFormState> buildState(
    ProviderContainer container, {
    int? ruleId,
  }) async {
    final value = await container.read(
      recurringRuleFormControllerProvider(ruleId: ruleId).future,
    );
    return value;
  }

  group('RecurringRuleFormController', () {
    test('build for create seeds default currency', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      final state = await buildState(c);

      expect(state.currency.code, 'USD');
      expect(state.isEdit, isFalse);
    });

    test('build for edit hydrates stored rule and pending count', () async {
      when(() => recurringRepo.getById(1)).thenAnswer((_) async => _rule());

      final c = makeContainer();
      addTearDown(c.dispose);

      final state = await buildState(c, ruleId: 1);

      expect(state.isEdit, isTrue);
      expect(state.memo, 'Netflix');
      expect(state.amountMinorUnits, 1599);
      expect(state.categoryId, 10);
      expect(state.accountId, 20);
    });

    test('save create inserts draft and runs generation', () async {
      when(
        () => recurringRepo.insert(any(), today: any(named: 'today')),
      ).thenAnswer((_) async => 42);

      final c = makeContainer();
      addTearDown(c.dispose);
      await buildState(c);
      final controller = c.read(recurringRuleFormControllerProvider().notifier);

      controller.updateMemo('Netflix');
      controller.appendDigit(1);
      controller.appendDigit(5);
      controller.updateCategory(10);
      controller.updateAccount(20);
      controller.updateDayOfMonth(15);

      final id = await controller.save();

      expect(id, 42);
      verify(
        () => recurringRepo.insert(any(), today: any(named: 'today')),
      ).called(1);
      verify(
        () => generationUseCase.executeForRule(42, clock: any(named: 'clock')),
      ).called(1);
    });

    test(
      'save edit updates draft and records generation failure flag',
      () async {
        when(
          () => recurringRepo.getById(7),
        ).thenAnswer((_) async => _rule(id: 7));
        when(() => recurringRepo.update(7, any())).thenAnswer((_) async {});
        when(
          () => generationUseCase.executeForRule(
            any(),
            clock: any(named: 'clock'),
          ),
        ).thenAnswer((_) async => RecurringGenerationOutcome.failed(7));

        final c = makeContainer();
        addTearDown(c.dispose);
        await buildState(c, ruleId: 7);
        final provider = recurringRuleFormControllerProvider(ruleId: 7);
        final controller = c.read(provider.notifier);

        final id = await controller.save();

        expect(id, 7);
        verify(() => recurringRepo.update(7, any())).called(1);
        final state = c.read(provider).valueOrNull!;
        expect(state.postSaveGenerationFailed, isTrue);
      },
    );

    test('save with incomplete fields marks validation errors', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await buildState(c);
      final provider = recurringRuleFormControllerProvider();
      final controller = c.read(provider.notifier);

      final id = await controller.save();

      expect(id, isNull);
      final state = c.read(provider).valueOrNull!;
      expect(state.nameError, RecurringFormErrorKey.nameRequired);
      expect(state.categoryError, RecurringFormErrorKey.categoryRequired);
      expect(state.accountError, RecurringFormErrorKey.accountRequired);
    });

    test('save surfaces archived reference error from repository', () async {
      when(
        () => recurringRepo.insert(any(), today: any(named: 'today')),
      ).thenThrow(
        const ArchivedReferenceException('Category 10 is archived or missing'),
      );

      final c = makeContainer();
      addTearDown(c.dispose);
      await buildState(c);
      final provider = recurringRuleFormControllerProvider();
      final controller = c.read(provider.notifier);

      controller.updateMemo('Netflix');
      controller.appendDigit(1);
      controller.appendDigit(5);
      controller.updateCategory(10);
      controller.updateAccount(20);
      controller.updateDayOfMonth(15);

      final id = await controller.save();

      expect(id, isNull);
      final state = c.read(provider).valueOrNull!;
      expect(state.formError, isA<ArchivedRefErr>());
      expect(
        (state.formError as ArchivedRefErr).detail,
        'Category 10 is archived or missing',
      );
    });

    test('save clears isLoading after async generation completes', () async {
      when(
        () => recurringRepo.insert(any(), today: any(named: 'today')),
      ).thenAnswer((_) async => 42);
      final completer = Completer<RecurringGenerationOutcome>();
      when(
        () =>
            generationUseCase.executeForRule(any(), clock: any(named: 'clock')),
      ).thenAnswer((_) => completer.future);

      final c = makeContainer();
      addTearDown(c.dispose);
      await buildState(c);
      final provider = recurringRuleFormControllerProvider();
      final controller = c.read(provider.notifier);

      controller.updateMemo('Netflix');
      controller.appendDigit(1);
      controller.appendDigit(5);
      controller.updateCategory(10);
      controller.updateAccount(20);
      controller.updateDayOfMonth(15);

      final pendingSave = controller.save();

      completer.complete(
        const RecurringGenerationOutcome(
          ruleId: 42,
          generated: 1,
          capped: false,
        ),
      );
      final id = await pendingSave;

      expect(id, 42);
      expect(c.read(provider).valueOrNull!.isLoading, isFalse);
    });
  });
}
