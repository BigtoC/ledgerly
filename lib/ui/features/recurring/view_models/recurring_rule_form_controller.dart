import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../data/repositories/recurring_rules_repository.dart';
import '../../../../domain/models/currency.dart';
import '../../../../domain/models/recurring_rule_draft.dart';
import '../../transactions/view_models/keypad_state.dart';
import 'recurring_rule_form_state.dart';

part 'recurring_rule_form_controller.g.dart';

@Riverpod(
  dependencies: [
    recurringRulesRepository,
    pendingTransactionRepository,
    recurringGenerationUseCase,
    currencyRepository,
    userPreferencesRepository,
  ],
)
class RecurringRuleFormController extends _$RecurringRuleFormController {
  @override
  Future<RecurringRuleFormState> build({int? ruleId}) async {
    final userPrefs = ref.watch(userPreferencesRepositoryProvider);
    final currencyRepo = ref.watch(currencyRepositoryProvider);
    final defaultCode = await userPrefs.getDefaultCurrency();
    final defaultCurrency = await currencyRepo.getByCode(defaultCode);

    if (ruleId != null) {
      final repo = ref.watch(recurringRulesRepositoryProvider);
      final rule = await repo.getById(ruleId);
      if (rule == null) {
        throw StateError('Recurring rule $ruleId not found');
      }
      final pendingRepo = ref.watch(pendingTransactionRepositoryProvider);
      final pendingCount = await pendingRepo.countByRecurringRule(ruleId);
      // Memo doubles as the rule name. Prefer the stored memo so user
      // edits round-trip; fall back to `rule.name` for legacy rows.
      final memo = (rule.memo?.trim().isNotEmpty ?? false)
          ? rule.memo!
          : rule.name;
      return RecurringRuleFormState(
        memo: memo,
        amountMinorUnits: rule.amountMinorUnits,
        currency: rule.currency,
        categoryId: rule.categoryId,
        accountId: rule.accountId,
        frequency: rule.frequency,
        dayOfWeek: rule.dayOfWeek,
        dayOfMonth: rule.dayOfMonth,
        monthOfYear: rule.monthOfYear,
        isEdit: true,
        pendingItemCount: pendingCount,
        keypad: KeypadState.fromAmount(
          rule.amountMinorUnits,
          decimals: rule.currency.decimals,
        ),
      );
    }

    return RecurringRuleFormState(
      currency: defaultCurrency ?? const Currency(code: 'USD', decimals: 2),
    );
  }

  // ---------- Field updates ----------

  void updateMemo(String memo) =>
      _update((s) => s.copyWith(memo: memo, nameError: null));

  /// Called from the memo field's focus-loss handler.
  void touchMemo() => _update(
    (s) => s.copyWith(
      nameError: s.memo.trim().isEmpty
          ? RecurringFormErrorKey.nameRequired
          : null,
    ),
  );

  // ---------- Keypad commands ----------

  void appendDigit(int digit) =>
      _press((k, decimals) => k.push(digit, decimals: decimals));

  void appendDecimal() =>
      _press((k, decimals) => k.pushDecimal(decimals: decimals));

  void backspace() => _press((k, decimals) => k.pop(decimals: decimals));

  void clearAmount() => _press((k, _) => k.clear());

  void applyOperator(CalcOperator op) =>
      _press((k, decimals) => k.pushOperator(op, decimals: decimals));

  void applyPercent() =>
      _press((k, decimals) => k.pushPercent(decimals: decimals));

  void equals() => _press((k, decimals) => k.equals(decimals: decimals));

  /// `amountMinorUnits` mirrors the value `=` would produce, so a pending
  /// expression (`1 + 2`) is validated and saved as its result.
  void _press(KeypadState Function(KeypadState keypad, int decimals) press) {
    final s = state.value;
    if (s == null || s.isLoading) return;
    final decimals = s.currency.decimals;
    final next = press(s.keypad, decimals);
    if (next == s.keypad) return;
    state = AsyncData(
      s.copyWith(
        keypad: next,
        amountMinorUnits: next.equals(decimals: decimals).amountMinorUnits,
      ),
    );
  }

  void updateCategory(int categoryId) =>
      _update((s) => s.copyWith(categoryId: categoryId, categoryError: null));

  void updateAccount(int accountId) =>
      _update((s) => s.copyWith(accountId: accountId, accountError: null));

  /// Returns the resulting `dayOfMonth`, so the screen can sync its field.
  int? updateFrequency(String frequency) {
    _update((s) {
      var dayOfMonth = s.dayOfMonth;
      if ((frequency == 'monthly' || frequency == 'yearly') &&
          dayOfMonth == null) {
        final today = DateTime.now();
        dayOfMonth = today.day > 28 ? 28 : today.day;
      } else if (frequency == 'daily' || frequency == 'weekly') {
        dayOfMonth = null;
      }
      final next = s.copyWith(
        frequency: frequency,
        dayOfWeek: frequency == 'weekly' ? s.dayOfWeek : null,
        dayOfMonth: dayOfMonth,
        monthOfYear: frequency == 'yearly' ? s.monthOfYear : null,
      );
      return next.copyWith(
        frequencyFieldError: next.hasFrequencyFieldError
            ? RecurringFormErrorKey.frequencyFieldRequired
            : null,
      );
    });
    return state.value?.dayOfMonth;
  }

