import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/models/recurring_rule.dart';

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
