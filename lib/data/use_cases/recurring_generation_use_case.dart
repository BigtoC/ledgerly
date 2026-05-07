// `RecurringGenerationUseCase` — scans active rules, creates pending rows,
// advances next_due_date.
//
// Lives in `data/use_cases/`, not `domain/`. Callers (bootstrap, the form
// controller after save) construct it manually with the two repositories
// and an `AppDatabase` handle. The DB handle is required because the use
// case wraps each rule's per-rule generation in a SAVEPOINT (Drift's
// nested `db.transaction(...)`) for failure isolation while amortizing
// the outer fsync cost.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/recurring_rule.dart';
import '../repositories/pending_transaction_repository.dart';
import '../repositories/recurring_rules_repository.dart';

class RecurringGenerationUseCase {
  RecurringGenerationUseCase({
    required this.recurringRepo,
    required this.pendingRepo,
    required this.db,
  });

  final RecurringRulesRepository recurringRepo;
  final PendingTransactionRepository pendingRepo;
  final AppDatabase db;

  /// Hard cap on per-rule generations in a single pass. Daily rules that
  /// have been silent for >12 days fast-forward to "today" and surface a
  /// cap-hit signal in the outcome.
  static const int catchUpCap = 12;

  /// Pathological-input guard for [RecurringRulesRepository.fastForwardToRecent].
  static const int _fastForwardSafetyCap = 10000;

  /// Run for every active, due rule. Used by bootstrap on cold start.
  /// Returns per-rule outcomes so callers can surface cap-hit / failure
  /// state without parsing logs.
  Future<RecurringGenerationResult> execute({
    DateTime Function()? clock,
  }) async {
    final now = clock?.call() ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dueRules = await recurringRepo.findDue(today);
    if (dueRules.isEmpty) {
      return const RecurringGenerationResult(outcomes: []);
    }

    return db.transaction<RecurringGenerationResult>(() async {
      final outcomes = <RecurringGenerationOutcome>[];
      for (final rule in dueRules) {
        outcomes.add(await _processRuleSafely(rule, today, clock));
      }
      return RecurringGenerationResult(outcomes: outcomes);
    });
  }

  /// Run for a single rule. Used by `RecurringRuleFormController.save()`
  /// after a successful insert/update so the user sees today's pending
  /// row without waiting for the next cold start.
  Future<RecurringGenerationOutcome> executeForRule(
    int ruleId, {
    DateTime Function()? clock,
  }) async {
    final now = clock?.call() ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rule = await recurringRepo.getById(ruleId);
    if (rule == null || !rule.isActive || rule.isArchived) {
      return RecurringGenerationOutcome.skipped(ruleId);
    }
    if (rule.nextDueDate.isAfter(today)) {
      // Future-dated: clear any prior error so the badge doesn't persist
      // after the user fixed the rule.
      await recurringRepo.clearFailure(ruleId);
      return RecurringGenerationOutcome.skipped(ruleId);
    }
    return db.transaction(() => _processRuleSafely(rule, today, clock));
  }

  Future<RecurringGenerationOutcome> _processRuleSafely(
    RecurringRule rule,
    DateTime today,
    DateTime Function()? clock,
  ) async {
    try {
      // Drift translates nested `transaction` to SAVEPOINT — per-rule
      // failures roll back this rule only, leaving sibling outcomes intact.
      return await db.transaction(() => _processRule(rule, today, clock));
    } on Object catch (cause) {
      // Defensive nested try/catch: if the failure-recording write itself
      // fails (DB locked, disk full, FK regression), DO NOT let that
      // escape and roll back the OUTER bootstrap transaction.
      try {
        await recurringRepo.recordFailure(
          rule.id,
          cause.toString(),
          DateTime.now(),
        );
      } on Object {
        // Swallow — observable only via the returned `failed` outcome
        // and the next cold start retry.
      }
      return RecurringGenerationOutcome.failed(rule.id);
    }
  }

  Future<RecurringGenerationOutcome> _processRule(
    RecurringRule rule,
    DateTime today,
    DateTime Function()? clock,
  ) async {
    var currentDue = rule.nextDueDate;
    var generated = 0;
    var capped = false;

    while (!_isAfter(currentDue, today) && generated < catchUpCap) {
      final exists = await pendingRepo.existsForRuleAndDate(
        rule.id,
        currentDue,
      );
      if (!exists) {
        final now = clock?.call() ?? DateTime.now();
        await pendingRepo.insert(
          source: 'recurring',
          amountMinorUnits: rule.amountMinorUnits,
          currencyCode: rule.currency.code,
          categoryId: rule.categoryId,
          accountId: rule.accountId,
          memo: rule.memo,
          date: currentDue,
          fetchedAt: now,
          recurringRuleId: rule.id,
        );
      }
      currentDue = recurringRepo.advanceDateByFrequency(rule, currentDue);
      generated++;
    }

    if (generated == catchUpCap && !_isAfter(currentDue, today)) {
      currentDue = recurringRepo.fastForwardToRecent(
        rule,
        today,
        safetyCap: _fastForwardSafetyCap,
      );
      capped = true;
    }

    await recurringRepo.advanceAfterGeneration(rule.id, currentDue);
    await recurringRepo.clearFailure(rule.id);

    return RecurringGenerationOutcome(
      ruleId: rule.id,
      generated: generated,
      capped: capped,
    );
  }

  bool _isAfter(DateTime a, DateTime b) {
    return a.isAfter(DateTime(b.year, b.month, b.day));
  }
}

/// Outcome of generating for a single rule.
class RecurringGenerationOutcome {
  const RecurringGenerationOutcome({
    required this.ruleId,
    required this.generated,
    required this.capped,
    this.failed = false,
    this.skipped = false,
  });

  factory RecurringGenerationOutcome.failed(int ruleId) =>
      RecurringGenerationOutcome(
        ruleId: ruleId,
        generated: 0,
        capped: false,
        failed: true,
      );

  factory RecurringGenerationOutcome.skipped(int ruleId) =>
      RecurringGenerationOutcome(
        ruleId: ruleId,
        generated: 0,
        capped: false,
        skipped: true,
      );

  final int ruleId;
  final int generated;
  final bool capped;
  final bool failed;
  final bool skipped;
}

/// Aggregate result of a generation pass (bootstrap or runtime).
class RecurringGenerationResult {
  const RecurringGenerationResult({required this.outcomes});
  final List<RecurringGenerationOutcome> outcomes;

  bool get anyCapped => outcomes.any((o) => o.capped);
  bool get anyFailed => outcomes.any((o) => o.failed);
  Iterable<int> get cappedRuleIds =>
      outcomes.where((o) => o.capped).map((o) => o.ruleId);
  Iterable<int> get failedRuleIds =>
      outcomes.where((o) => o.failed).map((o) => o.ruleId);
}

/// Bootstrap stores its single result here for Home (Wave 3) to read.
/// Default body throws — every test/runtime must override the value via
/// `ProviderScope` so missing-override bugs fail loudly instead of
/// silently returning `null`.
final lastGenerationResultProvider = Provider<RecurringGenerationResult>(
  (ref) => throw UnimplementedError(
    'lastGenerationResultProvider must be overridden by '
    'bootstrap() or a test harness',
  ),
  dependencies: const [],
);
