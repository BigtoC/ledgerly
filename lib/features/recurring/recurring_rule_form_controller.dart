import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/currency.dart';
import '../../data/models/recurring_rule_draft.dart';
import '../../data/repositories/recurring_rules_repository.dart';
import '../transactions/keypad_state.dart';
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
  /// Calculator keypad state. Mirrors `state.amountMinorUnits` and bumps
  /// `keypadRevision` on every press so the screen rebuilds even when
  /// `amountMinorUnits` doesn't change (decimal-start, operator press).
  KeypadState _keypad = const KeypadState.initial();
  int _keypadRevision = 0;

  /// Read-only accessor for the screen — `AmountDisplay` reads this to
  /// render the calculator's expression history and current input.
  KeypadState get keypadSnapshot => _keypad;

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
      _keypad = _keypadFromAmount(
        rule.amountMinorUnits,
        decimals: rule.currency.decimals,
      );
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
      );
    }

    _keypad = const KeypadState.initial();
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

  void appendDigit(int digit) {
    final s = state.valueOrNull;
    if (s == null || s.isLoading) return;
    _keypad = _keypad.push(digit, decimals: s.currency.decimals);
    _emitKeypad();
  }

  void appendDecimal() {
    final s = state.valueOrNull;
    if (s == null || s.isLoading) return;
    _keypad = _keypad.pushDecimal(decimals: s.currency.decimals);
    _emitKeypad();
  }

  void backspace() {
    final s = state.valueOrNull;
    if (s == null || s.isLoading) return;
    final next = _keypad.pop(decimals: s.currency.decimals);
    if (next == _keypad) return;
    _keypad = next;
    _emitKeypad();
  }

  void clearAmount() {
    final s = state.valueOrNull;
    if (s == null || s.isLoading) return;
    final next = _keypad.clear();
    if (next == _keypad) return;
    _keypad = next;
    _emitKeypad();
  }

  void applyOperator(CalcOperator op) {
    final s = state.valueOrNull;
    if (s == null || s.isLoading) return;
    final next = _keypad.pushOperator(op, decimals: s.currency.decimals);
    if (next == _keypad) return;
    _keypad = next;
    _emitKeypad();
  }

  void _emitKeypad() {
    _keypadRevision += 1;
    _update((s) => s.copyWith(amountMinorUnits: _keypad.amountMinorUnits));
  }

  void updateCurrency(Currency currency) =>
      _update((s) => s.copyWith(currency: currency));

  void updateCategory(int categoryId) =>
      _update((s) => s.copyWith(categoryId: categoryId, categoryError: null));

  void updateAccount(int accountId) =>
      _update((s) => s.copyWith(accountId: accountId, accountError: null));

  void updateFrequency(String frequency) {
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
  }

  void updateDayOfWeek(int? day) => _update(
    (s) => s.copyWith(
      dayOfWeek: day,
      frequencyFieldError: day != null ? null : s.frequencyFieldError,
    ),
  );

  void updateDayOfMonth(int? day) => _update(
    (s) => s.copyWith(
      dayOfMonth: day,
      frequencyFieldError:
          day != null && (s.frequency != 'yearly' || s.monthOfYear != null)
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

  /// Save the draft. Returns the rule id on success (creates or updates),
  /// `null` if `canSave` was false or a known repository error fired.
  /// On success, immediately runs generation for the new rule so the user
  /// sees today's pending row without waiting for a cold start.
  Future<int?> save() async {
    final current = state.valueOrNull;
    if (current == null) return null;
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
      return null;
    }

    _update((s) => s.copyWith(isLoading: true, formError: null));
    try {
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

      final repo = ref.read(recurringRulesRepositoryProvider);
      final int savedId;
      if (current.isEdit && ruleId != null) {
        await repo.update(ruleId!, draft);
        savedId = ruleId!;
      } else {
        savedId = await repo.insert(draft);
      }

      final useCase = ref.read(recurringGenerationUseCaseProvider);
      final outcome = await useCase.executeForRule(savedId);
      _update((s) => s.copyWith(postSaveGenerationFailed: outcome.failed));
      return savedId;
    } on ArchivedReferenceException catch (e) {
      _update(
        (s) => s.copyWith(formError: RecurringFormError.archivedRef(e.message)),
      );
      return null;
    } on RecurringRulesRepositoryException catch (e) {
      _update(
        (s) => s.copyWith(formError: RecurringFormError.unknown(e.message)),
      );
      return null;
    } finally {
      _update((s) => s.copyWith(isLoading: false));
    }
  }

  Future<void> deleteRule() async {
    if (ruleId == null) return;
    await ref.read(recurringRulesRepositoryProvider).archive(ruleId!);
  }

  void _update(RecurringRuleFormState Function(RecurringRuleFormState) fn) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(fn(current).copyWith(keypadRevision: _keypadRevision));
  }

  /// Reconstructs a [KeypadState] from a stored amount so backspace on a
  /// hydrated edit value walks back through the visible digits rather
  /// than dropping the whole amount in one press. Mirrors the equivalent
  /// helper on `TransactionFormController`.
  KeypadState _keypadFromAmount(int amountMinorUnits, {required int decimals}) {
    if (amountMinorUnits == 0 || decimals == 0) {
      return KeypadState(
        amountMinorUnits: amountMinorUnits,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        hasCurrentInput: amountMinorUnits != 0,
      );
    }
    final unit = _pow10(decimals);
    final fractionalRemainder = amountMinorUnits % unit;
    if (fractionalRemainder == 0) {
      return KeypadState(
        amountMinorUnits: amountMinorUnits,
        fractionalDigitsEntered: 0,
        isFractionalMode: false,
        hasCurrentInput: true,
      );
    }
    return KeypadState(
      amountMinorUnits: amountMinorUnits,
      fractionalDigitsEntered: decimals,
      isFractionalMode: true,
      hasCurrentInput: true,
    );
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
