// Recurring transactions integration tests.
//
// These exercise the full data-layer pipeline against a real (in-memory)
// AppDatabase: the repository computes next_due_date, the use case scans
// active rules and writes pending rows, and the v4 partial UNIQUE index
// backstops idempotency. Bootstrap-level wiring is also validated by
// running `bootstrapFor` against the test DB and asserting that
// generation actually fired.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/data/database/app_database.dart' show AppDatabase;
import 'package:ledgerly/data/models/currency.dart';
import 'package:ledgerly/data/models/recurring_rule_draft.dart';
import 'package:ledgerly/data/repositories/account_repository.dart';
import 'package:ledgerly/data/repositories/currency_repository.dart';
import 'package:ledgerly/data/repositories/pending_transaction_repository.dart';
import 'package:ledgerly/data/repositories/recurring_rules_repository.dart';
import 'package:ledgerly/data/services/locale_service.dart';
import 'package:ledgerly/data/use_cases/recurring_generation_use_case.dart';

import '../support/test_app.dart';

class _FixedLocaleService implements LocaleService {
  const _FixedLocaleService(this.deviceLocale);
  @override
  final String deviceLocale;
}

Future<({int accountId, int categoryId, Currency currency})> _seedBasics(
  AppDatabase db,
) async {
  final currencies = DriftCurrencyRepository(db);
  final usd = await currencies.getByCode('USD');
  final categoryId = await getSeededCategoryId(db, 'category.food');
  final accountTypeId = await getAccountTypeId(db, 'accountType.cash');

  // Find the Cash account from the seed (created with default currency).
  final accounts = DriftAccountRepository(db, currencies);
  final all = await accounts.watchAll().first;
  final cash = all.firstWhere((a) => a.accountTypeId == accountTypeId);
  return (accountId: cash.id, categoryId: categoryId, currency: usd!);
}