  void updateDayOfWeek(int day) =>
      _update((s) => s.copyWith(dayOfWeek: day, frequencyFieldError: null));

  void updateDayOfMonth(int day) => _update(
    (s) => s.copyWith(
      dayOfMonth: day,
      frequencyFieldError: s.frequency != 'yearly' || s.monthOfYear != null
          ? null
          : s.frequencyFieldError,
    ),
  );

  void updateMonthOfYear(int? month) => _update(
    (s) => s.copyWith(
      monthOfYear: month,
      frequencyFieldError: month != null && s.dayOfMonth != null
          ? null
          : s.frequencyFieldError,
    ),
  );

  // ---------- Commands ----------

  /// Save the draft (creates or updates). Never throws; see
  /// [SaveRecurringRuleOutcome]. Validation failures and known repository
  /// errors are written to the form state and reported as `rejected`.
  /// On success, immediately runs generation for the new rule so the user
  /// sees today's pending row without waiting for a cold start; a
  /// generation error, returned or thrown, is reported as `saved` with
  /// `generationFailed`. The repository and use case are read before the
  /// first await, so closing the form mid-save still runs generation for
  /// the saved rule.
  Future<SaveRecurringRuleOutcome> save() async {
    try {
      final current = state.value;
      if (current == null) return const SaveRecurringRuleOutcome.failed();
      if (!current.canSave) {
        _update(
          (s) => s.copyWith(
            nameError: s.memo.trim().isEmpty
                ? RecurringFormErrorKey.nameRequired
                : null,
            categoryError: s.categoryId == null
                ? RecurringFormErrorKey.categoryRequired
                : null,
            accountError: s.accountId == null
                ? RecurringFormErrorKey.accountRequired
                : null,
            frequencyFieldError: s.hasFrequencyFieldError
                ? RecurringFormErrorKey.frequencyFieldRequired
                : null,
          ),
        );
        return const SaveRecurringRuleOutcome.rejected();
      }
      final repo = ref.read(recurringRulesRepositoryProvider);
      final useCase = ref.read(recurringGenerationUseCaseProvider);

      // Saving finishes a pending expression, as if `=` had been pressed.
      equals();
      _update((s) => s.copyWith(isLoading: true, formError: null));

      // Memo doubles as the rule's user-visible name; both columns get
      // the same trimmed value so list tiles and pending-row memos stay
      // in sync.
      final memo = current.memo.trim();
      final draft = RecurringRuleDraft(
        name: memo,
        amountMinorUnits: current.amountMinorUnits,
        currency: current.currency,
        categoryId: current.categoryId!,
        accountId: current.accountId!,
        memo: memo,
        frequency: current.frequency,
        dayOfWeek: current.dayOfWeek,
        dayOfMonth: current.dayOfMonth,
        monthOfYear: current.monthOfYear,
      );

      final int savedId;
      if (current.isEdit && ruleId != null) {
        await repo.update(ruleId!, draft);
        savedId = ruleId!;
      } else {
        savedId = await repo.insert(draft);
      }

      // The rule is saved from here on, so a generation error must not
      // turn into `failed`: the user would retry and insert it twice.
      bool generationFailed;
      try {
        generationFailed = (await useCase.executeForRule(savedId)).failed;
      } catch (e) {
        debugPrint(
          '[RecurringRuleFormController] save generation failed: '
          '${e.runtimeType}',
        );
        generationFailed = true;
      }
      return SaveRecurringRuleOutcome.saved(savedId, generationFailed);
    } on RecurringRulesRepositoryException catch (e) {
      if (ref.mounted) _update((s) => s.copyWith(formError: e.message));
      return const SaveRecurringRuleOutcome.rejected();
    } catch (e) {
      debugPrint('[RecurringRuleFormController] save failed: ${e.runtimeType}');
      return const SaveRecurringRuleOutcome.failed();
    } finally {
      if (ref.mounted) _update((s) => s.copyWith(isLoading: false));
    }
  }

  /// Archives the rule being edited. Never throws; see
  /// [ArchiveRecurringRuleOutcome].
  Future<ArchiveRecurringRuleOutcome> deleteRule() async {
    try {
      if (ruleId == null) return const ArchiveRecurringRuleOutcome.failed();
      await ref.read(recurringRulesRepositoryProvider).archive(ruleId!);
      return const ArchiveRecurringRuleOutcome.ok();
    } catch (e) {
      debugPrint(
        '[RecurringRuleFormController] deleteRule failed: ${e.runtimeType}',
      );
      return const ArchiveRecurringRuleOutcome.failed();
    }
  }

  void _update(RecurringRuleFormState Function(RecurringRuleFormState) fn) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(fn(current));
  }
}
