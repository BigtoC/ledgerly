import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/currency.dart';
import '../../transactions/view_models/keypad_state.dart';

part 'recurring_rule_form_state.freezed.dart';

/// Typed validation-error keys. Decouples controller from l10n.
enum RecurringFormErrorKey {
  /// Memo doubles as the rule's user-visible name; required.
  nameRequired,
  categoryRequired,
  accountRequired,
  frequencyFieldRequired,
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

    /// Full calculator snapshot used by `AmountDisplay`.
    @Default(KeypadState.initial()) KeypadState keypad,
    RecurringFormErrorKey? nameError,
    RecurringFormErrorKey? categoryError,
    RecurringFormErrorKey? accountError,
    RecurringFormErrorKey? frequencyFieldError,
    String? formError,
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

/// Result of [RecurringRuleFormController.save].
@freezed
sealed class SaveRecurringRuleOutcome with _$SaveRecurringRuleOutcome {
  /// Saved as rule [ruleId]. The widget shows the saved snackbar, or the
  /// saved-but-generation-failed one when [generationFailed], and pops.
  const factory SaveRecurringRuleOutcome.saved(
    int ruleId,
    bool generationFailed,
  ) = SaveRecurringRuleSaved;

  /// Not saved, and the reason is already in the form state (field error
  /// keys or `formError`). The widget does nothing more.
  const factory SaveRecurringRuleOutcome.rejected() = SaveRecurringRuleRejected;

  /// Not saved for another reason. The widget shows the generic error
  /// snackbar and keeps the form open.
  const factory SaveRecurringRuleOutcome.failed() = SaveRecurringRuleFailed;
}

/// Result of [RecurringRuleFormController.deleteRule].
@freezed
sealed class ArchiveRecurringRuleOutcome with _$ArchiveRecurringRuleOutcome {
  /// Archived. The widget shows the "Rule deleted" snackbar and pops.
  const factory ArchiveRecurringRuleOutcome.ok() = ArchiveRecurringRuleOk;

  /// Not archived. The widget shows the generic error snackbar and keeps
  /// the form open.
  const factory ArchiveRecurringRuleOutcome.failed() =
      ArchiveRecurringRuleFailed;
}