void main() {
  group('Recurring transactions integration', () {
    test('create rule → execute use case → pending row inserted, '
        'next_due advanced', () async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await runTestSeed(db);

      final basics = await _seedBasics(db);
      final repo = DriftRecurringRulesRepository(db);
      final pendingRepo = DriftPendingTransactionRepository(db);
      final useCase = RecurringGenerationUseCase(
        recurringRepo: repo,
        pendingRepo: pendingRepo,
        db: db,
      );

      final ruleId = await repo.insert(
        RecurringRuleDraft(
          name: 'Netflix',
          amountMinorUnits: 1599,
          currency: basics.currency,
          categoryId: basics.categoryId,
          accountId: basics.accountId,
          frequency: 'monthly',
          dayOfMonth: 15,
        ),
        today: DateTime(2026, 3, 5),
      );

      // Initial next_due = March 15.
      var rule = await repo.getById(ruleId);
      expect(rule!.nextDueDate, DateTime(2026, 3, 15));

      // First "cold start" on March 16 — generates one pending row.
      final result = await useCase.execute(clock: () => DateTime(2026, 3, 16));
      expect(result.outcomes, hasLength(1));
      expect(result.outcomes.single.generated, 1);
      expect(result.anyFailed, isFalse);

      // next_due advanced to April 15.
      rule = await repo.getById(ruleId);
      expect(rule!.nextDueDate, DateTime(2026, 4, 15));

      // Pending row exists for the rule + March 15.
      expect(
        await pendingRepo.existsForRuleAndDate(ruleId, DateTime(2026, 3, 15)),
        isTrue,
      );
      expect(await pendingRepo.countByRecurringRule(ruleId), 1);
    });

    test('idempotency: running execute() twice on same day does not '
        'duplicate pending rows', () async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await runTestSeed(db);

      final basics = await _seedBasics(db);
      final repo = DriftRecurringRulesRepository(db);
      final pendingRepo = DriftPendingTransactionRepository(db);
      final useCase = RecurringGenerationUseCase(
        recurringRepo: repo,
        pendingRepo: pendingRepo,
        db: db,
      );

      final ruleId = await repo.insert(
        RecurringRuleDraft(
          name: 'Daily',
          amountMinorUnits: 100,
          currency: basics.currency,
          categoryId: basics.categoryId,
          accountId: basics.accountId,
          frequency: 'daily',
        ),
        today: DateTime(2026, 5, 7),
      );

      // First run.
      await useCase.execute(clock: () => DateTime(2026, 5, 7));
      // Second run on the same day should be a no-op (rule's next_due is
      // already > today).
      await useCase.execute(clock: () => DateTime(2026, 5, 7));

      expect(await pendingRepo.countByRecurringRule(ruleId), 1);
    });

    test('pause skips generation; resume recomputes next_due from today, '
        'missed periods are NOT back-generated', () async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await runTestSeed(db);

      final basics = await _seedBasics(db);
      final repo = DriftRecurringRulesRepository(db);
      final pendingRepo = DriftPendingTransactionRepository(db);
      final useCase = RecurringGenerationUseCase(
        recurringRepo: repo,
        pendingRepo: pendingRepo,
        db: db,
      );

      final ruleId = await repo.insert(
        RecurringRuleDraft(
          name: 'Daily',
          amountMinorUnits: 100,
          currency: basics.currency,
          categoryId: basics.categoryId,
          accountId: basics.accountId,
          frequency: 'daily',
        ),
        today: DateTime(2026, 5, 7),
      );

      await repo.setActive(ruleId, active: false);

      // Cold-start while paused → no pending rows generated.
      final result = await useCase.execute(clock: () => DateTime(2026, 5, 10));
      expect(result.outcomes, isEmpty);
      expect(await pendingRepo.countByRecurringRule(ruleId), 0);

      // Resume on May 15 — next_due should be today, not back-filled.
      await repo.setActive(ruleId, active: true, today: DateTime(2026, 5, 15));
      final rule = await repo.getById(ruleId);
      expect(rule!.nextDueDate, DateTime(2026, 5, 15));
    });

    test(
      'archive: rule no longer surfaces in watchActive nor in findDue',
      () async {
        final db = newTestAppDatabase();
        addTearDown(db.close);
        await runTestSeed(db);

        final basics = await _seedBasics(db);
        final repo = DriftRecurringRulesRepository(db);

        final ruleId = await repo.insert(
          RecurringRuleDraft(
            name: 'Daily',
            amountMinorUnits: 100,
            currency: basics.currency,
            categoryId: basics.categoryId,
            accountId: basics.accountId,
            frequency: 'daily',
          ),
          today: DateTime(2026, 5, 7),
        );

        await repo.archive(ruleId);

        final active = await repo.watchActive().first;
        expect(active, isEmpty);
        final due = await repo.findDue(DateTime(2026, 5, 7));
        expect(due, isEmpty);
      },
    );

    test('catch-up cap: 30-day-stale daily rule generates exactly '
        '${RecurringGenerationUseCase.catchUpCap} pending rows', () async {
      final db = newTestAppDatabase();
      addTearDown(db.close);
      await runTestSeed(db);

      final basics = await _seedBasics(db);
      final repo = DriftRecurringRulesRepository(db);
      final pendingRepo = DriftPendingTransactionRepository(db);
      final useCase = RecurringGenerationUseCase(
        recurringRepo: repo,
        pendingRepo: pendingRepo,
        db: db,
      );

      final ruleId = await repo.insert(
        RecurringRuleDraft(
          name: 'Daily',
          amountMinorUnits: 100,
          currency: basics.currency,
          categoryId: basics.categoryId,
          accountId: basics.accountId,
          frequency: 'daily',
        ),
        today: DateTime(2026, 4, 7),
      );

      // Cold-start 30 days later.
      final result = await useCase.execute(clock: () => DateTime(2026, 5, 7));
      expect(
        result.outcomes.single.generated,
        RecurringGenerationUseCase.catchUpCap,
      );
      expect(result.anyCapped, isTrue);
      expect(
        await pendingRepo.countByRecurringRule(ruleId),
        RecurringGenerationUseCase.catchUpCap,
      );
      // next_due now points to the first un-generated occurrence after today.
      final rule = await repo.getById(ruleId);
      expect(rule!.nextDueDate, DateTime(2026, 5, 8));
    });

    testWidgets('bootstrapFor() runs recurring generation as a post-seed step', (
      tester,
    ) async {
      // Pre-seed an active, due rule against the same DB instance that
      // bootstrap will reopen. Using a real DB confirms that bootstrap's
      // single-pass generation actually executes against persisted state.
      final db = newTestAppDatabase();
      addTearDown(db.close);
      late int ruleId;
      await tester.runAsync(() async {
        await runTestSeed(db);
        final basics = await _seedBasics(db);
        final repo = DriftRecurringRulesRepository(db);
        ruleId = await repo.insert(
          RecurringRuleDraft(
            name: 'Daily',
            amountMinorUnits: 100,
            currency: basics.currency,
            categoryId: basics.categoryId,
            accountId: basics.accountId,
            frequency: 'daily',
          ),
        );
      });

      // Read next_due before bootstrap (will equal today, set by repo.insert).
      late DateTime preBootstrapNextDue;
      await tester.runAsync(() async {
        final repo = DriftRecurringRulesRepository(db);
        final rule = await repo.getById(ruleId);
        preBootstrapNextDue = rule!.nextDueDate;
      });

      Widget? launched;
      await tester.runAsync(() async {
        await bootstrapFor(
          openDatabase: () async => db,
          localeService: const _FixedLocaleService('en_US'),
          runAppFn: (widget) => launched = widget,
        );
      });
      expect(launched, isA<ProviderScope>());

      await tester.runAsync(() async {
        final app = ((launched as ProviderScope).child as App);
        app.onFirstFrame!.call();
        for (var i = 0; i < 50; i++) {
          final pendingRepo = DriftPendingTransactionRepository(db);
          final repo = DriftRecurringRulesRepository(db);
          final rule = await repo.getById(ruleId);
          if (await pendingRepo.countByRecurringRule(ruleId) > 0 &&
              rule != null &&
              rule.nextDueDate.isAfter(preBootstrapNextDue)) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Timed out waiting for deferred recurring generation');
      });

      // After bootstrap, generation must have fired: at least one pending
      // row exists, and the rule's next_due_date advanced past the
      // pre-bootstrap value.
      await tester.runAsync(() async {
        final pendingRepo = DriftPendingTransactionRepository(db);
        final repo = DriftRecurringRulesRepository(db);
        final rule = await repo.getById(ruleId);
        expect(await pendingRepo.countByRecurringRule(ruleId), greaterThan(0));
        expect(rule!.nextDueDate.isAfter(preBootstrapNextDue), isTrue);
      });
    });
  });
}
