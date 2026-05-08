import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/currency.dart';

part 'recurring_rule_form_state.freezed.dart';

/// Typed validation-error keys. Decouples controller from l10n.
enum RecurringFormErrorKey {
  /// Memo doubles as the rule's user-visible name; required.
  nameRequired,
  amountRequired,
  categoryRequired,
  accountRequired,
  frequencyFieldRequired,
}

/// Save-time error surfaced on the form's banner.
sealed class RecurringFormError {
  const RecurringFormError();
  const factory RecurringFormError.archivedRef(String detail) = ArchivedRefErr;
  const factory RecurringFormError.unknown(String detail) = UnknownErr;
}

class ArchivedRefErr extends RecurringFormError {
  const ArchivedRefErr(this.detail);
  final String detail;
}

class UnknownErr extends RecurringFormError {
  const UnknownErr(this.detail);
  final String detail;
}

@freezed
abstract class RecurringRuleFormState with _$RecurringRuleFormState {
  const factory RecurringRuleFormState({
    /// User-visible label for the rule. Stored in `recurring_rules.memo`
    /// and copied verbatim into `recurring_rules.name` on save (the form
    /// no longer surfaces a separate Name field).
    @Default('') String memo,
    @Default(0) int amountMinorUnits,
    required Currency currency,
    int? categoryId,
    int? accountId,
    @Default('monthly') String frequency,
    int? dayOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    @Default(false) bool isEdit,
    @Default(false) bool isLoading,
    int? pendingItemCount,

    /// Bumped on every keypad mutation (digit, decimal, backspace,
    /// operator) so the screen rebuilds even when `amountMinorUnits`
    /// itself didn't change (decimal-start, operator press).
    @Default(0) int keypadRevision,
    RecurringFormErrorKey? nameError,
    RecurringFormErrorKey? categoryError,
    RecurringFormErrorKey? accountError,
    RecurringFormErrorKey? frequencyFieldError,
    RecurringFormError? formError,
    @Default(false) bool postSaveGenerationFailed,
  }) = _RecurringRuleFormState;

  const RecurringRuleFormState._();

  bool get hasFrequencyFieldError {
    switch (frequency) {
      case 'weekly':
        return dayOfWeek == null;
      case 'monthly':
        return dayOfMonth == null;
      case 'yearly':
        return monthOfYear == null || dayOfMonth == null;
      default:
        return false;
    }
  }

  bool get canSave =>
      memo.trim().isNotEmpty &&
      amountMinorUnits > 0 &&
      categoryId != null &&
      accountId != null &&
      !hasFrequencyFieldError;
}
