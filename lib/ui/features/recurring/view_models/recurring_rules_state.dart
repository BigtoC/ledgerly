import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/recurring_rule.dart';

part 'recurring_rules_state.freezed.dart';

/// Pending-delete sentinel for the rules screen's swipe-to-delete + undo
/// pattern. Mirrors `ShoppingListPendingDelete`.
class RecurringRulesPendingDelete {
  const RecurringRulesPendingDelete({required this.ruleId});
  final int ruleId;
}

@freezed
sealed class RecurringRulesState with _$RecurringRulesState {
  const factory RecurringRulesState.loading() = RecurringRulesLoading;
  const factory RecurringRulesState.empty() = RecurringRulesEmpty;
  const factory RecurringRulesState.data({
    required List<RecurringRule> rules,
    required RecurringRulesPendingDelete? pendingDelete,
  }) = RecurringRulesData;
  const factory RecurringRulesState.error(Object error, StackTrace stack) =
      RecurringRulesError;
}

/// Result of [RecurringRulesController.pauseRule].
@freezed
sealed class PauseRecurringRuleOutcome with _$PauseRecurringRuleOutcome {
  /// Paused. The widget shows the "Paused" snackbar.
  const factory PauseRecurringRuleOutcome.ok() = PauseRecurringRuleOk;

  /// Not paused. The widget shows the generic error snackbar.
  const factory PauseRecurringRuleOutcome.failed() = PauseRecurringRuleFailed;
}

/// Result of [RecurringRulesController.resumeRule].
@freezed
sealed class ResumeRecurringRuleOutcome with _$ResumeRecurringRuleOutcome {
  /// Resumed. The widget shows the "Resumed" snackbar with [nextDueDate],
  /// which is null when the resumed rule could not be read back.
  const factory ResumeRecurringRuleOutcome.ok(DateTime? nextDueDate) =
      ResumeRecurringRuleOk;

  /// Not resumed. The widget shows the generic error snackbar.
  const factory ResumeRecurringRuleOutcome.failed() = ResumeRecurringRuleFailed;
}

/// Result of [RecurringRulesController.deleteRule].
@freezed
sealed class DeleteRecurringRuleOutcome with _$DeleteRecurringRuleOutcome {
  /// The row is hidden and its undo window is open. The widget shows the
  /// "Rule deleted" snackbar with Undo.
  const factory DeleteRecurringRuleOutcome.pending() =
      DeleteRecurringRulePending;

  /// An earlier pending delete failed to commit, or the screen closed
  /// while it was committing, so this row was not hidden. The widget
  /// shows the generic error snackbar and no Undo.
  const factory DeleteRecurringRuleOutcome.notStarted() =
      DeleteRecurringRuleNotStarted;
}
