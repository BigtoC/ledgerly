// Use-case-level tests for [RecurringGenerationUseCase].
//
// `db.transaction(...)` cannot be honored by Mocktail without elaborate
// stubs, so we use a real in-memory `AppDatabase` and mock only the two
// repositories. The DB is needed only as a transaction host — it never
// receives writes (those go through the mocked repositories).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/data/use_cases/recurring_generation_use_case.dart';

import '../repositories/_harness/test_app_database.dart';

class _MockRecurringRulesRepository extends Mock
    implements RecurringRulesRepository {}

class _MockPendingTransactionRepository extends Mock
    implements PendingTransactionRepository {}

const _usd = Currency(code: 'USD', decimals: 2);

RecurringRule _rule({
  required int id,
  required DateTime nextDueDate,
  String name = 'Netflix',
  int amount = 1599,
  String frequency = 'monthly',
  int? dayOfMonth = 15,
  int? dayOfWeek,
  int? monthOfYear,
  bool isActive = true,
  bool isArchived = false,
  Currency currency = _usd,
}) => RecurringRule(
  id: id,
  name: name,
  amountMinorUnits: amount,
  currency: currency,
  categoryId: 1,
  accountId: 1,
  frequency: frequency,
  dayOfWeek: dayOfWeek,
  dayOfMonth: dayOfMonth,
  monthOfYear: monthOfYear,
  isActive: isActive,
  isArchived: isArchived,
  nextDueDate: nextDueDate,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

DateTime _addMonths(DateTime d, int months) {
  final m = d.month - 1 + months;
  final newYear = d.year + m ~/ 12;
  final newMonth = (m % 12) + 1;
  final lastDay = DateTime(newYear, newMonth + 1, 0).day;
  final day = d.day > lastDay ? lastDay : d.day;
  return DateTime(newYear, newMonth, day);
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
    registerFallbackValue(_rule(id: 0, nextDueDate: DateTime(2026, 1, 1)));
  });

  group('RecurringGenerationUseCase', () {
    late AppDatabase db;
    late _MockRecurringRulesRepository recurringRepo;
    late _MockPendingTransactionRepository pendingRepo;
    late RecurringGenerationUseCase useCase;

    setUp(() {
      db = newTestAppDatabase();
      recurringRepo = _MockRecurringRulesRepository();
      pendingRepo = _MockPendingTransactionRepository();
      useCase = RecurringGenerationUseCase(
        recurringRepo: recurringRepo,
        pendingRepo: pendingRepo,
        db: db,
      );

      // Default: no successful date math required for tests that don't
      // exercise the loop body. `advanceDateByFrequency` is overridden
      // per-test where needed.
      when(
        () => recurringRepo.advanceAfterGeneration(any(), any()),
      ).thenAnswer((_) async {});
      when(() => recurringRepo.clearFailure(any())).thenAnswer((_) async {});
      when(
        () => recurringRepo.recordFailure(any(), any(), any()),
      ).thenAnswer((_) async {});
    });

    tearDown(() async => db.close());

    test(
      'happy path: due rule generates pending row and advances date',
      () async {
        final today = DateTime(2026, 5, 15);
        final rule = _rule(id: 1, nextDueDate: DateTime(2026, 5, 15));

        when(
          () => recurringRepo.findDue(any()),
        ).thenAnswer((_) async => [rule]);
        when(
          () => recurringRepo.advanceDateByFrequency(any(), any()),
        ).thenAnswer((invocation) {
          final r = invocation.positionalArguments[0] as RecurringRule;
          final c = invocation.positionalArguments[1] as DateTime;
          return _addMonths(DateTime(c.year, c.month, r.dayOfMonth!), 1);
        });
        when(
          () => pendingRepo.existsForRuleAndDate(any(), any()),
        ).thenAnswer((_) async => false);
        when(
          () => pendingRepo.insert(
            source: any(named: 'source'),
            amountMinorUnits: any(named: 'amountMinorUnits'),
            currencyCode: any(named: 'currencyCode'),
            categoryId: any(named: 'categoryId'),
            accountId: any(named: 'accountId'),
            memo: any(named: 'memo'),
            date: any(named: 'date'),
            fetchedAt: any(named: 'fetchedAt'),
            recurringRuleId: any(named: 'recurringRuleId'),
          ),
        ).thenAnswer((_) async => 1);

        final result = await useCase.execute(clock: () => today);

        expect(result.outcomes, hasLength(1));
        expect(result.anyFailed, isFalse);
        expect(result.anyCapped, isFalse);
        verify(
          () => pendingRepo.insert(
            source: 'recurring',
            amountMinorUnits: 1599,
            currencyCode: 'USD',
            categoryId: 1,
            accountId: 1,
            memo: any(named: 'memo'),
            date: DateTime(2026, 5, 15),
            fetchedAt: any(named: 'fetchedAt'),
            recurringRuleId: 1,
          ),
        ).called(1);
        verify(
          () => recurringRepo.advanceAfterGeneration(1, DateTime(2026, 6, 15)),
        ).called(1);
        verify(() => recurringRepo.clearFailure(1)).called(1);
      },
    );

    test('idempotency: existing pending row is not re-inserted', () async {
      final today = DateTime(2026, 5, 15);
      final rule = _rule(id: 1, nextDueDate: DateTime(2026, 5, 15));

      when(() => recurringRepo.findDue(any())).thenAnswer((_) async => [rule]);
      when(() => recurringRepo.advanceDateByFrequency(any(), any())).thenAnswer(
        (invocation) {
          final c = invocation.positionalArguments[1] as DateTime;
          return DateTime(c.year, c.month + 1, c.day);
        },
      );
      when(
        () => pendingRepo.existsForRuleAndDate(any(), any()),
      ).thenAnswer((_) async => true); // Already exists.

      await useCase.execute(clock: () => today);

      verifyNever(
        () => pendingRepo.insert(
          source: any(named: 'source'),
          amountMinorUnits: any(named: 'amountMinorUnits'),
          currencyCode: any(named: 'currencyCode'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          memo: any(named: 'memo'),
          date: any(named: 'date'),
          fetchedAt: any(named: 'fetchedAt'),
          recurringRuleId: any(named: 'recurringRuleId'),
        ),
      );
      // next_due_date still advances even though the row was skipped.
      verify(
        () => recurringRepo.advanceAfterGeneration(1, DateTime(2026, 6, 15)),
      ).called(1);
    });

    test('catch-up cap: 30 stale daily occurrences produce exactly '
        '${RecurringGenerationUseCase.catchUpCap} pending rows', () async {
      final today = DateTime(2026, 5, 15);
      final rule = _rule(
        id: 1,
        frequency: 'daily',
        dayOfMonth: null,
        nextDueDate: DateTime(2026, 4, 15),
      );

      when(() => recurringRepo.findDue(any())).thenAnswer((_) async => [rule]);
      when(() => recurringRepo.advanceDateByFrequency(any(), any())).thenAnswer(
        (invocation) {
          final c = invocation.positionalArguments[1] as DateTime;
          return DateTime(c.year, c.month, c.day + 1);
        },
      );
      when(
        () => recurringRepo.fastForwardToRecent(
          any(),
          any(),
          safetyCap: any(named: 'safetyCap'),
        ),
      ).thenReturn(today);
      when(
        () => pendingRepo.existsForRuleAndDate(any(), any()),
      ).thenAnswer((_) async => false);
      when(
        () => pendingRepo.insert(
          source: any(named: 'source'),
          amountMinorUnits: any(named: 'amountMinorUnits'),
          currencyCode: any(named: 'currencyCode'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          memo: any(named: 'memo'),
          date: any(named: 'date'),
          fetchedAt: any(named: 'fetchedAt'),
          recurringRuleId: any(named: 'recurringRuleId'),
        ),
      ).thenAnswer((_) async => 1);

      final result = await useCase.execute(clock: () => today);

      expect(
        result.outcomes.single.generated,
        RecurringGenerationUseCase.catchUpCap,
      );
      expect(result.outcomes.single.capped, isTrue);
      expect(result.anyCapped, isTrue);
      verify(
        () => recurringRepo.fastForwardToRecent(
          any(),
          today,
          safetyCap: any(named: 'safetyCap'),
        ),
      ).called(1);
      verify(
        () => recurringRepo.advanceAfterGeneration(1, DateTime(2026, 5, 16)),
      ).called(1);
    });

    test('paused rule never reaches the loop (filtered by findDue)', () async {
      final today = DateTime(2026, 5, 15);
      // findDue is repository-side filtered by is_active. The use case
      // simply trusts that — verify it does not re-check.
      when(() => recurringRepo.findDue(any())).thenAnswer((_) async => []);

      final result = await useCase.execute(clock: () => today);

      expect(result.outcomes, isEmpty);
      verifyNever(
        () => pendingRepo.insert(
          source: any(named: 'source'),
          amountMinorUnits: any(named: 'amountMinorUnits'),
          currencyCode: any(named: 'currencyCode'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          memo: any(named: 'memo'),
          date: any(named: 'date'),
          fetchedAt: any(named: 'fetchedAt'),
          recurringRuleId: any(named: 'recurringRuleId'),
        ),
      );
    });

    test('multiple rules: failure in one does not abort siblings', () async {
      final today = DateTime(2026, 5, 15);
      final ruleA = _rule(id: 1, nextDueDate: DateTime(2026, 5, 15));
      final ruleB = _rule(
        id: 2,
        name: 'Rent',
        nextDueDate: DateTime(2026, 5, 15),
      );

      when(
        () => recurringRepo.findDue(any()),
      ).thenAnswer((_) async => [ruleA, ruleB]);
      when(() => recurringRepo.advanceDateByFrequency(any(), any())).thenAnswer(
        (invocation) {
          final c = invocation.positionalArguments[1] as DateTime;
          return DateTime(c.year, c.month + 1, c.day);
        },
      );
      // Rule 1 throws; rule 2 succeeds.
      when(
        () => pendingRepo.existsForRuleAndDate(1, any()),
      ).thenThrow(Exception('disk full'));
      when(
        () => pendingRepo.existsForRuleAndDate(2, any()),
      ).thenAnswer((_) async => false);
      when(
        () => pendingRepo.insert(
          source: any(named: 'source'),
          amountMinorUnits: any(named: 'amountMinorUnits'),
          currencyCode: any(named: 'currencyCode'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          memo: any(named: 'memo'),
          date: any(named: 'date'),
          fetchedAt: any(named: 'fetchedAt'),
          recurringRuleId: any(named: 'recurringRuleId'),
        ),
      ).thenAnswer((_) async => 1);

      final result = await useCase.execute(clock: () => today);

      expect(result.outcomes, hasLength(2));
      final byRule = {for (final o in result.outcomes) o.ruleId: o};
      expect(byRule[1]!.failed, isTrue);
      expect(byRule[2]!.failed, isFalse);
      expect(byRule[2]!.generated, 1);
      verify(() => recurringRepo.recordFailure(1, any(), any())).called(1);
    });

    test('executeForRule skips when rule is paused', () async {
      final today = DateTime(2026, 5, 15);
      final rule = _rule(
        id: 1,
        nextDueDate: DateTime(2026, 5, 15),
        isActive: false,
      );
      when(() => recurringRepo.getById(1)).thenAnswer((_) async => rule);

      final outcome = await useCase.executeForRule(1, clock: () => today);

      expect(outcome.skipped, isTrue);
      verifyNever(
        () => pendingRepo.insert(
          source: any(named: 'source'),
          amountMinorUnits: any(named: 'amountMinorUnits'),
          currencyCode: any(named: 'currencyCode'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
          memo: any(named: 'memo'),
          date: any(named: 'date'),
          fetchedAt: any(named: 'fetchedAt'),
          recurringRuleId: any(named: 'recurringRuleId'),
        ),
      );
    });

    test(
      'executeForRule with future-dated rule clears prior failure',
      () async {
        final today = DateTime(2026, 5, 15);
        final rule = _rule(id: 1, nextDueDate: DateTime(2026, 6, 1));
        when(() => recurringRepo.getById(1)).thenAnswer((_) async => rule);

        final outcome = await useCase.executeForRule(1, clock: () => today);

        expect(outcome.skipped, isTrue);
        verify(() => recurringRepo.clearFailure(1)).called(1);
      },
    );
  });
}
